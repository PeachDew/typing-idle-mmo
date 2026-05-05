extends ColorRect
## Background ripple feedback for correct/wrong keystrokes.
##
## Ring buffer of PULSE_COUNT concurrent ripples. Each keystroke spawns an
## expanding ring at a random position. Lifespan, fade speed, and hue are
## all independently tunable with per-ripple variation.

const PULSE_COUNT := 11  # change freely — shader MAX_PULSES is 32

@export var color_neutral := Color(0.11, 0.11, 0.14, 1.0)
@export var color_correct := Color(0.15, 0.30, 0.15, 1.0)
@export var color_wrong := Color(0.30, 0.12, 0.12, 1.0)
@export var max_lifespan := 1.5         # seconds for a ripple to go from spawn to dead
@export var lifespan_variation := 0.3   # +/- random on lifespan (0 = none)
@export var max_radius := 0.8          # how far the ring reaches at end of life
@export var ring_width := 0.06         # thickness of the ring band
@export var fade_speed := 4.0          # exponential fade rate (higher = fades faster)
@export var expansion_ease := 0.5     # curve power (lower = fast start slow finish, 1.0 = linear)
@export var fade_variation := 0.3      # +/- random multiplier on fade (0 = none)
@export var hue_variation := 0.1      # +/- random hue shift per ripple (0 = none)

var _next_slot: int = 0
var _centers: PackedVector2Array
var _progress: PackedFloat32Array
var _signs: PackedFloat32Array
var _hue_shifts: PackedFloat32Array
var _fade_scales: PackedFloat32Array
var _rates: PackedFloat32Array  # per-ripple progress rate (lifespan variation)


func _ready() -> void:
	_centers.resize(PULSE_COUNT)
	_progress.resize(PULSE_COUNT)
	_signs.resize(PULSE_COUNT)
	_hue_shifts.resize(PULSE_COUNT)
	_fade_scales.resize(PULSE_COUNT)
	_rates.resize(PULSE_COUNT)
	for i in PULSE_COUNT:
		_centers[i] = Vector2(0.5, 0.5)
		_progress[i] = 0.0
		_signs[i] = 0.0
		_hue_shifts[i] = 0.0
		_fade_scales[i] = 1.0
		_rates[i] = 1.0 / max_lifespan

	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/background_flash.gdshader")
	mat.set_shader_parameter("color_neutral", Vector3(color_neutral.r, color_neutral.g, color_neutral.b))
	mat.set_shader_parameter("color_correct", Vector3(color_correct.r, color_correct.g, color_correct.b))
	mat.set_shader_parameter("color_wrong", Vector3(color_wrong.r, color_wrong.g, color_wrong.b))
	mat.set_shader_parameter("max_radius", max_radius)
	mat.set_shader_parameter("ring_width", ring_width)
	mat.set_shader_parameter("fade_speed", fade_speed)
	mat.set_shader_parameter("expansion_ease", expansion_ease)
	mat.set_shader_parameter("active_pulse_count", PULSE_COUNT)
	mat.set_shader_parameter("aspect_ratio", get_viewport_rect().size.x / get_viewport_rect().size.y)
	mat.set_shader_parameter("pulse_center", _centers)
	mat.set_shader_parameter("pulse_progress", _progress)
	mat.set_shader_parameter("pulse_sign", _signs)
	mat.set_shader_parameter("pulse_hue_shift", _hue_shifts)
	mat.set_shader_parameter("pulse_fade_scale", _fade_scales)
	material = mat


func _process(delta: float) -> void:
	var any_active := false
	for i in PULSE_COUNT:
		if _progress[i] <= 0.0 or _progress[i] >= 1.0:
			continue
		any_active = true
		_progress[i] += _rates[i] * delta
		if _progress[i] >= 1.0:
			_progress[i] = 0.0
			_signs[i] = 0.0

	material.set_shader_parameter("aspect_ratio", get_viewport_rect().size.x / get_viewport_rect().size.y)

	if any_active:
		material.set_shader_parameter("pulse_progress", _progress)
		material.set_shader_parameter("pulse_sign", _signs)


func flash(correct: bool) -> void:
	if not correct:
		return
	var slot := _next_slot
	_next_slot = (_next_slot + 1) % PULSE_COUNT

	# Per-ripple lifespan: randomize the actual lifespan, derive progress rate
	var lifespan := max_lifespan * randf_range(1.0 - lifespan_variation, 1.0 + lifespan_variation)
	_rates[slot] = 1.0 / lifespan

	_progress[slot] = 0.001
	_signs[slot] = 1.0 if correct else -1.0
	_centers[slot] = Vector2(randf(), randf())
	_hue_shifts[slot] = randf_range(-hue_variation, hue_variation)
	_fade_scales[slot] = randf_range(1.0 - fade_variation, 1.0 + fade_variation)

	material.set_shader_parameter("pulse_center", _centers)
	material.set_shader_parameter("pulse_progress", _progress)
	material.set_shader_parameter("pulse_sign", _signs)
	material.set_shader_parameter("pulse_hue_shift", _hue_shifts)
	material.set_shader_parameter("pulse_fade_scale", _fade_scales)
