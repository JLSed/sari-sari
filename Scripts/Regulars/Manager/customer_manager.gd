extends Node2D

@export_category("Customer Spawning")
@export var customer_scene : PackedScene
@export var customer_data_pool : Array[CustomerData] = []
@export var has_active_customer : bool = false
@export var current_customer : Customer
@export var customer_requested_items : Array[PackData] = []
@export var current_happiness : int = 100
var chosen_customer_data : CustomerData

# UI references (set via initialize)
var customer_ui : Control
var happy_bar : ProgressBar
var request_label : RichTextLabel
var speech_label : Label
var customer_container : Node2D
var store_sections : Array[StoreSection]

func initialize(
	p_customer_container: Node2D,
	p_store_sections: Array[StoreSection],
	p_customer_ui: Control,
	p_happy_bar: ProgressBar,
	p_request_label: RichTextLabel,
	p_speech_label: Label
) -> void:
	customer_container = p_customer_container
	store_sections = p_store_sections
	customer_ui = p_customer_ui
	happy_bar = p_happy_bar
	request_label = p_request_label
	speech_label = p_speech_label
	SignalBus.customer_arrived.connect(_on_customer_arrived)

func try_spawn_customer() -> void:
	if has_active_customer:
		return
	if customer_data_pool.is_empty():
		print("No Customer to spawn")
		return
	var attraction_rate := StoreManager.get_store_attraction_rate()
	#var attraction_rate := 0.0
	#var attraction_rate := 1.0
	var roll := randf()
	if roll <= attraction_rate:
		_spawn_customer()

func _spawn_customer() -> void:
	has_active_customer = true
	chosen_customer_data = customer_data_pool.pick_random()
	var viewport_x := get_viewport_rect().size.x
	current_customer = customer_scene.instantiate()
	current_customer.customer_data = chosen_customer_data
	current_customer.center_x = viewport_x / 2
	var spawn_from_right : bool = randi() % 2 == 0
	if spawn_from_right:
		current_customer.global_position = Vector2(viewport_x + 35,0)
		current_customer.from_right = true
	customer_container.add_child(current_customer)
	current_customer.detector.body_entered.connect(_on_item_body_entered)
	current_happiness = chosen_customer_data.starting_happy_meter
	SignalBus.customer_spawned.emit()

func _on_customer_arrived() -> void:
	_generate_request()
	customer_ui.visible = true
	happy_bar.max_value = chosen_customer_data.starting_happy_meter
	happy_bar.value = current_happiness
	speech_label.visible = false
	_update_request_label()

func _on_item_body_entered(body: RigidBody2D) -> void:
	if !body.is_in_group("dropped_pack"):
		print("not pack")
	var dropped_pack : PackData = body.get_meta("pack_data")
	var dropped_item : ItemData = body.get_meta("item_data")
	var matched : PackData = _find_matching_request(dropped_pack, dropped_item)
	if matched != null:
		customer_requested_items.erase(matched)
		PlayerManager.increase_player_money(dropped_item.sell_price)
		body.set_deferred("freeze", true)
		body.set_deferred("collision_layer", 0)
		var tween : Tween = create_tween()
		tween.tween_property(body, "scale", Vector2.ZERO, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_callback(body.queue_free)
		_update_request_label()
		
		if customer_requested_items.is_empty():
			_customer_leave_happy()
	else:
		#if item dropped is wrong, decrease customer happiness and return to player's inventory
		current_happiness -= chosen_customer_data.wrong_item_penalty
		current_happiness = maxi(current_happiness, 0)
		happy_bar.value = current_happiness
		var tween : Tween = create_tween()
		tween.tween_property(body, "scale", Vector2.ZERO, 2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_callback(body.queue_free)
		if current_happiness <= 0:
			_customer_leave_angry()

func _find_matching_request(pack: PackData, item: ItemData) -> PackData:
	for i in range(customer_requested_items.size()):
		var req : PackData = customer_requested_items[i]
		if req.item_data == item:
			return req
		if req.item_data != null and item != null:
			if req.item_data.item_name == item.item_name:
				return req
	return null

func _generate_request() -> void:
	var count : int = randi_range(chosen_customer_data.min_request_count, chosen_customer_data.max_request_count)
	var source_pool : Array[PackData] = _get_available_items()
	customer_requested_items = []
	for i in range(count):
		var picked : PackData = source_pool.pick_random()
		customer_requested_items.append(picked)

func decay_customer_happiness() -> void:
	current_happiness -= chosen_customer_data.happiness_decay_per_tick
	current_happiness = maxi(current_happiness, 0)
	happy_bar.value = current_happiness
	
	if current_happiness <= 0:
		_customer_leave_angry()

func _customer_leave_angry() -> void:
	var line : String = chosen_customer_data.angry_lines.pick_random()
	speech_label.text = line
	speech_label.visible = true
	current_customer.leave()
	await get_tree().create_timer(1.5).timeout
	_cleanup_customer()
	SignalBus.customer_left.emit()

func _customer_leave_happy() -> void:
	PlayerManager.record_customer_served()
	speech_label.text = "Thank You!"
	speech_label.visible = true
	current_customer.leave()
	await get_tree().create_timer(1.5).timeout
	_cleanup_customer()
	SignalBus.customer_left.emit()

func _get_available_items() -> Array[PackData]:
	if !chosen_customer_data.can_buy_all_packs:
		return chosen_customer_data.allowed_packs
	#gets existing packs from containers for customers that can buy all packs
	var items: Array[PackData] = []
	for section : StoreSection in store_sections:
		for child : Node in section.get_children():
			if child is GoodsContainer:
				var container : GoodsContainer = child as GoodsContainer
				for slot : GoodsContainerSlot in container.pack_per_slot:
					if slot.current_pack != null and slot.current_pack.current_stack > 0:
						var already_added := false
						for existing : PackData in items:
							if existing.item_data != null and slot.current_pack.item_data != null:
								if existing.item_data.item_name == slot.current_pack.item_data.item_name:
									already_added = true
									break
						if !already_added:
							items.append(slot.current_pack)
	return items

func _cleanup_customer() -> void:
	current_customer = null
	has_active_customer = false
	chosen_customer_data = null
	customer_requested_items = []
	current_happiness = 100
	customer_ui.visible = false

func _update_request_label() -> void:
	if customer_requested_items.is_empty():
		print("No request")
		return
	var names : Array[String] = []
	for pack : PackData in customer_requested_items:
		if pack.item_data != null:
			names.append(pack.item_data.item_name)
	request_label.text = "I need " + ", ".join(names)

func reject_current_customer() -> void:
	var line : String = chosen_customer_data.angry_lines.pick_random()
	speech_label.text = line
	speech_label.visible = true
	current_customer.leave()
	await get_tree().create_timer(1.5).timeout
	_cleanup_customer()
	SignalBus.customer_left.emit()
