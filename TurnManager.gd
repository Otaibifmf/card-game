extends Node

enum Turn {
	PLAYER,
	BOT
}

var current_turn = Turn.PLAYER
var is_turn_active = false
var game_over = false

signal player_turn_started
signal bot_turn_started

func _ready():
	start_game()

func start_game():
	print("🟢 Game started - Player turn")
	current_turn = Turn.PLAYER
	is_turn_active = true
	game_over = false
	emit_signal("player_turn_started")

func end_player_turn():
	if current_turn != Turn.PLAYER or not is_turn_active or game_over:
		push_warning("⚠️ Invalid attempt to end player turn")
		return
	print("🟡 Player ended turn")
	current_turn = Turn.BOT
	is_turn_active = true
	emit_signal("bot_turn_started")

func end_bot_turn():
	if current_turn != Turn.BOT or not is_turn_active or game_over:
		push_warning("⚠️ Invalid attempt to end bot turn")
		return
	print("🤖 Bot ended turn")
	current_turn = Turn.PLAYER
	is_turn_active = true
	emit_signal("player_turn_started")
