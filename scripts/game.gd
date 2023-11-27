extends Node

var world:
	get: return get_tree().current_scene


# players
var player_list = Node.new()

# menu
@export var menu_scene = preload("res://scenes/ui/menu.tscn")
var menu:Control

# multiplayer
var dedicated = OS.has_feature("dedicated_server") || "--server" in OS.get_cmdline_user_args()
var mp_sync = Timer.new()
var mp_port = 26262


func _init():
	# the node containing the players
	player_list.name = "Players"
	add_sibling.call_deferred(player_list)

	# multiplayer sync timer
	mp_sync.name = "MPSync"
	mp_sync.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(mp_sync)


func _ready():
	# start sync timer
	mp_sync.start(1.0/20) # 20hz

	if !dedicated:
		# load the player
		Player.set_name.call_deferred(1)
		Player.reparent.call_deferred(player_list)
		# load the menu
		menu = menu_scene.instantiate()
		add_child(menu)
	else:
		# or start the game if we are a server
		Player.queue_free()
		host_game()


func host_game():
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(mp_port) != OK:
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)


func join_game(address):
	var peer = ENetMultiplayerPeer.new()
	if peer.create_client(IP.resolve_hostname(address), mp_port) != OK:
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_player_connected(id):
	request_player.rpc_id(id)


func _on_player_disconnected(id):
	var old_player = player_list.get_node_or_null(str(id))
	if old_player:
		get_tree().queue_delete(old_player)


func _on_connected_to_server():
	# change player id to our new peer id
	var id = multiplayer.multiplayer_peer.get_unique_id()
	Player.name = str(id)
	Player.set_multiplayer_authority(id)
	if Player.pawn:
		# respawn the player
		Player.spawn()


func _on_server_disconnected():
	multiplayer.multiplayer_peer = null


func create_player(id, data):
	var new_player = player.new()
	new_player.name = str(id)
	player_list.add_child(new_player)
	new_player.set_multiplayer_authority(id)
	new_player.data.merge(data, true)
	return new_player


@rpc("any_peer", "call_remote", "reliable")
func request_player():
	if !Player:
		return
	var peer_id = multiplayer.get_remote_sender_id()
	# send player data and whether they have spawned
	send_player.rpc_id(peer_id, Player.data, !!Player.pawn)


@rpc("any_peer", "call_remote", "reliable")
func send_player(player_data, spawned):
	var peer_id = multiplayer.get_remote_sender_id()
	print("recieving player: ", peer_id)
	var new_player = create_player(peer_id, player_data)
	if spawned:
		new_player.spawn()
