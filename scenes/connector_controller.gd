extends Area2D

var parent_line = null  # Reference to the line this controller is associated with
@export var map_game: Node2D   # Reference to the MapGame script
enum Tools {MOVE, CONNECT, DISCONNECT}
@export var this_node: Area2D
# Called when the node enters the scene tree for the first time.
func _ready():
	map_game = get_parent().get_parent().get_parent().get_node("MapGame")
	parent_line = get_parent()
	set_process_input(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
			
# Assuming you have a visual representation (e.g., Sprite or ColorRect) for size reference
func get_global_rect() -> Rect2:
	var global_position = get_global_position()
	var shape = $CollisionShape2D.shape
	var radius = 0
	if shape is CircleShape2D:
		radius = shape.radius
	else:
		# Handle other shapes if necessary
		pass
	return Rect2(global_position - Vector2(radius, radius), Vector2(radius * 2, radius * 2))
