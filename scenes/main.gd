extends Control

var score := 0

@onready var counter: Label = $Counter
@onready var keyboard: Control = $KeyboardLayout


func _ready() -> void:
	keyboard.key_pressed.connect(_on_key_pressed)


func _on_key_pressed(label: String) -> void:
	score += 1
	counter.text = str(score)
