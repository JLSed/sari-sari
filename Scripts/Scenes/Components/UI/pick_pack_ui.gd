class_name PickGoodsUI extends Control

@export var PackItemUI : PackedScene
@onready var item_container: HBoxContainer = $ItemContainer

signal pack_item_placed(pack : PackData)

func catalog_setup(container_id : int) -> void:
	for pack_entry : PurchasedPackEntry in PlayerManager.player_progress.purchased_goods:
		if  container_id in pack_entry.pack_data.allowed_container:
			var new_pack_ui : GoodsUI = PackItemUI.instantiate()
			item_container.add_child(new_pack_ui)
			new_pack_ui.setup(pack_entry)
			new_pack_ui.place_button_clicked.connect(_on_place_button_clicked)

func _on_place_button_clicked(pack : PurchasedPackEntry) -> void:
	self.queue_free()
	pack_item_placed.emit(pack)


func _on_close_button_pressed() -> void:
	self.queue_free()
