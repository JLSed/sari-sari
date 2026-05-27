extends Node2D

@onready var front_store_image: Sprite2D = $FrontStoreImage
@onready var day_night_shader: ColorRect = $DayNightShader
@onready var night_modulate: CanvasModulate = $NightModulate
@onready var night_bulb: PointLight2D = $NightBulb
@onready var container_button: TextureButton = $UI/ContainerButton
@onready var edit_packs_button: TextureButton = $UI/EditPacksButton
@onready var start_day_bg: NinePatchRect = $UI/StartDayBG
@onready var time_label: Label = $UI/TimeLabelBG/TimeLabel
@onready var phone_ui_animation: AnimationPlayer = $PhoneUIAnimation
@onready var money_label: Label = $UI/MoneyLabelBG/HBoxContainer/MoneyLabel
@onready var edit_label_container: PanelContainer = $UI/EditLabelContainer


@onready var customer_manager: Node2D = $CustomerManager
@onready var delivery_manager: Node2D = $DeliveryManManager

@onready var day_summary_ui: Control = $DaySummaryUI
@onready var day_label: Label = $DaySummaryUI/ContentContainer/MarginContainer/VBoxContainer/DayLabel
@onready var profit_label: Label = $DaySummaryUI/ContentContainer/MarginContainer/VBoxContainer/ProfitLabel
@onready var customer_served_label: Label = $DaySummaryUI/ContentContainer/MarginContainer/VBoxContainer/CustomerServedLabel


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
var pack_edit_mode : bool = false

func  _ready() -> void:
	AudioManager.play_bgm("main_game")
	front_store_image.texture = PlayerManager.player_progress.current_store.store_texture
	_update_money_label()
	PlayerManager.money_changed.connect(_update_money_label)
	StoreManager.phase_changed.connect(_on_phase_changed)
	StoreManager.entered_preparation_phase.connect(_on_preparation_phase)
	SignalBus.day_ended.connect(_on_day_ended)
	for store_section in store_sections:
		store_section.signal_clicked.connect(_on_section_pressed)
		store_section.set_container_edit_mode(container_edit_mode)
	customer_manager.initialize(
		$CustomerContainer,
		store_sections,
		$CustomerUI,
		$CustomerUI/HappyBar,
		$CustomerUI/RequestContainer/RequestLabel,
		$CustomerUI/SpeechLabel
	)
	delivery_manager.initialize($CustomerContainer, start_day_bg)
	StoreManager.enter_preparation_phase()

func _on_preparation_phase() -> void:
	if PlayerManager.has_pending_deliveres():
		delivery_manager.spawn_deliveryman()

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
		customer_manager.try_spawn_customer()
		if customer_manager.has_active_customer and customer_manager.current_customer.has_arrived:
			customer_manager.decay_customer_happiness()
	
	if current_minutes >= END_TIME and !customer_manager.has_active_customer and !StoreManager.is_day_ended:
		StoreManager.enter_end_day_phase()
	
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
		_set_edit_pack_mode(false)
	else:
		_set_edit_pack_mode(true)
		edit_label_container.visible = false

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

func _set_edit_pack_mode(enabled: bool) -> void:
	pack_edit_mode = enabled
	StoreManager.set_pack_edit_mode(enabled)
	edit_label_container.visible = enabled and StoreManager.is_day_phase

func _on_day_ended() -> void:
	var progress : PlayerProgress = PlayerManager.player_progress
	AudioManager.play_sfx("day_complete")
	day_label.text = "Day - " + str(progress.current_day) + " Complete!"
	customer_served_label.text = "Customer Served : " + str(progress.today_customer_served)
	profit_label.text = "Today's Profit : " + str(progress.today_profit)
	day_summary_ui.visible = true
	var tween : Tween = create_tween()
	tween.tween_property(day_summary_ui, "scale", Vector2.ONE, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)

func _on_next_day_button_pressed() -> void:
	var tween : Tween = create_tween()
	tween.tween_property(day_summary_ui, "scale", Vector2.ZERO, 0.3).set_ease(Tween.EASE_IN_OUT)
	PlayerManager.to_next_day()
	SignalBus.next_day_started.emit()
	StoreManager.enter_preparation_phase()

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

func _on_reject_button_pressed() -> void:
	customer_manager.reject_current_customer()

func _on_item_dropped_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("dropped_pack"):
		var dropped_pack : PackData = body.get_meta("pack_data")
		PlayerManager.add_pack_quantity(dropped_pack, 1)
		body.set_deferred("collision_layer", 0)
		var tween : Tween = create_tween()
		tween.tween_property(body, "modulate", Color(0.0, 0.0, 0.0, 0.0), 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
		tween.tween_callback(body.queue_free)
		print("dropped " + dropped_pack.item_data.item_name + " added to inventory")

func _on_edit_packs_button_pressed() -> void:
	_set_edit_pack_mode(!pack_edit_mode)
