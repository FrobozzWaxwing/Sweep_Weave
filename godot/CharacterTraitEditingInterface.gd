extends Panel

var character = null
var keyring = [] #First entry is bounded number property name, other entries specify the chain of characters.

signal bnumber_property_changed(character, keyring, new_value)

func _ready():
	pass # Replace with function body.

func refresh():
	if (0 == keyring.size() or null == character):
		return false
	var value = character.get_bnumber_property(keyring)
	$VBC/Slidebar.value = value
	$VBC/HBC/SpinBox.value = value
	var text = keyring[0]
	text += ": "
	$VBC/HBC/Label.set_text(text)
	return true

func _on_Slidebar_value_changed(value):
	$VBC/HBC/SpinBox.value = (value)
	if (0 != keyring.size() and null != character):
		character.set_bnumber_property(keyring, value)
		emit_signal("bnumber_property_changed", character, keyring, value)

func _on_SpinBox_value_changed(value):
	$VBC/Slidebar.value = value
	if (0 != keyring.size() and null != character):
		character.set_bnumber_property(keyring, value)
		emit_signal("bnumber_property_changed", character, keyring, value)
