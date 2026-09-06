package app.pockethost

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import app.pockethost.engine.BundledImageEngine
import app.pockethost.ui.PocketHostApp
import app.pockethost.ui.theme.PocketHostTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val engine = BundledImageEngine(applicationContext)
        setContent {
            PocketHostTheme {
                PocketHostApp(engine = engine)
            }
        }
    }
}
