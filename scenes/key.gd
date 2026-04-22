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

@export_group("Fade Timings")
@export var fade_in_duration := 0.05
@export var fade_to_dim_duration := 0.3
@export var fade_out_duration := 0.4

@export var glow_intensity_held := 0.4

## Current glow intensity: 0.0 = off, 1.0 = full highlight.
var glow := 0.0:
	set(v):
		glow = v
		queue_redraw()

var _held := false
var _tween: Tween = null


func press() -> void:
	_held = true
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "glow", 1.0, fade_in_duration)
	_tween.tween_property(self, "glow", glow_intensity_held, fade_to_dim_duration)


func release() -> void:
	_held = false
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "glow", 0.0, fade_out_duration)


func _ready() -> void:
	custom_minimum_size = key_size
	queue_redraw()


func _kill_tween() -> void:
	if _tween:
		_tween.kill()
		_tween = null


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, key_size), bg_color)

	var border := border_color.lerp(highlight_color, glow)
	var border_width := 1.0 + glow * 2.0
	draw_rect(Rect2(Vector2.ZERO, key_size), border, false, border_width)

	if label.is_empty():
		return

	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := Vector2(
		(key_size.x - text_size.x) / 2.0,
		(key_size.y + font_size) / 2.0 - font.get_descent(font_size),
	)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
