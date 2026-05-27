class_name StoreSection extends Area2D


@export var PickSectionUI : PackedScene
@export var section_type: Enums.SectionType
@export var current_container : GoodsContainerEntry
signal signal_clicked(section_type: Enums.SectionType)
@export_category("Edit Mode Stuff")
@export var container_edit_mode : bool = false
@onready var edit_overlay: ColorRect = $ColorRect
@onready var action_ui: Control = $ActionUI
@onready var remove_button:TextureButton = $ActionUI/RemoveButton


func _ready() -> void:
	_refresh_container()
	_update_edit_visuals()
	action_ui.visible = false

func _on_input_event(viewport : Node, event : InputEvent, shape_idx : int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if container_edit_mode:
			if current_container != null:
				action_ui.visible = !action_ui.visible
			else:
				showPickContainerUI()
			return
		signal_clicked.emit(section_type)

func set_container_edit_mode(enabled: bool) -> void:
	container_edit_mode = enabled
	_update_edit_visuals()
	if !enabled:
		action_ui.visible = false

func _update_edit_visuals() -> void:
	edit_overlay.visible = container_edit_mode

func showPickContainerUI() -> void:
	var picker : PickContainerUI = PickSectionUI.instantiate()
	var main_game := get_tree().get_first_node_in_group("main_game_scene")
	main_game.add_child(picker)
	picker.catalog_setup(section_type)
	picker.container_placed.connect(_on_container_placed)
	
func _on_container_placed(entry: GoodsContainerEntry) -> void:
	current_container = entry
	_refresh_container()
	_update_edit_visuals()

func _refresh_container() -> void:
	for child in get_children():
		if child is GoodsContainer:
			child.queue_free()
	if current_container and current_container.container_scene:
		add_child(current_container.container_scene.instantiate())

func _on_remove_button_pressed() -> void:
	if current_container == null:
		print("no container")
		return
	
	var container_node : GoodsContainer = get_current_container_node()
	if container_node != null:
		_eject_all_packs(container_node)
	action_ui.visible = false
	current_container = null
	_refresh_container()
	

func get_current_container_node() -> GoodsContainer:
	for child in get_children():
		if child is GoodsContainer:
			return child as GoodsContainer
	return null

func _eject_all_packs(container: GoodsContainer) -> void:
	var main_game : Node = get_tree().get_first_node_in_group("main_game_scene")
	if main_game == null:
		print("main game not found")
		return
	
	for slot : GoodsContainerSlot in container.pack_per_slot:
		var pack : PackData = slot.current_pack
		if pack == null or pack.current_stack <= 0:
			continue
		while pack.current_stack > 0:
			pack.current_stack -= 1
			var goods_body : RigidBody2D = pack.item_data.item_body.instantiate()
			main_game.add_child(goods_body)
			goods_body.global_position = self.global_position
			goods_body.rotation_degrees = randf_range(0.0, 360.0)
			goods_body.get_child(0).texture = pack.item_data.item_sprite
			goods_body.set_meta("pack_data", pack)
			goods_body.set_meta("item_data", pack.item_data)
			goods_body.add_to_group("dropped_pack")
		slot.current_pack = null
