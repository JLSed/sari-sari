class_name StoreUpgrade extends PhoneApp

@onready var containers_container: GridContainer = $HScrollBar/MarginContainer/ContainersContainer

@export var StoreUpgradeItemCardUI: PackedScene

const STORE_FOLDER := "res://Assets/Resources/Store/"

var _cards: Array[StoreUpgradeItemCard] = []

func _ready() -> void:
	var stores := _load_all_stores()
	for store in stores:
		var new_card: StoreUpgradeItemCard = StoreUpgradeItemCardUI.instantiate()
		containers_container.add_child(new_card)
		new_card.setup(store)
		_cards.append(new_card)

	PlayerManager.store_switched.connect(_on_store_switched)

func _load_all_stores() -> Array[StoreStat]:
	var stores: Array[StoreStat] = []
	var dir := DirAccess.open(STORE_FOLDER)
	if dir == null:
		print("no directory")
		return stores
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
			var res_path := STORE_FOLDER + file_name.replace(".remap", "")
			var res := load(res_path)
			if res is StoreStat:
				stores.append(res as StoreStat)
		file_name = dir.get_next()
	dir.list_dir_end()
	return stores

func _on_store_switched() -> void:
	for card in _cards:
		card._refresh_button_state()

func _on_back_button_pressed() -> void:
	close()
