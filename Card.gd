extends Node2D

signal pressed
signal hovered
signal hovered_off

var card_data = null

func _ready():
	$Area2D.mouse_entered.connect(_on_mouse_entered)
	$Area2D.mouse_exited.connect(_on_mouse_exited)
	$Area2D.input_event.connect(_on_input_event)

func _on_mouse_entered():
	emit_signal("hovered", self)

func _on_mouse_exited():
	emit_signal("hovered_off", self)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("🟥 Card clicked:", self.name)
		emit_signal("pressed", self)
