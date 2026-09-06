package app.pockethost.ui

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.pockethost.engine.BundledImageEngine
import app.pockethost.engine.EngineResult
import app.pockethost.engine.HostStatus
import app.pockethost.ui.components.EmptyState
import app.pockethost.ui.components.MonoBlock
import app.pockethost.ui.components.PhCard
import app.pockethost.ui.components.StatusPill
import app.pockethost.ui.theme.Accent
import app.pockethost.ui.theme.Ink
import app.pockethost.ui.theme.Mute
import app.pockethost.ui.theme.Paper

@Composable
fun HomeScreen(engine: BundledImageEngine, onOpenEngine: () -> Unit) {
    val manifest = remember { engine.manifest() }
    var status by remember { mutableStateOf(engine.hostStatus()) }
    var dialog by remember { mutableStateOf<EngineResult?>(null) }
    val paths = remember { engine.imagePaths() }
    val clipboard = LocalClipboardManager.current
    val ctx = LocalContext.current
    val termux = remember { engine.termuxInstalled() }
    var variant by remember { mutableStateOf(engine.settings.variant) }
    var ram by remember { mutableStateOf(engine.settings.ramMb) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Ink)
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
    ) {
        Text("POCKETHOST", color = Accent, fontSize = 12.sp, fontWeight = FontWeight.Medium, letterSpacing = 1.6.sp)
        Text("One-tap AahaOS", color = Paper, fontSize = 30.sp, fontWeight = FontWeight.SemiBold)
        Text(
            "ஆஹா! நம்ம OS. Our guest — not an ISO wizard.",
            color = Mute,
            fontSize = 14.sp,
            modifier = Modifier.padding(top = 4.dp, bottom = 20.dp),
        )

        when (status) {
            HostStatus.MissingImage -> EmptyState(
                title = "Image contract missing",
                body = "Rebuild the APK so assets/aahaos/manifest.json ships.",
            )
            else -> PhCard {
                Text(
                    "AahaOS",
                    color = Paper,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.SemiBold,
                    fontFamily = FontFamily.Monospace,
                )
                Text(
                    "Embedded Linux  ·  ${manifest?.version ?: "0.4.0"}  ·  $variant",
                    color = Mute,
                    fontSize = 13.sp,
                    modifier = Modifier.padding(top = 4.dp),
                )
                Spacer(Modifier.height(10.dp))
                Row {
                    listOf("core", "net", "lab", "study").forEach { v ->
                        FilterChip(
                            selected = variant == v,
                            onClick = {
                                variant = v
                                engine.settings.variant = v
                            },
                            label = { Text(v.replaceFirstChar { it.uppercase() }) },
                        )
                        Spacer(Modifier.width(6.dp))
                    }
                }
                Row {
                    listOf(256, 512, 1024).forEach { mb ->
                        FilterChip(
                            selected = ram == mb,
                            onClick = {
                                ram = mb
                                engine.settings.ramMb = mb
                            },
                            label = { Text("${mb}M") },
                        )
                        Spacer(Modifier.width(6.dp))
                    }
                }
                Spacer(Modifier.height(12.dp))
                StatusPill(status)
                Spacer(Modifier.height(10.dp))
                Text(
                    when (status) {
                        HostStatus.Running -> "Guest console is live in this app."
                        HostStatus.HandedOff -> "Boot command was handed to Termux. This APK is not the guest."
                        HostStatus.Starting -> "Preparing Termux hand-off…"
                        else -> "Ready. Start copies the boot script and opens Termux if installed. It will not fake a running VM here."
                    },
                    color = Mute,
                    fontSize = 13.sp,
                    lineHeight = 18.sp,
                )
                Spacer(Modifier.height(8.dp))
                MonoBlock("Termux ${if (termux) "installed" else "not installed"}")
                MonoBlock("ram ${ram}M  disk ${engine.settings.diskMb}M  $variant")
                MonoBlock("on-device  ${paths.onDeviceRoot}")
                Spacer(Modifier.height(20.dp))
                Button(
                    onClick = {
                        val result = engine.start()
                        status = engine.hostStatus()
                        clipboard.setText(AnnotatedString(engine.fetchScriptCommand()))
                        Toast.makeText(ctx, "Boot command copied", Toast.LENGTH_SHORT).show()
                        dialog = result
                    },
                    enabled = status != HostStatus.MissingImage,
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Accent,
                        contentColor = Ink,
                        disabledContainerColor = Mute,
                    ),
                    shape = RoundedCornerShape(14.dp),
                ) {
                    Text("Start", fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                }
            }
        }

        Spacer(Modifier.height(16.dp))
        Text(
            "Phone: Termux + our aarch64 image. PC: make run. Web: demo only.",
            color = Mute,
            fontSize = 12.sp,
            lineHeight = 17.sp,
        )
    }

    dialog?.let { info ->
        val title = when (info) {
            is EngineResult.HandedOff -> "Handed to Termux"
            is EngineResult.Started -> "Started"
            is EngineResult.Unavailable -> "Start — next step"
        }
        val body = when (info) {
            is EngineResult.HandedOff -> info.note + "\n\n" + info.command
            is EngineResult.Started -> info.note
            is EngineResult.Unavailable -> info.reason + "\n\n" + info.nextStep +
                if (info.command.isNotBlank()) "\n\n${info.command}" else ""
        }
        AlertDialog(
            onDismissRequest = { dialog = null },
            title = { Text(title) },
            text = { Text(body) },
            confirmButton = {
                TextButton(onClick = {
                    dialog = null
                    onOpenEngine()
                }) { Text("Engine sheet") }
            },
            dismissButton = {
                TextButton(onClick = { dialog = null }) { Text("Close") }
            },
        )
    }
}
