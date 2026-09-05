package app.pockethost.engine

import android.content.Context
import org.json.JSONObject
import java.io.File

/**
 * v1 engine: the AahaOS image is Ready (bundled contract).
 *
 * Full QEMU-on-Android JNI is not wired. Start() tells the truth and
 * points at Termux/QEMU or a future JNI module. It never pretends the
 * guest is running.
 */
class BundledImageEngine(private val context: Context) : VmEngine {

    override val imageReady: Boolean
        get() = readManifest() != null

    override val isRunning: Boolean
        get() = false

    override fun imagePath(): String {
        val files = File(context.filesDir, "aahaos")
        return files.absolutePath
    }

    fun manifest(): GuestManifest? = readManifest()

    override fun start(): EngineResult {
        if (!imageReady) {
            return EngineResult.Unavailable(
                reason = "AahaOS image contract missing from assets.",
                nextStep = "Rebuild the app so assets/aahaos/manifest.json ships.",
            )
        }
        return EngineResult.Unavailable(
            reason = "PocketHost v1 has no in-app QEMU yet. " +
                "The guest image is Ready; the engine is not connected.",
            nextStep = NEXT_STEP,
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
                    version = json.optString("version", "0.1.0"),
                    kind = json.optString("kind", "embedded-linux"),
                    engine = json.optString("engine", "placeholder"),
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
        const val NEXT_STEP =
            "On a Linux PC: make image && make run. " +
                "On a phone later: install Termux + qemu-system-aarch64 and " +
                "point it at the bundled AahaOS vmlinuz + initramfs, or wait " +
                "for the JNI engine. Do not download a random ISO."
    }
}
