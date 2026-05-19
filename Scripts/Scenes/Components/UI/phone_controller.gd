class_name PhoneController extends Control

@export var app_scenes: Dictionary[StringName, PackedScene]
@export var current_app: PhoneApp

@onready var app_container: Control = $AppContainer

var _apps :Dictionary[StringName, PhoneApp] = {}

func _ready() -> void:
	for app_id : StringName in app_scenes.keys():
		var scene := app_scenes[app_id]
		if scene == null:
			continue
		var app : PhoneApp = scene.instantiate()
		app_container.add_child(app)
		app.visible = false
		_apps[app_id] = app
	

func _open_app(app_id: StringName) -> void:
	if current_app:
		current_app.close()
	current_app = _apps[app_id]
	current_app.open()

func _on_shopy_button_pressed() -> void:
	_open_app("Shopy")

func _on_container_shop_button_pressed() -> void:
	_open_app("ContainerShop")
