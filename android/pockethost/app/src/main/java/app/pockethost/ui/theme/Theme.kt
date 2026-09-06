package app.pockethost.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

val Ink = Color(0xFF070B14)
val Card = Color(0xFF101827)
val CardHi = Color(0xFF162033)
val Line = Color(0xFF2A3A55)
val Accent = Color(0xFF2EE6D6)
val AccentDim = Color(0xFF1A6F68)
val Ready = Color(0xFF3DDC97)
val Paper = Color(0xFFF2F6FF)
val Mute = Color(0xFF8FA0BB)
val Warn = Color(0xFFF5C16C)
val Danger = Color(0xFFFF8A80)

private val Scheme = darkColorScheme(
    primary = Accent,
    onPrimary = Ink,
    background = Ink,
    onBackground = Paper,
    surface = Card,
    onSurface = Paper,
    surfaceVariant = CardHi,
    onSurfaceVariant = Mute,
    outline = Line,
    secondary = Ready,
    error = Warn,
)

private val Type = Typography(
    headlineLarge = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 30.sp,
        letterSpacing = (-0.5).sp,
        color = Paper,
    ),
    titleLarge = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 20.sp,
        fontFamily = FontFamily.SansSerif,
        color = Paper,
    ),
    bodyMedium = TextStyle(
        fontSize = 14.sp,
        lineHeight = 20.sp,
        color = Mute,
    ),
    labelLarge = TextStyle(
        fontWeight = FontWeight.SemiBold,
        fontSize = 16.sp,
    ),
)

@Composable
fun PocketHostTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = Scheme,
        typography = Type,
        content = content,
    )
}
