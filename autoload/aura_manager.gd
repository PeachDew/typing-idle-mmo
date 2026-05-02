extends Node

var aura: int = 0
var base_tick_duration: float = 1.0
@export var tick_decay_rate: float = 0.9

var idle_timer := Timer.new()

signal aura_changed

func _ready() -> void:
	idle_timer.wait_time = base_tick_duration
	idle_timer.one_shot = false
	add_child(idle_timer)
	idle_timer.timeout.connect(_on_idle_tick)
	idle_timer.start()
	UpgradeManager.upgrade_leveled.connect(_on_upgrade_changed)

func _on_idle_tick() -> void:
	AuraManager.aura += UpgradeManager.get_level("basic_aura_per_tick_boost")
	aura_changed.emit()

func increment_aura(amt: int) -> void:
	aura += amt
	aura_changed.emit()

func _on_upgrade_changed(id: String, _level: int) -> void:
	if id == "basic_aura_tickspeed_reduce":
		update_tickspeed()

func update_tickspeed() -> void:
	var level := UpgradeManager.get_level("basic_aura_tickspeed_reduce")
	idle_timer.wait_time = base_tick_duration * pow(tick_decay_rate, level)
	print(idle_timer.wait_time)
