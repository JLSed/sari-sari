class_name Customer extends Node2D
@onready var animated_customer_sprite: AnimatedSprite2D = $AnimatedCustomerSprite
@onready var detector: Area2D = $Detector


@export var customer_data : CustomerData
@export var walking_speed := 40.0

var happiness := 100
var has_arrived := false
var from_right := false
var requested_items : Array[PackData] = []
var is_leaving := false
# the final stop of the customer
var center_x := 151.0


func _ready() -> void:
	happiness = customer_data.starting_happy_meter
	_apply_customer_sprite()
	animated_customer_sprite.flip_h = from_right
	animated_customer_sprite.play("walking")
	detector.monitoring = false

func _apply_customer_sprite() -> void:

	var sprite_sheet : Texture2D = customer_data.customer_sprite
	var columns : int = 2  # two 64x64 frames side by side
	var rows : int = 1
	var frame_width : int = sprite_sheet.get_width() / columns
	var frame_height : int = sprite_sheet.get_height() / rows
	var new_sprite_frames : SpriteFrames = SpriteFrames.new()
	new_sprite_frames.remove_animation(&"default")
	new_sprite_frames.add_animation(&"idle")
	new_sprite_frames.set_animation_loop(&"idle", true)
	new_sprite_frames.set_animation_speed(&"idle", 3.0)
	var idle_frame : AtlasTexture = AtlasTexture.new()
	idle_frame.atlas = sprite_sheet
	idle_frame.region = Rect2(0, 0, frame_width, frame_height)
	new_sprite_frames.add_frame(&"idle", idle_frame)
	new_sprite_frames.add_animation(&"walking")
	new_sprite_frames.set_animation_loop(&"walking", true)
	new_sprite_frames.set_animation_speed(&"walking", 3.0)
	for y in range(rows):
		for x in range(columns):
			var frame_texture : AtlasTexture = AtlasTexture.new()
			frame_texture.atlas = sprite_sheet
			frame_texture.region = Rect2(x * frame_width, y * frame_height, frame_width, frame_height)
			new_sprite_frames.add_frame(&"walking", frame_texture)
	animated_customer_sprite.sprite_frames = new_sprite_frames

func _process(delta: float) -> void:
	if has_arrived or is_leaving:
		return
	var direction : float = sign(center_x - global_position.x)
	global_position.x += direction * walking_speed * delta
	
	if absf(global_position.x - center_x) <= 2.0:
		global_position.x = center_x
		_arrived()
	

func _arrived() -> void:
	has_arrived = true
	animated_customer_sprite.play("idle")
	detector.monitoring = true
	SignalBus.customer_arrived.emit()

func leave() -> void:
	if is_leaving:
		return
	is_leaving = true
	detector.set_deferred("monitoring", false)
	animated_customer_sprite.play("walking")
	#customer will walk to where they came from
	animated_customer_sprite.flip_h = !from_right
	
	var exit_x : float = -50 if !from_right else 350.0
	var tween : Tween = create_tween()
	tween.tween_property(self, "global_position:x", exit_x, randf_range(1.0, 2.0))
	tween.tween_callback(queue_free)
