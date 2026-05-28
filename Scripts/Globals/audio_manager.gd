extends Node

var _bgm_player_a:AudioStreamPlayer
var _bgm_player_b:AudioStreamPlayer
var _active_bgm : AudioStreamPlayer
var _inavtive_bgm : AudioStreamPlayer

const SFX_POOL_SIZE : int = 8
var _sfx_pool: Array[AudioStreamPlayer] = []

var bgm_volume_db: float = -10.0:
	set(value):
		bgm_volume_db = value
		_active_bgm.volume_db = value
		_inavtive_bgm.volume_db = value
		

var sfx_volume_db: float = 0.0

@export var crossfade_duration :float = 0.5

var bgm_tracks: Dictionary = {}
var sfx_sounds : Dictionary = {}
var voice_sounds : Dictionary = {}

func _ready() -> void:

	_setup_bgm_players()
	_setup_sfx_pool()
	_preload_audio()
	bgm_volume_db = PlayerManager.player_progress.bgm_volume
	sfx_volume_db = PlayerManager.player_progress.sgx_volume

func _setup_bgm_players() -> void:
	_bgm_player_a = AudioStreamPlayer.new()
	_bgm_player_a.bus = "BGM"
	_bgm_player_a.volume_db = bgm_volume_db
	
	_bgm_player_b = AudioStreamPlayer.new()
	_bgm_player_b.bus = "BGM"
	_bgm_player_b.volume_db = bgm_volume_db
	add_child(_bgm_player_b)
	
	_active_bgm = _bgm_player_a
	_inavtive_bgm = _bgm_player_b
	

func _setup_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)
		

func _preload_audio() -> void:
	bgm_tracks["main_game"] = preload("res://Assets/Audio/BGM/Interior Birdecorator Decorate.ogg")
	bgm_tracks["starting_screen"] = preload("res://Assets/Audio/BGM/VGMA Challenge 29.ogg")

	sfx_sounds["customer_happy_sfx"] = preload("res://Assets/Audio/SFX/customer_happy.mp3")
	sfx_sounds["customer_angry_sfx"] = preload("res://Assets/Audio/SFX/Retro Event Wrong Echo 03.wav")
	sfx_sounds["play_button"] = preload("res://Assets/Audio/SFX/play_button.mp3")
	sfx_sounds["button_click"] = preload("res://Assets/Audio/SFX/button_click.mp3")
	sfx_sounds["item_buy"] = preload("res://Assets/Audio/SFX/item_buy.mp3")
	sfx_sounds["npc_walking"] = preload("res://Assets/Audio/SFX/FOOTSTEPS (A) Walking Loop 01.ogg")
	sfx_sounds["day_complete"] = preload("res://Assets/Audio/SFX/day_complete.wav")
	sfx_sounds["correct_item"] = preload("res://Assets/Audio/SFX/Retro Blop StereoUP 09.wav")
	sfx_sounds["click"] = preload("res://Assets/Audio/SFX/wrong_item.mp3")
	sfx_sounds["wrong_item"] = preload("res://Assets/Audio/SFX/Retro Event Wrong Simple 03.wav")
	sfx_sounds["item_added"] = preload("res://Assets/Audio/SFX/button_click.mp3")

	voice_sounds["jastin1_lalaki"] = preload("res://Assets/Audio/Voices/jastin1-lalaki.ogg")
	voice_sounds["kim1_ea"] = preload("res://Assets/Audio/Voices/kim1-ea.ogg")
	voice_sounds["kim2_ea"] = preload("res://Assets/Audio/Voices/kim2-ea.ogg")
	voice_sounds["rafael1_lalaki"] = preload("res://Assets/Audio/Voices/rafael1-lalaki.ogg")
	voice_sounds["romer1_ea"] = preload("res://Assets/Audio/Voices/romer1-ea.ogg")
	voice_sounds["romer2_lalaki"] = preload("res://Assets/Audio/Voices/romer2-lalaki.ogg")
	voice_sounds["romer3_lalaki"] = preload("res://Assets/Audio/Voices/romer3-lalaki.ogg")
	voice_sounds["sed1_lalaki"] = preload("res://Assets/Audio/Voices/sed1-lalaki.ogg")
	voice_sounds["sed2_lalaki"] = preload("res://Assets/Audio/Voices/sed2-lalaki.ogg")
	voice_sounds["deliveryman1"] = preload("res://Assets/Audio/Voices/deliveryman1.ogg")

func play_bgm(track_key : String) -> void:
	if not bgm_tracks.has(track_key):
		print("audio not found")
		return
	var stream : AudioStream = bgm_tracks[track_key]
	
	#dont restart if the same track
	if _active_bgm.stream == stream and _active_bgm.playing:
		return
	
	#swap active and inactive
	var temp := _active_bgm
	_active_bgm = _inavtive_bgm
	_inavtive_bgm = temp

	_active_bgm.stream = stream
	_active_bgm.volume_db = -80.0
	_active_bgm.play()
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_active_bgm, "volume_db", bgm_volume_db, crossfade_duration)
	tween.tween_property(_inavtive_bgm, "volume_db", -80.0, crossfade_duration)
	tween.chain().tween_callback(_inavtive_bgm.stop)
	
func stop_bgm(fade_duration : float = 1.0) -> void:
	var tween := create_tween()
	tween.tween_property(_active_bgm,"volume_db",-80.0, fade_duration)
	tween.tween_callback(_active_bgm.stop)

func play_sfx(sfx_key:String, pitch_range: float = 0.2, volume_offset_db : float = 0.0) -> void:
	if not sfx_sounds.has(sfx_key):
		print("audio not found")
		return
	var player : AudioStreamPlayer = _get_available_sfx_player()
	if player == null:
		print("STOP! SFX poll maxxed out")
		return
	player.stream = sfx_sounds[sfx_key]
	player.volume_db = sfx_volume_db + volume_offset_db
	player.pitch_scale = 1.0 + randf_range(-pitch_range, pitch_range)
	player.play()

func play_voice(voice_key: String, volume_offset_db: float = 0.0) -> void:
	if not voice_sounds.has(voice_key):
		print("voice not found: ", voice_key)
		return
	var player : AudioStreamPlayer = _get_available_sfx_player()
	if player == null:
		print("STOP! SFX pool maxxed out")
		return
	player.stream = voice_sounds[voice_key]
	player.volume_db = sfx_volume_db + volume_offset_db
	player.pitch_scale = 1.0
	player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player : AudioStreamPlayer in _sfx_pool:
		if not player.playing:
			return player
	return null
