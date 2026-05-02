extends Node

var upgrade_data: Dictionary[String, UpgradeDefinition] = {}
var upgrade_levels: Dictionary[String, int] = {}
var sorted_upgrade_ids: Array[String] = []

signal purchase_resolved(success: bool)
signal upgrade_leveled(id: String, new_level: int)


func on_upgrade_purchase_attempt(id: String) -> bool:
	# connected in pause_menu.gd
	var upgrade_cost: int = get_cost(id)
	if AuraManager.aura >= upgrade_cost:
		AuraManager.aura -= upgrade_cost
		AuraManager.aura_changed.emit()
		upgrade_levels[id] += 1
		purchase_resolved.emit(true)
		upgrade_leveled.emit(id, upgrade_levels[id])
		return true
	purchase_resolved.emit(false)
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
				print(file_name)
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


func get_all_ids() -> Array[String]:
	if sorted_upgrade_ids:
		return sorted_upgrade_ids
	var upgrade_ids: Array[String] = []
	for id in upgrade_data:
		upgrade_ids.append(id)
	upgrade_ids.sort_custom(func(a: String, b: String) -> bool:
		return upgrade_data[a].sort_order < upgrade_data[b].sort_order
	)
	sorted_upgrade_ids = upgrade_ids
	return upgrade_ids


func _ready() -> void:
	_load_upgrade_resources()
