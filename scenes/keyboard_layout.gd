@tool
extends Control
## Visual keyboard layout — 3 rows of Key child nodes with configurable row offsets.

signal key_pressed(label: String)
signal layout_toggled(new_layout: String)

const KeyScene := preload("res://scenes/key.tscn")

# Physical QWERTY rows used for node naming (physical_keycode always gives QWERTY)
var _PHYSICAL_ROWS: Array[PackedStringArray] = [
	PackedStringArray(["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]),
	PackedStringArray(["A", "S", "D", "F", "G", "H", "J", "K", "L"]),
	PackedStringArray(["Z", "X", "C", "V", "B", "N", "M"]),
]

@export var key_size := Vector2(48, 48):
	set(v):
		key_size = v
		_rebuild()

@export var key_spacing := 4.0:
	set(v):
		key_spacing = v
		_rebuild()

@export var row_offsets: Array[float] = [0.0, 16.0, 32.0]:
	set(v):
		row_offsets = v
		_rebuild()

@export var font_size := 16:
	set(v):
		font_size = v
		_apply_to_keys(func(k: Node): k.font_size = v)

@export var rows: Array[PackedStringArray] = [
	["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
	["A", "S", "D", "F", "G", "H", "J", "K", "L"],
	["Z", "X", "C", "V", "B", "N", "M"],
]:
	set(v):
		rows = v
		_rebuild()

@export var bg_color := Color(0.15, 0.15, 0.18):
	set(v):
		bg_color = v
		_apply_to_keys(func(k: Node): k.bg_color = v)

@export var border_color := Color(0.4, 0.4, 0.45):
	set(v):
		border_color = v
		_apply_to_keys(func(k: Node): k.border_color = v)

@export var text_color := Color(0.9, 0.9, 0.9):
	set(v):
		text_color = v
		_apply_to_keys(func(k: Node): k.text_color = v)


func _ready() -> void:
	resized.connect(_rebuild)
	if not Engine.is_editor_hint():
		SettingsManager.layout_changed.connect(_on_layout_changed)
		_update_from_settings()
	_rebuild()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.echo:
			return
		# physical_keycode is always QWERTY position — use it to find the key node
		var physical := OS.get_keycode_string(key_event.physical_keycode).to_upper()
		var key_node := get_node_or_null("Key" + physical)
		if key_node:
			if key_event.pressed:
				key_node.press()
				key_pressed.emit(physical)
			elif not key_event.pressed:
				key_node.release()

func _on_layout_changed(new_layout: String) -> void:
	_update_from_settings()
	layout_toggled.emit(new_layout)

func _update_from_settings() -> void:
	var new_rows := SettingsManager.get_layout_rows()
	var typed_rows: Array[PackedStringArray] = []
	for row in new_rows:
		typed_rows.append(row as PackedStringArray)
	rows = typed_rows


func _rebuild() -> void:
	# Bail if not in tree yet (setters fire during scene load)
	if not is_inside_tree():
		return

	# Remove old keys immediately — queue_free is deferred and causes stale refs
	for child in get_children():
		remove_child(child)
		child.free()

	var kb_size := _get_keyboard_size()
	var origin := (size - kb_size) / 2.0
	var row_y := origin.y

	for row_idx in rows.size():
		var keys := rows[row_idx]
		var physical_keys: PackedStringArray = _PHYSICAL_ROWS[row_idx] if row_idx < _PHYSICAL_ROWS.size() else PackedStringArray()
		var offset := row_offsets[row_idx] if row_idx < row_offsets.size() else 0.0
		var x := origin.x + offset

		for col_idx in keys.size():
			var key_label: String = keys[col_idx]
			# Name node by physical QWERTY position so physical_keycode can find it
			var physical_name: String = physical_keys[col_idx] if col_idx < physical_keys.size() else key_label

			var key_node := KeyScene.instantiate()
			key_node.name = "Key" + physical_name
			key_node.label = key_label
			key_node.add_to_group("keyboard_keys")
			key_node.key_size = key_size
			key_node.font_size = font_size
			key_node.bg_color = bg_color
			key_node.border_color = border_color
			key_node.text_color = text_color
			key_node.position = Vector2(x, row_y)
			add_child(key_node)

			x += key_size.x + key_spacing

		row_y += key_size.y + key_spacing


## Call [param fn] on every key node. Passes the Key node as argument.
## Usage: keyboard.for_each_key(func(k): k.bg_color = Color.RED)
func for_each_key(fn: Callable) -> void:
	for child in get_children():
		if child.is_in_group("keyboard_keys"):
			fn.call(child)


func _apply_to_keys(fn: Callable) -> void:
	for_each_key(fn)


func _get_keyboard_size() -> Vector2:
	var max_x := 0.0
	var total_y := 0.0

	for row_idx in rows.size():
		var keys := rows[row_idx]
		var offset := row_offsets[row_idx] if row_idx < row_offsets.size() else 0.0
		var row_width := offset + keys.size() * (key_size.x + key_spacing) - key_spacing
		max_x = maxf(max_x, row_width)
		total_y += key_size.y + key_spacing

	total_y -= key_spacing
	return Vector2(max_x, total_y)
