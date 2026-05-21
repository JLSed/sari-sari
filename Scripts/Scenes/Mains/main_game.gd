extends Node2D

@onready var front_store_image: Sprite2D = $FrontStoreImage
@onready var day_night_shader: ColorRect = $DayNightShader
@onready var night_modulate: CanvasModulate = $NightModulate
@onready var night_bulb: PointLight2D = $NightBulb
@onready var container_button: TextureButton = $UI/ContainerButton
@onready var start_day_button: Button = $UI/StartDayButton
@onready var time_label: Label = $UI/TimeLabel
@onready var phone_ui_animation: AnimationPlayer = $PhoneUIAnimation
@onready var money_label: Label = $UI/MoneyLabel


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

func  _ready() -> void:
	front_store_image.texture = PlayerManager.player_progress.current_store.store_texture
	money_label.text = str(PlayerManager.player_progress.money)
	PlayerManager.money_changed.connect(_update_money_label)
	for store_section in store_sections:
		store_section.signal_clicked.connect(_on_section_pressed)
		store_section.set_container_edit_mode(container_edit_mode)
	
	StoreManager.phase_changed.connect(_on_phase_changed)
	StoreManager.enter_preparation_phase()

func _update_money_label() -> void:
	money_label.text = str(PlayerManager.player_progress.money)

func _process(delta: float) -> void:
	if !StoreManager.is_day_phase:
		return

	tick_accum += delta
	while tick_accum >= time_incrementor and current_minutes < END_TIME:
		tick_accum -= time_incrementor
		current_minutes = min(current_minutes + INCREMENT_VALUE, END_TIME)
		_update_cloat_and_lighting()

	# ---Day and Night Stuff ---
func _on_phase_changed(is_day: bool) -> void:
	start_day_button.visible = !is_day
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
