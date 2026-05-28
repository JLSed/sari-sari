extends Node2D

signal phase_changed(is_day_phase: bool)
signal entered_preparation_phase
signal entered_day_phase
signal pack_edit_mode_changed(enabled: bool)

var is_day_phase: bool = false
var is_day_ended: bool = false
var pack_edit_mode: bool = false
var _speech_font : Font

func _ready() -> void:
	_speech_font = load("res://Assets/Fonts/monogram-extended.ttf")

func enter_preparation_phase() -> void:
	is_day_phase = false
	is_day_ended = false
	phase_changed.emit(is_day_phase)
	entered_preparation_phase.emit()

func enter_day_phase() -> void:
	is_day_phase = true
	phase_changed.emit(is_day_phase)
	entered_day_phase.emit()

func enter_end_day_phase() -> void:
	is_day_phase = false
	is_day_ended = true
	SignalBus.day_ended.emit()

func set_pack_edit_mode(enabled: bool) -> void:
	pack_edit_mode = enabled
	pack_edit_mode_changed.emit(enabled)

func get_store_attraction_rate() -> float:
	if !PlayerManager.player_progress:
		print("Player Progress is missing")
		return 0.0
	return PlayerManager.player_progress.current_store.attraction_rate

func spawn_speech_label(text: String, duration: float = 1.0) -> void:
	var viewport_size := get_viewport_rect().size
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _speech_font)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(viewport_size.x / 2, viewport_size.y / 2)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.pivot_offset = label.size / 2
	label.modulate.a = 0.0
	get_tree().root.add_child(label)
	var drift_offset := Vector2(randf_range(-40.0, 40.0), randf_range(-30.0, -10.0))
	var target_pos := label.position + drift_offset
	var target_rotation := randf_range(deg_to_rad(-15.0), deg_to_rad(15.0))
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	tween.tween_property(label, "position", target_pos, duration + 0.65).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "rotation", target_rotation, duration + 0.65).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(duration)
	tween.chain().tween_callback(label.queue_free)

func spawn_remainder(text: String) -> void:
	var remainder_scene : PackedScene = preload("res://Scenes/Components/UI/remainder.tscn")
	var main_game := get_tree().get_first_node_in_group("main_game_scene")
	if main_game == null:
		print("spawning remainder label: main game not found")
		return
	var remainder_container : Control = main_game.get_node("RemainderUI/MarginContainer/VBoxContainer")
	if remainder_container == null:
		print("spawning remainder label: remainder container not found")
		return
	var remainder_inst : Remainder = remainder_scene.instantiate()
	remainder_container.add_child(remainder_inst)
	remainder_inst.setup(text)
