package app.pockethost.ui

import android.widget.Toast
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
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.pockethost.engine.BundledImageEngine
import app.pockethost.ui.components.MonoBlock
import app.pockethost.ui.components.PhCard
import app.pockethost.ui.theme.Accent
import app.pockethost.ui.theme.Ink
import app.pockethost.ui.theme.Mute
import app.pockethost.ui.theme.Paper

@Composable
fun EngineScreen(engine: BundledImageEngine) {
    val steps = engine.termuxSteps()
    val paths = engine.imagePaths()
    val clipboard = LocalClipboardManager.current
    val ctx = LocalContext.current

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Ink)
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
    ) {
        Text("Engine", color = Paper, fontSize = 28.sp, fontWeight = FontWeight.SemiBold)
        Text(
            "Not connected. This sheet is the real next step — Termux QEMU on our image, or a future JNI module. PocketHost will not show a fake console.",
            color = Mute,
            fontSize = 13.sp,
            lineHeight = 18.sp,
            modifier = Modifier.padding(top = 6.dp, bottom = 18.dp),
        )

        PhCard {
            Text("Bundled path contract", color = Paper, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(8.dp))
            MonoBlock("root     ${paths.onDeviceRoot}")
            MonoBlock("kernel   ${paths.kernelHint}")
            MonoBlock("initramfs ${paths.initramfsHint}")
            MonoBlock("asset    ${paths.contractAsset}")
        }

        Spacer(Modifier.height(12.dp))
        PhCard {
            Text("Share on LAN / Fetch from LAN", color = Paper, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(8.dp))
            MonoBlock(engine.shareCommand(), color = Accent)
            Text(
                "Serves dist/aarch64. Other phone: set AAHA_RAW=http://<ip>:8766 in More, or paste below.",
                color = Mute,
                fontSize = 13.sp,
            )
            androidx.compose.material3.OutlinedTextField(
                value = engine.settings.lanRaw,
                onValueChange = { engine.settings.lanRaw = it },
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                label = { Text("Fetch from LAN (AAHA_RAW)") },
                placeholder = { Text("http://192.168.1.10:8766") },
            )
            Button(
                onClick = {
                    clipboard.setText(AnnotatedString(engine.shareCommand()))
                    Toast.makeText(ctx, "Copied share script", Toast.LENGTH_SHORT).show()
                },
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Accent, contentColor = Ink),
                shape = RoundedCornerShape(12.dp),
            ) { Text("Copy Share on LAN") }
            Button(
                onClick = {
                    clipboard.setText(AnnotatedString(engine.sshCommand()))
                    Toast.makeText(ctx, "Copied ssh", Toast.LENGTH_SHORT).show()
                },
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Accent, contentColor = Ink),
                shape = RoundedCornerShape(12.dp),
            ) { Text("Copy ssh command") }
        }

        steps.forEach { step ->
            Spacer(Modifier.height(12.dp))
            PhCard {
                Text(step.title, color = Paper, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(8.dp))
                MonoBlock(step.command, color = Accent)
                Spacer(Modifier.height(8.dp))
                Text(step.note, color = Mute, fontSize = 13.sp, lineHeight = 18.sp)
                Spacer(Modifier.height(12.dp))
                Button(
                    onClick = {
                        clipboard.setText(AnnotatedString(step.command))
                        Toast.makeText(ctx, "Copied", Toast.LENGTH_SHORT).show()
                    },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Accent,
                        contentColor = Ink,
                    ),
                    shape = RoundedCornerShape(12.dp),
                ) {
                    Text("Copy command")
                }
            }
        }
    }
}
