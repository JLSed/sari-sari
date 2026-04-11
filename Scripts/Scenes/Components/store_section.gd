class_name StoreSection extends Area2D



@export var section_type: Enums.SectionType
@export var current_container : GoodsContainerData

func _ready() -> void:
	if current_container:
		current_container = current_container.duplicate(true)
		var container_scene : Node = current_container.scene_reference.instantiate();
		add_child(container_scene)

#func _process(delta: float) -> void:
	#if container_image == null and current_container != null:
		#container_image.texture = current_container.container_sprite

func _on_input_event(viewport : Node, event : InputEvent, shape_idx : int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Tell the UI that this specific section was clicked, and pass its type
		SignalBus.emit_signal("section_clicked", self, section_type)
