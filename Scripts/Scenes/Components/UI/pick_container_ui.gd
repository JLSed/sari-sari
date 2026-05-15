class_name PickContainerUI extends Control

@export var ContainerItemUI : PackedScene
@onready var item_container: HBoxContainer = $ItemContainer

signal container_placed(container : GoodsContainerEntry)

func catalog_setup(section_type : Enums.SectionType) -> void:
	for entry : GoodsContainerEntry in PlayerManager.owned_containers:
		if  section_type in entry.allowed_placement:
			var new_container_ui : ContainerUI = ContainerItemUI.instantiate()
			item_container.add_child(new_container_ui)
			new_container_ui.setup(entry)
			new_container_ui.place_button_clicked.connect(_on_place_button_clicked)

func _on_place_button_clicked(container : GoodsContainerEntry) -> void:
	self.queue_free()
	container_placed.emit(container)


func _on_close_button_pressed() -> void:
	self.queue_free()
