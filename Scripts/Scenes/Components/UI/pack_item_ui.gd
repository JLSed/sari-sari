class_name GoodsUI extends NinePatchRect

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@export var current_entry : PurchasedPackEntry

signal place_button_clicked(pack : PackData)

func setup(pack_entry: PurchasedPackEntry) -> void:
	current_entry = pack_entry
	texture_rect.texture = pack_entry.pack_data.item_data.item_sprite
	label.text = "%s x%d" % [pack_entry.pack_data.item_data.item_name, pack_entry.quantity]

func _on_button_pressed() -> void:
	place_button_clicked.emit(current_entry)
