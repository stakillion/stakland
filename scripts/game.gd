extends Node

var player_list = Node.new()
var world:Node3D

# multiplayer
@onready var dedicated = OS.has_feature("dedicated_server")
var mp_peer = ENetMultiplayerPeer.new()
var mp_tick = Timer.new()
var mp_port = 26262

# menu
@export var menu_scene = preload("res://scenes/ui/menu.tscn")
var menu:Control

# player
var player:Player


func _ready():
	# the node containing the players
	player_list.name = "Players"
	add_child(player_list)

	# multiplayer tick timer
	mp_tick.name = "MPTick"
	mp_tick.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(mp_tick)
	mp_tick.start(1.0/30) # 30hz

	if !dedicated:
		# load the player
		player = Player.new(1)
		# load the menu
		menu = menu_scene.instantiate()
		add_child(menu)
	else:
		# or start the game if we are a server
		host_game()


func host_game():
	if mp_peer.create_server(mp_port) != OK:
		return
	multiplayer.multiplayer_peer = mp_peer
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)


func join_game(address):
	address = IP.resolve_hostname(address)
	if mp_peer.create_client(address, mp_port) != OK:
		return
	multiplayer.multiplayer_peer = mp_peer
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)


func _on_player_connected(id):
	request_player.rpc_id(id)


func _on_player_disconnected(id):
	var old_player = player_list.get_node_or_null(str(id))
	if old_player:
		get_tree().queue_delete(old_player)


func _on_connected_to_server():
	# change player id to our new peer id
	var id = mp_peer.get_unique_id()
	player.name = str(id)
	player.set_multiplayer_authority(id)


@rpc("any_peer", "call_remote", "reliable")
func request_player():
	if !player:
		return
	var peer_id = multiplayer.get_remote_sender_id()
	# for now just send whether or not the player has spawned, can extend in the future
	send_player.rpc_id(peer_id, player.spawned)


@rpc("any_peer", "call_remote", "reliable")
func send_player(spawned):
	var peer_id = multiplayer.get_remote_sender_id()
	print("recieving player: ", peer_id)
	var new_player = Player.new(peer_id)
	if spawned:
		new_player.spawn()
