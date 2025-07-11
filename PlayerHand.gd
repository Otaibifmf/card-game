extends Node2D

const HAND_COUNT = 8
const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const CARD_WIDTH = 200
const HAND_Y_POSITION = 978
const HAND_CENTER_X = 941

var player_hand = []
var center_screen_x
var card_width = 200 

func _ready() -> void:
	var card_scene = preload(CARD_SCENE_PATH)
	for i in range(HAND_COUNT):
		var new_card = card_scene.instantiate()
		new_card.name = "Card"
		new_card.scale = Vector2.ONE
		
		var card_manager = get_node("../CardManager")
		card_manager.add_child(new_card)
		
		#var pos_x = calculate_card_position(i)
		#var pos_y = HAND_Y_POSITION
		#var new_position = Vector2(pos_x, pos_y)
		
		new_card.position = Vector2(941, -200)
		add_card_to_hand(new_card)
		
		print("Card #", i, "position set to:", new_card.position, " Global:", new_card.global_position)
	



func add_card_to_hand(card):
	if card not in player_hand:
		player_hand.insert(0, card)
		set_card_width()
		update_hand_positions()
	else:
		animate_card_to_position(card, card.hand_position)


func update_hand_positions():
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		print("Card position:", card.position, " global:", card.global_position)
		card.hand_position = new_position
		animate_card_to_position(card, new_position)

func calculate_card_position(index):
	var total_width = (HAND_COUNT - 1) * card_width
	var x_offset = HAND_CENTER_X + index * card_width - total_width / 2
	print("Calculated X for card ", index, ":", x_offset)
	return x_offset

func animate_card_to_position(card, new_position):
	var  tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.5)
	
	
func set_card_width():
	card_width = max(250 - (HAND_COUNT * 10),100)

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions()
