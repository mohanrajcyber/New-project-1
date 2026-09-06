package app.pockethost.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.pockethost.engine.BundledImageEngine
import app.pockethost.ui.components.MonoBlock
import app.pockethost.ui.components.PhCard
import app.pockethost.ui.theme.Ink
import app.pockethost.ui.theme.Mute
import app.pockethost.ui.theme.Paper

@Composable
fun SettingsScreen(engine: BundledImageEngine) {
    var ram by remember { mutableFloatStateOf(engine.settings.ramMb.toFloat()) }
    var disk by remember { mutableFloatStateOf(engine.settings.diskMb.toFloat()) }
    var variant by remember { mutableStateOf(engine.settings.variant) }
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
            "Saved on this phone. Start / Termux script uses -m RAM and a persist disk of this size.",
            color = Mute,
            fontSize = 13.sp,
            modifier = Modifier.padding(top = 6.dp, bottom = 18.dp),
        )

        PhCard {
            Text("RAM  ${ram.toInt()} MB  →  qemu -m", color = Paper, fontSize = 16.sp)
            Slider(
                value = ram,
                onValueChange = {
                    ram = it
                    engine.settings.ramMb = it.toInt()
                },
                valueRange = 256f..2048f,
                steps = 6,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(8.dp))
            Text("Disk  ${disk.toInt()} MB  →  persist.img", color = Paper, fontSize = 16.sp)
            Slider(
                value = disk,
                onValueChange = {
                    disk = it
                    engine.settings.diskMb = it.toInt()
                },
                valueRange = 0f..1024f,
                steps = 7,
                modifier = Modifier.fillMaxWidth(),
            )
            Text(
                "Guest mounts this image at /data (vfat). Files survive reboot.",
                color = Mute,
                fontSize = 13.sp,
            )
            Spacer(Modifier.height(12.dp))
            Text("RAM profiles → AAHA_MEM", color = Paper, fontSize = 16.sp)
            Row {
                listOf(256, 512, 1024).forEach { mb ->
                    FilterChip(
                        selected = ram.toInt() == mb,
                        onClick = {
                            ram = mb.toFloat()
                            engine.settings.ramMb = mb
                        },
                        label = { Text("${mb}") },
                    )
                    Spacer(Modifier.width(8.dp))
                }
            }
            Spacer(Modifier.height(12.dp))
            Text("Guest variant → AAHA_VARIANT", color = Paper, fontSize = 16.sp)
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
                    Spacer(Modifier.width(8.dp))
                }
            }
            Text(
                "Core local · Net DHCP+ssh · Lab applets · Study classroom lessons. Persist /data is vfat when AAHA_DISK > 0.",
                color = Mute,
                fontSize = 13.sp,
            )
            MonoBlock(engine.qemuCommand())
        }

        Spacer(Modifier.height(12.dp))
        PhCard {
            Text("About", color = Paper, fontSize = 16.sp)
            Spacer(Modifier.height(8.dp))
            Text("PocketHost 0.5  ·  guest ${manifest?.os ?: "AahaOS"} ${manifest?.version ?: ""}", color = Mute, fontSize = 13.sp)
            Text("Not a hypervisor brand. Not Windows. MIT userspace + Linux kernel.", color = Mute, fontSize = 13.sp)
        }
    }
}
