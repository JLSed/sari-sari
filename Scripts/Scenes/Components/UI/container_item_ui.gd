class_name ContainerUI extends NinePatchRect

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@export var current_container : GoodsContainerEntry

signal place_button_clicked(container : GoodsContainerEntry)

func setup(entry: GoodsContainerEntry) -> void:
	current_container = entry
	label.text = entry.container_name
	if entry.container_scene:
		# this takes the texture for the scene to the ui
		var inst : GoodsContainer = entry.container_scene.instantiate()
		texture_rect.texture = inst.container_texture
		inst.queue_free()

func _on_button_pressed() -> void:
	place_button_clicked.emit(current_container)
