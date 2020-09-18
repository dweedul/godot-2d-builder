extends CenterContainer


const QUICKBAR_ACTIONS := [
	"quickbar_1",
	"quickbar_2",
	"quickbar_3",
	"quickbar_4",
	"quickbar_5",
	"quickbar_6",
	"quickbar_7",
	"quickbar_8",
	"quickbar_9",
	"quickbar_0"
]

export var debug_items := {}

var blueprint: BlueprintEntity setget _set_blueprint, _get_blueprint
var _open_gui: Control
var _is_open := false

onready var player_inventory := $InventoryWindow
onready var quickbar_container := $MarginContainer/MarginContainer
onready var quickbar := $MarginContainer/MarginContainer/Quickbar
onready var _drag_preview := $DragPreview


func _ready() -> void:
	player_inventory.setup(self)
	quickbar.setup(self)
	
	# ----- Temp Debug system -----
	# TODO: Make proper debug system
	var index := 0
	for item in debug_items.keys():
		var item_instance: Node = item.instance()
		var panel: Panel = player_inventory.inventories.get_child(0).panels[index]
		panel.held_item = item_instance
		item_instance.stack_count = min(item_instance.stack_size, debug_items[item])
		panel._update_label()
		index += 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		if _is_open:
			_close_inventories()
		else:
			_open_inventories()
	
	for i in QUICKBAR_ACTIONS.size():
		var quick_action: String = QUICKBAR_ACTIONS[i]
		if InputMap.event_is_action(event, quick_action) and event.is_pressed():
			_simulate_input(quickbar.panels[i])
			break


func add_to_inventory(item: BlueprintEntity) -> bool:
	if item.get_parent() != null:
		item.get_parent().remove_child(item)
	var existing_stacks: Array = quickbar.find_panels_with(item.id) + player_inventory.find_panels_with(item.id)
	for panel in existing_stacks:
		if panel.held_item.stack_count < panel.held_item.stack_size:
			var available_space: int = panel.held_item.stack_size - panel.held_item.stack_count
			if item.stack_count > available_space:
				panel.held_item.stack_count += available_space
				item.stack_count -= available_space
			else:
				panel.held_item.stack_count += item.stack_count
				item.queue_free()
				return true
	
	if quickbar.add_to_first_available_inventory(item):
		return true

	return player_inventory.add_to_first_available_inventory(item)


func destroy_blueprint() -> void:
	_drag_preview.destroy_blueprint()


func update_label() -> void:
	_drag_preview.update_label()


func open_entity_gui(entity: Entity) -> void:
	var component := get_gui_component_from(entity)
	if not component:
		return
	
	_open_gui = component.gui
	player_inventory.inventories.add_child(_open_gui)
	player_inventory.inventories.move_child(_open_gui, 0)
	_open_gui.setup(self)
	_open_inventories()


func get_gui_component_from(entity: Node) -> GUIComponent:
	for child in entity.get_children():
		if child is GUIComponent:
			return child
	
	return null


func find_inventory_bars_in(component: GUIComponent) -> Array:
	var output := []
	var parent_stack := [component.window]
	
	while not parent_stack.empty():
		var current: Node = parent_stack.pop_back()
		
		if current is InventoryBar:
			output.push_back(current)
		
		parent_stack += current.get_children()
	
	return output


func _open_inventories() -> void:
	_is_open = true
	player_inventory.visible = true
	player_inventory.claim_quickbar(quickbar)


func _close_inventories() -> void:
	_is_open = false
	player_inventory.visible = false
	_claim_quickbar()
	if _open_gui:
		player_inventory.inventories.remove_child(_open_gui)
		_open_gui = null


func _simulate_input(panel: InventoryPanel) -> void:
	var input := InputEventMouseButton.new()
	input.button_index = BUTTON_LEFT
	input.pressed = true
	panel._gui_input(input)


func _claim_quickbar() -> void:
	quickbar.get_parent().remove_child(quickbar)
	quickbar_container.add_child(quickbar)


func _set_blueprint(value: BlueprintEntity) -> void:
	if not is_inside_tree():
		yield(self, "ready")
	_drag_preview.blueprint = value


func _get_blueprint() -> BlueprintEntity:
	return _drag_preview.blueprint
