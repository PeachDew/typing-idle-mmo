extends Node

var upgrade_data: Dictionary[String, UpgradeDefinition] = {}
var upgrade_levels: Dictionary[String, int] = {}

signal purchase_completed(success: bool)


func on_upgrade_purchase_attempt(id: String) -> bool:
	# connected in pause_menu.gd
	var upgrade_cost: int = get_cost(id)
	if AuraManager.aura >= upgrade_cost:
		AuraManager.aura -= upgrade_cost
		AuraManager.aura_changed.emit()
		upgrade_levels[id] += 1
		purchase_completed.emit(true)
		return true
	purchase_completed.emit(false)
	return false


func _load_upgrade_resources(path: String = "res://resources/"):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == "." or file_name == "..":
				continue
			if file_name.ends_with(".tres"):
				var res: Resource = load(path + file_name)
				if not res is UpgradeDefinition:
					continue
				var def: UpgradeDefinition = res
				upgrade_data[def.id] = def
				upgrade_levels[def.id] = 0
			file_name = dir.get_next()


func get_level(id: String) -> int:
	return upgrade_levels[id]


func get_upgrade_name(id: String) -> String:
	return upgrade_data[id].name


func get_cost(id: String) -> int:
	var upgrade: UpgradeDefinition = upgrade_data[id]
	return int(upgrade.base_cost * pow(upgrade.cost_multiplier, upgrade_levels[id]))


func get_all_ids() -> Array:
	return upgrade_data.keys()


func _ready() -> void:
	_load_upgrade_resources()
