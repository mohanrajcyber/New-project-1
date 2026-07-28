import { COMMON_PORTS, HTTP_PROBE_PORTS } from '../constants/ports';
import type { DiscoveredHost, OpenPort, ScanProgress } from '../types';

const PROBE_TIMEOUT_MS = 900;
const HOST_CONCURRENCY = 24;
const PORT_CONCURRENCY = 6;

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('timeout')), ms);
    promise.then(
      (value) => {
        clearTimeout(timer);
        resolve(value);
      },
      (err) => {
        clearTimeout(timer);
        reject(err);
      },
    );
  });
}

function schemeForPort(port: number): 'http' | 'https' {
  return port === 443 || port === 8443 ? 'https' : 'http';
}

async function probeHttpPort(ip: string, port: number): Promise<OpenPort | null> {
  const service = COMMON_PORTS.find((p) => p.port === port)?.service ?? `Port ${port}`;
  const url = `${schemeForPort(port)}://${ip}:${port}/`;
  const started = Date.now();

  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), PROBE_TIMEOUT_MS);
    const response = await fetch(url, {
      method: 'GET',
      signal: controller.signal,
      headers: { Accept: 'text/html,application/json,*/*' },
    });
    clearTimeout(timer);

    const server = response.headers.get('server') ?? undefined;
    let title: string | undefined;
    try {
      const text = await withTimeout(response.text(), 400);
      const match = text.match(/<title[^>]*>([^<]{1,80})<\/title>/i);
      title = match?.[1]?.trim();
    } catch {
      // ignore body parse failures
    }

    return {
      port,
      service,
      banner: [server, title].filter(Boolean).join(' · ') || undefined,
    };
  } catch {
    // A refused/reset connection usually means closed; timeouts/CORS-ish failures
    // on native can still indicate something listening — treat only clear success above.
    const elapsed = Date.now() - started;
    if (elapsed < PROBE_TIMEOUT_MS - 50) {
      // Fast failure often means RST / no route — closed.
      return null;
    }
    return null;
  }
}

/**
 * Best-effort probe for non-HTTP ports via WebSocket handshake.
 * Only counts a port open when the socket actually opens (low false positives in Expo).
 */
async function probeGenericPort(ip: string, port: number): Promise<OpenPort | null> {
  const service = COMMON_PORTS.find((p) => p.port === port)?.service ?? `Port ${port}`;

  return new Promise((resolve) => {
    let settled = false;
    const finish = (open: boolean) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      try {
        socket.close();
      } catch {
        // ignore
      }
      resolve(open ? { port, service } : null);
    };

    let socket: WebSocket;
    try {
      socket = new WebSocket(`ws://${ip}:${port}`);
    } catch {
      resolve(null);
      return;
    }

    const timer = setTimeout(() => finish(false), PROBE_TIMEOUT_MS);
    socket.onopen = () => finish(true);
    socket.onerror = () => finish(false);
    socket.onclose = () => {
      if (!settled) finish(false);
    };
  });
}

async function mapPool<T, R>(
  items: T[],
  concurrency: number,
  worker: (item: T, index: number) => Promise<R>,
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let next = 0;

  async function run() {
    while (next < items.length) {
      const index = next++;
      results[index] = await worker(items[index], index);
    }
  }

  const runners = Array.from({ length: Math.min(concurrency, items.length) }, () => run());
  await Promise.all(runners);
  return results;
}

export async function scanHostPorts(ip: string): Promise<OpenPort[]> {
  const ports = COMMON_PORTS.map((p) => p.port);
  const findings = await mapPool(ports, PORT_CONCURRENCY, async (port) => {
    if (HTTP_PROBE_PORTS.has(port)) {
      return probeHttpPort(ip, port);
    }
    return probeGenericPort(ip, port);
  });
  return findings.filter((f): f is OpenPort => Boolean(f)).sort((a, b) => a.port - b.port);
}

function guessHostname(ip: string, isGateway: boolean, ports: OpenPort[]): string {
  if (isGateway) return 'Router / Gateway';
  const banner = ports.find((p) => p.banner)?.banner;
  if (banner) {
    const short = banner.split('·')[0]?.trim();
    if (short) return short.slice(0, 40);
  }
  if (ports.some((p) => p.port === 631 || p.port === 9100)) return 'Printer';
  if (ports.some((p) => p.port === 554 || p.port === 8554)) return 'Camera / NVR';
  if (ports.some((p) => p.port === 445 || p.port === 139)) return 'File share';
  if (ports.some((p) => p.port === 22)) return 'SSH host';
  if (ports.some((p) => [80, 443, 8080, 8443].includes(p.port))) return 'Web server';
  return `Host ${ip.split('.').pop()}`;
}

export type ScanOptions = {
  subnetPrefix: string;
  gatewayIp?: string | null;
  selfIp?: string | null;
  /** 1..254 */
  from?: number;
  to?: number;
  onProgress?: (progress: ScanProgress) => void;
  onHost?: (host: DiscoveredHost) => void;
  signal?: AbortSignal;
};

export async function scanSubnet(options: ScanOptions): Promise<DiscoveredHost[]> {
  const from = options.from ?? 1;
  const to = options.to ?? 254;
  const hosts: DiscoveredHost[] = [];
  const ips = Array.from({ length: to - from + 1 }, (_, i) => `${options.subnetPrefix}.${from + i}`);
  let checked = 0;

  await mapPool(ips, HOST_CONCURRENCY, async (ip) => {
    if (options.signal?.aborted) return;

    const started = Date.now();
    // Quick liveness: probe a few likely HTTP ports first
    const quickPorts = [80, 443, 8080, 8000, 631];
    let alivePorts: OpenPort[] = [];

    for (const port of quickPorts) {
      if (options.signal?.aborted) break;
      const hit = await probeHttpPort(ip, port);
      if (hit) alivePorts.push(hit);
    }

    // Also try gateway / self even if quiet, and a light generic probe on .1
    const isGateway = ip === options.gatewayIp || ip.endsWith('.1');
    if (alivePorts.length === 0 && isGateway) {
      const ssh = await probeGenericPort(ip, 53);
      if (ssh) alivePorts.push(ssh);
    }

    checked += 1;
    options.onProgress?.({
      checked,
      total: ips.length,
      found: hosts.length + (alivePorts.length ? 1 : 0),
      currentIp: ip,
    });

    if (alivePorts.length === 0) return;

    // Deep scan remaining ports
    const known = new Set(alivePorts.map((p) => p.port));
    const remaining = COMMON_PORTS.map((p) => p.port).filter((p) => !known.has(p));
    const more = await mapPool(remaining, PORT_CONCURRENCY, async (port) => {
      if (options.signal?.aborted) return null;
      if (HTTP_PROBE_PORTS.has(port)) return probeHttpPort(ip, port);
      return probeGenericPort(ip, port);
    });
    alivePorts = [...alivePorts, ...more.filter((p): p is OpenPort => Boolean(p))].sort(
      (a, b) => a.port - b.port,
    );

    const host: DiscoveredHost = {
      ip,
      isGateway,
      openPorts: alivePorts,
      hostname: guessHostname(ip, isGateway, alivePorts),
      latencyMs: Date.now() - started,
    };

    hosts.push(host);
    options.onHost?.(host);
  });

  return hosts.sort((a, b) => {
    const aa = a.ip.split('.').map(Number);
    const bb = b.ip.split('.').map(Number);
    return aa[3] - bb[3];
  });
}
