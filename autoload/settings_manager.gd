extends Node

## Persistent game settings manager. Saves to user://settings.json.
## Layout toggle is visual + mapping only. Uses physical_keycode (always QWERTY position)
## so it works regardless of the user's OS keyboard layout.

signal layout_changed(new_layout: String)

enum Layout {
	QWERTY,
	COLEMAK,
}

var current_layout := Layout.COLEMAK:
	set(v):
		if current_layout != v:
			current_layout = v
			layout_changed.emit(Layout.keys()[v].to_lower())
			_save()

const _SETTINGS_FILE := "user://settings.json"

const _LAYOUTS := {
	Layout.QWERTY: [
		["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
		["A", "S", "D", "F", "G", "H", "J", "K", "L"],
		["Z", "X", "C", "V", "B", "N", "M"],
	],
	Layout.COLEMAK: [
		["Q", "W", "F", "P", "G", "J", "L", "U", "Y", ";"],
		["A", "R", "S", "T", "D", "H", "N", "E", "I", "O"],
		["Z", "X", "C", "V", "B", "N", "M"],
	],
}

## Maps QWERTY physical key position → Colemak character.
## Keys that stay the same are omitted (identity mapping).
const _PHYSICAL_TO_COLEMAK := {
	KEY_E: "f", KEY_R: "p", KEY_T: "g", KEY_Y: "j", KEY_U: "l", KEY_I: "u", KEY_O: "y", KEY_P: ";",
	KEY_S: "r", KEY_D: "s", KEY_F: "t", KEY_G: "d", KEY_J: "n", KEY_K: "e", KEY_L: "i", KEY_SEMICOLON: "o",
	KEY_N: "k",
}


func _ready() -> void:
	_load()


func toggle_layout() -> void:
	current_layout = Layout.QWERTY if current_layout == Layout.COLEMAK else Layout.COLEMAK


func get_layout_rows() -> Array:
	return _LAYOUTS[current_layout]


## Convert a physical_keycode (always QWERTY position) to the character
## for the current in-game layout. Returns lowercase, or "" for non-letter keys.
func physical_to_char(physical_keycode: int) -> String:
	if physical_keycode == KEY_SPACE:
		return " "
	if current_layout == Layout.COLEMAK:
		var mapped: String = _PHYSICAL_TO_COLEMAK.get(physical_keycode, "")
		if mapped != "":
			return mapped
	var raw := OS.get_keycode_string(physical_keycode).to_lower()
	if raw.length() != 1 or raw < "a" or raw > "z":
		return ""
	return raw


func _save() -> void:
	var data := {
		"layout": current_layout,
	}
	var file := FileAccess.open(_SETTINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func _load() -> void:
	var file := FileAccess.open(_SETTINGS_FILE, FileAccess.READ)
	if file:
		var text := file.get_as_text()
		file.close()
		var json := JSON.new()
		var error := json.parse(text)
		if error == OK:
			var data : Variant = json.data
			if data.has("layout") and data.layout is int and data.layout in _LAYOUTS:
				current_layout = data.layout
