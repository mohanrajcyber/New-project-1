package app.pockethost.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val Ink = Color(0xFF0B1220)
val Card = Color(0xFF121A2B)
val Line = Color(0xFF243044)
val Accent = Color(0xFF2EE6D6)
val Ready = Color(0xFF3DDC97)
val Paper = Color(0xFFE8EEF7)
val Mute = Color(0xFF93A0B8)
val Warn = Color(0xFFF5C16C)

private val Scheme = darkColorScheme(
    primary = Accent,
    onPrimary = Ink,
    background = Ink,
    onBackground = Paper,
    surface = Card,
    onSurface = Paper,
    surfaceVariant = Color(0xFF1A2438),
    onSurfaceVariant = Mute,
    outline = Line,
    secondary = Ready,
    error = Warn,
)

@Composable
fun PocketHostTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = Scheme,
        content = content,
    )
}
