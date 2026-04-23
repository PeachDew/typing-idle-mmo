extends Control

@onready var counter: Label = $Counter
@onready var keyboard: Control = $KeyboardLayout
@onready var pause_menu: Panel = $PauseMenu

func _ready() -> void:
	keyboard.key_pressed.connect(_on_key_pressed)
	AuraManager.aura_changed.connect(on_aura_manager_aura_changed)

func on_aura_manager_aura_changed():
	counter.text = str(AuraManager.aura)

func _on_key_pressed(_label: String) -> void:
	AuraManager.aura += 1 + UpgradeManager.get_level("basic_keypress_boost")
	counter.text = str(AuraManager.aura)
