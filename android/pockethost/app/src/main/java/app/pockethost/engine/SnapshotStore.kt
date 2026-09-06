package app.pockethost.engine

import android.content.Context
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class SnapshotStore(private val context: Context) {
    private val root: File = File(context.filesDir, "snapshots").apply { mkdirs() }

    fun list(): List<GuestSnapshot> {
        return root.listFiles()
            ?.filter { it.isDirectory && File(it, "meta.json").isFile }
            ?.mapNotNull { dir ->
                try {
                    val json = JSONObject(File(dir, "meta.json").readText())
                    GuestSnapshot(
                        id = dir.name,
                        title = json.optString("title", dir.name),
                        createdLabel = json.optString("created", ""),
                        note = json.optString("note", ""),
                    )
                } catch (_: Exception) {
                    null
                }
            }
            ?.sortedByDescending { it.id }
            ?: emptyList()
    }

    fun create(settings: HostSettings): GuestSnapshot {
        val id = SimpleDateFormat("yyyyMMdd-HHmmss", Locale.US).format(Date())
        val dir = File(root, id).apply { mkdirs() }
        val created = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.US).format(Date())
        val guest = File(context.filesDir, "aahaos")
        val initrd = File(guest, "aarch64/initramfs.cpio.gz")
        val copied = if (initrd.isFile) {
            initrd.copyTo(File(dir, "initramfs.cpio.gz"), overwrite = true)
            true
        } else {
            false
        }
        val note = if (copied) {
            "Saved initramfs + settings (ram ${settings.ramMb}M, disk ${settings.diskMb}M, ${settings.variant})."
        } else {
            "Saved settings only (ram ${settings.ramMb}M, disk ${settings.diskMb}M, ${settings.variant}). Download the image in Termux for a full file snapshot."
        }
        val meta = JSONObject()
            .put("title", "Snapshot $id")
            .put("created", created)
            .put("note", note)
            .put("ramMb", settings.ramMb)
            .put("diskMb", settings.diskMb)
            .put("variant", settings.variant)
            .put("hasInitrd", copied)
        File(dir, "meta.json").writeText(meta.toString())
        return GuestSnapshot(id, "Snapshot $id", created, note)
    }

    fun delete(id: String) {
        val dir = File(root, id)
        if (dir.isDirectory) {
            dir.deleteRecursively()
        }
    }
}
