extends Node2D

signal phase_changed(is_day_phase: bool)
signal entered_preparation_phase
signal entered_day_phase

var is_day_phase: bool = false

func enter_preparation_phase() -> void:
	is_day_phase = false
	phase_changed.emit(is_day_phase)
	entered_preparation_phase.emit()

func enter_day_phase() -> void:
	is_day_phase = true
	phase_changed.emit(is_day_phase)
	entered_day_phase.emit()

func get_store_attraction_rate() -> float:
	if !PlayerManager.player_progress:
		print("Player Progress is missing")
		return 0.0
	return PlayerManager.player_progress.current_store.attraction_rate
