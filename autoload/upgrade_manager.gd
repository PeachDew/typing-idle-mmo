extends Node

class Upgrade:
	var name: String
	var base_cost: int
	var level: int = 1
	var cost_multiplier: float = 1.5
	var effect_ids: PackedStringArray

	func _init(p_name: String, p_base_cost: int, p_effect_ids: PackedStringArray) -> void:
		name = p_name
		base_cost = p_base_cost
		effect_ids = p_effect_ids

	func get_cost() -> int:
		return int(base_cost * pow(cost_multiplier, level))

var upgrades: Array[Upgrade] = []
signal purchase_completed(success: bool)

func on_upgrade_purchase_attempt(index: int) -> bool:
	# connected in pause_menu.gd
	var upgrade: Upgrade = upgrades[index]
	if AuraManager.aura >= upgrade.get_cost():
		AuraManager.aura -= upgrade.get_cost()
		AuraManager.aura_changed.emit()
		upgrade.level += 1
		purchase_completed.emit(true)
		return true
	purchase_completed.emit(false)
	return false

func _ready() -> void:
	upgrades = [
		Upgrade.new("Speed Typing", 5, PackedStringArray(["up_base_points"])),
		Upgrade.new("Aura Mind", 10, PackedStringArray(["up_points_p_sec"])),
	]
