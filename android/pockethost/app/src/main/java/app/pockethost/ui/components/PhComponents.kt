package app.pockethost.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.pockethost.engine.HostStatus
import app.pockethost.ui.theme.Accent
import app.pockethost.ui.theme.Card
import app.pockethost.ui.theme.Line
import app.pockethost.ui.theme.Mute
import app.pockethost.ui.theme.Paper
import app.pockethost.ui.theme.Ready
import app.pockethost.ui.theme.Warn

@Composable
fun PhCard(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(22.dp))
            .background(Card)
            .border(1.dp, Line, RoundedCornerShape(22.dp))
            .padding(20.dp),
    ) { content() }
}

@Composable
fun StatusPill(status: HostStatus) {
    val (label, tint) = when (status) {
        HostStatus.Running -> "Running" to Accent
        HostStatus.ReadyEngineOff -> "Ready" to Ready
        HostStatus.MissingImage -> "Missing image" to Warn
    }
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            "●",
            color = tint,
            fontSize = 12.sp,
        )
        Text(
            label,
            color = tint,
            fontSize = 15.sp,
            fontWeight = FontWeight.SemiBold,
        )
        if (status == HostStatus.ReadyEngineOff) {
            Text("engine off", color = Mute, fontSize = 12.sp)
        }
    }
}

@Composable
fun EmptyState(title: String, body: String) {
    PhCard {
        Text(title, color = Paper, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.height(8.dp))
        Text(body, color = Mute, fontSize = 13.sp, lineHeight = 18.sp)
    }
}

@Composable
fun MonoBlock(text: String, color: Color = Mute) {
    Text(
        text,
        color = color,
        fontSize = 11.sp,
        lineHeight = 16.sp,
        fontFamily = FontFamily.Monospace,
    )
}
