class_name ShopyApp extends PhoneApp

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var item_container: GridContainer = $ShopyBackground/HScrollBar/MarginContainer/ItemContainer

@export var ShopyItemCardUI : PackedScene
@export var forsale_goods : Array[PackData]

func _ready() -> void:
	for forsale in forsale_goods:
		var new_card : ShopyItemCard = ShopyItemCardUI.instantiate()
		item_container.add_child(new_card)
		new_card.setup(forsale)

func _on_back_button_pressed() -> void:
	close()
