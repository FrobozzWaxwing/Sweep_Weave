extends Control

var storyworld = null
var selected_property = null
var allow_root_character_editing = true
var allow_coefficient_editing = false
var KeyringOptionButton = load("res://interface/KeyringOptionButton.tscn")

signal bnumber_property_selected(selected_property)

func _ready():
	pass

func set_error_message(text = "", tooltip = ""):
	$Background/InverseParserHBC/ErrorMessage.set_text(text)
	if ("" == text):
		$Background/InverseParserHBC/ErrorMessage.set_visible(true)
		$Background/InverseParserHBC/ErrorMessage.set_visible(true)
		$Background/InverseParserHBC/ErrorMessage.set_tooltip("")
	else:
		$Background/InverseParserHBC/ErrorMessage.set_visible(false)
		$Background/InverseParserHBC/ErrorMessage.set_visible(false)
		if ("" == tooltip):
			$Background/InverseParserHBC/ErrorMessage.set_tooltip(text)
		else:
			$Background/InverseParserHBC/ErrorMessage.set_tooltip(tooltip)

func refresh_character_name(character):
	for index in range($Background/InverseParserHBC/RootCharacterSelector.get_item_count()):
		if ($Background/InverseParserHBC/RootCharacterSelector.get_item_metadata(index) == character):
			$Background/InverseParserHBC/RootCharacterSelector.set_item_text(index, character.char_name)
	for child in $Background/InverseParserHBC/KeyringBC.get_children():
		for index in range(child.get_item_count()):
			if (child.get_item_metadata(index) == character):
				child.set_item_text(index, character.char_name)

func refresh():
	#This function refreshes the interface.
	#The reset() function should be called at least once before this function, to create a bounded number property and initialize the editor.
	if (null == selected_property or null == selected_property.character or selected_property.keyring.empty() or null == storyworld or storyworld.characters.empty()):
		return false
	#Refresh character selector.
	$Background/InverseParserHBC/RootCharacterSelector.visible = allow_root_character_editing
	$Background/InverseParserHBC/RootCharacterSelector.clear()
	var option_index = 0
	var selected_index = 0
	for character in storyworld.characters:
		if (character.has_properties()):
			$Background/InverseParserHBC/RootCharacterSelector.add_item(character.char_name)
			$Background/InverseParserHBC/RootCharacterSelector.set_item_metadata(option_index, character)
			if (selected_property.character == character):
				selected_index = option_index
			option_index += 1
		if (0 == option_index):
			set_error_message("No one selected.", "No characters are available to select. Try adding some characters or adding some properties to your existing characters.")
			break
		else:
			$Background/InverseParserHBC/RootCharacterSelector.select(selected_index)
	if (0 == selected_property.character.authored_property_directory.size()):
		$Background/InverseParserHBC/NegateToggleButton.visible = false
		#The selected character has no authored properties associated with them.
		for child in $Background/InverseParserHBC/KeyringBC.get_children():
			child.queue_free()
		set_error_message("No property selected.", "The selected character, \"" + selected_property.character.char_name + ",\" currently has no properties available to select.")
		return true
	else:
		set_error_message("", "")
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
	var onion = selected_property.character.bnumber_properties[selected_property.keyring.front()]
	for keyring_index in range(layers + 1):
		if (0 == keyring_index):
			var selector = KeyringOptionButton.instance()
			selector.keyring_index = keyring_index
			option_index = 0
			selected_index = 0
			for key in selected_property.character.authored_property_directory.keys():
				var property_blueprint = selected_property.character.authored_property_directory[key]
				if (property_blueprint.attribution_target == property_blueprint.possible_attribution_targets.ENTIRE_CAST or property_blueprint.affected_characters.has(selected_property.character)):
					if (0 == property_blueprint.depth or !selected_property.character.bnumber_properties[property_blueprint.id].empty()):
						selector.add_item(property_blueprint.get_property_name())
						selector.set_item_metadata(option_index, property_blueprint)
						if (selected_property.keyring[keyring_index] == property_blueprint.id):
							selected_index = option_index
						option_index += 1
			if (0 == option_index):
				set_error_message("No property selected.", "The selected character, \"" + selected_property.character.char_name + ",\" currently has no properties available to select.")
				break
			else:
				selector.select(selected_index)
			selector.connect("keyring_change_requested", self, "change_keyring")
			$Background/InverseParserHBC/KeyringBC.add_child(selector)
		elif (1 <= keyring_index):
			if (onion.empty()):
				set_error_message("Error: The selected property is empty.")
				break
			else:
				var selector = KeyringOptionButton.instance()
				selector.keyring_index = keyring_index
				option_index = 0
				selected_index = 0
				for character in storyworld.characters:
					if (character.id in onion):
						selector.add_item(character.char_name)
						selector.set_item_metadata(option_index, character)
						if (selected_property.keyring[keyring_index] == character.id):
							selected_index = option_index
						option_index += 1
				selector.select(selected_index)
				selector.connect("keyring_change_requested", self, "change_keyring")
				$Background/InverseParserHBC/KeyringBC.add_child(selector)
				if (onion.has(selected_property.keyring[keyring_index])):
					onion = onion[selected_property.keyring[keyring_index]]
				else:
					set_error_message("Error: The selected property does not exist.")
					break
	return true

func change_keyring(keyring_index, option_metadata):
	if (null == storyworld or storyworld.characters.empty()):
		return
	var onion = null
	if (0 == keyring_index):
		selected_property.keyring.clear()
		selected_property.keyring.append(option_metadata.id)
		onion = selected_property.character.bnumber_properties[option_metadata.id]
	elif (0 < keyring_index and option_metadata is Actor):
		selected_property.keyring[keyring_index] = option_metadata.id
		selected_property.keyring.resize(keyring_index + 1)
		onion = selected_property.character.bnumber_properties[selected_property.keyring.front()]
	while (TYPE_DICTIONARY == typeof(onion)):
		for prospect in storyworld.characters:
			if (onion.has(prospect.id)):
				selected_property.keyring.append(prospect.id)
				onion = onion[prospect.id]
				break
	refresh()
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
	var character = $Background/InverseParserHBC/RootCharacterSelector.get_item_metadata(index)
	if (character is Actor):
		selected_property.character = character
		var blueprint = selected_property.get_ap_blueprint()
		if (null == blueprint or !blueprint.applies_to(character) or !character.bnumber_properties.has(blueprint.id)):
			blueprint = character.authored_properties.front()
		change_keyring(0, blueprint)
