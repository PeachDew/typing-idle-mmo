extends Control

@onready var counter: Label = $Counter
@onready var keyboard: Control = $VBoxContainer/KeyboardLayout
@onready var pause_menu: Panel = $PauseMenu
@onready var wordstream: Control = $VBoxContainer/WordStream
@onready var background_flash: ColorRect = $BackgroundFlash

func _ready() -> void:
	wordstream.character_typed.connect(_on_key_pressed)
	wordstream.character_typed.connect(background_flash.flash)
	wordstream.layout_toggled.connect(_on_layout_toggled)
	AuraManager.aura_changed.connect(on_aura_manager_aura_changed)

func on_aura_manager_aura_changed():
	counter.text = str(AuraManager.aura)

func _on_layout_toggled(new_layout: String) -> void:
	print("Layout toggled to: ", new_layout)
	# Keyboard will update automatically via SettingsManager signal

func _on_key_pressed(correct: bool) -> void:
	var increment_amount: int = 1 + UpgradeManager.get_level("basic_keypress_boost")
	if correct:
		increment_amount *= 3
	AuraManager.increment_aura(increment_amount)
