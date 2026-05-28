class_name ContainerShopItemCard extends TextureRect

@onready var container_image: TextureRect = $ContainerImage
@onready var price_label: Label = $PriceLabel
@onready var container_name: Label = $ContainerName
@onready var button_label: Label = $ButtonLabel
@onready var buy_button: Button = $BuyButton

var _current_container : GoodsContainerEntry
var _is_owned : bool = false

func setup(container: GoodsContainerEntry) -> void:
	_current_container = container
	container_name.text = container.container_name
	price_label.text = "P" + str(container.price)
	if container.container_scene:
		var inst : GoodsContainer = container.container_scene.instantiate()
		container_image.texture = inst.container_texture
		inst.queue_free()
	
	_check_owned_status()

func _check_owned_status() -> void:
	for owned: GoodsContainerEntry in PlayerManager.player_progress.owned_containers:
		if owned == _current_container or owned.container_name == _current_container.container_name:
			_mark_as_owned()
			return

func _mark_as_owned() -> void:
	_is_owned = true
	button_label.text = "OWNED"
	buy_button.disabled = true

func _on_buy_button_pressed() -> void:
	if _is_owned:
		return
	if PlayerManager.player_progress.money < _current_container.price:
		return
	PlayerManager.decrease_player_money(_current_container.price)
	PlayerManager.add_container(_current_container)
	_mark_as_owned()
