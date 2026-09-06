package app.pockethost.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Bolt
import androidx.compose.material.icons.outlined.Memory
import androidx.compose.material.icons.outlined.PhotoLibrary
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.Terminal
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import app.pockethost.engine.BundledImageEngine
import app.pockethost.ui.theme.Card
import app.pockethost.ui.theme.Ink

@Composable
fun PocketHostApp(engine: BundledImageEngine) {
    val nav = rememberNavController()
    val back by nav.currentBackStackEntryAsState()
    val route = back?.destination?.route ?: "home"
    var showWizard by remember { mutableStateOf(!engine.settings.wizardDone) }

    fun go(dest: String) {
        nav.navigate(dest) {
            launchSingleTop = true
            restoreState = true
        }
    }

    Scaffold(
        containerColor = Ink,
        bottomBar = {
            NavigationBar(containerColor = Card) {
                NavigationBarItem(
                    selected = route == "home",
                    onClick = { go("home") },
                    icon = { Icon(Icons.Outlined.Memory, contentDescription = "AahaOS") },
                    label = { Text("AahaOS") },
                )
                NavigationBarItem(
                    selected = route == "snapshots",
                    onClick = { go("snapshots") },
                    icon = { Icon(Icons.Outlined.PhotoLibrary, contentDescription = "Snapshots") },
                    label = { Text("Snaps") },
                )
                NavigationBarItem(
                    selected = route == "serial",
                    onClick = { go("serial") },
                    icon = { Icon(Icons.Outlined.Terminal, contentDescription = "Serial") },
                    label = { Text("Serial") },
                )
                NavigationBarItem(
                    selected = route == "engine",
                    onClick = { go("engine") },
                    icon = { Icon(Icons.Outlined.Bolt, contentDescription = "Engine") },
                    label = { Text("Engine") },
                )
                NavigationBarItem(
                    selected = route == "settings",
                    onClick = { go("settings") },
                    icon = { Icon(Icons.Outlined.Settings, contentDescription = "Settings") },
                    label = { Text("More") },
                )
            }
        },
    ) { padding ->
        NavHost(
            navController = nav,
            startDestination = "home",
            modifier = Modifier.padding(padding),
        ) {
            composable("home") { HomeScreen(engine, onOpenEngine = { go("engine") }) }
            composable("snapshots") { SnapshotsScreen(engine) }
            composable("serial") { SerialScreen(engine) }
            composable("engine") { EngineScreen(engine) }
            composable("settings") { SettingsScreen(engine) }
        }
    }
    if (showWizard) {
        FirstRunWizard(engine) { showWizard = false }
    }
}
