package app.pockethost.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
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
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
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
    val status = remember { engine.hostStatus() }
    var dialog by remember { mutableStateOf<EngineResult.Unavailable?>(null) }
    val paths = remember { engine.imagePaths() }

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
                body = "Rebuild the APK so assets/aahaos/manifest.json ships. Start stays disabled until then.",
            )
            HostStatus.ReadyEngineOff, HostStatus.Running -> PhCard {
                Text(
                    "AahaOS",
                    color = Paper,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.SemiBold,
                    fontFamily = FontFamily.Monospace,
                )
                Text(
                    "Embedded Linux  ·  ${manifest?.version ?: "0.2.0"}  ·  ${manifest?.variant ?: "core"}",
                    color = Mute,
                    fontSize = 13.sp,
                    modifier = Modifier.padding(top = 4.dp),
                )
                Spacer(Modifier.height(16.dp))
                StatusPill(status)
                Spacer(Modifier.height(10.dp))
                Text(
                    when (status) {
                        HostStatus.Running -> "Guest console is live."
                        else -> "Guest image is Ready. Engine is not connected. Start will not fake a boot."
                    },
                    color = Mute,
                    fontSize = 13.sp,
                    lineHeight = 18.sp,
                )
                Spacer(Modifier.height(12.dp))
                MonoBlock("on-device  ${paths.onDeviceRoot}")
                Spacer(Modifier.height(20.dp))
                Button(
                    onClick = {
                        when (val result = engine.start()) {
                            is EngineResult.Started -> Unit
                            is EngineResult.Unavailable -> dialog = result
                        }
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
            "Our OS image. Not Debian-you-install. Not a pirated ISO. " +
                "PC: make run  ·  Phone: Engine tab (Termux sheet).",
            color = Mute,
            fontSize = 12.sp,
            lineHeight = 17.sp,
        )
    }

    dialog?.let { info ->
        AlertDialog(
            onDismissRequest = { dialog = null },
            title = { Text("Engine not wired") },
            text = {
                Column {
                    Text(info.reason)
                    Spacer(Modifier.height(12.dp))
                    Text(info.nextStep)
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    dialog = null
                    onOpenEngine()
                }) { Text("Open Engine sheet") }
            },
            dismissButton = {
                TextButton(onClick = { dialog = null }) { Text("Close") }
            },
        )
    }
}
