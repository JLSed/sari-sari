class_name PhoneApp extends Control

signal close_app
signal open_app(app_id: StringName)

func open()-> void:
	visible = true
	set_process(true)

func close() -> void:
	visible = false
	set_process(false)
