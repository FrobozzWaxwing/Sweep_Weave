extends Control

var storyworld = null
var character = null
var keyring = [] #First entry is bounded number property name, other entries specify the chain of characters.
var KeyringOptionButton = load("res://KeyringOptionButton.tscn")

onready var ControlDial = $VBC/HBC2/SpinBox
onready var ControlSlider = $VBC/HBC2/Slidebar

signal bnumber_property_changed(character, keyring, new_value)

func _ready():
	pass # Replace with function body.

func refresh_character_name(character):
	for child in $VBC/HBC1/KeyringHBC.get_children():
		for index in range(child.get_item_count()):
			if (child.get_item_metadata(index) == character):
				child.set_item_text(index, character.char_name)

func refresh():
	if (0 == keyring.size() or null == character):
		return false
	var value = character.get_bnumber_property(keyring)
	$VBC/HBC2/Slidebar.value = value
	$VBC/HBC2/SpinBox.value = value
	var property_id = keyring[0]
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
		for keyring_index in range(keyring.size()):
			if (1 <= keyring_index):
				var selector = KeyringOptionButton.instance()
				selector.keyring_index = keyring_index
				var option_index = 0
				var selected_index = 0
				for character in storyworld.characters:
					selector.add_item(character.char_name)
					selector.set_item_metadata(option_index, character)
					if (keyring[keyring_index] == character.id):
						selected_index = option_index
					option_index += 1
				selector.select(selected_index)
				selector.connect("keyring_change_requested", self, "change_keyring")
				$VBC/HBC1/KeyringHBC.add_child(selector)
	return true

func change_keyring(keyring_index, option_index, perceived_character):
	keyring[keyring_index] = perceived_character.id
	var value = character.get_bnumber_property(keyring)
	ControlSlider.value = value
	ControlDial.value = value

func _on_Slidebar_value_changed(value):
	ControlDial.value = (value)
	if (0 != keyring.size() and null != character):
		character.set_bnumber_property(keyring, value)
		emit_signal("bnumber_property_changed", character, keyring, value)

func _on_SpinBox_value_changed(value):
	ControlSlider.value = value
	if (0 != keyring.size() and null != character):
		character.set_bnumber_property(keyring, value)
		emit_signal("bnumber_property_changed", character, keyring, value)

#GUI Themes:

