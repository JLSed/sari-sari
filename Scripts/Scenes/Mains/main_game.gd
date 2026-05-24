extends Node2D

@onready var front_store_image: Sprite2D = $FrontStoreImage
@onready var day_night_shader: ColorRect = $DayNightShader
@onready var night_modulate: CanvasModulate = $NightModulate
@onready var night_bulb: PointLight2D = $NightBulb
@onready var container_button: TextureButton = $UI/ContainerButton
@onready var start_day_bg: NinePatchRect = $UI/StartDayBG
@onready var time_label: Label = $UI/TimeLabelBG/TimeLabel
@onready var phone_ui_animation: AnimationPlayer = $PhoneUIAnimation
@onready var money_label: Label = $UI/MoneyLabelBG/HBoxContainer/MoneyLabel

@onready var customer_ui: Control = $CustomerUI
@onready var happy_bar: ProgressBar = $CustomerUI/HappyBar
@onready var reject_button: Button = $CustomerUI/RejectButton
@onready var request_label: RichTextLabel = $CustomerUI/RequestContainer/RequestLabel
@onready var customer_container: Node2D = $CustomerContainer
@onready var speech_label: Label = $CustomerUI/SpeechLabel

@export_category("Store Section")
@export var store_sections : Array[StoreSection]
@export_category("Day Phase Parameter")
@export var time_incrementor : float = 30.0 #in seconds
@export var current_minutes : int = START_TIME
var START_TIME : int = 6*60 #6:00
var END_TIME : int = 23*60 #23:00
@export var INCREMENT_VALUE : int = 10
@export var tick_accum : float = 0.0
@export_category("DayNight Shader Parameter")
@export var day_color : Color = Color(1.0, 1.0, 1.0, 1.0)
@export var night_color : Color = Color(0.489, 0.551, 0.844, 1.0)
@export var max_ray_weight : float = 0.07
@export var max_light_energy : float = 1.0
@export var time_of_day : float = 0.3
@export var day_speed : float = 0.05
var container_edit_mode : bool = false
@export_category("Spawning Customer Parameter")
@export var customer_scene : PackedScene
@export var customer_data_pool : Array[CustomerData] = []
@export var has_active_customer : bool = false
@export var current_customer : Customer
@export var customer_requested_items : Array[PackData] = []
@export var current_happiness : int = 100
var chosen_customer_data : CustomerData

func  _ready() -> void:
	front_store_image.texture = PlayerManager.player_progress.current_store.store_texture
	_update_money_label()
	PlayerManager.money_changed.connect(_update_money_label)
	StoreManager.phase_changed.connect(_on_phase_changed)
	SignalBus.customer_arrived.connect(_on_customer_arrived)
	for store_section in store_sections:
		store_section.signal_clicked.connect(_on_section_pressed)
		store_section.set_container_edit_mode(container_edit_mode)
	
	StoreManager.enter_preparation_phase()

func _update_money_label() -> void:
	money_label.text = "₱"+ PlayerManager.update_money_ui()

func _process(delta: float) -> void:
	if !StoreManager.is_day_phase:
		return

	tick_accum += delta
	while tick_accum >= time_incrementor and current_minutes < END_TIME:
		tick_accum -= time_incrementor
		current_minutes = min(current_minutes + INCREMENT_VALUE, END_TIME)
		_update_cloat_and_lighting()
		_try_spawn_customer()
		if has_active_customer and current_customer.has_arrived:
			_decay_customer_happiness()

	# ---Day and Night Stuff ---
func _on_phase_changed(is_day: bool) -> void:
	start_day_bg.visible = !is_day
	container_button.visible = !is_day
	current_minutes = START_TIME
	tick_accum = 0.0
	_update_cloat_and_lighting()
	if is_day:
		container_edit_mode = false
		for section in store_sections:
			section.set_container_edit_mode(false)

func _update_cloat_and_lighting() -> void:
	var hours := current_minutes / 60
	var minutes := current_minutes % 60
	time_label.text = "%02d:%02d" % [hours, minutes]
	
	var t := float(current_minutes) / 1440.0
	var sun_x := t
	var sun_y := 1.0 - sin(PI * t)
	
	# 0.0 is night, 1.0 is high noon
	var intensity_multiplier : float = clamp(sin(PI * t), 0.0, 1.0)
	var current_weight : float = max_ray_weight * intensity_multiplier
	day_night_shader.material.set_shader_parameter("light_position", Vector2(sun_x, sun_y))
	day_night_shader.material.set_shader_parameter("weight", current_weight)
	night_modulate.color = night_color.lerp(day_color, intensity_multiplier)
	#light bulb at night
	night_bulb.energy = max_light_energy * (1.0 - intensity_multiplier)

func _try_spawn_customer() -> void:
	if has_active_customer:
		return
	if customer_data_pool.is_empty():
		print("No Customer to spawn")
		return
	var attraction_rate := StoreManager.get_store_attraction_rate()
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

func _decay_customer_happiness() -> void:
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
	
func _on_reject_button_pressed() -> void:
	var line : String = chosen_customer_data.angry_lines.pick_random()
	speech_label.text = line
	speech_label.visible = true
	current_customer.leave()
	await get_tree().create_timer(1.5).timeout
	_cleanup_customer()
	SignalBus.customer_left.emit()

func _on_section_pressed(section_type: Enums.SectionType) -> void:
	print("this is called", section_type)

func _on_container_button_pressed() -> void:
	container_edit_mode = !container_edit_mode
	for store_section in store_sections:
		store_section.set_container_edit_mode(container_edit_mode)

func _on_start_day_button_pressed() -> void:
	StoreManager.enter_day_phase()

func _on_light_button_toggled(toggled_on: bool) -> void:
	night_bulb.visible = toggled_on

func _on_phone_button_pressed() -> void:
	phone_ui_animation.play("opening_phone")

func _on_background_pressed() -> void:
	phone_ui_animation.play("closing_phone")

func _on_item_dropped_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("dropped_pack"):
		var dropped_pack : PackData = body.get_meta("pack_data")
		PlayerManager.add_pack_quantity(dropped_pack, 1)
		body.set_deferred("collision_layer", 0)
		var tween : Tween = create_tween()
		tween.tween_property(body, "modulate", Color(0.0, 0.0, 0.0, 0.0), 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
		tween.tween_callback(body.queue_free)
		print("dropped " + dropped_pack.item_data.item_name + " added to inventory")
