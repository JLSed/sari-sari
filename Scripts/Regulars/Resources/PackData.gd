class_name PackData extends Resource

@export_category("Metadata")
@export var item_data : ItemData
@export var buy_amount: int = 1
@export var current_stack : int
@export var max_stack : int
@export var allowed_container : Array[int]
@export_category("Sprite Data")
@export var pack_sprite_by_container : Dictionary[int, PackSpriteData]
