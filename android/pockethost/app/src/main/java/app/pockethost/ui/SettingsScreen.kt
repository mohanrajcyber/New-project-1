package app.pockethost.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
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
import app.pockethost.engine.BundledImageEngine
import app.pockethost.ui.components.PhCard
import app.pockethost.ui.theme.Ink
import app.pockethost.ui.theme.Mute
import app.pockethost.ui.theme.Paper

@Composable
fun SettingsScreen(engine: BundledImageEngine) {
    var ram by remember { mutableFloatStateOf(512f) }
    val manifest = remember { engine.manifest() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Ink)
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
    ) {
        Text("Settings", color = Paper, fontSize = 28.sp)
        Text(
            "Defaults only. They do not change a running guest — there isn't one.",
            color = Mute,
            fontSize = 13.sp,
            modifier = Modifier.padding(top = 6.dp, bottom = 18.dp),
        )

        PhCard {
            Text("RAM  ${ram.toInt()} MB", color = Paper, fontSize = 16.sp)
            Slider(
                value = ram,
                onValueChange = { ram = it },
                valueRange = 256f..2048f,
                steps = 6,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(8.dp))
            Text("Disk", color = Paper, fontSize = 16.sp)
            Text(
                "Bundled AahaOS initramfs (ephemeral). No browse-ISO picker. Variants: Core (console) and Net (Core + DHCP applets).",
                color = Mute,
                fontSize = 13.sp,
                modifier = Modifier.padding(top = 4.dp),
            )
        }

        Spacer(Modifier.height(12.dp))
        PhCard {
            Text("About", color = Paper, fontSize = 16.sp)
            Spacer(Modifier.height(8.dp))
            Text("PocketHost 0.2  ·  guest ${manifest?.os ?: "AahaOS"} ${manifest?.version ?: ""}", color = Mute, fontSize = 13.sp)
            Text("Not a hypervisor brand. Not Windows. MIT userspace + Linux kernel.", color = Mute, fontSize = 13.sp)
        }
    }
}
