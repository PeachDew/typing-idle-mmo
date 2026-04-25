extends Node

var aura: int = 0
var tick_duration: float = 1.0

var idle_timer := Timer.new()

signal aura_changed

func _ready() -> void:
	idle_timer.wait_time = tick_duration
	idle_timer.one_shot = false
	add_child(idle_timer)
	idle_timer.timeout.connect(_on_idle_tick)
	idle_timer.start()

func _on_idle_tick() -> void:
	AuraManager.aura += UpgradeManager.get_level("basic_aura_per_tick_boost")
	aura_changed.emit()

func increment_aura(amt: int):
	aura += amt
	aura_changed.emit()
