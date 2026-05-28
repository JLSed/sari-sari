class_name Remainder extends PanelContainer

@onready var rich_text_label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	pivot_offset = size / 2
	scale = Vector2.ZERO
	_pop_in()
	

func setup(text: String) -> void:
	rich_text_label.text = text

func _pop_in() -> void :
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(1.0)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)
