extends Node

var cards = []
var deck = []

func _ready():
	_init_deck()
	shuffle_deck()

func _init_deck():
	var suits = ["clubs", "spades", "hearts", "diamonds"]
	var ranks = ["ace", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]

	for suit in suits:
		for rank in ranks:
			var filename = "%s_of_%s.png" % [rank, suit]
			var card_data = {
				"name": "%s of %s" % [rank.capitalize(), suit.capitalize()],
				"sprite_path": "res://assets/cards/%s" % filename
			}
			cards.append(card_data)

	deck = cards.duplicate()

func shuffle_deck():
	deck.shuffle()

func draw_card():
	if deck.is_empty():
		print("Deck is empty!")
		return null
	return deck.pop_back()
