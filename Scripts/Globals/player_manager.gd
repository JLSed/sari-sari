extends Node

@export var player_progress: PlayerProgress

signal money_changed()

# Tracks store goods bought from the phone (Dictionary: ItemID -> Amount)
var warehouse_stock: Dictionary = {}

func is_same_pack(pack_a: PackData, pack_b: PackData) -> bool:
	if pack_a == null or pack_b == null:
		return false
	if pack_a == pack_b:
		return true
	if pack_a.item_data != null and pack_a.item_data == pack_b.item_data:
		return true
	if pack_a.item_data != null and pack_b.item_data != null:
		return pack_a.item_data.item_name == pack_b.item_data.item_name 
	return false

func get_purchased_pack_entry(pack: PackData) -> PurchasedPackEntry:
	for entry: PurchasedPackEntry in player_progress.purchased_goods:
		if entry != null and is_same_pack(entry.pack_data, pack):
			return entry
	return null

func add_pack_quantity(pack: PackData, amount: int) -> void:
	if pack == null or amount <= 0:
		return
	
	var existing_entry: PurchasedPackEntry = get_purchased_pack_entry(pack)
	if existing_entry != null:
		existing_entry.quantity += amount
		return
	
	var new_entry : PurchasedPackEntry = PurchasedPackEntry.new()
	new_entry.pack_data = pack
	new_entry.quantity = amount
	player_progress.purchased_goods.append(new_entry)

func remove_pack_quantity(pack: PackData, amount : int) -> int:
	if pack == null or amount <= 0:
		return 0
	
	var existing_entry: PurchasedPackEntry = get_purchased_pack_entry(pack)
	if existing_entry == null:
		return 0
	var removed_amount : int = mini(existing_entry.quantity, amount)
	existing_entry.quantity -= removed_amount
	return removed_amount
	


func add_container(new_container: GoodsContainerEntry) -> void:
	# make sure no duplicates
	if player_progress.owned_containers.has(new_container):
		return
	player_progress.owned_containers.append(new_container)

func add_stock(item_id: String, amount: int) -> void:
	if warehouse_stock.has(item_id):
		warehouse_stock[item_id] += amount
	else:
		warehouse_stock[item_id] = amount

func increase_player_money(amount:int) -> void:
	player_progress.money += amount
	money_changed.emit()

func decrease_player_money(amount:int) -> void:
	player_progress.money -= amount
	money_changed.emit()

func update_money_ui() -> String:
	# 99999 -> 99,999
	var regex := RegEx.new()
	regex.compile("(\\d)(?=(\\d{3})+(?!\\d))")
	return regex.sub(str(player_progress.money), "$1,", true)
