extends Tree

#For other examples of how to implement drag and drop, see:
# 1) https://godotengine.org/qa/19320/how-to-add-drag-and-drop-to-a-tree-node
# 2) https://www.youtube.com/watch?v=cNvzGKCkNXg
#var list_to_display = [{"text": "Alpha", "metadata": "Alpha_"},
#						{"text": "Beta", "metadata": "Beta_"},
#						{"text": "Gamma", "metadata": "Gamma_"},
#						{"text": "Delta", "metadata": "Delta_"}]
var list_to_display = []
var last_item = null

signal moved_item(item, from_index, to_index)

func _ready():
	refresh()

func refresh():
	display_list(list_to_display)

func display_list(list):
	clear()
	var root = create_item()
	var entry_index = 0
	for entry in list:
		var branch = create_item(root)
		branch.set_text(0, entry["text"])
		var meta = {}
		meta["index"] = entry_index
		meta["listed_object"] = entry["metadata"]
		branch.set_metadata(0, meta)
		last_item = branch
		entry_index += 1

func get_drag_data(position): # begin drag
	set_drop_mode_flags(DROP_MODE_INBETWEEN)
	var preview = Label.new()
	preview.text = "  " + get_selected().get_text(0)
	set_drag_preview(preview) # This will set the preview label to hover near the cursor while dragging an element.
	return get_selected() # TreeItem

func can_drop_data(position, data):
	var shift = get_drop_section_at_position(position)
	var check = (data is TreeItem and -1 == shift or 1 == shift)
	return data is TreeItem

func drop_data(position, item): # end drag
	var from_index = item.get_metadata(0)["index"]
	var shift = get_drop_section_at_position(position)
	var to_index = -1
	match shift:
		-1:
			#Dropping element before another element.
			to_index = get_item_at_position(position).get_metadata(0)["index"]
		1:
			#Dropping element after another element.
			to_index = get_item_at_position(position).get_metadata(0)["index"] + 1
	if (0 <= to_index):
		var relocated_object = item.get_metadata(0)["listed_object"]
		emit_signal('moved_item', relocated_object, from_index, to_index)
		# Rearrange list.
		var element = list_to_display.pop_at(from_index)
		if (to_index > from_index):
			to_index = to_index - 1
		if (to_index < list_to_display.size()):
			list_to_display.insert(to_index, element)
		else:
			list_to_display.append(element)
		display_list(list_to_display)

func get_selected_metadata():
	#Returns the element stored as metadata in the currently selected list item.
	var selection = get_selected()
	if (null != selection and selection is TreeItem):
		return selection.get_metadata(0)["listed_object"]
	else:
		return null

func select_first_item():
	var treeitem = get_root().get_children()
	if (null != treeitem):
		treeitem.select(0)

func select_last_item():
	if (null != last_item):
		last_item.select(0)

func replace_item(object, replacement, unique_rows = true):
	for row in list_to_display:
		if (object == row["metadata"]):
			row["metadata"] = replacement
			if (unique_rows):
				break
