package app.pockethost.engine

import android.content.Context

/** Persisted host defaults that flow into the Termux/QEMU command line. */
class HostSettings(context: Context) {
    private val prefs = context.getSharedPreferences("pockethost", Context.MODE_PRIVATE)

    var ramMb: Int
        get() = prefs.getInt(KEY_RAM, 512).coerceIn(256, 2048)
        set(value) { prefs.edit().putInt(KEY_RAM, value.coerceIn(256, 2048)).apply() }

    var diskMb: Int
        get() = prefs.getInt(KEY_DISK, 64).coerceIn(0, 4096)
        set(value) { prefs.edit().putInt(KEY_DISK, value.coerceIn(0, 4096)).apply() }

    var variant: String
        get() = prefs.getString(KEY_VARIANT, "core") ?: "core"
        set(value) {
            prefs.edit().putString(KEY_VARIANT, if (value == "net") "net" else "core").apply()
        }

    companion object {
        private const val KEY_RAM = "ram_mb"
        private const val KEY_DISK = "disk_mb"
        private const val KEY_VARIANT = "variant"
    }
}
