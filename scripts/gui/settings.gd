extends ScrollContainer

onready var options = get_node("/root/Options")

onready var line = get_node("Vbox/Number/CenterContainer/Hbox/Line")

func _ready():
	line.connect("text_entered", self, "on_text_entered")

func on_text_entered(text: String):
	if not text.is_valid_integer():
		return

	options.limit = text
