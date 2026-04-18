@tool
extends Control
## Base key node — extend or attach scripts to add effects/behavior per key.

@export var label := "":
	set(v):
		label = v
		queue_redraw()

@export var key_size := Vector2(48, 48):
	set(v):
		key_size = v
		custom_minimum_size = v
		queue_redraw()

@export var bg_color := Color(0.15, 0.15, 0.18):
	set(v):
		bg_color = v
		queue_redraw()

@export var border_color := Color(0.4, 0.4, 0.45):
	set(v):
		border_color = v
		queue_redraw()

@export var text_color := Color(0.9, 0.9, 0.9):
	set(v):
		text_color = v
		queue_redraw()

@export var highlight_color := Color(0.0, 1.0, 0.4):
	set(v):
		highlight_color = v
		queue_redraw()

@export var font_size := 16:
	set(v):
		font_size = v
		queue_redraw()


var pressed := false:
	set(v):
		pressed = v
		_on_pressed_changed()

func press():
	pressed = true

func release():
	pressed = false

func _ready() -> void:
	custom_minimum_size = key_size
	queue_redraw()


## Called whenever [member pressed] changes. Override or extend for additional effects.
func _on_pressed_changed() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, key_size), bg_color)
	var current_border := highlight_color if pressed else border_color
	draw_rect(Rect2(Vector2.ZERO, key_size), current_border, false, 2.0 if pressed else 1.0)

	if label.is_empty():
		return

	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := Vector2(
		(key_size.x - text_size.x) / 2.0,
		(key_size.y + font_size) / 2.0 - font.get_descent(font_size),
	)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
