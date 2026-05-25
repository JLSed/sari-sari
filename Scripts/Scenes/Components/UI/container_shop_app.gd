class_name ContainerShopApp extends PhoneApp

@onready var containers_container: GridContainer = $HScrollBar/MarginContainer/ContainersContainer

@export var ContainerShopItemCardUI : PackedScene

const CONTAINER_FOLDER := "res://Assets/Resources/Container/"

func _ready() -> void:
	var containers := _load_all_containers()
	for container in containers:
		var new_card := ContainerShopItemCardUI.instantiate()
		containers_container.add_child(new_card)
		new_card.setup(container)


func _load_all_containers() -> Array[GoodsContainerEntry]:
	var containers : Array[GoodsContainerEntry] = []
	var dir := DirAccess.open(CONTAINER_FOLDER)
	if dir == null:
		print("no directory")
		return containers
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(CONTAINER_FOLDER + file_name)
			if res is GoodsContainerEntry:
				containers.append(res as GoodsContainerEntry)
		file_name = dir.get_next()
	dir.list_dir_end()
	return containers






func _on_back_button_pressed() -> void:
	close()
