extends Node2D

@export_category("Delivery Parameter")
@export var deliveryman_scene : PackedScene
var delivery_man : Deliveryman = null
var is_delivering : bool = false

# References (set via initialize)
var customer_container : Node2D
var start_day_bg : NinePatchRect

func initialize(p_customer_container: Node2D, p_start_day_bg: NinePatchRect) -> void:
	customer_container = p_customer_container
	start_day_bg = p_start_day_bg
	SignalBus.delivery_arrived.connect(_on_deliveryman_arrived)

func spawn_deliveryman() -> void:
	is_delivering = true
	start_day_bg.visible = false
	var viewport_x := get_viewport_rect().size.x
	delivery_man = deliveryman_scene.instantiate()
	delivery_man.center_x = viewport_x / 2
	delivery_man.global_position = Vector2(-35, 0)
	customer_container.add_child(delivery_man)

func _on_deliveryman_arrived() -> void:
	await PlayerManager.spawn_pending_delivery_packs()
	StoreManager.spawn_speech_label("Bili po kayo ule!")
	PlayerManager.money_changed.emit()
	await get_tree().create_timer(1.0).timeout
	if delivery_man != null:
		delivery_man.leave()
	await get_tree().create_timer(2.0).timeout
	delivery_man = null
	is_delivering = false
	start_day_bg.visible = true
