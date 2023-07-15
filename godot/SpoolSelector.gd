extends Control

var storyworld = null
var selected_pointer = null
var allow_negation = false

signal spool_selected(selected_pointer)

func _ready():
	pass

func fill_spool_selection_list(selector):
	selector.clear()
	if (null == storyworld or storyworld.spools.empty()):
		return false
	var option_index = 0
	var selected_index = 0
	for spool in storyworld.spools:
		selector.add_item(spool.spool_name)
		selector.set_item_metadata(option_index, spool)
		if (selected_pointer is SpoolPointer or selected_pointer is SpoolStatusPointer):
			if (selected_pointer.spool == spool):
				selected_index = option_index
		option_index += 1
	selector.select(selected_index)
	return true

func reset(pointer_type = "SpoolPointer"):
	#This function resets the selected property to default, or creates a new property if necessary.
	#Since this is a temporary pointer used by the interface, we need not set the "parent_operator" property of the pointer.
	if (null != storyworld and storyworld is Storyworld):
		if (!storyworld.spools.empty()):
			if (null != selected_pointer and is_instance_valid(selected_pointer) and selected_pointer is SWPointer):
				if (selected_pointer is SpoolPointer):
					selected_pointer.spool = storyworld.spools[0]
				elif (selected_pointer is SpoolStatusPointer):
					selected_pointer.spool = storyworld.spools[0]
					selected_pointer.negated = false
			else:
				if ("SpoolPointer" == pointer_type):
					selected_pointer = SpoolPointer.new(storyworld.spools[0])
				elif ("SpoolStatusPointer" == pointer_type):
					selected_pointer = SpoolStatusPointer.new(storyworld.spools[0], false)

func refresh():
	#This function refreshes the interface.
	#The reset() function should be called at least once before this function, to create a bounded number property and initialize the editor.
	if (null == storyworld or storyworld.spools.empty()):
		return false
	fill_spool_selection_list($Panel/HBC/SpoolSelectionList)
	if (allow_negation):
		$Panel/HBC/Label.visible = false
		$Panel/HBC/NegateButton.visible = true
		if (selected_pointer is SpoolStatusPointer):
			if (selected_pointer.negated):
				$Panel/HBC/NegateButton.text = " is not active"
			else:
				$Panel/HBC/NegateButton.text = " is active"
	else:
		$Panel/HBC/Label.visible = true
		$Panel/HBC/NegateButton.visible = false

func _on_SpoolSelectionList_item_selected(index):
	var metadata = $Panel/HBC/SpoolSelectionList.get_item_metadata(index)
	if (metadata is Spool):
		selected_pointer.spool = metadata
		emit_signal("spool_selected", selected_pointer)

func _on_NegateButton_pressed():
	if (selected_pointer is SpoolStatusPointer):
		if (selected_pointer.negated):
			selected_pointer.negated = false
			$Panel/HBC/NegateButton.text = " is active"
			emit_signal("spool_selected", selected_pointer)
		else:
			selected_pointer.negated = true
			$Panel/HBC/NegateButton.text = " is not active"
			emit_signal("spool_selected", selected_pointer)
	else:
		$Panel/HBC/Label.visible = true
		$Panel/HBC/NegateButton.visible = false
