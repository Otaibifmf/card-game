extends Node2D

const HAND_COUNT = 5
const MAX_SELECTION = 2
const HAND_Y = 600
const HAND_CENTER_X = 640
const CARD_WIDTH = 140

var cards = []
var selected_cards = []
var card_scene = preload("res://Scenes/Card.tscn")

func _ready():
	var deck = get_node("../Deck")
	if deck == null:
		push_error("Deck not found. Make sure it's named 'Deck' and is a sibling of PlayerHand.")
		return

	for i in range(HAND_COUNT):
		var card_data = deck.draw_card()
		if card_data == null:
			break

		var card = _create_card_from_data(card_data)
		cards.append(card)

	_update_card_positions()

	var discard_button = get_node("../DiscardButton")
	if discard_button == null:
		push_error("DiscardButton not found.")
	else:
		discard_button.disabled = true
		discard_button.pressed.connect(_on_discard_pressed)

func _create_card_from_data(card_data):
	var card = card_scene.instantiate()
	add_child(card)
	card.position = Vector2(-500, HAND_Y)
	card.card_data = card_data

	var sprite = card.get_node("Sprite")
	var tex = load(card_data.sprite_path)
	if tex:
		sprite.texture = tex
	else:
		print("⚠️ Missing texture:", card_data.sprite_path)

	card.pressed.connect(_on_card_pressed)
	card.hovered.connect(_on_card_hovered)
	card.hovered_off.connect(_on_card_hovered_off)
	return card

func _on_card_pressed(card):
	if card in selected_cards:
		selected_cards.erase(card)
	else:
		if selected_cards.size() < MAX_SELECTION:
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

func _animate_position(card, target_pos):
	var tween = create_tween()
	tween.tween_property(card, "position", target_pos, 0.3)

func _animate_scale(card, target_scale):
	var tween = create_tween()
	tween.tween_property(card, "scale", target_scale, 0.2)

func _update_discard_button_state():
	var discard_button = get_node("../DiscardButton")
	discard_button.disabled = selected_cards.is_empty()

func _on_discard_pressed():
	if selected_cards.is_empty():
		return

	var deck = get_node("../Deck")
	if deck == null:
		push_error("Deck not found.")
		return

	var num_to_replace = selected_cards.size()

	for card in selected_cards:
		cards.erase(card)
		card.queue_free()

	selected_cards.clear()

	for i in range(num_to_replace):
		var card_data = deck.draw_card()
		if card_data == null:
			break
		var new_card = _create_card_from_data(card_data)
		cards.append(new_card)

	_update_card_positions()
	_update_discard_button_state()
