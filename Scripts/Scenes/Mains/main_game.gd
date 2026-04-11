extends Node2D

@onready var front_store_image: Sprite2D = $FrontStoreImage
@onready var day_night_shader: ColorRect = $DayNightShader
@onready var night_modulate: CanvasModulate = $NightModulate
@onready var night_bulb: PointLight2D = $NightBulb
@onready var light_button: Button = $Control/LightButton



@export_category("DayNight Shader Parameter")
@export var day_color : Color = Color(1.0, 1.0, 1.0, 1.0)
@export var night_color : Color = Color(0.489, 0.551, 0.844, 1.0)
@export var max_ray_weight : float = 0.07
@export var max_light_energy : float = 1.0
@export var time_of_day : float = 0.3
@export var day_speed : float = 0.05

func  _ready() -> void:
	front_store_image.texture = PlayerManager.current_store.store_texture

func _process(delta: float) -> void:
	
	
	# ---Day and Night Stuff ---
	time_of_day += day_speed * delta
	var sun_x : float = time_of_day
	var sun_y : float = 1.0 - sin(PI * time_of_day)
	if time_of_day > 1.0:
		time_of_day = 0.0
		#reset sun location
		sun_x = 0.0
		sun_y = 0.0
	# 0.0 is night, 1.0 is high noon
	var intensity_multiplier : float = sin(PI * time_of_day)
	intensity_multiplier = clamp(intensity_multiplier, 0.0, 1.0)
	var current_weight : float = max_ray_weight * intensity_multiplier
	day_night_shader.material.set_shader_parameter("light_position", Vector2(sun_x, sun_y))
	day_night_shader.material.set_shader_parameter("weight", current_weight)
	night_modulate.color = night_color.lerp(day_color, intensity_multiplier)
	#light bulb at night
	var darkness_level : float = 1.0 - intensity_multiplier
	night_bulb.energy = max_light_energy * darkness_level


func _on_light_button_pressed() -> void:
	night_bulb.visible = !night_bulb.visible
	if night_bulb.visible == true:
		light_button.text = "Light Off"
	else:
		light_button.text = "Light On"
