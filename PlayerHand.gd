extends Node2D

const HAND_COUNT = 5
const MAX_SELECTION = 2
const HAND_Y = 520 #500 #600
const HAND_CENTER_X = 470 #540 #640
const CARD_WIDTH = 140

const POSSIBLE_TARGETS = [22, 23, 24, 25, 26, 27, 28, 29, 30]
var TARGET_TOTAL = 25  # will be set randomly on _ready

var rank_values = {
	"ace": 1,
	"two": 2,
	"three": 3,
	"four": 4,
	"five": 5,
	"six": 6,
	"seven": 7,
	"eight": 8,
	"nine": 9,
	"ten": 10
}

var cards = []
var selected_cards = []
var card_scene = preload("res://Scenes/Card.tscn")

func _ready():
	randomize()
	TARGET_TOTAL = POSSIBLE_TARGETS[randi() % POSSIBLE_TARGETS.size()]
	print("🎯 Target total this game:", TARGET_TOTAL)

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
	update_hand_sum_label()
	var discard_button = get_node("../DiscardButton")
	if discard_button == null:
		push_error("DiscardButton not found.")
	else:
		discard_button.disabled = true
		discard_button.pressed.connect(_on_discard_pressed)

	var win_label = get_node("../WinLabel")
	if win_label:
		win_label.visible = false

func _create_card_from_data(card_data):
	print("Card data received:", card_data)
	var card = card_scene.instantiate()
	add_child(card)
	card.position = Vector2(-500, HAND_Y)
	#card.scale = Vector2(2, 2)
	card.card_data = card_data

	var sprite = card.get_node("CardImage")
	if sprite:
		var tex = load(card_data.get("sprite_path", ""))
		if tex:
			sprite.texture = tex
		else:
			print("⚠️ Missing texture:", card_data.get("sprite_path", ""))
	else:
		print("❌ CardImage node not found in card scene!")

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

	update_hand_sum_label()
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

func calculate_hand_total() -> int:
	var total = 0
	for card in cards:
		if typeof(card.card_data) == TYPE_DICTIONARY:
			var name_str = card.card_data.get("name", "")
			if name_str == "":
				print("⚠️ Empty name in card_data!")
				continue

			var parts = name_str.split(" ")
			if parts.size() >= 1:
				var rank = parts[0].to_lower()
				if rank_values.has(rank):
					total += rank_values[rank]
				else:
					print("⚠️ Unknown rank:", rank)
			else:
				print("⚠️ Couldn't parse rank from name:", name_str)
		else:
			print("⚠️ card_data is NOT a dictionary!")
	return total

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
	update_hand_sum_label()

	var hand_total = calculate_hand_total()
	print("🧮 DEBUG Hand total:", hand_total, " Target:", TARGET_TOTAL)

	if hand_total == TARGET_TOTAL:
		print("🎉 You win! Total is", TARGET_TOTAL)
		var win_label = get_node("../WinLabel")
		if win_label:
			win_label.text = "🎉 You win! Total is " + str(TARGET_TOTAL)
			win_label.visible = true
	else:
		print("Keep discarding to reach", TARGET_TOTAL)


func update_hand_sum_label():
	var sum = calculate_hand_total()
	var label = get_node("../HandSumLabel")
	if label:
		label.text = "Sum: " + str(sum)
