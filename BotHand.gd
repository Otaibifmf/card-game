extends Node2D

const HAND_COUNT = 5
const HAND_Y = 230
const HAND_CENTER_X = 950
const CARD_WIDTH = 140

signal bot_card_pressed(card)

var card_scene = preload("res://Scenes/Card.tscn")
var back_texture = preload("res://assets/red_backing.png")

var cards = []
var TARGET_TOTAL = 0
var deck = null
var turn_manager = null
var has_won = false
var can_play = false

func _ready():
	deck = get_node("../Deck")
	turn_manager = get_node("../TurnManager")
	
	turn_manager.bot_turn_started.connect(_on_bot_turn_started)

	var player_hand = get_node("../PlayerHand")
	if player_hand:
		TARGET_TOTAL = player_hand.TARGET_TOTAL

	for i in range(HAND_COUNT):
		var card_data = deck.draw_card()
		var card = _create_hidden_card(card_data)
		cards.append(card)

	_update_card_positions()

func _on_bot_turn_started():
	if has_won or turn_manager.game_over:
		return

	can_play = true
	print("🤖 Bot turn begins")

	await get_tree().create_timer(1.2).timeout

	print("🤖 Bot total before:", calculate_total(), "Target:", TARGET_TOTAL)

	_discard_random_cards()

	await get_tree().create_timer(1.2).timeout

	var total = calculate_total()
	print("🤖 Bot total after:", total)

	if total == TARGET_TOTAL:
		var win_popup = get_node("../WinPopup")
		if win_popup:
			win_popup.texture = load("res://assets/lose_popup.png")
			win_popup.visible = true

		has_won = true
		can_play = false
		if turn_manager:
			turn_manager.game_over = true
		print("🤖 Bot won. Ending game.")
		return

	can_play = false
	print("👉 Ending Bot Turn")
	turn_manager.end_bot_turn()

func _create_hidden_card(card_data):
	var card = card_scene.instantiate()
	add_child(card)
	card.position = Vector2(-500, HAND_Y)
	card.card_data = card_data

	var sprite = card.get_node("CardImage")
	if sprite:
		sprite.texture = back_texture

	var area = card.get_node("Area2D")
	if area:
		area.set_deferred("monitoring", true)
		area.set_deferred("input_pickable", true)

	card.pressed.connect(_on_card_pressed)
	return card

func _on_card_pressed(card):
	print("🟦 Bot card pressed signal emitted:", card.name)
	emit_signal("bot_card_pressed", card)

func _update_card_positions():
	var total_width = (cards.size() - 1) * CARD_WIDTH
	for i in range(cards.size()):
		var card = cards[i]
		var base_x = HAND_CENTER_X + i * CARD_WIDTH - total_width / 2
		var target_pos = Vector2(base_x, HAND_Y)
		var tween = create_tween()
		tween.tween_property(card, "position", target_pos, 0.3)

func _discard_random_cards():
	var count_to_discard = min(cards.size(), randi() % 2 + 1)
	var cards_to_discard = []

	while cards_to_discard.size() < count_to_discard:
		var random_index = randi() % cards.size()
		var card = cards[random_index]
		if card not in cards_to_discard:
			cards_to_discard.append(card)

	for card in cards_to_discard:
		cards.erase(card)
		card.queue_free()

	for i in range(count_to_discard):
		var card_data = deck.draw_card()
		if card_data == null:
			var popup = get_node("../WinPopup")
			if popup:
				popup.texture = load("res://assets/lose_popup.png")
				popup.visible = true
			can_play = false
			if turn_manager:
				turn_manager.game_over = true
			return

		var new_card = _create_hidden_card(card_data)
		cards.append(new_card)

	_update_card_positions()

func calculate_total() -> int:
	var total = 0
	var rank_values = {
		"ace": 1, "two": 2, "three": 3, "four": 4, "five": 5,
		"six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10
	}
	for card in cards:
		var name_str = card.card_data.get("name", "")
		var parts = name_str.split(" ")
		if parts.size() >= 1:
			var rank = parts[0].to_lower()
			if rank_values.has(rank):
				total += rank_values[rank]
	return total
