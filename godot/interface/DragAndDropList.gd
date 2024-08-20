extends Tree

var items_to_list = []
var last_treeitem = null
var item_count = 0
var context_menu_enabled = false
var item_type = "" #Used by context menu.
var focused_item = null
var clipboard = null

signal item_moved(item, from_index, to_index)
signal add_at(index)
signal cut(items)
signal copy(items)
signal paste_at(index)
signal delete(items)
signal duplicate(items)
signal edit_visibility_script(option)
signal edit_performability_script(option)
signal edit_desirability_script(reaction)
signal edit_effect_script(effect)

func _ready():
	refresh()

func list_item(item):
	var branch = create_item(get_root())
	branch.set_text(0, item.get_listable_text(500))
	branch.set_tooltip_text(0, item.get_listable_text(500))
	var meta = {}
	meta["index"] = item_count
	meta["listed_object"] = item
	branch.set_metadata(0, meta)
	last_treeitem = branch
	item_count += 1

func refresh():
	clear()
	create_item()
	last_treeitem = null
	item_count = 0
	for item in items_to_list:
		list_item(item)

func _get_drag_data(position): # begin drag
	set_drop_mode_flags(DROP_MODE_INBETWEEN)
	var preview = Label.new()
	preview.text = "  " + get_selected().get_text(0)
	set_drag_preview(preview) # This will set the preview label to hover near the cursor while dragging an element.
	return get_selected() # TreeItem

func _can_drop_data(position, data):
	var shift = get_drop_section_at_position(position)
	var check = (data is TreeItem and -1 == shift or 1 == shift)
	return data is TreeItem

func _drop_data(position, item): # end drag
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
		item_moved.emit(relocated_object, from_index, to_index)
		# Rearrange list.
		var element = items_to_list.pop_at(from_index)
		if (to_index > from_index):
			to_index = to_index - 1
		if (to_index < items_to_list.size()):
			items_to_list.insert(to_index, element)
		else:
			items_to_list.append(element)
		refresh()
		select_linked_item(element)

func get_first_selected_metadata():
	#Returns the element stored as metadata in the first currently selected list item.
	var selected_item = get_next_selected(null)
	if (selected_item is TreeItem):
		return selected_item.get_metadata(0)["listed_object"]
	else:
		return null

func get_first_selected_index():
	#Returns the index of the first currently selected list item.
	var selected_item = get_next_selected(null)
	if (selected_item is TreeItem):
		return selected_item.get_metadata(0)["index"]
	else:
		return null

func get_all_selected_metadata():
	#Returns the element stored as metadata in the first currently selected list item.
	var selected_item = get_next_selected(null)
	var metadata = []
	while (null != selected_item):
		metadata.append(selected_item.get_metadata(0)["listed_object"])
		selected_item = get_next_selected(selected_item)
	return metadata

func select_first_item():
	var treeitem = get_root().get_first_child()
	if (null != treeitem):
		treeitem.select(0)

func select_last_item():
	if (null != last_treeitem):
		last_treeitem.select(0)

func select_linked_item(search_term):
	#Finds and selects the treeitem associated with an option, reaction, effect, or other object.
	var branch = get_root().get_first_child()
	while (null != branch):
		if (search_term == branch.get_metadata(0)["listed_object"]):
			branch.select(0)
			break
		branch = branch.get_next()

func select_only_linked_item(search_term):
	#Selects the linked item while deselecting all other items.
	var branch = get_root().get_first_child()
	while (null != branch):
		if (search_term == branch.get_metadata(0)["listed_object"]):
			branch.select(0)
		else:
			branch.deselect(0)
		branch = branch.get_next()

func select_all():
	var branch = get_root().get_first_child()
	while (null != branch):
		branch.select(0)
		branch = branch.get_next()

func raise_selected_item():
	var index = get_first_selected_index()
	if (0 < index and index < items_to_list.size()):
		var swap = items_to_list[index]
		items_to_list[index] = items_to_list[index - 1]
		items_to_list[index - 1] = swap
		refresh()
		select_linked_item(swap)
		item_moved.emit(swap, index, index - 1)

func lower_selected_item():
	var index = get_first_selected_index()
	if (index < (items_to_list.size() - 1)):
		var swap = items_to_list[index]
		items_to_list[index] = items_to_list[index + 1]
		items_to_list[index + 1] = swap
		refresh()
		select_linked_item(swap)
		item_moved.emit(swap, index, index + 2)

func can_paste():
	if (clipboard.clipped_copies.is_empty()):
		return false
	elif (clipboard.clipped_copies.front() is Option and "option" == item_type):
		return true
	elif (clipboard.clipped_copies.front() is Reaction and "reaction" == item_type):
		return true
	elif (clipboard.clipped_copies.front() is SWEffect and "effect" == item_type):
		return true
	else:
		return false

func _on_item_rmb_selected(position):
	if (context_menu_enabled):
		focused_item = get_item_at_position(position).get_metadata(0)["listed_object"]
		# Bring up context menu.
		var mouse_position = get_global_mouse_position()
		var context_menu = $ContextMenu
		context_menu.clear()
		if ("option" == item_type or "reaction" == item_type):
			context_menu.add_item("Add " + item_type + " before this", 0)
			context_menu.add_item("Add " + item_type + " after this", 1)
		context_menu.add_item("Cut", 3)
		context_menu.add_item("Copy", 4)
		context_menu.add_item("Paste before this", 5)
		context_menu.add_item("Paste after this", 6)
		if (!can_paste()):
			#Disable pasting options.
			context_menu.set_item_disabled((context_menu.get_item_count() - 1), true)
			context_menu.set_item_disabled((context_menu.get_item_count() - 2), true)
		context_menu.add_item("Delete", 8)
		context_menu.add_item("Duplicate", 9)
		context_menu.add_item("Select all", 10)
		context_menu.add_item("Deselect all", 11)
		if ("option" == item_type):
			context_menu.add_item("Edit visibility script", 12)
			context_menu.add_item("Edit performability script", 13)
			#context_menu.add_item("Inspect option internals", 16)
		if ("reaction" == item_type):
			context_menu.add_item("Edit desirability script", 14)
		if ("effect" == item_type):
			context_menu.add_item("Edit effect script", 15)
		context_menu.popup(Rect2(mouse_position.x, mouse_position.y, context_menu.size.x, context_menu.size.y))

func _on_item_mouse_selected(position, mouse_button_index):
	if (MouseButton.MOUSE_BUTTON_RIGHT == mouse_button_index):
		_on_item_rmb_selected(position)

func show_outer_context_menu():
	# This shows the context menu that is designed for when the user clicks the empty part of the tree.
	focused_item = null
	# Bring up context menu.
	var mouse_position = get_global_mouse_position()
	var context_menu = $ContextMenu
	context_menu.clear()
	if ("option" == item_type or "reaction" == item_type):
		context_menu.add_item("Add new " + item_type, 2)
	context_menu.add_item("Paste", 7)
	if (!can_paste()):
		# Disable pasting options.
		context_menu.set_item_disabled((context_menu.get_item_count() - 1), true)
	context_menu.add_item("Select all", 10)
	context_menu.add_item("Deselect all", 11)
	#context_menu.set_as_minsize()
	context_menu.popup(Rect2(mouse_position.x, mouse_position.y, context_menu.size.x, context_menu.size.y))

func _on_empty_clicked(position, mouse_button_index):
	if (MouseButton.MOUSE_BUTTON_RIGHT == mouse_button_index and context_menu_enabled):
		show_outer_context_menu()

func _on_ContextMenu_id_pressed(id):
	var index = 0
	if (null != focused_item):
		if (focused_item is Option or focused_item is Reaction or focused_item is SWEffect):
			index = focused_item.get_index()
	match id:
		0:
			# Add new item before
			add_at.emit(index)
			print ("Adding new " + item_type + " before the selected one.")
		1:
			# Add new item after
			add_at.emit(index + 1)
			print ("Adding new " + item_type + " after the selected one.")
		2:
			# Add new item at end of list
			add_at.emit(item_count)
			print ("Adding new " + item_type + " at the end of the list.")
		3:
			# Cut
			cut.emit(get_all_selected_metadata())
			print ("Cutting selected " + item_type + " for pasting.")
		4:
			# Copy
			copy.emit(get_all_selected_metadata())
			print ("Copying selected " + item_type + ".")
		5:
			# Paste before
			paste_at.emit(index)
			print ("Pasting before selected " + item_type + ".")
		6:
			# Paste after
			paste_at.emit(index + 1)
			print ("Pasting after selected " + item_type + ".")
		7:
			# Paste at end of list
			paste_at.emit(item_count)
			print ("Pasting at the end of the list.")
		8:
			# Delete
			delete.emit(get_all_selected_metadata())
			print ("Asking for confirmation for possible deletion of " + item_type + "s.")
		9:
			# Duplicate
			duplicate.emit(get_all_selected_metadata())
			print ("Duplicating selected " + item_type + "s.")
		10:
			# Select all
			select_all()
			print ("Selecting all " + item_type + "s.")
		11:
			# Deselect all
			deselect_all()
			print ("Deselecting all " + item_type + "s.")
		12:
			# Edit visibility script
			edit_visibility_script.emit(focused_item)
			print ("Editing visibility script.")
		13:
			# Edit performability script
			edit_performability_script.emit(focused_item)
			print ("Editing performability script.")
		14:
			# Edit desirability script
			edit_desirability_script.emit(focused_item)
			print ("Editing desirability script.")
		15:
			# Edit effect script
			edit_effect_script.emit(focused_item)
			print ("Editing effect script.")
		16:
			# Inspect item internals
			if (null == focused_item):
				print ("Item is null.")
			elif (!(is_instance_valid(focused_item))):
				print ("Item is invalid.")
			elif (focused_item is Option):
				if (null == focused_item.encounter):
					print ("null == focused_item.encounter")
				elif (focused_item.encounter is Encounter):
					print ("focused_item.encounter: " + focused_item.encounter.id)
			else:
				print ("Item is not the correct type.")
