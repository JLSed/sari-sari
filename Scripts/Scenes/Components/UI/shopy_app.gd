class_name ShopyApp extends PhoneApp

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_back_button_pressed() -> void:
	close()
