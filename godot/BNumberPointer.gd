extends SWPointer
class_name BNumberPointer

var character = null
var coefficient = 1
var keyring = []

func _init(in_character = null, in_keyring = []):
	pointer_type = "Bounded Number Pointer"
	output_type = sw_script_data_types.BNUMBER
	character = in_character
	keyring = in_keyring.duplicate()

func get_value(leaf = null):
	if (null != character and character is Actor):
		return coefficient * character.get_bnumber_property(keyring)

func set_value(value):
	if (null != character and character is Actor):
		character.set_bnumber_property(keyring, value)

func get_ap_blueprint():
	if (null == character or keyring.empty()):
		return null
	var property_id = keyring[0]
	if (!character.authored_property_directory.has(property_id)):
		return null
	var property_blueprint = character.authored_property_directory[property_id]
	return property_blueprint

func get_bnumber_name():
	if (null == character or keyring.empty()):
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

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Pointer"
	output["pointer_type"] = pointer_type
	output["coefficient"] = coefficient
	if (include_editor_only_variables):
		output["character"] = character.id
		output["keyring"] = keyring.duplicate()
	else:
		output["character"] = character.get_index()
		output["keyring"] = []
		if (!keyring.empty() and character.authored_property_directory.has(keyring[0])):
			for key_index in range(keyring.size()):
				var key = keyring[key_index]
				if (0 == key_index):
					output["keyring"].append(key)
				elif (parent_storyworld.character_directory.has(key)):
					output["keyring"].append(parent_storyworld.character_directory[key].get_index())
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
	text += "] ("
	text += str(character.get_bnumber_property(keyring))
	text += ")"
	return text
