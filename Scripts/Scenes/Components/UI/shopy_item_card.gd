class_name ShopyItemCard extends TextureRect

@onready var item_image: TextureRect = $ItemImage
@onready var price_label: Label = $PriceLabel
@onready var item_name: Label = $ItemName
var _current_item : PackData
signal buy_request(item: PackData)

func setup(item: PackData) -> void:
	_current_item = item
	item_image.texture = item.item_data.item_sprite
	item_name.text = item.item_data.item_name
	price_label.text = str(item.item_data.price)

func _on_buy_button_pressed() -> void:
	if PlayerManager.player_progress.money < _current_item.item_data.price:
		return
	PlayerManager.player_progress.money -= _current_item.item_data.price
	PlayerManager.add_pack_quantity(_current_item, _current_item.buy_amount)
	PlayerManager.money_changed.emit()
