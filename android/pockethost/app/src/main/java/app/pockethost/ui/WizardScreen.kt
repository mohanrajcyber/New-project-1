package app.pockethost.ui

import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.pockethost.engine.BundledImageEngine
import app.pockethost.ui.components.MonoBlock
import app.pockethost.ui.theme.Accent
import app.pockethost.ui.theme.Ink
import app.pockethost.ui.theme.Mute

@Composable
fun FirstRunWizard(engine: BundledImageEngine, onDone: () -> Unit) {
    val ctx = LocalContext.current
    val clipboard = LocalClipboardManager.current
    val termux = remember { engine.termuxInstalled() }
    var checked by remember { mutableStateOf(engine.settings.termuxReady) }

    AlertDialog(
        onDismissRequest = { },
        title = { Text("First run · முதல் முறை") },
        text = {
            Column {
                Text(
                    "ஆஹா! நம்ம OS. PocketHost is the host UI — not a hypervisor. " +
                        "Real boot is Termux + our aarch64 image. " +
                        "Study lessons: authorized / own-VM only.",
                    color = Mute,
                    fontSize = 13.sp,
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    if (termux) "Termux: installed on this phone."
                    else "Termux: not installed. Install from F-Droid (Play build is limited).",
                    fontSize = 13.sp,
                )
                Spacer(Modifier.height(8.dp))
                MonoBlock(engine.fetchScriptCommand(), color = Accent)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(checked = checked, onCheckedChange = { checked = it })
                    Text("I’ve installed Termux  ·  Termux போட்டுட்டேன்", fontSize = 13.sp)
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    engine.settings.termuxReady = checked
                    engine.settings.wizardDone = true
                    onDone()
                },
                colors = ButtonDefaults.buttonColors(containerColor = Accent, contentColor = Ink),
                shape = RoundedCornerShape(10.dp),
            ) { Text("Continue") }
        },
        dismissButton = {
            Column {
                TextButton(onClick = {
                    clipboard.setText(AnnotatedString(engine.fetchScriptCommand()))
                    Toast.makeText(ctx, "Copied", Toast.LENGTH_SHORT).show()
                }) { Text("Copy install+boot") }
                TextButton(onClick = {
                    ctx.startActivity(
                        Intent(Intent.ACTION_VIEW, Uri.parse(BundledImageEngine.FDROID_TERMUX)),
                    )
                }) { Text("F-Droid Termux") }
            }
        },
    )
}
