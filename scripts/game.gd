extends Node

var active = false: set = set_game_active # is game running?

# menu
@onready var menu_scene = preload("res://scenes/ui/menu.tscn")
var menu:Control

# multiplayer
var peer = ENetMultiplayerPeer.new()


func _ready():
	menu = menu_scene.instantiate()
	add_child(menu)


func host_game():
	peer.create_server(26262)
	multiplayer.multiplayer_peer = peer
	#multiplayer.peer_connected.connect(Player.create_pawn)
	Player.create_pawn()
	active = true


func join_game(address = "localhost"):
	peer.create_client(address, 26262)
	multiplayer.multiplayer_peer = peer
	Player.create_pawn()
	active = true


func set_game_active(value):
	menu.enable_game_menu(value)
