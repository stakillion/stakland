extends Node

# multiplayer
var peer = ENetMultiplayerPeer.new()
var player_list:Node
var mp_spawner:MultiplayerSpawner
var port = 26262

# menu
@export var menu_scene = preload("res://scenes/ui/menu.tscn")
var menu:Control

# player
@export var player_scene = preload("res://scenes/player.tscn")
var player:Node


func _ready():
	# player list
	player_list = Node.new()
	player_list.name = "Players"
	add_child(player_list)

	# menu
	menu = menu_scene.instantiate()
	add_child(menu)

	# mutliplayer spawner
	mp_spawner = MultiplayerSpawner.new()
	mp_spawner.name = "MultiplayerSpawner"
	mp_spawner.spawn_path = player_list.get_path() # throws an error and works anyway?
	mp_spawner.add_spawnable_scene("res://scenes/player.tscn")
	add_child(mp_spawner)


func add_player(peer_id = 1):
	var new_player = player_scene.instantiate()
	new_player.name = str(peer_id)
	player_list.add_child(new_player)


func remove_player(peer_id):
	var old_player = player_list.get_node_or_null(str(peer_id))
	if old_player == player:
		player = null
		menu.enable_game_menu(false)
	if old_player:
		old_player.queue_free()


func host_game():
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	add_player()


func join_game(address = "localhost"):
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
