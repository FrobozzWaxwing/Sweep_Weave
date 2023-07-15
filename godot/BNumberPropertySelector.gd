extends Control

var storyworld = null
var selected_property = null
var allow_root_character_editing = true
var allow_coefficient_editing = false
var KeyringOptionButton = load("res://KeyringOptionButton.tscn")

signal bnumber_property_selected(selected_property)

func _ready():
	pass

func refresh_character_name(character):
	for index in range($Background/InverseParserHBC/RootCharacterSelector.get_item_count()):
		if ($Background/InverseParserHBC/RootCharacterSelector.get_item_metadata(index) == character):
			$Background/InverseParserHBC/RootCharacterSelector.set_item_text(index, character.char_name)
	for child in $Background/InverseParserHBC/KeyringBC.get_children():
		for index in range(child.get_item_count()):
			if (child.get_item_metadata(index) == character):
				child.set_item_text(index, character.char_name)

func fill_character_selector(keyring_index, selector):
	selector.clear()
	if (null == selected_property or 0 == selected_property.keyring.size() or null == storyworld or 0 == storyworld.characters.size()):
		return false
	# If keyring_index is -1, this fills the root character selector.
	var option_index = 0
	var selected_index = 0
	for character in storyworld.characters:
		selector.add_item(character.char_name)
		selector.set_item_metadata(option_index, character)
		if (-1 == keyring_index):
			if (selected_property.character == character):
				selected_index = option_index
		else:
			if (selected_property.keyring[keyring_index] == character.id):
				selected_index = option_index
		option_index += 1
	selector.select(selected_index)
	return true

func refresh():
	#This function refreshes the interface.
	#The reset() function should be called at least once before this function, to create a bounded number property and initialize the editor.
	if (null == selected_property or null == selected_property.character or 0 == selected_property.keyring.size() or null == storyworld):
		return false
	#Refresh character selector.
	$Background/InverseParserHBC/RootCharacterSelector.visible = allow_root_character_editing
	fill_character_selector(-1, $Background/InverseParserHBC/RootCharacterSelector)
	if (0 == selected_property.character.authored_property_directory.size()):
		$Background/InverseParserHBC/RootCharacterSelector.visible = false
		$Background/InverseParserHBC/NegateToggleButton.visible = false
		#The selected character has no authored properties associated with them.
		for child in $Background/InverseParserHBC/KeyringBC.get_children():
			child.queue_free()
		var warning_message = Label.new()
		warning_message.text = "No property selected."
		warning_message.hint_tooltip = "The selected character, \"" + selected_property.character.char_name + ",\" currently has no properties available to select."
		warning_message.set_mouse_filter(0)
		$Background/InverseParserHBC/KeyringBC.add_child(warning_message)
		return true
	#Refresh negation toggle button.
	$Background/InverseParserHBC/NegateToggleButton.visible = allow_coefficient_editing
	if (1 == selected_property.coefficient):
		$Background/InverseParserHBC/NegateToggleButton.text = " "
	elif (-1 == selected_property.coefficient):
		$Background/InverseParserHBC/NegateToggleButton.text = "-"
	#Refresh keyring selector.
	for child in $Background/InverseParserHBC/KeyringBC.get_children():
		child.queue_free()
	if (null == selected_property.get_ap_blueprint()):
		return false #An error occurred.
	var layers = selected_property.get_ap_blueprint().depth
	for keyring_index in range(layers + 1):
		if (0 == keyring_index):
			var selector = KeyringOptionButton.instance()
			selector.keyring_index = keyring_index
			var option_index = 0
			var selected_index = 0
			for key in selected_property.character.authored_property_directory.keys():
				var property_blueprint = selected_property.character.authored_property_directory[key]
				if (property_blueprint.attribution_target == property_blueprint.possible_attribution_targets.ENTIRE_CAST or property_blueprint.affected_characters.has(selected_property.character)):
					selector.add_item(property_blueprint.get_property_name())
					selector.set_item_metadata(option_index, property_blueprint)
					if (selected_property.keyring[keyring_index] == property_blueprint.id):
						selected_index = option_index
					option_index += 1
			selector.select(selected_index)
			selector.connect("keyring_change_requested", self, "change_keyring")
			$Background/InverseParserHBC/KeyringBC.add_child(selector)
		elif (1 <= keyring_index):
			var selector = KeyringOptionButton.instance()
			selector.keyring_index = keyring_index
			fill_character_selector(keyring_index, selector)
			selector.connect("keyring_change_requested", self, "change_keyring")
			$Background/InverseParserHBC/KeyringBC.add_child(selector)
	return true

func change_keyring(keyring_index, option_index, option_metadata):
	if (0 == keyring_index):
		selected_property.keyring = []
		selected_property.keyring.append(option_metadata.id)
		for layer in range(storyworld.authored_property_directory[option_metadata.id].depth):
			if (0 < storyworld.characters.size()):
				selected_property.keyring.append(storyworld.characters[0].id)
		refresh()
	elif (0 < keyring_index and option_metadata is Actor):
		selected_property.keyring[keyring_index] = option_metadata.id
	emit_signal("bnumber_property_selected", selected_property)

func reset():
	#This function resets the selected property to default, or creates a new property if necessary.
	if (storyworld is Storyworld):
		if (0 < storyworld.characters.size() and 0 < storyworld.authored_property_directory.size()):
			if (null != selected_property and is_instance_valid(selected_property)):
				var temporary = storyworld.create_default_bnumber_pointer()
				selected_property.set_as_copy_of(temporary)
				temporary.call_deferred("free")
			else:
				selected_property = storyworld.create_default_bnumber_pointer()
				#Since this is a temporary pointer used by the interface, we need not set the "parent_operator" property.

func _on_NegateToggleButton_pressed():
	if (1 == selected_property.coefficient):
		selected_property.coefficient = -1
		$Background/InverseParserHBC/NegateToggleButton.text = "-"
	elif (-1 == selected_property.coefficient):
		selected_property.coefficient = 1
		$Background/InverseParserHBC/NegateToggleButton.text = " "
	emit_signal("bnumber_property_selected", selected_property)

func _on_RootCharacterSelector_item_selected(index):
	var metadata = $Background/InverseParserHBC/RootCharacterSelector.get_item_metadata(index)
	if (metadata is Actor):
		var blueprint = selected_property.get_ap_blueprint()
		if (null != blueprint and blueprint.applies_to(metadata)):
			selected_property.character = metadata
		else:
			reset()
			selected_property.character = metadata
		refresh()
		emit_signal("bnumber_property_selected", selected_property)
