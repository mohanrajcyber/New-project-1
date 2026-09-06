package app.pockethost.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.pockethost.engine.BundledImageEngine
import app.pockethost.ui.components.EmptyState
import app.pockethost.ui.theme.Ink
import app.pockethost.ui.theme.Mute
import app.pockethost.ui.theme.Paper

@Composable
fun SnapshotsScreen(engine: BundledImageEngine) {
    val snaps = remember { engine.snapshots() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Ink)
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
    ) {
        Text("Snapshots", color = Paper, fontSize = 28.sp, fontWeight = FontWeight.SemiBold)
        Text(
            "Local list only. No guest disk exists yet, so there is nothing to freeze.",
            color = Mute,
            fontSize = 13.sp,
            modifier = Modifier.padding(top = 6.dp, bottom = 20.dp),
        )

        if (snaps.isEmpty()) {
            EmptyState(
                title = "No snapshots",
                body = "When an engine can persist AahaOS, snapshots will land here. " +
                    "v0.2 does not invent a fake restore point.",
            )
        } else {
            snaps.forEach { snap ->
                Spacer(Modifier.height(10.dp))
                Text(snap.title, color = Paper, fontSize = 16.sp)
                Text(snap.note, color = Mute, fontSize = 13.sp)
            }
        }
    }
}
