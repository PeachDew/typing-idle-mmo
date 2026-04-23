@tool
extends Panel
## Semi-transparent pause menu overlay. Toggle visibility via Escape.

signal upgrade_purchase_attempt(index: String)

@export var border_margin := 40.0:
	set(v):
		border_margin = v
		_update_anchors()

@export var overlay_color := Color(0.0, 0.0, 0.0, 0.7):
	set(v):
		overlay_color = v
		queue_redraw()

@export var placeholder_size := Vector2(80, 80):
	set(v):
		placeholder_size = v
		_update_placeholders()

@export var selected_color := Color(1.0, 0.85, 0.0, 1.0)
@export var unselected_color := Color(0.3, 0.3, 0.35, 1.0)

var selected_index := 0
var feedback_text := "":
	set(v):
		feedback_text = v
		_update_feedback()

var _feedback_timer := 0.0


func on_upgrade_manager_purchase_complete(purchase_success: bool):
	if purchase_success:
		show_feedback("Purchased")
		refresh_costs()
	else:
		show_feedback("Not Enough Points")


func _ready() -> void:
	_update_anchors()
	_update_placeholders()
	_refresh_from_manager()
	_update_selection()

	UpgradeManager.purchase_completed.connect(on_upgrade_manager_purchase_complete)
	upgrade_purchase_attempt.connect(UpgradeManager.on_upgrade_purchase_attempt)


func _process(delta: float) -> void:
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0:
			feedback_text = ""


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.keycode == KEY_ESCAPE and not event.echo:
		if event.pressed:
			_toggle()
			return
	if visible and event is InputEventKey and event.pressed and not event.echo:
		var dir := 0
		match event.keycode:
			KEY_LEFT, KEY_H:
				dir = -1
			KEY_RIGHT, KEY_L:
				dir = 1
			KEY_UP, KEY_K:
				dir = -1
			KEY_DOWN, KEY_J:
				dir = 1
		if dir != 0:
			selected_index = wrapi(selected_index + dir, 0, _option_count())
			_update_selection()
			accept_event()
			return
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			var upgrade_id: String = UpgradeManager.get_all_ids()[selected_index]
			upgrade_purchase_attempt.emit(upgrade_id)
			accept_event()


func _toggle() -> void:
	visible = not visible
	if visible:
		_refresh_from_manager()
		_update_selection()


func show_feedback(text: String, duration := 2.0) -> void:
	feedback_text = text
	_feedback_timer = duration


func refresh_costs() -> void:
	_refresh_from_manager()


func _refresh_from_manager() -> void:
	if not is_inside_tree():
		return
	var labels := _get_desc_labels()
	var cost_labels := _get_cost_labels()
	for i in UpgradeManager.get_all_ids().size():
		var upgrade_id: String = UpgradeManager.get_all_ids()[i]
		if i < labels.size():
			labels[i].text = UpgradeManager.get_upgrade_name(upgrade_id)
		if i < cost_labels.size():
			cost_labels[i].text = str(UpgradeManager.get_cost(upgrade_id)) + " pts"


func _update_anchors() -> void:
	if not is_inside_tree():
		return
	var m := border_margin
	offset_left = m
	offset_top = m
	offset_right = -m
	offset_bottom = -m


func _update_placeholders() -> void:
	if not is_inside_tree():
		return
	for ph in _get_icons():
		ph.custom_minimum_size = placeholder_size


func _update_feedback() -> void:
	if not is_inside_tree():
		return
	var fb := get_node_or_null("FeedbackLabel") as Label
	if fb:
		fb.text = feedback_text


func _option_count() -> int:
	if not is_inside_tree():
		return 0
	return $HBoxContainer.get_child_count()


func _update_selection() -> void:
	if not is_inside_tree():
		return
	var options := $HBoxContainer.get_children()
	for i in options.size():
		var opt := options[i] as PanelContainer
		if not opt:
			continue
		var style := StyleBoxFlat.new()
		style.content_margin_left = 8.0
		style.content_margin_top = 8.0
		style.content_margin_right = 8.0
		style.content_margin_bottom = 8.0
		style.bg_color = Color(0.2, 0.2, 0.25, 1)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = selected_color if i == selected_index else unselected_color
		opt.add_theme_stylebox_override("panel", style)


func _get_icons() -> Array[ColorRect]:
	var result: Array[ColorRect] = []
	if is_inside_tree():
		for child in $HBoxContainer.get_children():
			var icon := child.get_node_or_null("VBox/Icon") as ColorRect
			if icon:
				result.append(icon)
	return result


func _get_desc_labels() -> Array[Label]:
	var result: Array[Label] = []
	if is_inside_tree():
		for child in $HBoxContainer.get_children():
			var lbl := child.get_node_or_null("VBox/Description") as Label
			if lbl:
				result.append(lbl)
	return result


func _get_cost_labels() -> Array[Label]:
	var result: Array[Label] = []
	if is_inside_tree():
		for child in $HBoxContainer.get_children():
			var lbl := child.get_node_or_null("VBox/Cost") as Label
			if lbl:
				result.append(lbl)
	return result
