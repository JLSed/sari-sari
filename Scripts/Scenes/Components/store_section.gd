class_name StoreSection extends Area2D


@export var PickSectionUI : PackedScene
@export var section_type: Enums.SectionType
@export var current_container : GoodsContainerEntry
signal signal_clicked(section_type: Enums.SectionType)
@export_category("Edit Mode Stuff")
@export var container_edit_mode : bool = false
@onready var edit_overlay: ColorRect = $ColorRect


func _ready() -> void:
	_refresh_container()
	_update_edit_visuals()

#func _process(delta: float) -> void:
	#if container_image == null and current_container != null:
		#container_image.texture = current_container.container_sprite

func _on_input_event(viewport : Node, event : InputEvent, shape_idx : int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if container_edit_mode:
			showPickContainerUI()
			return
		signal_clicked.emit(section_type)

func set_container_edit_mode(enabled: bool) -> void:
	container_edit_mode = enabled
	_update_edit_visuals()

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
