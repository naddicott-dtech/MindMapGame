extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	if theme == null:
		var new_theme := Theme.new()
		theme = new_theme
	# create a Dynamic font
	var font = FontFile.new()
	# Load the font data from ttf file
	font.font_data = load("res://Arial_Bold.ttf")
	#set the font size
	font.set_extra_spacing(1,TextServer.SPACING_TOP, 2)
	font.set_extra_spacing(1,TextServer.SPACING_GLYPH, 1)
	theme.set_font("normal_font", "RichTextLabel", font)
	theme.set_font_size("normal_font_size", "RichTextLabel", 20)
		
	# Set the text color to black
	var new_color = Color(0, 0, 0, 1) #Black color
	theme.set_color("default_color", self.get_class(), new_color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
