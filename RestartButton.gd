extends TextureButton

func _ready():
	# Always visible
	visible = true
	pressed.connect(_on_pressed)

func _on_pressed():
	get_tree().reload_current_scene()
