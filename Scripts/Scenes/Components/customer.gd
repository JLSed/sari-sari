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
	animated_customer_sprite.flip_h = from_right
	animated_customer_sprite.play("walking")
	detector.monitoring = false

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
	tween.tween_property(self, "global_position:x", exit_x, 2.0)
	tween.tween_callback(queue_free)
