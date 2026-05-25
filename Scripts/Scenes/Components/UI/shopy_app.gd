class_name ShopyApp extends PhoneApp

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var item_container: GridContainer = $ShopyBackground/HScrollBar/MarginContainer/ItemContainer

@export var ShopyItemCardUI : PackedScene

const PACK_FOLDER := "res://Assets/Resources/Pack/"

func _ready() -> void:
	var forsale_goods := _load_all_packs()
	for forsale in forsale_goods:
		var new_card : ShopyItemCard = ShopyItemCardUI.instantiate()
		item_container.add_child(new_card)
		new_card.setup(forsale)

func _load_all_packs() -> Array[PackData]:
	var packs : Array[PackData] = []
	var dir := DirAccess.open(PACK_FOLDER)
	if dir == null:
		print("no directory")
		return packs
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
			var res_path := PACK_FOLDER + file_name.replace(".remap", "")
			var res := load(res_path)
			if res is PackData:
				packs.append(res as PackData)
		file_name = dir.get_next()
	dir.list_dir_end()
	return packs

func _on_back_button_pressed() -> void:
	close()
