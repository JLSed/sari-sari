class_name GoodsContainer extends Node2D


@export var container_texture : Texture2D
@export var PickPackUI : PackedScene
@export var pack_per_slot : Array[GoodsContainerSlot]
@export var pack_sprites : Array[AnimatedSprite2D]
@export var slot_buttons : Array[BaseButton]
@onready var container_sprite: Sprite2D = $ContainerSprite

var current_index: int = -1

func _ready() -> void:
	container_sprite.texture = container_texture
	for i in range(slot_buttons.size()):
		slot_buttons[i].pressed.connect(_on_slot_button_pressed.bind(i))

func _on_slot_button_pressed(slot_index : int) -> void:
	print(slot_index)
	current_index = slot_index
	var pack : PackData = pack_per_slot[current_index].current_pack
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

func showPickPackUI() -> void:
	var allowed_pack : int = pack_per_slot[current_index].container_id
	var new_pickPackUI : PickGoodsUI = PickPackUI.instantiate()
	var main_game : Node = get_tree().get_first_node_in_group("main_game_scene")
	main_game.add_child(new_pickPackUI)
	new_pickPackUI.catalog_setup(allowed_pack)
	new_pickPackUI.pack_item_placed.connect(_pack_placed)

func _pack_placed(pack_entry : PurchasedPackEntry) -> void:
	print(pack_entry)
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
	
 
