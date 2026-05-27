class_name GoodsContainer extends Node2D

@export var container_texture : Texture2D
@export var PickPackUI : PackedScene
@export var remove_button_ui : PackedScene
@export var pack_per_slot : Array[GoodsContainerSlot]
@export var pack_sprites : Array[AnimatedSprite2D]
@export var slot_buttons : Array[BaseButton]
@onready var container_sprite: Sprite2D = $ContainerSprite

var current_index: int = -1
var pack_edit_mode : bool = false
var _active_remove_slot : int = -1
var _active_remove_ui : Node = null

func _ready() -> void:
	container_sprite.texture = container_texture
	for i in range(slot_buttons.size()):
		# make sure the current pack is unique
		pack_per_slot[i].resource_local_to_scene = true
		slot_buttons[i].pressed.connect(_on_slot_button_pressed.bind(i))
	StoreManager.phase_changed.connect(_on_phase_changed)
	#pick up the current pack_edit_mode state when this container is created
	pack_edit_mode = StoreManager.pack_edit_mode
	StoreManager.pack_edit_mode_changed.connect(_on_pack_edit_mode_changed)

func _on_pack_edit_mode_changed(enabled: bool) -> void:
	pack_edit_mode = enabled
	_dismiss_remove_ui()
	_refresh_slot_buttons_for_phase(StoreManager.is_day_phase)


func _on_phase_changed(is_day: bool) -> void:
	_refresh_slot_buttons_for_phase(is_day)

func _refresh_slot_buttons_for_phase(is_day: bool) -> void:
	for i in range(slot_buttons.size()):
		var has_pack:= pack_per_slot[i].current_pack != null
		var has_stack := has_pack and pack_per_slot[i].current_pack.current_stack > 0
		slot_buttons[i].visible = !is_day or has_pack or has_stack or pack_edit_mode
		if has_pack and !has_stack and pack_edit_mode:
			slot_buttons[i].get_child(0).show()
		elif has_pack and !has_stack:
			slot_buttons[i].get_child(0).hide()
			

func _on_slot_button_pressed(slot_index : int) -> void:
	current_index = slot_index
	
	var slot : GoodsContainerSlot = pack_per_slot[current_index]
	var has_pack:= slot.current_pack != null
	var has_stack := has_pack and slot.current_pack.current_stack > 0
	
	if pack_edit_mode:
		if has_pack and has_stack:
			_show_remove_ui(slot_index)
		else:
			if has_pack and !has_stack:
				slot.current_pack = null
				pack_sprites[slot_index].sprite_frames = SpriteFrames.new()
				slot_buttons[slot_index].get_child(0).show()
			showPickPackUI()
		return
	
	#for preparation phase
	if !StoreManager.is_day_phase:
		showPickPackUI()
		return
	
	#for day phase
	var pack : PackData = slot.current_pack
	if pack == null:
		showPickPackUI()
	else:
		if pack.current_stack > 0:
			pack.current_stack -= 1
			updatePackSpriteFrame(current_index, pack)
			var goods_body : RigidBody2D = pack.item_data.item_body.instantiate()
			var main_game : Node = get_tree().get_first_node_in_group("main_game_scene")
			main_game.add_child(goods_body)
			goods_body.global_position = Vector2(get_viewport_rect().size.x / 2.0, 0)
			goods_body.rotation_degrees = randf_range(0.0, 360.0)
			goods_body.get_child(0).texture = pack.item_data.item_sprite
			goods_body.set_meta("pack_data", pack)
			goods_body.set_meta("item_data", pack.item_data)
			goods_body.add_to_group("dropped_pack")

func showPickPackUI() -> void:
	var allowed_pack : int = pack_per_slot[current_index].container_id
	var new_pickPackUI : PickGoodsUI = PickPackUI.instantiate()
	var main_game : Node = get_tree().get_first_node_in_group("main_game_scene")
	main_game.add_child(new_pickPackUI)
	new_pickPackUI.catalog_setup(allowed_pack)
	new_pickPackUI.pack_item_placed.connect(_pack_placed)

func _pack_placed(pack_entry : PurchasedPackEntry) -> void:
	#allows placing packs in day phase only if edit mode is on
	if StoreManager.is_day_phase and !pack_edit_mode:
		return
	if current_index == -1:
		return
	var slot: GoodsContainerSlot = pack_per_slot[current_index]
	var selected_pack: PackData = pack_entry.pack_data
	
	if slot.current_pack != null and PlayerManager.is_same_pack(slot.current_pack, selected_pack):
		var free_space: int = maxi(slot.current_pack.max_stack - slot.current_pack.current_stack, 0)
		var moved_same_pack: int = mini(free_space, pack_entry.quantity)
		slot.current_pack.current_stack += moved_same_pack
		pack_entry.quantity -= moved_same_pack
		if moved_same_pack > 0:
			updatePackSpriteFrame(current_index, slot.current_pack)
		return
		
	if slot.current_pack != null and slot.current_pack.current_stack > 0:
		PlayerManager.add_pack_quantity(slot.current_pack, slot.current_pack.current_stack)
	var moved_to_slot: int = mini(selected_pack.max_stack, pack_entry.quantity)
	if moved_to_slot <= 0:
		return
	
	pack_entry.quantity -= moved_to_slot
	
	var placed_pack : PackData = selected_pack.duplicate(true)
	placed_pack.current_stack = moved_to_slot
	slot.current_pack = placed_pack
	
	setupGoodsSprite(placed_pack.pack_sprite_by_container[slot.container_id], current_index)
	updatePackSpriteFrame(current_index, placed_pack)
	

func setupGoodsSprite(sprite_data : PackSpriteData, sprite_index : int) -> void:
	var sprite_sheet : Texture2D = sprite_data.sprite_sheet
	var rows : int  = sprite_data.sheet_rows
	var columns : int = sprite_data.sheet_columns
	var new_sprite_frames : SpriteFrames = SpriteFrames.new()
	new_sprite_frames.set_animation_speed("default", 8.0)
	var frame_width : int = sprite_sheet.get_width() / columns
	var frame_height : int = sprite_sheet.get_height() / rows
	for y in range(rows):
		for x in range(columns):
			var frame_texture : AtlasTexture = AtlasTexture.new()
			frame_texture.atlas = sprite_sheet
			frame_texture.region = Rect2(x * frame_width, y * frame_height, frame_width, frame_height)
			new_sprite_frames.add_frame("default", frame_texture)
	pack_sprites[sprite_index].sprite_frames = new_sprite_frames
	slot_buttons[sprite_index].get_child(0).hide()
	

func updatePackSpriteFrame(slot_index : int, pack: PackData) -> void :
	var sprite : AnimatedSprite2D = pack_sprites[slot_index]
	var total_frames : int = sprite.sprite_frames.get_frame_count("default")
	var max_frame_index : int = total_frames - 1
	var empty_ratio : float = 1.0 - (float(pack.current_stack) / float(pack.max_stack))
	var target_frame : int =  roundi(empty_ratio * max_frame_index)
	sprite.frame = clampi(target_frame, 0, max_frame_index)

func _eject_slot(slot_index : int ) -> void:
	var main_game : Node = get_tree().get_first_node_in_group("main_game_scene")
	if main_game == null:
		print("main game not found")
		return
	var slot : GoodsContainerSlot = pack_per_slot[slot_index]
	var pack : PackData = slot.current_pack
	if pack == null or pack.current_stack <= 0:
		return
	while pack.current_stack > 0:
		pack.current_stack -= 1
		var goods_body : RigidBody2D = pack.item_data.item_body.instantiate()
		main_game.add_child(goods_body)
		goods_body.global_position = self.global_position
		goods_body.rotation_degrees = randf_range(0.0, 360.0)
		goods_body.get_child(0).texture = pack.item_data.item_sprite
		goods_body.set_meta("pack_data", pack)
		goods_body.set_meta("item_data", pack.item_data)
		goods_body.add_to_group("dropped_pack")
	slot.current_pack = null
	pack_sprites[slot_index].sprite_frames = SpriteFrames.new()
	slot_buttons[slot_index].get_child(0).show()

func _show_remove_ui(slot_index : int) -> void:
	if _active_remove_slot == slot_index and is_instance_valid(_active_remove_ui):
		_dismiss_remove_ui()
		return
	#clear remove ui if exist
	_dismiss_remove_ui()
	if remove_button_ui == null:
		print("no remove button packed scene assigned")
		return
	
	var remove_ui_inst : TextureButton = remove_button_ui.instantiate()
	var slot_btn : BaseButton = slot_buttons[slot_index]
	#var slot_x : float = ( + slot_btn.offset_right) / 2.0
	#var slot_y : float = (slot_btn.offset_top + slot_btn.offset_bottom) / 2.0
	add_child(remove_ui_inst)
	remove_ui_inst.position = Vector2(slot_btn.position.x, slot_btn.position.y)
	remove_ui_inst.pressed.connect(_on_remove_pack_pressed.bind(slot_index))
	_active_remove_ui = remove_ui_inst
	_active_remove_slot = slot_index
	
func _on_remove_pack_pressed(slot_index : int) -> void:
	_eject_slot(slot_index)
	_dismiss_remove_ui()

func _dismiss_remove_ui() -> void:
	if is_instance_valid(_active_remove_ui):
		_active_remove_ui.queue_free()
	_active_remove_ui = null
	_active_remove_slot = -1
