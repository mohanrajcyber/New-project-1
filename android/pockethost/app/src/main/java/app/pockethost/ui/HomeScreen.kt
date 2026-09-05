package app.pockethost.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.pockethost.engine.BundledImageEngine
import app.pockethost.engine.EngineResult
import app.pockethost.ui.theme.Accent
import app.pockethost.ui.theme.Card
import app.pockethost.ui.theme.Ink
import app.pockethost.ui.theme.Line
import app.pockethost.ui.theme.Mute
import app.pockethost.ui.theme.Paper
import app.pockethost.ui.theme.Ready
import app.pockethost.ui.theme.Warn

@Composable
fun HomeScreen(engine: BundledImageEngine) {
    val manifest = remember { engine.manifest() }
    var dialog by remember { mutableStateOf<EngineResult.Unavailable?>(null) }
    val ready = engine.imageReady
    val running = engine.isRunning

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Ink)
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
    ) {
        Text("PocketHost", color = Accent, fontSize = 14.sp, fontWeight = FontWeight.Medium)
        Text(
            "One-tap AahaOS",
            color = Paper,
            fontSize = 28.sp,
            fontWeight = FontWeight.SemiBold,
        )
        Text(
            "ஆஹா! நம்ம OS. Not an ISO wizard.",
            color = Mute,
            fontSize = 14.sp,
            modifier = Modifier.padding(top = 4.dp),
        )

        Spacer(Modifier.height(20.dp))

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(20.dp))
                .background(Card)
                .border(1.dp, Line, RoundedCornerShape(20.dp))
                .padding(20.dp),
        ) {
            Text(
                "AahaOS",
                color = Paper,
                fontSize = 22.sp,
                fontWeight = FontWeight.SemiBold,
                fontFamily = FontFamily.Monospace,
            )
            Text(
                "Custom embedded Linux  ·  ${manifest?.version ?: "0.1.0"}",
                color = Mute,
                fontSize = 13.sp,
                modifier = Modifier.padding(top = 2.dp),
            )

            Spacer(Modifier.height(16.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Text("Status", color = Mute, fontSize = 13.sp)
                val label = when {
                    running -> "Running"
                    ready -> "Ready"
                    else -> "Missing image"
                }
                val tint = when {
                    running -> Accent
                    ready -> Ready
                    else -> Warn
                }
                Text(
                    label,
                    color = tint,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                )
            }

            Text(
                if (running) {
                    "Guest console is live."
                } else if (ready) {
                    "Bundled guest is Ready. Engine is not connected yet — Start will not fake a boot."
                } else {
                    "Image contract missing."
                },
                color = Mute,
                fontSize = 13.sp,
                modifier = Modifier.padding(top = 8.dp),
            )

            Text(
                "path  ${engine.imagePath()}",
                color = Mute,
                fontSize = 11.sp,
                fontFamily = FontFamily.Monospace,
                modifier = Modifier.padding(top = 8.dp),
            )

            Spacer(Modifier.height(20.dp))

            Button(
                onClick = {
                    when (val result = engine.start()) {
                        is EngineResult.Started -> Unit
                        is EngineResult.Unavailable -> dialog = result
                    }
                },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Accent,
                    contentColor = Ink,
                ),
                shape = RoundedCornerShape(14.dp),
            ) {
                Text("Start", fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
            }
        }

        Spacer(Modifier.height(16.dp))
        Text(
            "This is our OS image, not Debian-you-install, not Vectras, not a pirated ISO. " +
                "PC proof: make run  ·  Phone engine: next (Termux/QEMU or JNI).",
            color = Mute,
            fontSize = 12.sp,
        )
    }

    dialog?.let { info ->
        AlertDialog(
            onDismissRequest = { dialog = null },
            title = { Text("AahaOS is Ready — engine next") },
            text = {
                Column {
                    Text(info.reason)
                    Spacer(Modifier.height(12.dp))
                    Text(info.nextStep)
                }
            },
            confirmButton = {
                TextButton(onClick = { dialog = null }) { Text("OK") }
            },
        )
    }
}
