class_name PlayerProgress extends Resource


@export var current_store : StoreStat
@export var owned_stores : Array[StoreStat] = []
@export var purchased_goods : Array[PurchasedPackEntry]
@export var owned_containers : Array[GoodsContainerEntry] = []
@export var money: int
@export var current_day : int = 1
@export var pending_deliveries : Array[PendingDeliveryEntry] = []

@export var total_customer_served : int = 0
@export var today_customer_served : int = 0
@export var today_profit : int = 0

@export var bgm_volume : float = -10.0
@export var sgx_volume : float = 0.0
@export var audio_muted : bool = false
