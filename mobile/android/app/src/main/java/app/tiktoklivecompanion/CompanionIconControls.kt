package app.tiktoklivecompanion

import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.selection.toggleable
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp

private val LocalIconStyle = staticCompositionLocalOf { "plastisch" }
private val LocalSetIconStyle = staticCompositionLocalOf<(String) -> Unit> { {} }
@Composable fun CompanionIconTheme(content: @Composable () -> Unit) {
    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences("icon-design", 0) }
    var style by remember { mutableStateOf(prefs.getString("style", "plastisch") ?: "plastisch") }
    if (style !in listOf("plastisch", "glass", "linear")) style = "plastisch"
    CompositionLocalProvider(LocalIconStyle provides style, LocalSetIconStyle provides { value -> style = value; prefs.edit().putString("style", value).apply() }, content = content)
}
@Composable fun CompanionControlIcon(component: String, description: String? = null) {
    val context = LocalContext.current
    val style = LocalIconStyle.current
    val bitmap = remember(style, component) { context.assets.open("icons/$style/$component.png").use { BitmapFactory.decodeStream(it).asImageBitmap() } }
    Image(bitmap, contentDescription = description, modifier = Modifier.size(32.dp))
}
@OptIn(ExperimentalMaterial3Api::class)
@Composable fun CompanionIconHint(label: String, content: @Composable () -> Unit) {
    TooltipBox(positionProvider = TooltipDefaults.rememberPlainTooltipPositionProvider(),
        tooltip = { PlainTooltip { Text(label) } }, state = rememberTooltipState(), content = content)
}
@Composable fun CompanionIconLabel(label: String, component: String) {
    CompanionIconHint(label) { Box(Modifier.size(48.dp), contentAlignment = Alignment.Center) { CompanionControlIcon(component, label) } }
}
@Composable fun CompanionIconSwitch(checked: Boolean, onCheckedChange: (Boolean) -> Unit, label: String = if (checked) "Off" else "On") {
    CompanionIconHint(label) {
        Box(Modifier.size(48.dp).semantics { contentDescription = label }.toggleable(value = checked, role = Role.Switch, onValueChange = onCheckedChange), contentAlignment = Alignment.Center) {
            CompanionControlIcon(if (checked) "on" else "off")
        }
    }
}
@Composable fun CompanionIconStylePicker() {
    val style = LocalIconStyle.current
    val setStyle = LocalSetIconStyle.current
    var expanded by remember { mutableStateOf(false) }
    Column {
        Text("Icon-Stil")
        Box {
            OutlinedButton(onClick = { expanded = true }) { Text(when(style) { "glass" -> "Glass / Realistisch"; "linear" -> "Minimal / Linear"; else -> "3D / Plastisch" }) }
            DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                for ((value, label) in listOf("plastisch" to "3D / Plastisch", "glass" to "Glass / Realistisch", "linear" to "Minimal / Linear")) {
                    DropdownMenuItem(text = { Text(label) }, onClick = { setStyle(value); expanded = false })
                }
            }
        }
    }
}
