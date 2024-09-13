extends Node2D
# the path to the JSON file
#var json_path = "res://data/NeuronsData.json"
var json_path = "res://data/Metabolism.json"
var term_scene_path = "res://scenes/Term.tscn"
var connector_line_scene_path = "res://scenes/ConnectorLine.tscn"
enum Tools {MOVE, CONNECT, DISCONNECT}
var current_tool = Tools.MOVE
var first_clicked_term = null
var line_in_progress = null
var term_connections = {}
var active_term = null

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true)
	var json_data = load_and_parse_json()
	if json_data != null:
		process_json(json_data)
	var move_tool_button = get_node("UI/CenterContainer/VBoxContainer/HBoxContainer/MoveToolButton")
	move_tool_button.grab_focus() # this makes the 'Move Tool" button the focused button
	# instantiate_term("Example Term", Vector2(200,200))

# Function to load content from a JSON file
func load_and_parse_json():
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close() #explicitly close the file
		
		var my_json := JSON.new()
		var parse_result := my_json.parse(json_text)
		if parse_result == OK:
			return my_json.get_data() #successfully parsed JSON data
		else:
			print(parse_result)
			print("Failed to parse JSON " , my_json.get_error_message(), " in ", json_text, " at line ", my_json.get_error_line())
	else:
		print("filed to open file at path:", json_path)
	return null
	
# Placeholder function to do something with parsed data
func process_json(json_data):
	var current_position = Vector2(50, 50)
	var term_offset = Vector2(0, 60)
	var column_width = 150 # width of each term
	var screen_height = DisplayServer.screen_get_size().y # get the window height
	var term_index = 0
	var term_level = 0
	var term_category_ranks = {"cat 1": 1.0, "cat 2": 0.5}
	var term_term_ranks = {"term 1": 1.0, "term 2": 0.5}

	if json_data.size() > 0:
		var just_items = json_data["just_items"]
		var item_data = json_data["item_data"]

		if just_items.size() > 0:
			for i in range(just_items.size()):
				var term_name = just_items[i]
				var term_dict = null
				# find the dictionary for the term
				for data in item_data:
					if data["name"] == term_name:
						term_dict = data
						break
				# if term data was found, get the details
				if term_dict:
					# print("found term_dict for:", term_name)
					term_index = i # the loop index is the term index
					if(int(term_dict["level"])):
						term_level = int(term_dict["level"])
					if(term_dict["categories"]):
						term_category_ranks = term_dict["categories"]
					if(term_dict["relatedness"]):
						term_term_ranks = term_dict["relatedness"]
					# print("Term details - level:", term_level, "Categories:", term_category_ranks, "Relatedness:", term_term_ranks)
				else:
					# handle missing term data
					print("Missing data for:", term_name)
					continue

				# Debugging output
				#print("Processing term:", term_name)
				#print("Level:", term_level)
				#print("Categories:", term_category_ranks)
				#print("Relatedness:", term_term_ranks)

				if current_position.y + term_offset.y > screen_height:
					# start a new column
					current_position.y = term_offset.y
					current_position.x += column_width
				current_position += term_offset # staggered position
				instantiate_term(term_name, current_position, term_index, term_level, term_category_ranks, term_term_ranks)
				term_connections[i] = {"start_lines": [], "end_lines": []}

func instantiate_term(term_name: String, my_position: Vector2, index: int, level: int, category_ranks: Dictionary, term_ranks: Dictionary):
	var term_scene: PackedScene = load(term_scene_path)
	if term_scene:
		var term_instance = term_scene.instantiate()
		add_child(term_instance)
		term_instance.position = my_position
		term_instance.get_node("RichTextLabel").text = term_name #set the term name
		term_instance.term_index = index
		term_instance.term_level = level
		term_instance.category_ranks = category_ranks
		term_instance.term_ranks = term_ranks
		term_instance.add_to_group("terms") #add to the group "terms"
		term_instance.MapGame = self
# Called every frame. 'delta' is the elapsed time since the previous frame.

func instantiate_connector_line() -> MyConnectorLine:
	var connector_line_scene = preload("res://scenes/ConnectorLine.tscn")
	var connector_line = connector_line_scene.instantiate() as MyConnectorLine
	# set up connector line with additional properties if necessary
	return connector_line
	

func _process(delta):
	pass

func _input(event):
	if current_tool == Tools.MOVE:
		pass # done in script for items
	elif current_tool == Tools.CONNECT:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var clicked_term = get_clicked_term(event.position)
#			var clicked_name = clicked_term.get_node("RichTextLabel").text
#			print("clicked ", clicked_name)
			if clicked_term != null:
				if not first_clicked_term:
					#this is first click, start the line
					first_clicked_term = clicked_term
					line_in_progress = instantiate_connector_line()
					first_clicked_term.add_child(line_in_progress)
					line_in_progress.setup_connector(first_clicked_term.term_index, -1)
					line_in_progress.width = 2 # set the width
					line_in_progress.z_index = 0 # behind the terms
					line_in_progress.add_point(first_clicked_term.get_local_mouse_position())
					line_in_progress.add_point(first_clicked_term.get_local_mouse_position())
				else: #second click, finish line
					var second_clicked_term = clicked_term
					if second_clicked_term != first_clicked_term:
						#check if a connection already exists between the two terms
						var connection_exists = false
						for line in term_connections[first_clicked_term.term_index]["start_lines"]:
							if line.end_term_index == second_clicked_term.term_index:
								connection_exists = true
								# cancel the line, putting the user back to first click
								first_clicked_term.remove_child(line_in_progress)
								line_in_progress.queue_free()
								line_in_progress = null
								first_clicked_term = null
								break
						if not connection_exists:
							line_in_progress.set_point_position(1, second_clicked_term.global_position - first_clicked_term.get_global_position())
							line_in_progress.setup_connector(first_clicked_term.term_index, second_clicked_term.term_index)
							#update global connections
							term_connections[first_clicked_term.term_index]["start_lines"].append(line_in_progress)
							term_connections[second_clicked_term.term_index]["end_lines"].append(line_in_progress)
							update_line_positions(line_in_progress, first_clicked_term, second_clicked_term)
							# set up signaling for dragging around
							# set up updating dictionary / list of connections
							#reset for next connection
							first_clicked_term = null
							line_in_progress = null
			elif first_clicked_term and line_in_progress:
				# we didn't click a term
				first_clicked_term.remove_child(line_in_progress)
				line_in_progress.queue_free()
				line_in_progress = null
				first_clicked_term = null
		else: #input was not a mouse button
			#handle movement mid-line creation
			if first_clicked_term and line_in_progress:
				if event is InputEventMouseMotion :
					if event.global_position:
						line_in_progress.set_point_position(1, first_clicked_term.to_local(event.global_position))
	elif current_tool == Tools.DISCONNECT:
		# disconnect logic
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			var clicked_term = get_clicked_term(event.position)
			if clicked_term != null:
				disconnect_term(clicked_term)

func update_lines_for_term(changed_term):
	# move start and end points of lines where this term is the start
	for line in term_connections[changed_term.term_index]["start_lines"]:
		# Calculate the previous global position of the line's start point
		# Get the end term node using the term index stored in the line
		var end_term = get_term_instance_by_index(line.get_connected_term_index())
		if end_term:
			update_line_positions(line, changed_term, end_term)
			line.z_index = 0
	# move end points of lines wher ethis term is the end
	for line in term_connections[changed_term.term_index]["end_lines"]:
		var start_term = get_term_instance_by_index(line.origin_term_index)
		if start_term:
			update_line_positions(line, start_term, changed_term)
			line.z_index = 0
		
func calculate_score():
	var base_score = 10
	var total_connections = 0
	var terms_count = term_connections.size()
	var penalty_for_low_relatedness = 0.75 # penalty for low relatedness
	var high_relatedness_bonus = 1.5 # bonus multiplier for high relatedness connections
	var high_relatedness_value = 0.9
	var base_score_per_high_relatedness_connection = high_relatedness_value * 10 * high_relatedness_bonus
	
	# OLD Hypothetical very high score calculation (for normalizing later)
	#var hypothetical_max_connections = terms_count # assuming one high quality connection per term
	#var a_very_high_score = base_score + hypothetical_max_connections * base_score_per_high_relatedness_connection
	var a_very_high_score = base_score
	for term_index in term_connections:
		var term_instance = get_term_instance_by_index(term_index)
		var max_relatedness = 0.0
		
		#loop through all other terms to find the most related non-self term
		for other_term_index in term_connections:
			if other_term_index != term_index:
				var relatedness = get_relatedness(term_index, other_term_index)
				if relatedness > max_relatedness:
					max_relatedness = relatedness
		
		#add the contribution of the most related term to the very high score
		if max_relatedness > high_relatedness_value: # if relatedness qualifies as high
			a_very_high_score += max_relatedness * 10 * high_relatedness_bonus
		else:
			#apply a default contribution if not high relatedness connection is found
			a_very_high_score += max_relatedness * 5 #assuming max was better than 0.3
	# The a_very_high_score now reflects the sume of the base score and all the best possible single connections
	
	# Calculate base score from connections
	for term_index in term_connections:
		var term_data = term_connections[term_index]
		for connection in term_data["start_lines"]:
			var end_term_index = connection.get_connected_term_index()
			var relatedness = get_relatedness(term_index, end_term_index)
			if relatedness > 0.8: # considered high relatedness
				base_score += relatedness * 10 * high_relatedness_bonus
			elif relatedness < 0.3: # considered low relatedness
				base_score -= (1 - relatedness) * 10 * penalty_for_low_relatedness
			else:
				base_score += relatedness * 5
			
			# Extra credit for heiarchal (sp?) level connections
			var origin_level = get_level(term_index)
			var end_level = get_level(end_term_index)
			if origin_level == 1 and end_level == 2: #top level to mid level
				base_score +=5 #extra credit for 1->2 connection
			elif origin_level == 2 and end_level == 3:
				base_score +=2 #extra credit for 2->3 connection
			
			total_connections += 1
	# Calculate complexity penalty
	var penalty_threshold = terms_count * 1.1
	var complexity_penalty_multiplier = 1.0
	if total_connections > penalty_threshold:
		var excess_connections = total_connections - penalty_threshold
		complexity_penalty_multiplier = max(0.1, 1 - excess_connections / (terms_count * 1.1))
		
	var final_score = base_score * complexity_penalty_multiplier
	# final_score = round(final_score * 10) / 10  # Rounds to one decimal place
	print("final score: ", final_score)
	print("a very high score: ", a_very_high_score)
	
	# Normalization
	var normalized_score = (final_score / a_very_high_score) * 1000
	normalized_score = round(normalized_score *10) / 10 #round normalized score to one decimal
	print("normalized_score: ", normalized_score)
	return normalized_score

func get_relatedness(term_index_1, term_index_2) -> float:
	#retrieve the term instances from the scene tree
	var term_instance_1 = get_term_instance_by_index(term_index_1)
	var term_instance_2 = get_term_instance_by_index(term_index_2)
	
	# retrieve the name of term 2 to use it as a key in the term_ranks of term 1.
	var term_2_name = term_instance_2.get_node("RichTextLabel").text
	
	# get the relatedness value from term 1's term ranks.
	var relatedness = 0.1
	if term_2_name in term_instance_1.term_ranks:
		relatedness = term_instance_1.term_ranks[term_2_name]
	else:
		relatedness = 0.1
	return relatedness

func get_level(term_index: int) -> int:
	var term_instance = get_term_instance_by_index(term_index)
	if term_instance != null:
		return term_instance.term_level
	return -1 # In case the term doesn't exist or something went wrong

func get_term_instance_by_index(desired_term_index: int) -> Node:
	var terms = get_tree().get_nodes_in_group("terms")
	#assuming all terms are children of this node
	for term in terms:
		if term.term_index == desired_term_index:
			return term
	return null

func _on_move_tool_button_pressed():
	current_tool = Tools.MOVE
	for term in get_tree().get_nodes_in_group("terms"):
		term.set_tool_mode("move")
	# calculate_score()

func _on_connect_terms_tool_button_pressed():
	current_tool = Tools.CONNECT
	for term in get_tree().get_nodes_in_group("terms"):
		term.set_tool_mode("connect")

func get_clicked_term(click_position) -> Node2D:
	for term in get_tree().get_nodes_in_group("terms"):
		if term.get_global_rect().has_point(click_position):
			# print(term.name)
			return term
	return null

func _on_calculate_score_button_pressed():
	var score = calculate_score()
	$UI/Score/ScoreBox.text = "Score: " + str(score)
	$UI/Score/ScoreBox.visible = true


func _on_disconnect_pressed():
	current_tool = Tools.DISCONNECT
	for term in get_tree().get_nodes_in_group("terms"):
		term.set_tool_mode("disconnect")

func set_active_term(term: Node2D):
	active_term = term

func clear_active_term():
	active_term = null

func disconnect_term(term: Node2D):
	var term_index = term.term_index
	var to_free = []

	# Gather lines connected to the term to be freed.
	for line in term_connections[term_index]["start_lines"]:
		to_free.append(line)
	for line in term_connections[term_index]["end_lines"]:
		to_free.append(line)

	# Clear the references in the current term's connection data.
	term_connections[term_index]["start_lines"] = []
	term_connections[term_index]["end_lines"] = []

	# Remove references in other terms' connection data where this term is involved.
	for other_term_index in term_connections:
		if other_term_index == term_index:
			continue  # Skip the current term.

		# Filter out the disconnected lines from start lines.
		var filtered_start_lines = []
		for line in term_connections[other_term_index]["start_lines"]:
			if not line in to_free:
				filtered_start_lines.append(line)
		term_connections[other_term_index]["start_lines"] = filtered_start_lines

		# Filter out the disconnected lines from end lines.
		var filtered_end_lines = []
		for line in term_connections[other_term_index]["end_lines"]:
			if not line in to_free:
				filtered_end_lines.append(line)
		term_connections[other_term_index]["end_lines"] = filtered_end_lines

	# Now free the lines after they've been removed from all references.
	for line in to_free:
		if is_instance_valid(line):
			line.queue_free()

#function to calculate hot points for a given term node
func get_hot_points(node):
	var rect_size = node.get_node("ColorRect").size
	var points = []
	# print(node.position)
	#centers
	points.append(node.position + Vector2(rect_size.x / 2, 0)) # top center
	points.append(node.position + Vector2(rect_size.x / 2, rect_size.y)) #bottom center
	points.append(node.position + Vector2(0, rect_size.y / 2))  # Left center
	points.append(node.position + Vector2(rect_size.x, rect_size.y / 2))  # Right center
	#corners
	points.append(node.position)  # Top left
	points.append(node.position + Vector2(rect_size.x, 0))  # Top right
	points.append(node.position + Vector2(0, rect_size.y))  # Bottom left
	points.append(node.position + Vector2(rect_size.x, rect_size.y))  # Bottom right
	# print(points)
	return points

func update_line_positions(line, start_node, end_node):
	var start_points = get_hot_points(start_node)
	var end_points = get_hot_points(end_node)
	var min_distance = 2000.0 #start with a large number
	var best_start_point = start_points[0]
	var best_end_point = end_points[0]
	
	for point1 in start_points:
		for point2 in end_points:
			var distance = point1.distance_to(point2)
			# print("Checking distance: ", distance)  # Debugging output
			if distance < min_distance:
				min_distance = distance
				best_start_point = point1
				best_end_point = point2
				# print("New min distance: ", min_distance, " between ", best_start_point, " and ", best_end_point)  # Debugging output

	if line.get_parent():
		best_start_point = line.get_parent().to_local(best_start_point)
		best_end_point = line.get_parent().to_local(best_end_point)
		
	# Set the line's points
	if line.get_parent():
		line.points[0] = best_start_point
		line.points[1] = best_end_point
