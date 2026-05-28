class_name StoreUpgradeItemCard extends TextureRect

@onready var container_image: TextureRect = $ContainerImage
@onready var price_label: Label = $PriceLabel
@onready var container_name: Label = $ContainerName
@onready var button_label: Label = $ButtonLabel
@onready var buy_button: Button = $BuyButton
@onready var ar_label: Label = $ARLabel

var _current_store: StoreStat
var _is_owned: bool = false

func setup(store: StoreStat) -> void:
	_current_store = store
	container_name.text = store.store_name
	price_label.text = "P" + str(store.price)
	ar_label.text = "AR" + str(int(store.attraction_rate * 100))
	if store.store_texture:
		container_image.texture = store.store_texture

	_refresh_button_state()

func _refresh_button_state() -> void:
	var is_current := PlayerManager.player_progress.current_store == _current_store
	_is_owned = PlayerManager.owns_store(_current_store)

	if _is_owned and is_current:
		button_label.text = "ACTIVE"
		buy_button.disabled = true
	elif _is_owned:
		button_label.text = "USE"
		buy_button.disabled = false
	else:
		button_label.text = "BUY"
		buy_button.disabled = false

func _on_buy_button_pressed() -> void:
	# Block buying during day phase
	if StoreManager.is_day_phase:
		AudioManager.play_sfx("wrong_item", 0.1, -10.0)
		return

	if _is_owned:
		# Switch to this store
		PlayerManager.switch_store(_current_store)
		return

	# Not owned — attempt purchase
	if PlayerManager.player_progress.money < _current_store.price:
		AudioManager.play_sfx("wrong_item", 0.1, -10.0)
		return

	AudioManager.play_sfx("item_buy", 0.1, -10.0)
	PlayerManager.decrease_player_money(_current_store.price)
	PlayerManager.buy_store(_current_store)
	# Auto-switch to newly purchased store
	PlayerManager.switch_store(_current_store)
