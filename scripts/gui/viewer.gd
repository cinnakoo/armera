extends VBoxContainer

var title: String

func set_title(album_title: String):
	title = album_title

	get_node("Title/Label").text = album_title

# Applies the ImageTexture onto the album art.
func set_album_art(texture: ImageTexture):
	get_node("Centerbox/Art").texture = texture

# Clear the album inspector.
func clear():
	var children = get_node("Scroller/List").get_children()

	if children.size() == 0:
		return
	
	for child in children:
		child.queue_free()
