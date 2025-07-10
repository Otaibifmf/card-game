extends Node2D

var card_being_dragged
var drag_offset = Vector2.ZERO


func _process(delta):
	if card_being_dragged:
		card_being_dragged.global_position = get_global_mouse_position() + drag_offset


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var card = raycast_check_for_card()
			if card:
				card_being_dragged = card
				drag_offset = card.global_position - get_global_mouse_position()
		else:
			card_being_dragged = null


func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
