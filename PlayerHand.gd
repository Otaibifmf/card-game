extends Node2D

const HAND_COUNT = 5
const MAX_SELECTION = 2
const HAND_Y = 520
const HAND_CENTER_X = 470
const CARD_WIDTH = 140

var cards = []
var selected_cards = []
var selected_bot_cards = []
var card_scene = preload("res://Scenes/Card.tscn")
var TARGET_TOTAL_VALUES = [22, 23, 24, 25, 26, 27, 28, 29, 30]
var TARGET_TOTAL = 25
var can_play = false
var trade_mode = false
var deck = null
var turn_manager = null

func _ready():
	randomize()
	TARGET_TOTAL = TARGET_TOTAL_VALUES[randi() % TARGET_TOTAL_VALUES.size()]
	
	deck = get_node("../Deck")
	turn_manager = get_node("../TurnManager")

	if turn_manager:
		turn_manager.player_turn_started.connect(_on_player_turn_started)

	var bot_hand = get_node("../BotHand")
	if bot_hand:
		bot_hand.bot_card_pressed.connect(_on_bot_card_selected)

	for i in range(HAND_COUNT):
		var card_data = deck.draw_card()
		if card_data == null:
			break
		var card = _create_card_from_data(card_data)
		cards.append(card)

	_update_card_positions()

	var discard_button = get_node("../DiscardButton")
	if discard_button:
		discard_button.disabled = true
		discard_button.pressed.connect(_on_discard_pressed)

	var trade_button = get_node("../TradeButton")
	if trade_button:
		trade_button.pressed.connect(toggle_trade_mode)

	update_hand_total_label()
	update_target_label()

func _on_player_turn_started():
	can_play = true
	print("🧑 Player's turn started - you can now play.")
	var trade_button = get_node("../TradeButton")
	if trade_button:
		trade_button.disabled = false

func _create_card_from_data(card_data):
	var card = card_scene.instantiate()
	add_child(card)
	card.position = Vector2(-500, HAND_Y)
	card.card_data = card_data

	var sprite = card.get_node("CardImage")
	if sprite:
		var tex = load(card_data.sprite_path)
		if tex:
			sprite.texture = tex

	card.pressed.connect(_on_card_pressed)
	card.hovered.connect(_on_card_hovered)
	card.hovered_off.connect(_on_card_hovered_off)
	return card

func _on_card_pressed(card):
	if not can_play:
		print("⛔ You tried to select a card during bot's turn!")
		return

	if trade_mode:
		if card in selected_cards:
			selected_cards.erase(card)
		elif selected_cards.size() < MAX_SELECTION:
			selected_cards.append(card)
	else:
		if card in selected_cards:
			selected_cards.erase(card)
		elif selected_cards.size() < MAX_SELECTION:
			selected_cards.append(card)

	_update_card_positions()
	_update_discard_button_state()

func _on_card_hovered(card):
	if card not in selected_cards:
		_animate_scale(card, Vector2(1.05, 1.05))

func _on_card_hovered_off(card):
	if card not in selected_cards:
		_animate_scale(card, Vector2(1, 1))

func _update_card_positions():
	var total_width = (cards.size() - 1) * CARD_WIDTH
	for i in range(cards.size()):
		var card = cards[i]
		var base_x = HAND_CENTER_X + i * CARD_WIDTH - total_width / 2
		var target_pos = Vector2(base_x, HAND_Y)
		if card in selected_cards:
			target_pos.y -= 30
			_animate_scale(card, Vector2(1.15, 1.15))
		else:
			_animate_scale(card, Vector2(1, 1))
		_animate_position(card, target_pos)

	update_target_label()
	update_hand_total_label()

func _animate_position(card, target_pos):
	var tween = create_tween()
	tween.tween_property(card, "position", target_pos, 0.3)

func _animate_scale(card, target_scale):
	var tween = create_tween()
	tween.tween_property(card, "scale", target_scale, 0.2)

func _update_discard_button_state():
	var discard_button = get_node("../DiscardButton")
	if discard_button:
		discard_button.disabled = selected_cards.is_empty() or trade_mode

func _on_discard_pressed():
	if not can_play:
		print("⛔ Discard pressed during bot's turn!")
		return

	if selected_cards.is_empty():
		return

	var num_to_replace = selected_cards.size()

	for card in selected_cards:
		cards.erase(card)
		card.queue_free()
	selected_cards.clear()

	for i in range(num_to_replace):
		var card_data = deck.draw_card()
		if card_data == null:
			var win_label = get_node("../WinLabel")
			if win_label:
				win_label.text = "❌ Deck is empty – Game Over!"
				win_label.visible = true
			can_play = false
			if turn_manager:
				turn_manager.game_over = true
			return
		var new_card = _create_card_from_data(card_data)
		cards.append(new_card)

	_update_card_positions()
	_update_discard_button_state()

	if calculate_total() == TARGET_TOTAL:
		var win_label = get_node("../WinLabel")
		if win_label:
			win_label.text = "🎉 You Win!"
			win_label.visible = true
		can_play = false
		if turn_manager:
			turn_manager.game_over = true
		return

	can_play = false
	print("👉 Ending Player Turn")
	if turn_manager:
		turn_manager.end_player_turn()

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

func update_hand_total_label():
	var label = get_node("../HandSumLabel")
	if label:
		label.text = "Sum: " + str(calculate_total())

func update_target_label():
	var label = get_node("../TargetLabel")
	if label:
		label.text = "Target: " + str(TARGET_TOTAL)

func toggle_trade_mode():
	trade_mode = not trade_mode
	selected_cards.clear()
	selected_bot_cards.clear()
	_update_card_positions()
	_update_discard_button_state()
	print("🟢 Trade mode is", trade_mode)

func _on_bot_card_selected(card):
	if not can_play or not trade_mode:
		return

	if card in selected_bot_cards:
		selected_bot_cards.erase(card)
	elif selected_bot_cards.size() < MAX_SELECTION:
		selected_bot_cards.append(card)

	_check_and_execute_trade()

func _check_and_execute_trade():
	if selected_cards.size() != selected_bot_cards.size():
		return

	for i in range(selected_cards.size()):
		var my_card = selected_cards[i]
		var bot_card = selected_bot_cards[i]

		var temp_data = my_card.card_data
		my_card.card_data = bot_card.card_data
		bot_card.card_data = temp_data

		var sprite = my_card.get_node("CardImage")
		if sprite:
			sprite.texture = load(my_card.card_data.sprite_path)

	selected_cards.clear()
	selected_bot_cards.clear()
	trade_mode = false
	_update_card_positions()
	_update_discard_button_state()

	print("🔁 Trade completed!")

	if calculate_total() == TARGET_TOTAL:
		var win_label = get_node("../WinLabel")
		if win_label:
			win_label.text = "🎉 You Win!"
			win_label.visible = true
		can_play = false
		if turn_manager:
			turn_manager.game_over = true
	else:
		can_play = false

	var trade_button = get_node("../TradeButton")
	if trade_button:
		trade_button.disabled = true

	print("👉 Ending Player Turn after trade")
	if turn_manager:
		turn_manager.end_player_turn()
