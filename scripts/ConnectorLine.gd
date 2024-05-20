extends Line2D

class_name MyConnectorLine

var origin_term_index: int = -1
var end_term_index: int = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func setup_connector(origin_index: int, end_index: int):
	origin_term_index = origin_index
	end_term_index = end_index

func get_connected_term_index() -> int:
	return end_term_index
