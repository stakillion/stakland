extends Node

var world:
	get: return get_tree().current_scene

# trunk nodes
var players: = Node.new()
var effects: = Node.new()
var tools: = Node.new()

# menu
@export var menu_scene: = preload("res://scenes/ui/menu.tscn")
var menu:Control

# mobile controls
@export var mobile_controls_scene: = preload("res://scenes/ui/mobile_controls.tscn")
var mobile_controls:Node2D

# multiplayer
const mp_port: = 26262
const mp_sync_rate: = 30
var mp_status: = 0 #  1 = hosting,  2 = connected to host
var mp_tick:int
var upnp_thread:Thread


func _init() -> void:
	# node containing the players
	players.name = "Players"
	add_sibling.call_deferred(players)
	# node containing effects
	effects.name = "Effects"
	add_child.call_deferred(effects)
	# node supplying admin and debug tools
	tools.set_script(preload("res://scripts/tools.gd"))
	tools.name = "Tools"
	add_child.call_deferred(tools)


func _ready() -> void:
	get_tree().connect("node_added", _on_node_added)

	if DisplayServer.get_name() == "headless":
		# start the game without the player if we are a server
		Player.queue_free()
		host_game()
	else:
		# add player to the player list
		Player.set_name.call_deferred("1")
		Player.reparent.call_deferred(players)
		# load the menu
		menu = menu_scene.instantiate() as Control
		add_child.call_deferred(menu)

		if OS.has_feature("mobile"):
			# load touch-screen controls on mobile
			mobile_controls = mobile_controls_scene.instantiate() as Node2D
			mobile_controls.visible = false
			add_child.call_deferred(mobile_controls)

	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _physics_process(delta:float) -> void:
	mp_tick += 1
	# sync physics at our desired sync rate
	if mp_tick % int(1 / (delta * mp_sync_rate)) == 0:
		get_tree().root.propagate_call.call_deferred("_on_mp_sync_frame")


func host_game() -> bool:
	var peer: = ENetMultiplayerPeer.new()
	if peer.create_server(mp_port) != OK:
		return false
	multiplayer.multiplayer_peer = peer
	update_player_id()
	mp_status = 1
	menu.update_mp_menu("Hosting")
	# attempt UPNP port forwarding
	upnp_thread = Thread.new()
	upnp_thread.start(upnp_setup.bind(mp_port))
	return true


func join_game(address:String) -> bool:
	var peer: = ENetMultiplayerPeer.new()
	if peer.create_client(IP.resolve_hostname(address), mp_port) != OK:
		return false
	multiplayer.multiplayer_peer = peer
	return true


func leave_game() -> void:
	for player in players.get_children():
		if player != Player:
			multiplayer.multiplayer_peer.disconnect_peer(player.name.to_int())
	multiplayer.multiplayer_peer.host.destroy.call_deferred()


@rpc("call_local", "reliable")
func load_level(path: = "res://scenes/levels/test_level.tscn") -> void:
	for player in players.get_children():
		player.remove_pawn()
	get_tree().change_scene_to_file(path)
	Game.menu.update_main_menu()


func upnp_setup(port:int) -> void:
	var upnp = UPNP.new()
	var err = upnp.discover()
	if err != OK:
		print("UPNP Failed: %d" % err)
		return
	if upnp.get_gateway() && upnp.get_gateway().is_valid_gateway():
		upnp.add_port_mapping(port, port, ProjectSettings.get_setting("application/config/name"), "UDP")
		upnp.add_port_mapping(port, port, ProjectSettings.get_setting("application/config/name"), "TCP")
		print("UPNP Success!")
		menu.update_mp_menu(upnp.query_external_address())


func _on_player_connected(id:int) -> void:
	request_player.rpc_id(id)
	if is_multiplayer_authority():
		send_mp_tick.rpc_id(id, mp_tick, Time.get_unix_time_from_system())


func _on_player_disconnected(id:int) -> void:
	var old_player: = players.get_node_or_null(str(id)) as Player
	if old_player:
		get_tree().queue_delete(old_player)


func _on_connected_to_server() -> void:
	Player.remove_pawn()
	update_player_id()
	mp_status = 2
	menu.update_main_menu()
	menu.update_mp_menu()


func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	update_player_id()
	mp_status = 0
	menu.update_main_menu()
	menu.update_mp_menu()


func _on_node_added(node:Node) -> void:
	# automatically set ownership of any nodes under a player to that player
	for player in players.get_children():
		if player.is_ancestor_of(node):
			node.owner = player
			return


func _exit_tree():
	if upnp_thread:
		upnp_thread.wait_to_finish()


func create_player(id:int, data:Dictionary) -> Player:
	var new_player: = GamePlayer.new()
	new_player.name = str(id)
	players.add_child(new_player)
	new_player.set_multiplayer_authority(id)
	new_player.data.merge(data, true)
	return new_player


func update_player_id() -> void:
	var id: = multiplayer.multiplayer_peer.get_unique_id()
	Player.name = str(id)
	Player.set_multiplayer_authority(id)


@rpc("any_peer", "call_remote", "reliable")
func request_player() -> void:
	if !is_instance_valid(Player):
		return
	var peer_id: = multiplayer.get_remote_sender_id()
	# send player data and whether they have spawned
	send_player.rpc_id(peer_id, Player.data, !!Player.pawn)


@rpc("any_peer", "call_remote", "reliable")
func send_player(player_data:Dictionary, spawned:bool) -> void:
	var peer_id: = multiplayer.get_remote_sender_id()
	print("recieving player: ", peer_id)
	var new_player: = create_player(peer_id, player_data)
	if spawned:
		new_player.spawn()


@rpc("call_remote", "reliable")
func send_mp_tick(tick:int, host_timestamp:float) -> void:
	var current_time: = Time.get_unix_time_from_system()
	var diff: = current_time - host_timestamp
	mp_tick = tick + int(diff * Engine.physics_ticks_per_second)
