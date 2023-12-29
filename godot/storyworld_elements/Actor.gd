extends Object
class_name Actor

var storyworld = null
var id = ""
var char_name = ""
var pronoun = ""
var bnumber_properties = {}
var authored_properties = []
var authored_property_directory = {}
#Variables for editor:
var creation_index = 0
var creation_time = null
var modified_time = null

func _init(in_storyworld, in_char_name:String, in_pronoun:String, in_bnumber_properties = null):
	storyworld = in_storyworld
	char_name = in_char_name
	pronoun = in_pronoun
	if (null != in_bnumber_properties):
		bnumber_properties = in_bnumber_properties.duplicate(true)
	creation_time = OS.get_unix_time()
	modified_time = OS.get_unix_time()

func log_update():
	modified_time = OS.get_unix_time()

func get_index():
	if (null != storyworld):
		return storyworld.characters.find(self)
	return -1

func index_authored_property(property):
	authored_properties.append(property)
	authored_property_directory[property.id] = property

func set_as_copy_of(in_character, create_mutual_links = true):
	id = in_character.id
	char_name = in_character.char_name
	pronoun = in_character.pronoun
	bnumber_properties = in_character.bnumber_properties.duplicate(true)
	authored_properties = []
	authored_property_directory = {}
	for property in in_character.authored_properties:
		#Sanity check:
		if (is_instance_valid(property)):
			index_authored_property(property)
			if (create_mutual_links):
				if (!property.affected_characters.has(self)):
					property.affected_characters.append(self)
	var keys = bnumber_properties.keys()
	for key in keys:
		if (!authored_property_directory.has(key)):
			bnumber_properties.erase(key)
	modified_time = OS.get_unix_time()

func remap(to_storyworld):
	storyworld = to_storyworld
	var properties_to_index = authored_properties.duplicate()
	authored_properties = []
	authored_property_directory = {}
	for property_blueprint in properties_to_index:
		if (storyworld.authored_property_directory.has(property_blueprint.id)):
			index_authored_property(storyworld.authored_property_directory[property_blueprint.id])

func set_classical_personality_model(in_Bad_Good, in_False_Honest, in_Timid_Dominant, in_pBad_Good, in_pFalse_Honest, in_pTimid_Dominant):
	initialize_bnumber_properties()
	set_bnumber_property(["Bad_Good"], in_Bad_Good)
	set_bnumber_property(["False_Honest"], in_False_Honest)
	set_bnumber_property(["Timid_Dominant"], in_Timid_Dominant)
	set_bnumber_property(["pBad_Good"], in_pBad_Good)
	set_bnumber_property(["pFalse_Honest"], in_pFalse_Honest)
	set_bnumber_property(["pTimid_Dominant"], in_pTimid_Dominant)

func compile_onion(parent_storyworld, onion):
	var output = null
	if (TYPE_DICTIONARY == typeof(onion)):
		output = {}
		for character in parent_storyworld.characters:
			if (onion.has(character.id)):
				var index = character.get_index()
				if (0 <= index):
					output[index] = compile_onion(parent_storyworld, onion[character.id])
	elif (TYPE_INT == typeof(onion) or TYPE_REAL == typeof(onion)):
		output = onion
	return output

func compile(parent_storyworld, include_editor_only_variables = false):
	var result = {}
	result["name"] = char_name
	result["pronoun"] = pronoun
	if (include_editor_only_variables):
		result["bnumber_properties"] = bnumber_properties.duplicate(true)
	else:
		result["bnumber_properties"] = {}
		for authored_property in authored_properties:
			if (bnumber_properties.has(authored_property.id)):
				var onion = bnumber_properties[authored_property.id]
				result["bnumber_properties"][authored_property.id] = compile_onion(parent_storyworld, onion)
	if (include_editor_only_variables):
		#Editor only variables:
		result["id"] = id
		result["creation_index"] = creation_index
		result["creation_time"] = creation_time
		result["modified_time"] = modified_time
	return result

#Character personality / relationship model:
#A storyworld employs a character model in order to determine what sorts of traits characters can have, what sorts of relationships can exist between them, and how these are stored.
#Characters can have properties that involve them alone, but they can also have perceptions of other characters and their traits, as well as perceptions of other characters' perceptions, and so on, as many layers deep as the author wishes to delve.
#This means the system must be capable of tracking how many layers deep perceptions can go.
#In the zeroth layer, we need only store variables as dictionary entries in a property applied to each character. The property name and value need to be stored.
#In the first layer, we need to include the property name, the value, and the secondary character that the character possessing the property perceives in the specified way.
#In each subsequent layer we will need to track another character.
#All characters can have relationships with all characters, hence each new layer multiplies the memory footprint by the number of characters.
#Layer 0:	Character.bnumber_properties["Property Name"] = A floating point number from -1 to 1.
#Layer 1:	Character.bnumber_properties["Property Name"]["Character ID"] = Float
#Layer 2:	Character.bnumber_properties["Property Name"]["Character ID"]["Character ID"] = Float
#And so forth.

#func add_property_to_bnumber_properties(property_blueprint, characters = storyworld.characters):
#	index_authored_property(property_blueprint)
#	if (0 == property_blueprint.depth):
#		bnumber_properties[property_blueprint.id] = property_blueprint.default_value
#	elif (0 < property_blueprint.depth):
#		var onion = property_blueprint.default_value
#		for layer in range (property_blueprint.depth):
#			var onion_b = {}
#			for character in characters:
#				if (0 == layer):
#					onion_b[character.id] = onion
#				else:
#					onion_b[character.id] = onion.duplicate()
#			onion = onion_b.duplicate()
#		bnumber_properties[property_blueprint.id] = onion

func fill_onion(characters:Array, excluded_actor_id:String, layer:int, onion:Dictionary, value):
	for character in characters:
		if (excluded_actor_id != character.id):
			if (0 == layer):
				onion[character.id] = value
			else:
				onion[character.id] = {}
				fill_onion(characters, character.id, layer - 1, onion[character.id], value)

func add_property_to_bnumber_properties(property_blueprint, characters:Array = storyworld.characters):
	index_authored_property(property_blueprint)
	if (0 == property_blueprint.depth):
		bnumber_properties[property_blueprint.id] = property_blueprint.default_value
	elif (0 < property_blueprint.depth):
		bnumber_properties[property_blueprint.id] = {}
		fill_onion(characters, id, property_blueprint.depth - 1, bnumber_properties[property_blueprint.id], property_blueprint.default_value)

func initialize_bnumber_properties(characters:Array = storyworld.characters, in_authored_properties:Array = storyworld.authored_properties):
	for property_blueprint in in_authored_properties:
		if (property_blueprint.attribution_target == property_blueprint.possible_attribution_targets.ENTIRE_CAST):
			add_property_to_bnumber_properties(property_blueprint, characters)
		elif (property_blueprint.attribution_target == property_blueprint.possible_attribution_targets.CAST_MEMBERS):
			if (property_blueprint.affected_characters.has(self)):
				add_property_to_bnumber_properties(property_blueprint, characters)

func get_bnumber_property(keyring:Array):
	if (TYPE_ARRAY != typeof(keyring) or keyring.empty()):
		return null
	var first_loop = true
	var property = keyring[0]
	var onion = null
	for key in keyring:
		if (first_loop):
			first_loop = false
			if (!bnumber_properties.has(property)):
				print ("Property '" + property + "' not found.")
				return null
			else:
				onion = bnumber_properties[property]
		else:
			if (TYPE_DICTIONARY == typeof(onion) and onion.has(key)):
				onion = onion[key]
			else:
				print ("Character '" + storyworld.character_directory[key].char_name + "' not found.")
				return null
	return onion

func set_bnumber_property(keyring:Array, value):
	if (TYPE_ARRAY != typeof(keyring) or keyring.empty() or !(TYPE_INT == typeof(value) or TYPE_REAL == typeof(value))):
		return false #Let the calling function know an error occurred.
	var property = keyring[0]
	var onion = null
	for index in range(keyring.size()):
		var key = keyring[index]
		if (0 == index):
			#First pass through loop.
			if (!bnumber_properties.has(property)):
				return false #Let the calling function know an error occurred.
			else:
				if (1 == keyring.size()):
					bnumber_properties[property] = value
					return true #Let the calling function know the attribute was set successfully.
				else:
					onion = bnumber_properties[property]
		elif (0 < index and index < (keyring.size() - 1)):
			if (TYPE_DICTIONARY == typeof(onion) and onion.has(key)):
				onion = onion[key]
			else:
				return false #Let the calling function know an error occurred.
		else:
			#Last pass through loop.
			if (TYPE_DICTIONARY == typeof(onion) and onion.has(key)):
				onion[key] = value
				return true #Let the calling function know the attribute was set successfully.
			else:
				return false #Let the calling function know an error occurred.
	if (0 == keyring.size()):
		print ("Keyring is empty.")
		return false #Let the calling function know an error occurred.recursive_has_properties(value)

#func add_to_onion(dictionary, new_key, layer, additions):
#	if (TYPE_DICTIONARY != typeof(dictionary) or 0 > layer or layer >= additions.size()):
#		#Validate input variables.
#		return false
#	for each_key in dictionary.keys():
#		var each_value = dictionary[each_key]
#		if (TYPE_DICTIONARY == typeof(each_value)):
#			add_to_onion(each_value, new_key, layer + 1, additions)
#	dictionary[new_key] = additions[layer]
#
#func add_character_to_bnumber_property(new_character, property_id, layers, default_value = 0, characters = storyworld.characters):
#	if (!(TYPE_STRING == typeof(property_id)) or !(TYPE_INT == typeof(default_value) or TYPE_REAL == typeof(default_value))):
#		#Validate input types.
#		return false
#	var perceived_character_ids = []
#	for character in characters:
#		perceived_character_ids.append(character.id)
#	perceived_character_ids.append(new_character.id)
#	var onion = default_value
#	var onions = [] #Each array entry represents a version of the onion at a certain layer.
#	onions.append(onion)
#	for layer in range(layers - 1):
#		var onion_b = {}
#		for perceived_character_id in perceived_character_ids:
#			if (0 == layer):
#				onion_b[perceived_character_id] = onion
#			else:
#				onion_b[perceived_character_id] = onion.duplicate()
#		onion = onion_b.duplicate()
#		onions.append(onion)
#	onions.invert()
#	add_to_onion(bnumber_properties[property_id], new_character.id, 0, onions)
#	return true

func recursive_add_character_to_bnumber_property(new_character, characters:Array, layer:int, onion:Dictionary, value):
	if (0 == layer):
		onion[new_character.id] = value
	elif (0 < layer):
		for key in onion.keys():
			recursive_add_character_to_bnumber_property(new_character, characters, layer - 1, onion[key], value)
		onion[new_character.id] = {}
		fill_onion(characters, new_character.id, layer - 1, onion[new_character.id], value)

func add_character_to_bnumber_property(new_character, property_blueprint, characters:Array = storyworld.characters):
	if (0 < property_blueprint.depth):
		var property_onion = bnumber_properties[property_blueprint.id]
		recursive_add_character_to_bnumber_property(new_character, characters, property_blueprint.depth - 1, property_onion, property_blueprint.default_value)

func add_character_to_bnumber_properties(new_character, characters:Array = storyworld.characters):
	for property in authored_properties:
		add_character_to_bnumber_property(new_character, property, characters)

func delete_property_from_bnumber_properties(property_blueprint):
	bnumber_properties.erase(property_blueprint.id)
	authored_properties.erase(property_blueprint)
	authored_property_directory.erase(property_blueprint.id)

func delete_character_from_onion(character, onion:Dictionary):
	onion.erase(character.id)
	for each_key in onion.keys():
		var each_value = onion[each_key]
		if (TYPE_DICTIONARY == typeof(each_value)):
			delete_character_from_onion(character, each_value)
		else:
			break

func delete_character_from_bnumber_property(character, property_blueprint):
	if (bnumber_properties.has(property_blueprint.id)):
		var onion = bnumber_properties[property_blueprint.id]
		if (TYPE_DICTIONARY == typeof(onion)):
			delete_character_from_onion(character, onion)

func delete_character_from_bnumber_properties(character):
	for property_blueprint in authored_properties:
		delete_character_from_bnumber_property(character, property_blueprint)

func recursive_has_properties(onion:Dictionary):
	var value = onion.values().front()
	var type = typeof(value)
	if (TYPE_INT == type or TYPE_REAL == type):
		return true
	elif (TYPE_DICTIONARY == type and !value.empty()):
		return recursive_has_properties(value)
	return false

func has_properties():
	if (bnumber_properties.empty()):
		return false
	for value in bnumber_properties.values():
		var type = typeof(value)
		if (TYPE_INT == type or TYPE_REAL == type):
			return true
		elif (TYPE_DICTIONARY == type and !value.empty()):
			return recursive_has_properties(value)
	return false

func data_to_string():
	var result = char_name + ": bnumber_properties: "
	for key in bnumber_properties.keys():
		if (TYPE_INT == typeof(bnumber_properties[key]) or TYPE_REAL == typeof(bnumber_properties[key])):
			result += "(" + key + ": " + str(bnumber_properties[key]) + ")"
		elif (TYPE_DICTIONARY == typeof(bnumber_properties[key])):
			for key2 in bnumber_properties[key].keys():
				if (TYPE_INT == typeof(bnumber_properties[key][key2]) or TYPE_REAL == typeof(bnumber_properties[key][key2])):
					result += "(" + key + "(" + key2 + "): " + str(bnumber_properties[key][key2]) + ")"
				else:
					result += "(" + key + "(" + key2 + "): ...)"
	return result
