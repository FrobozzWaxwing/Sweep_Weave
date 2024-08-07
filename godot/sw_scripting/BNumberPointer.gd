extends SWPointer
class_name BNumberPointer

var character = null
var coefficient = 1
var keyring = []

func _init(in_character = null, in_keyring = []):
	output_type = sw_script_data_types.BNUMBER
	character = in_character
	keyring = in_keyring.duplicate()

func get_pointer_type():
	return "Bounded Number Pointer"

func get_value():
	var output = null
	if (character is Actor):
		output = coefficient * character.get_bnumber_property(keyring)
	return output

func set_value(value):
	if (character is Actor):
		character.set_bnumber_property(keyring, value)

func get_ap_blueprint():
	if (null == character or keyring.is_empty()):
		return null
	var property_id = keyring[0]
	if (!character.authored_property_directory.has(property_id)):
		return null
	var property_blueprint = character.authored_property_directory[property_id]
	return property_blueprint

func get_bnumber_name():
	if (null == character or keyring.is_empty()):
		return ""
	var property_blueprint = get_ap_blueprint()
	if (null == property_blueprint):
		return ""
	return property_blueprint.get_property_name()

func get_character_name_from_id(character_id):
	var storyworld = character.storyworld
	if (null == storyworld):
		return "unknown_character"
	elif (!(storyworld.character_directory.has(character_id))):
		return "unknown_character"
	else:
		return storyworld.character_directory[character_id].char_name

func compile(_parent_storyworld, _include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Pointer"
	output["pointer_type"] = get_pointer_type()
	output["coefficient"] = coefficient
	if (_include_editor_only_variables):
		output["character"] = character.id
		output["keyring"] = keyring.duplicate()
	else:
		output["character"] = character.get_index()
		output["keyring"] = []
		if (!keyring.is_empty() and character.authored_property_directory.has(keyring[0])):
			for key_index in range(keyring.size()):
				var key = keyring[key_index]
				if (0 == key_index):
					output["keyring"].append(key)
				elif (_parent_storyworld.character_directory.has(key)):
					output["keyring"].append(_parent_storyworld.character_directory[key].get_index())
	return output

func set_as_copy_of(original):
	character = original.character
	coefficient = original.coefficient
	keyring = []
	for each in original.keyring:
		keyring.append(each)

func replace_character_with_character(search_term, replacement):
	if (search_term is Actor and replacement is Actor):
		if (character is Actor):
			if (character.id == search_term.id):
				character = replacement
			var index = 0
			var keys = keyring.duplicate()
			for key in keys:
				if (key == search_term.id):
					keyring[index] = replacement.id
					index += 1

func remap(to_storyworld):
	if (to_storyworld.character_directory.has(character.id)):
		character = to_storyworld.character_directory[character.id]
		return true
	else:
		character = null
		return false

func data_to_string():
	if (null == character or !(character is Actor) or 0 == keyring.size()):
		return "Invalid BNumberPointer"
	var text = ""
	if (1 != coefficient):
		text += str(coefficient) + " * "
	text += character.char_name + " ["
	for index in range(keyring.size()):
		if (0 == index):
			text += get_bnumber_name()
		else:
			var character_id = keyring[index]
			text += ", " + get_character_name_from_id(character_id)
	text += "]"
#	text += "] ("
#	text += str(character.get_bnumber_property(keyring))
#	text += ")"
	return text

func validate(_intended_script_output_datatype):
	var report = ""
	#Check character:
	if (null == character):
		report += "\n" + "Null character."
	elif (!(character is Actor)):
		report += "\n" + "Invalid character."
	elif (!is_instance_valid(character)):
		report += "\n" + "Character has been deleted."
	#Check coefficient:
	if (TYPE_INT != typeof(coefficient) and TYPE_FLOAT != typeof(coefficient)):
		report += "\n" + "Coefficient is not a number."
	#Check keyring and value:
	if (keyring.is_empty()):
		report += "\n" + "Keyring is empty."
	elif (character is Actor and is_instance_valid(character)):
		if (!character.bnumber_properties.has(keyring[0])):
			report += "\n" + "Character does not possess the property that this pointer refers to."
		elif (null == get_value()):
			report += "\n" + "Value is null."
	if ("" == report):
		return "Passed."
	else:
		return get_pointer_type() + " errors:" + report

func is_parallel_to(sibling):
	if (character == sibling.character and coefficient == sibling.coefficient and keyring.size() == sibling.keyring.size()):
		for index in range(keyring.size()):
			if (keyring[index] != sibling.keyring[index]):
				return false
		return true
	return false
