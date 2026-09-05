package app.pockethost.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.pockethost.ui.theme.Ink
import app.pockethost.ui.theme.Mute
import app.pockethost.ui.theme.Paper

@Composable
fun SettingsScreen() {
    var ram by remember { mutableFloatStateOf(512f) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Ink)
            .padding(20.dp),
    ) {
        Text("Settings", color = Paper, fontSize = 24.sp)
        Text(
            "Defaults only. These do not change a running VM — there isn't one yet.",
            color = Mute,
            fontSize = 13.sp,
            modifier = Modifier.padding(top = 6.dp, bottom = 20.dp),
        )

        Text("RAM  ${ram.toInt()} MB", color = Paper, fontSize = 16.sp)
        Slider(
            value = ram,
            onValueChange = { ram = it },
            valueRange = 256f..2048f,
            steps = 6,
            modifier = Modifier.fillMaxWidth(),
        )

        Spacer(Modifier.height(12.dp))
        Text("Disk", color = Paper, fontSize = 16.sp)
        Text(
            "Bundled AahaOS initramfs (read-only / ephemeral). No browse-ISO picker.",
            color = Mute,
            fontSize = 13.sp,
            modifier = Modifier.padding(top = 4.dp),
        )
    }
}
