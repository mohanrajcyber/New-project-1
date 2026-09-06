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
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
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
import app.pockethost.ui.components.MonoBlock
import app.pockethost.ui.components.PhCard
import app.pockethost.ui.theme.Accent
import app.pockethost.ui.theme.Ink
import app.pockethost.ui.theme.Mute
import app.pockethost.ui.theme.Paper
import app.pockethost.ui.theme.Warn

@Composable
fun SerialScreen(engine: BundledImageEngine) {
    val clipboard = LocalClipboardManager.current
    val ctx = LocalContext.current
    var pasted by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Ink)
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
    ) {
        Text("Serial (via Termux)", color = Paper, fontSize = 26.sp, fontWeight = FontWeight.SemiBold)
        Text(
            "Not a live guest. JNI QEMU is not in this APK. This screen holds instructions, SSH, and a paste buffer for a Termux serial log.",
            color = Warn,
            fontSize = 13.sp,
            modifier = Modifier.padding(top = 6.dp, bottom = 16.dp),
        )
        PhCard {
            Text("Boot in Termux", color = Paper, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(8.dp))
            MonoBlock(engine.qemuCommand(), color = Accent)
            Spacer(Modifier.height(8.dp))
            MonoBlock(engine.lastSerialHint())
            Button(
                onClick = {
                    clipboard.setText(AnnotatedString(engine.qemuCommand()))
                    Toast.makeText(ctx, "Boot command copied", Toast.LENGTH_SHORT).show()
                },
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Accent, contentColor = Ink),
                shape = RoundedCornerShape(12.dp),
            ) { Text("Copy boot command") }
        }
        Spacer(Modifier.height(12.dp))
        PhCard {
            Text("SSH (Net / Lab)", color = Paper, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.height(8.dp))
            MonoBlock(engine.sshCommand(), color = Accent)
            Text("Blank password. Guest dropbear. Host port 2222.", color = Mute, fontSize = 13.sp)
            Button(
                onClick = {
                    clipboard.setText(AnnotatedString(engine.sshCommand()))
                    Toast.makeText(ctx, "SSH command copied", Toast.LENGTH_SHORT).show()
                },
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Accent, contentColor = Ink),
                shape = RoundedCornerShape(12.dp),
            ) { Text("Copy ssh command") }
        }
        Spacer(Modifier.height(12.dp))
        PhCard {
            Text("Paste Termux serial (optional)", color = Paper, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            Text("Paste from ~/aahaos/serial.log — labeled paste, not DEMO meminfo.", color = Mute, fontSize = 13.sp)
            OutlinedTextField(
                value = pasted,
                onValueChange = { pasted = it },
                modifier = Modifier.fillMaxWidth().height(160.dp).padding(top = 8.dp),
                textStyle = androidx.compose.ui.text.TextStyle(fontFamily = FontFamily.Monospace, fontSize = 11.sp),
            )
            Button(
                onClick = {
                    clipboard.setText(AnnotatedString(pasted.ifBlank { engine.lastSerialHint() }))
                    Toast.makeText(ctx, "Copied", Toast.LENGTH_SHORT).show()
                },
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Accent, contentColor = Ink),
                shape = RoundedCornerShape(12.dp),
            ) { Text("Copy last serial / hint") }
        }
    }
}
