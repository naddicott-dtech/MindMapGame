extends ColorRect


# Called when the node enters the scene tree for the first time.
func _ready():
	# Ensure it updates size when the window is resized
	get_tree().get_root().size_changed.connect(Callable(self, "_on_screen_resized"))
	size = get_viewport_rect().size
	pass # Replace with function body.

func _on_screen_resized():
	# Set size to match the entire 
	size = get_viewport_rect().size

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
