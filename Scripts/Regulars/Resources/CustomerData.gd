class_name CustomerData extends Resource

@export var customer_sprite : Texture2D

@export var starting_happy_meter := 100
@export var happiness_decay_per_tick := 10
@export var wrong_item_penalty := 20
@export var voices_pool : Array[String]

@export var allowed_packs : Array[PackData]
@export var can_buy_all_packs := false
@export var min_request_count := 1
@export var max_request_count := 4

@export var angry_lines : Array[String] = [
	"Hay nako! ang tagal",
	"Mag sara na kayo!",
	"Nasayang lang oras ko!",
	"I'm never coming back!",
	"Uso mag restock!"
]
