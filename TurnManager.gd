extends Node

enum Turn {
	PLAYER,
	BOT
}

var current_turn = Turn.PLAYER

signal player_turn_started
signal bot_turn_started

func _ready():
	start_game()

func start_game():
	current_turn = Turn.PLAYER
	emit_signal("player_turn_started")

func end_player_turn():
	current_turn = Turn.BOT
	emit_signal("bot_turn_started")

func end_bot_turn():
	current_turn = Turn.PLAYER
	emit_signal("player_turn_started")
