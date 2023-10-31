extends Node

var player_list = Node.new()
var world:Node3D

# multiplayer
@onready var dedicated = OS.has_feature("dedicated_server")
@onready var mobile = get_name() == "Android"
var mp_peer = ENetMultiplayerPeer.new()
var mp_spawner = MultiplayerSpawner.new()
var mp_tick = Timer.new()
var mp_port = 26262

# menu
@export var menu_scene = preload("res://scenes/ui/menu.tscn")
var menu:Control

# player
@export var player_scene = preload("res://scenes/player.tscn")
var player:Node


func _ready():
	# menu (unless we're a server)
	if !dedicated:
		menu = menu_scene.instantiate()
		add_child(menu)

	# player list
	player_list.name = "Players"
	add_child(player_list)

	# mutliplayer spawner
	mp_spawner.name = "MPSpawner"
	mp_spawner.spawn_path = player_list.get_path() # throws an error and works anyway?
	mp_spawner.add_spawnable_scene("res://scenes/player.tscn")
	add_child(mp_spawner)

	# multiplayer tick
	mp_tick.name = "MPTick"
	mp_tick.wait_time = 1.0/60 # 60hz
	add_child(mp_tick)
	mp_tick.start()

	# start the game if we are a server
	if dedicated:
		host_game()


func add_player(peer_id = 1):
	var new_player = player_scene.instantiate()
	new_player.name = str(peer_id)
	player_list.add_child(new_player)


func remove_player(old_player):
	if old_player == player:
		menu.enable_game_menu(false)

	get_tree().queue_delete(old_player)


func host_game():
	mp_peer.create_server(mp_port)
	multiplayer.multiplayer_peer = mp_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	if !dedicated:
		add_player()


func join_game(address):
	address = IP.resolve_hostname(address)
	mp_peer.create_client(address, mp_port)
	multiplayer.multiplayer_peer = mp_peer
