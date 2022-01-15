extends VBoxContainer

# Clear the search results.
func clear():
	var children: Array = get_node("Scroller/List").get_children()

	if children.size() == 0:
		return
	
	for child in children:
		child.queue_free()
