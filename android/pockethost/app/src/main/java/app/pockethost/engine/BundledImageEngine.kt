package app.pockethost.engine

import android.content.Context
import org.json.JSONObject
import java.io.File

/**
 * v1 engine: the AahaOS image contract is Ready.
 *
 * Full QEMU-on-Android JNI is not wired. Start() tells the truth.
 * Never pretends the guest is running.
 */
class BundledImageEngine(private val context: Context) : VmEngine {

    override val imageReady: Boolean
        get() = readManifest() != null

    override val isRunning: Boolean
        get() = false

    fun hostStatus(): HostStatus = when {
        isRunning -> HostStatus.Running
        imageReady -> HostStatus.ReadyEngineOff
        else -> HostStatus.MissingImage
    }

    override fun imagePath(): String = File(context.filesDir, "aahaos").absolutePath

    fun manifest(): GuestManifest? = readManifest()

    fun snapshots(): List<GuestSnapshot> = emptyList()

    fun imagePaths(): ImagePathSpec {
        val root = imagePath()
        return ImagePathSpec(
            contractAsset = CONTRACT_ASSET,
            onDeviceRoot = root,
            kernelHint = "$root/aarch64/vmlinuz",
            initramfsHint = "$root/aarch64/initramfs.cpio.gz",
        )
    }

    fun termuxSteps(): List<TermuxStep> {
        val paths = imagePaths()
        return listOf(
            TermuxStep(
                title = "1. Install QEMU in Termux",
                command = "pkg update && pkg install qemu-system-aarch64-headless",
                note = "Headless is enough. We talk serial, not a fake VGA.",
            ),
            TermuxStep(
                title = "2. Copy our AahaOS image",
                command = "mkdir -p ~/aahaos && echo put vmlinuz + initramfs.cpio.gz here",
                note = "Build on a PC with make image-aarch64, then share " +
                    "${paths.kernelHint} and ${paths.initramfsHint}. " +
                    "Do not download a random ISO.",
            ),
            TermuxStep(
                title = "3. Boot AahaOS (serial)",
                command = TERMUX_BOOT,
                note = "You should see the AahaOS banner and aaha@aaha prompt. " +
                    "This is outside PocketHost until JNI exists.",
            ),
        )
    }

    fun contractText(): String = try {
        context.assets.open(CONTRACT_ASSET).bufferedReader().readText()
    } catch (_: Exception) {
        "Image contract missing from APK assets."
    }

    override fun start(): EngineResult {
        if (!imageReady) {
            return EngineResult.Unavailable(
                reason = "AahaOS image contract missing from assets.",
                nextStep = "Rebuild so assets/aahaos/manifest.json ships inside the APK.",
            )
        }
        return EngineResult.Unavailable(
            reason = "AahaOS is Ready. The in-app engine is not wired — " +
                "PocketHost will not pretend the guest is running.",
            nextStep = "Use the Engine tab Termux sheet, or make run on a Linux PC.",
        )
    }

    override fun stop() {
        /* nothing running */
    }

    private fun readManifest(): GuestManifest? {
        return try {
            context.assets.open(MANIFEST_ASSET).bufferedReader().use { reader ->
                val json = JSONObject(reader.readText())
                GuestManifest(
                    os = json.optString("os", "AahaOS"),
                    version = json.optString("version", "0.2.0"),
                    kind = json.optString("kind", "embedded-linux"),
                    engine = json.optString("engine", "placeholder"),
                    variant = json.optString("variant", "core"),
                    imageHint = json.optString(
                        "imageHint",
                        "files/aahaos/<arch>/vmlinuz + initramfs.cpio.gz",
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
        const val TERMUX_BOOT =
            "qemu-system-aarch64 -machine virt -cpu max -m 512 " +
                "-kernel ~/aahaos/vmlinuz " +
                "-initrd ~/aahaos/initramfs.cpio.gz " +
                "-append \"console=ttyAMA0 rdinit=/sbin/init\" " +
                "-nographic"
    }
}
