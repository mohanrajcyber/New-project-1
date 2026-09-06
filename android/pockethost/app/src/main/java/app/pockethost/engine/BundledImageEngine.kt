package app.pockethost.engine

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import org.json.JSONObject
import java.io.File

/**
 * PocketHost engine: Ready image contract + Termux hand-off.
 * Never sets isRunning — QEMU lives in Termux, not in this APK.
 */
class BundledImageEngine(private val context: Context) : VmEngine {
    val settings = HostSettings(context)
    private val snapStore = SnapshotStore(context)
    @Volatile var lastHandOff: String? = null
        private set
    @Volatile var lastStatus: HostStatus = HostStatus.ReadyEngineOff
        private set

    override val imageReady: Boolean
        get() = readManifest() != null

    override val isRunning: Boolean
        get() = false

    fun hostStatus(): HostStatus = when {
        isRunning -> HostStatus.Running
        lastHandOff != null -> HostStatus.HandedOff
        imageReady -> HostStatus.ReadyEngineOff
        else -> HostStatus.MissingImage
    }.also { lastStatus = it }

    fun termuxInstalled(): Boolean = try {
        context.packageManager.getPackageInfo("com.termux", 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    override fun imagePath(): String = File(context.filesDir, "aahaos").absolutePath

    fun manifest(): GuestManifest? = readManifest()

    fun snapshots(): List<GuestSnapshot> = snapStore.list()

    fun createSnapshot(): GuestSnapshot = snapStore.create(settings)

    fun deleteSnapshot(id: String) = snapStore.delete(id)

    fun imagePaths(): ImagePathSpec {
        val root = imagePath()
        return ImagePathSpec(
            contractAsset = CONTRACT_ASSET,
            onDeviceRoot = root,
            kernelHint = "$root/aarch64/vmlinuz",
            initramfsHint = "$root/aarch64/initramfs.cpio.gz",
        )
    }

    fun qemuCommand(): String {
        val mem = settings.ramMb
        val disk = settings.diskMb
        val variant = settings.variant
        return "AAHA_VARIANT=$variant AAHA_MEM=$mem AAHA_DISK=$disk bash ~/termux-boot-aahaos.sh"
    }

    fun fetchScriptCommand(): String =
        "pkg update && pkg install qemu-system-aarch64-headless wget && " +
            "curl -fsSL -o ~/termux-boot-aahaos.sh $SCRIPT_RAW && " +
            "chmod +x ~/termux-boot-aahaos.sh && ${qemuCommand()}"

    fun termuxSteps(): List<TermuxStep> = listOf(
        TermuxStep(
            title = "1. Install QEMU in Termux",
            command = "pkg update && pkg install qemu-system-aarch64-headless wget",
            note = "Headless serial. Not a fake VGA.",
        ),
        TermuxStep(
            title = "2. Get our boot script",
            command = "curl -fsSL -o ~/termux-boot-aahaos.sh $SCRIPT_RAW && chmod +x ~/termux-boot-aahaos.sh",
            note = "Downloads OUR aarch64 image from the public repo. No random ISO.",
        ),
        TermuxStep(
            title = "3. Boot (uses your RAM/disk/variant settings)",
            command = qemuCommand(),
            note = "Banner + aaha@aaha. Ctrl-A x to quit. Guest runs in Termux, not in this APK.",
        ),
    )

    override fun start(): EngineResult {
        lastStatus = HostStatus.Starting
        if (!imageReady) {
            lastStatus = HostStatus.MissingImage
            return EngineResult.Unavailable(
                reason = "AahaOS image contract missing from assets.",
                nextStep = "Rebuild so assets/aahaos/manifest.json ships.",
            )
        }
        val cmd = fetchScriptCommand()
        if (termuxInstalled()) {
            val launched = launchTermux(cmd)
            return if (launched) {
                lastHandOff = cmd
                lastStatus = HostStatus.HandedOff
                EngineResult.HandedOff(
                    dest = "Termux",
                    command = cmd,
                    note = "Start handed the boot script to Termux. " +
                        "PocketHost is not running the guest. Watch Termux for the AahaOS banner.",
                )
            } else {
                lastHandOff = null
                lastStatus = HostStatus.ReadyEngineOff
                EngineResult.Unavailable(
                    reason = "Termux is installed but RUN_COMMAND was blocked. Command copied below.",
                    nextStep = "Open Termux → paste. Enable RUN_COMMAND in Termux settings if asked.",
                    command = cmd,
                )
            }
        }
        lastHandOff = null
        lastStatus = HostStatus.ReadyEngineOff
        return EngineResult.Unavailable(
            reason = "Termux is not installed. PocketHost will not fake a running guest.",
            nextStep = "Install Termux (F-Droid), then paste this command.",
            command = cmd,
        )
    }

    override fun stop() {
        lastHandOff = null
        lastStatus = if (imageReady) HostStatus.ReadyEngineOff else HostStatus.MissingImage
    }

    private fun launchTermux(cmd: String): Boolean {
        return try {
            val intent = Intent().apply {
                setClassName("com.termux", "com.termux.app.RunCommandService")
                action = "com.termux.RUN_COMMAND"
                putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-lc", cmd))
                putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", false)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startService(intent)
            true
        } catch (_: Exception) {
            try {
                val open = context.packageManager.getLaunchIntentForPackage("com.termux")
                if (open != null) {
                    open.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(open)
                    true
                } else {
                    false
                }
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun readManifest(): GuestManifest? {
        return try {
            context.assets.open(MANIFEST_ASSET).bufferedReader().use { reader ->
                val json = JSONObject(reader.readText())
                GuestManifest(
                    os = json.optString("os", "AahaOS"),
                    version = json.optString("version", "0.3.0"),
                    kind = json.optString("kind", "embedded-linux"),
                    engine = json.optString("engine", "termux-handoff"),
                    variant = json.optString("variant", "core"),
                    imageHint = json.optString(
                        "imageHint",
                        "dist/aarch64/{core,net}/initramfs.cpio.gz",
                    ),
                )
            }
        } catch (_: Exception) {
            null
        }
    }

    companion object {
        const val MANIFEST_ASSET = "aahaos/manifest.json"
        const val CONTRACT_ASSET = "aahaos/IMAGE_CONTRACT.txt"
        const val SCRIPT_RAW =
            "https://raw.githubusercontent.com/mohanrajcyber/New-project-1/main/scripts/termux-boot-aahaos.sh"
        const val TERMUX_BOOT =
            "AAHA_VARIANT=core AAHA_MEM=512 AAHA_DISK=64 bash ~/termux-boot-aahaos.sh"
    }
}
