extends Node2D

# Assignable Properties
var category_ranks: Dictionary = {}
var term_ranks: Dictionary = {}
var term_index: int = 0
var term_level: int = 0

var drag_offset = Vector2()
var dragging = false
var original_z_index = 0
var num_drops = 0
var MapGame = null
var old_global_position = Vector2()

enum Tools {MOVE, CONNECT, DISCONNECT}
var current_tool = Tools.MOVE

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true)
	
func _input(event):
	if current_tool == Tools.MOVE:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			# Get the term's global Rect2
			var term_rect = get_global_rect()
			# Check if the click is within the bounds of the ColorRect
			if event.pressed and term_rect.has_point(event.global_position):
				if MapGame.active_term != null and MapGame.active_term != self:
					return # ignore the click because another term is already active
				MapGame.set_active_term(self)
				drag_offset = to_local(term_rect.position) - to_local(event.global_position)
				dragging = true
				#print("Dragging: ", dragging)
				# Optionally, raise to ensure it's drawn on top while moving
				z_index = 1000 # temporarily set a high z_index to draw it on top
			elif not event.pressed and dragging:
				dragging = false
				MapGame.clear_active_term()
				#print("Dragging: ", dragging)
				z_index = original_z_index + num_drops
				num_drops += 1

		if event is InputEventMouseMotion and dragging:
			old_global_position = global_position
			if event.global_position:
				global_position = event.global_position + drag_offset
				update_connected_lines_position()
			#print("Dragging: ", dragging, " Position: ", global_position)
func update_connected_lines_position():
	#notify MapGame.gd to update the lines connected to this term
	if MapGame:
		MapGame.update_lines_for_term(self)

func get_global_rect() -> Rect2:
	var color_rect = get_node("ColorRect") as ColorRect
	var rect_pos = color_rect.global_position
	var rect_size = color_rect.size
	return Rect2(rect_pos, rect_size)

func set_text(content: String):
	var rich_text_label = get_node("RichTextLabel") as RichTextLabel
	rich_text_label.bbcode_text = content

func connect_to(other_term: Node2D):
	var line = get_node("Line2D") as Line2D
#	line.points = PoolVector2Array([position, other_term.position])
# note to self - create a PoolVector2Array function later

func set_tool_mode(new_mode: String):
	if new_mode == "move":
		current_tool = Tools.MOVE
	elif new_mode == "connect":
		current_tool = Tools.CONNECT	
	elif new_mode == "disconnect":
		current_tool == Tools.DISCONNECT

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
