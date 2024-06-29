extends Control

var storyworld = null
var character_to_edit = null
var keyring = [] #First entry is bounded number property name, other entries specify the chain of characters.
var KeyringOptionButton = load("res://interface/KeyringOptionButton.tscn")

@onready var ControlDial = $VBC/HBC2/SpinBox
@onready var ControlSlider = $VBC/HBC2/Slidebar

signal bnumber_property_changed(character, keyring, new_value)

func _ready():
	pass # Replace with function body.

func set_error_message(text = ""):
	$VBC/Label.set_text(text)
	if ("" == text):
		$VBC/HBC1.set_visible(true)
		$VBC/HBC2.set_visible(true)
	else:
		$VBC/HBC1.set_visible(false)
		$VBC/HBC2.set_visible(false)

func refresh_character_name(character):
	for child in $VBC/HBC1/KeyringHBC.get_children():
		for index in range(child.get_item_count()):
			if (child.get_item_metadata(index) == character):
				child.set_item_text(index, character.char_name)

func refresh():
	if (0 == keyring.size()):
		set_error_message("Error: Empty property keyring.")
		return false
	elif (null == character_to_edit):
		set_error_message("Error: Null character reference.")
		return false
	elif (null == storyworld):
		set_error_message("Error: Null storyworld reference.")
		return false
	var value = character_to_edit.get_bnumber_property(keyring)
	if (null == value):
		set_error_message("Error: Could not find property when checking character.")
		return false
	elif (TYPE_DICTIONARY == typeof(value)):
		set_error_message("Error: Could not find bnumber when checking character.")
		return false
	elif (TYPE_INT == typeof(value) or TYPE_FLOAT == typeof(value)):
		$VBC/HBC2/Slidebar.set_value_no_signal(value)
		$VBC/HBC2/SpinBox.set_value_no_signal(value)
	var property_id = keyring.front()
	if (!storyworld.authored_property_directory.has(property_id)):
		set_error_message("Error: Could not find property when checking storyworld.")
		return false
	var property = storyworld.authored_property_directory[property_id]
	var text = property.get_property_name()
	text += ": "
	$VBC/Label.set_text(text)
	for child in $VBC/HBC1/KeyringHBC.get_children():
		child.queue_free()
	if (1 == keyring.size()):
		$VBC/HBC1/KeyringHBC.visible = false
	else:
		$VBC/HBC1/KeyringHBC.visible = true
		var onion = character_to_edit.bnumber_properties[property_id]
		for keyring_index in range(1, keyring.size()):
			var selector = KeyringOptionButton.instantiate()
			selector.keyring_index = keyring_index
			var option_index = 0
			var selected_index = 0
			for character in storyworld.characters:
				if (character.id in onion):
					selector.add_item(character.char_name)
					selector.set_item_metadata(option_index, character)
					if (keyring[keyring_index] == character.id):
						selected_index = option_index
					option_index += 1
			selector.select(selected_index)
			selector.keyring_change_requested.connect(change_keyring)
			$VBC/HBC1/KeyringHBC.add_child(selector)
			onion = onion[keyring[keyring_index]]
	return true

func refresh_keyring_interface(refresh_index):
	var onion = character_to_edit.bnumber_properties[keyring.front()]
	var buttons = $VBC/HBC1/KeyringHBC.get_children()
	for keyring_index in range(1, keyring.size()):
		if(refresh_index <= keyring_index and keyring_index - 1 < buttons.size()):
			var selector = buttons[keyring_index - 1]
			selector.clear()
			var option_index = 0
			var selected_index = 0
			for character in storyworld.characters:
				if (character.id in onion):
					selector.add_item(character.char_name)
					selector.set_item_metadata(option_index, character)
					if (keyring[keyring_index] == character.id):
						selected_index = option_index
					option_index += 1
			selector.select(selected_index)
		onion = onion[keyring[keyring_index]]

func change_keyring(keyring_index, perceived_character):
	keyring[keyring_index] = perceived_character.id
	var length = keyring.size()
	keyring.resize(keyring_index + 1)
	var onion = character_to_edit.get_bnumber_property(keyring)
	if (!storyworld.characters.is_empty()):
		while (TYPE_DICTIONARY == typeof(onion) and keyring.size() < length):
			for prospect in storyworld.characters:
				if (onion.has(prospect.id)):
					keyring.append(prospect.id)
					onion = onion[prospect.id]
					break
	if (TYPE_INT == typeof(onion) or TYPE_FLOAT == typeof(onion)):
		ControlSlider.value = onion
		ControlDial.value = onion
	if (keyring_index + 1 < keyring.size()):
		refresh_keyring_interface(keyring_index + 1)

func _on_Slidebar_value_changed(value):
	ControlDial.value = (value)
	if (0 != keyring.size() and null != character_to_edit):
		character_to_edit.set_bnumber_property(keyring, value)
		bnumber_property_changed.emit(character_to_edit, keyring, value)

func _on_SpinBox_value_changed(value):
	ControlSlider.value = value
	if (0 != keyring.size() and null != character_to_edit):
		character_to_edit.set_bnumber_property(keyring, value)
		bnumber_property_changed.emit(character_to_edit, keyring, value)

#GUI Themes:

