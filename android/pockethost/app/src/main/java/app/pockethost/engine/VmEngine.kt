package app.pockethost.engine

/**
 * Host-side contract for booting the bundled AahaOS guest.
 *
 * Ready means the image contract is present — not that a VM process
 * is executing inside PocketHost. Do not report Running unless we own the process.
 */
interface VmEngine {
    val imageReady: Boolean
    val isRunning: Boolean
    fun imagePath(): String
    fun start(): EngineResult
    fun stop()
}

sealed class EngineResult {
    data class Started(val note: String) : EngineResult()

    data class HandedOff(
        val dest: String,
        val command: String,
        val note: String,
    ) : EngineResult()

    data class Unavailable(
        val reason: String,
        val nextStep: String,
        val command: String = "",
    ) : EngineResult()
}

enum class HostStatus {
    MissingImage,
    ReadyEngineOff,
    Starting,
    HandedOff,
    Running,
}

data class GuestManifest(
    val os: String,
    val version: String,
    val kind: String,
    val engine: String,
    val variant: String,
    val imageHint: String,
)

data class GuestSnapshot(
    val id: String,
    val title: String,
    val createdLabel: String,
    val note: String,
)

data class TermuxStep(
    val title: String,
    val command: String,
    val note: String,
)

data class ImagePathSpec(
    val contractAsset: String,
    val onDeviceRoot: String,
    val kernelHint: String,
    val initramfsHint: String,
)
