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
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.pockethost.engine.BundledImageEngine
import app.pockethost.engine.GuestSnapshot
import app.pockethost.ui.components.EmptyState
import app.pockethost.ui.components.PhCard
import app.pockethost.ui.theme.Accent
import app.pockethost.ui.theme.Ink
import app.pockethost.ui.theme.Mute
import app.pockethost.ui.theme.Paper

@Composable
fun SnapshotsScreen(engine: BundledImageEngine) {
    var snaps by remember { mutableStateOf(engine.snapshots()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Ink)
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
    ) {
        Text("Snapshots", color = Paper, fontSize = 28.sp, fontWeight = FontWeight.SemiBold)
        Text(
            "Local host snapshots: settings + initramfs copy if you downloaded one. Not a fake restore point.",
            color = Mute,
            fontSize = 13.sp,
            modifier = Modifier.padding(top = 6.dp, bottom = 16.dp),
        )

        Button(
            onClick = {
                engine.createSnapshot()
                snaps = engine.snapshots()
            },
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = Accent, contentColor = Ink),
            shape = RoundedCornerShape(12.dp),
        ) {
            Text("Create snapshot")
        }

        Spacer(Modifier.height(16.dp))
        if (snaps.isEmpty()) {
            EmptyState(
                title = "No snapshots yet",
                body = "Tap Create snapshot. A row will appear with RAM/disk/variant. Full file copy needs the image in Termux files.",
            )
        } else {
            snaps.forEach { snap: GuestSnapshot ->
                Spacer(Modifier.height(10.dp))
                PhCard {
                    Text(snap.title, color = Paper, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                    Text(snap.createdLabel, color = Mute, fontSize = 12.sp)
                    Spacer(Modifier.height(6.dp))
                    Text(snap.note, color = Mute, fontSize = 13.sp)
                    Spacer(Modifier.height(8.dp))
                    OutlinedButton(onClick = {
                        engine.deleteSnapshot(snap.id)
                        snaps = engine.snapshots()
                    }) {
                        Text("Delete")
                    }
                }
            }
        }
    }
}
