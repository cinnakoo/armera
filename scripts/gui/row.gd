extends HBoxContainer

var metadata

func set_title(title: String):
	get_node("Label").text = title

func set_flip_visibility(hidden: bool):
	get_node("Flip").visible = hidden
