extends Node

@export var player_progress: PlayerProgress

signal money_changed()
signal store_switched()

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

func add_pending_delivery(pack: PackData, amount: int) -> void:
	for entry : PendingDeliveryEntry in player_progress.pending_deliveries:
		if is_same_pack(entry.pack_data, pack):
			entry.quantity += amount
			return
	var new_entry : PendingDeliveryEntry = PendingDeliveryEntry.new()
	new_entry.pack_data = pack
	new_entry.quantity = amount
	player_progress.pending_deliveries.append(new_entry)

func increase_player_money(amount:int) -> void:
	player_progress.money += amount
	player_progress.today_profit += amount
	money_changed.emit()

func decrease_player_money(amount:int) -> void:
	player_progress.money -= amount
	money_changed.emit()

func update_money_ui() -> String:
	# 99999 -> 99,999
	var regex := RegEx.new()
	regex.compile("(\\d)(?=(\\d{3})+(?!\\d))")
	return regex.sub(str(player_progress.money), "$1,", true)

func has_pending_deliveres() -> bool:
	return !player_progress.pending_deliveries.is_empty()

func spawn_pending_delivery_packs() -> void:
	var main_game : Node = get_tree().get_first_node_in_group("main_game_scene")
	StoreManager.spawn_speech_label("Shopy Delivery!")
	if main_game == null:
		# Fallback: if main_game not found, add packs directly
		for entry: PendingDeliveryEntry in player_progress.pending_deliveries:
			add_pack_quantity(entry.pack_data, entry.quantity)
		player_progress.pending_deliveries.clear()
		return

	var viewport_size : Vector2 = main_game.get_viewport_rect().size
	var center : Vector2 = viewport_size / 2.0

	for entry: PendingDeliveryEntry in player_progress.pending_deliveries:
		if entry.pack_data == null or entry.pack_data.item_data == null:
			continue
		for i in range(entry.quantity):
			var goods_body : RigidBody2D = entry.pack_data.item_data.item_body.instantiate()
			main_game.add_child(goods_body)
			goods_body.global_position = Vector2(center.x + randf_range(-20.0, 20.0), center.y)
			goods_body.rotation_degrees = randf_range(0.0, 360.0)
			goods_body.get_child(0).texture = entry.pack_data.item_data.item_sprite
			goods_body.set_meta("pack_data", entry.pack_data)
			goods_body.set_meta("item_data", entry.pack_data.item_data)
			goods_body.add_to_group("dropped_pack")
			await get_tree().create_timer(0.08).timeout

	player_progress.pending_deliveries.clear()

func record_customer_served() -> void:
	player_progress.today_customer_served += 1
	player_progress.total_customer_served += 1

func to_next_day() -> void:
	player_progress.current_day += 1
	player_progress.today_customer_served = 0
	player_progress.today_profit = 0

func owns_store(store: StoreStat) -> bool:
	for owned: StoreStat in player_progress.owned_stores:
		if owned == store or owned.store_name == store.store_name:
			return true
	return false

func buy_store(store: StoreStat) -> void:
	if owns_store(store):
		return
	player_progress.owned_stores.append(store)

func switch_store(store: StoreStat) -> void:
	player_progress.current_store = store
	store_switched.emit()
