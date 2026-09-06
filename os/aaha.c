/*
 * aaha — AahaOS operator CLI.
 *
 * Real in-initramfs commands: status, ident, mem, net, help.
 * lock reports mount flags and is NOT a security control.
 */
#define _GNU_SOURCE
#include <dirent.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/utsname.h>
#include <unistd.h>

static void usage(void)
{
    fputs("aaha — AahaOS operator CLI\n"
          "\n"
          "Usage: aaha <command>\n"
          "\n"
          "  status   short OS identity\n"
          "  ident    full identity (variant, os-release, machine)\n"
          "  mem      memory from /proc/meminfo (real)\n"
          "  net      local interfaces the kernel already exposes\n"
          "  lock     remount / read-only (changes /proc/mounts)\n"
          "  lock persist     encrypt /data (openssl AES-256)\n"
          "  unlock   remount / read-write\n"
          "  unlock persist   decrypt /data vault\n"
          "  lab      Lab tools menu\n"
          "  help     this text\n",
          stdout);
}

static void print_os_keys(void)
{
    FILE *fp = fopen("/etc/os-release", "r");
    char line[256];
    if (!fp) {
        return;
    }
    while (fgets(line, sizeof(line), fp)) {
        if (strncmp(line, "PRETTY_NAME=", 12) == 0 ||
            strncmp(line, "VERSION_ID=", 11) == 0 ||
            strncmp(line, "ID=", 3) == 0 ||
            strncmp(line, "VARIANT=", 8) == 0 ||
            strncmp(line, "VARIANT_ID=", 11) == 0) {
            fputs(line, stdout);
        }
    }
    fclose(fp);
}

static void read_trim(const char *path, char *out, size_t n, const char *fallback)
{
    FILE *fp = fopen(path, "r");
    if (!fp) {
        snprintf(out, n, "%s", fallback);
        return;
    }
    if (!fgets(out, (int)n, fp)) {
        snprintf(out, n, "%s", fallback);
    }
    fclose(fp);
    out[strcspn(out, "\r\n")] = '\0';
}

static void cmd_status(void)
{
    struct utsname uts;
    char host[64] = "?";
    char variant[32] = "core";

    gethostname(host, sizeof(host));
    read_trim("/etc/aaha/variant", variant, sizeof(variant), "core");

    fputs("AahaOS status\n", stdout);
    fputs("-------------\n", stdout);
    fputs("os        : AahaOS (custom embedded Linux)\n", stdout);
    fputs("not       : hypervisor clone, Windows, distro installer, from-scratch kernel\n",
          stdout);
    print_os_keys();
    printf("variant   : %s\n", variant);
    printf("hostname  : %s\n", host);
    if (uname(&uts) == 0) {
        printf("kernel    : %s %s (%s)\n", uts.sysname, uts.release,
               uts.machine);
    }
    {
        FILE *mp = fopen("/proc/mounts", "r");
        char line[256];
        int persist = 0, share = 0;
        if (mp) {
            while (fgets(line, sizeof(line), mp)) {
                if (strstr(line, " /data ")) {
                    persist = 1;
                }
                if (strstr(line, " /share ")) {
                    share = 1;
                }
            }
            fclose(mp);
        }
        printf("persist   : %s\n", persist ? "/data mounted" : "/data not mounted");
        printf("share     : %s\n", share ? "/share mounted (9p)" : "/share not mounted");
    }
    fputs("auth      : console; dropbear on Net/Lab (blank password, not a boundary).\n",
          stdout);
}

static void cmd_ident(void)
{
    struct utsname uts;
    char host[64] = "?";
    char variant[32] = "core";
    char version[32] = "0.4.0";

    gethostname(host, sizeof(host));
    read_trim("/etc/aaha/variant", variant, sizeof(variant), "core");
    read_trim("/etc/aaha/version", version, sizeof(version), "0.2.0");

    fputs("AahaOS identity\n", stdout);
    fputs("---------------\n", stdout);
    printf("product   : AahaOS %s\n", version);
    printf("variant   : %s  (Core = local, Net = DHCP+ssh, Lab = Net + extra applets)\n",
           variant);
    printf("hostname  : %s\n", host);
    print_os_keys();
    if (uname(&uts) == 0) {
        printf("uname     : %s %s %s %s\n", uts.sysname, uts.release,
               uts.version, uts.machine);
    }
    fputs("prompt    : aaha@aaha\n", stdout);
    fputs("services  : dropbear on Net/Lab only; no getty login\n", stdout);
}

static void cmd_mem(void)
{
    FILE *fp = fopen("/proc/meminfo", "r");
    char line[256];
    int shown = 0;

    fputs("AahaOS mem\n", stdout);
    fputs("----------\n", stdout);
    if (!fp) {
        fputs("no /proc/meminfo — proc not mounted?\n", stdout);
        return;
    }
    while (fgets(line, sizeof(line), fp)) {
        if (strncmp(line, "MemTotal:", 9) == 0 ||
            strncmp(line, "MemFree:", 8) == 0 ||
            strncmp(line, "MemAvailable:", 13) == 0 ||
            strncmp(line, "Buffers:", 8) == 0 ||
            strncmp(line, "Cached:", 7) == 0) {
            fputs(line, stdout);
            shown++;
        }
        if (shown >= 5) {
            break;
        }
    }
    fclose(fp);
    fputs("Source: /proc/meminfo (this guest). Not a host leak tool.\n",
          stdout);
}

static void cmd_net(void)
{
    FILE *fp;
    char line[256];
    char variant[32] = "core";

    read_trim("/etc/aaha/variant", variant, sizeof(variant), "core");

    fputs("AahaOS net (local view)\n", stdout);
    fputs("-----------------------\n", stdout);
    printf("variant   : %s\n", variant);
    {
        DIR *d = opendir("/sys/class/net");
        struct dirent *ent;
        fputs("ifaces    :", stdout);
        if (d) {
            while ((ent = readdir(d)) != NULL) {
                if (ent->d_name[0] == '.') {
                    continue;
                }
                printf(" %s", ent->d_name);
            }
            closedir(d);
        } else {
            fputs(" (none)", stdout);
        }
        fputc('\n', stdout);
    }

    fp = fopen("/proc/net/dev", "r");
    if (fp) {
        while (fgets(line, sizeof(line), fp)) {
            fputs(line, stdout);
        }
        fclose(fp);
    } else {
        fputs("no /proc/net/dev — proc not mounted?\n", stdout);
    }

    if (strcmp(variant, "net") == 0 || strcmp(variant, "lab") == 0) {
        fputs("\nIPv4 routes (/proc/net/route):\n", stdout);
        fp = fopen("/proc/net/route", "r");
        if (fp) {
            while (fgets(line, sizeof(line), fp)) {
                fputs(line, stdout);
            }
            fclose(fp);
        } else {
            fputs("(no /proc/net/route)\n", stdout);
        }
        fputs("\nSSH (Net/Lab): dropbear :22 — from host  ssh -p 2222 root@127.0.0.1\n",
              stdout);
        fputs("No port scan, no exploit tools.\n", stdout);
    } else {
        fputs("\nCore variant: interface list only. "
              "AahaOS Net/Lab add DHCP + dropbear.\n",
              stdout);
    }
    fputs("This command only lists what the kernel already exposes.\n",
          stdout);
}

static void print_root_line(void)
{
    FILE *fp = fopen("/proc/mounts", "r");
    char line[256];
    if (!fp) {
        fputs("root mount: (no /proc/mounts)\n", stdout);
        return;
    }
    while (fgets(line, sizeof(line), fp)) {
        char src[64], tgt[64], fstype[64], opts[128];
        if (sscanf(line, "%63s %63s %63s %127s", src, tgt, fstype, opts) == 4 &&
            strcmp(tgt, "/") == 0) {
            printf("root mount: %s %s (%s) %s\n", src, tgt, fstype, opts);
            break;
        }
    }
    fclose(fp);
}

static void cmd_lock(void)
{
    fputs("aaha lock\n---------\n", stdout);
    fputs("Remounting / read-only. Not a security boundary.\n", stdout);
    if (mount(NULL, "/", NULL, MS_REMOUNT | MS_RDONLY, NULL) == 0) {
        fputs("remount   : ok\n", stdout);
    } else {
        perror("remount");
    }
    print_root_line();
}

static void cmd_unlock(void)
{
    fputs("aaha unlock\n-----------\n", stdout);
    if (mount(NULL, "/", NULL, MS_REMOUNT, NULL) == 0) {
        fputs("remount   : rw ok\n", stdout);
    } else {
        perror("remount");
    }
    print_root_line();
}

static void handoff_sh(int argc, char **argv)
{
    const char *a1 = argc > 1 ? argv[1] : "";
    const char *a2 = argc > 2 ? argv[2] : NULL;
    if (a2) {
        execl("/bin/sh", "sh", "/usr/lib/aaha/aaha.sh", a1, a2, (char *)NULL);
    } else {
        execl("/bin/sh", "sh", "/usr/lib/aaha/aaha.sh", a1, (char *)NULL);
    }
    perror("aaha.sh");
}

int main(int argc, char **argv)
{
    const char *cmd;

    if (argc < 2) {
        usage();
        return 1;
    }
    cmd = argv[1];
    if (strcmp(cmd, "status") == 0) {
        cmd_status();
        return 0;
    }
    if (strcmp(cmd, "ident") == 0) {
        cmd_ident();
        return 0;
    }
    if (strcmp(cmd, "mem") == 0) {
        cmd_mem();
        return 0;
    }
    if (strcmp(cmd, "net") == 0) {
        cmd_net();
        return 0;
    }
    if (strcmp(cmd, "lock") == 0) {
        if (argc >= 3 && strcmp(argv[2], "persist") == 0) {
            handoff_sh(argc, argv);
            return 1;
        }
        cmd_lock();
        return 0;
    }
    if (strcmp(cmd, "unlock") == 0) {
        if (argc >= 3 && strcmp(argv[2], "persist") == 0) {
            handoff_sh(argc, argv);
            return 1;
        }
        cmd_unlock();
        return 0;
    }
    if (strcmp(cmd, "lab") == 0) {
        handoff_sh(argc, argv);
        return 1;
    }
    if (strcmp(cmd, "help") == 0 || strcmp(cmd, "-h") == 0 ||
        strcmp(cmd, "--help") == 0) {
        usage();
        return 0;
    }
    fprintf(stderr, "aaha: unknown command '%s'\n", cmd);
    usage();
    return 1;
}
