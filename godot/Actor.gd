extends Object
class_name Actor

var storyworld = null
var id = ""
var char_name = ""
var pronoun = ""
var bnumber_properties = {}
#Variables for editor:
var creation_index = 0
var creation_time = OS.get_unix_time()
var modified_time = OS.get_unix_time()

func _init(in_storyworld, in_char_name, in_pronoun, in_bnumber_properties = null):
	storyworld = in_storyworld
	char_name = in_char_name
	pronoun = in_pronoun
	if (null != in_bnumber_properties):
		bnumber_properties = in_bnumber_properties.duplicate(true)
	else:
		set_classical_personality_model(0, 0, 0, 0, 0, 0)

func log_update():
	modified_time = OS.get_unix_time()

func get_index():
	if (null != storyworld):
		return storyworld.characters.find(self)
	return -1

func set_as_copy_of(in_character):
	id = in_character.id
	char_name = in_character.char_name
	pronoun = in_character.pronoun
	bnumber_properties = in_character.bnumber_properties.duplicate(true)
	creation_index = in_character.creation_index
	creation_time = in_character.creation_time
	modified_time = OS.get_unix_time()

func set_classical_personality_model(in_Bad_Good, in_False_Honest, in_Timid_Dominant, in_pBad_Good, in_pFalse_Honest, in_pTimid_Dominant):
	var personality_model = {}
	personality_model["Bad_Good"] = 0
	personality_model["False_Honest"] = 0
	personality_model["Timid_Dominant"] = 0
	personality_model["pBad_Good"] = 0
	personality_model["pFalse_Honest"] = 0
	personality_model["pTimid_Dominant"] = 0
	initialize_bnumber_properties(storyworld.characters, personality_model)
	set_bnumber_property(["Bad_Good"], in_Bad_Good)
	set_bnumber_property(["False_Honest"], in_False_Honest)
	set_bnumber_property(["Timid_Dominant"], in_Timid_Dominant)
	set_bnumber_property(["pBad_Good"], in_pBad_Good)
	set_bnumber_property(["pFalse_Honest"], in_pFalse_Honest)
	set_bnumber_property(["pTimid_Dominant"], in_pTimid_Dominant)

func compile(include_editor_only_variables = false):
	var result = {}
	result["name"] = char_name
	result["pronoun"] = pronoun
	result["bnumber_properties"] = bnumber_properties.duplicate(true)
#	result["Bad_Good"] = bnumber_properties["Bad_Good"]
#	result["False_Honest"] = bnumber_properties["False_Honest"]
#	result["Timid_Dominant"] = bnumber_properties["Timid_Dominant"]
#	result["pBad_Good"] = bnumber_properties["pBad_Good"]
#	result["pFalse_Honest"] = bnumber_properties["pFalse_Honest"]
#	result["pTimid_Dominant"] = bnumber_properties["pTimid_Dominant"]
	if (include_editor_only_variables):
		#Editor only variables:
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

func add_property_to_bnumber_properties(property, default_value = 0, characters = storyworld.characters, personality_model = storyworld.personality_model):
	if (0 == personality_model[property]):
		bnumber_properties[property] = 0
	elif (0 < personality_model[property]):
		var onion = default_value
		for layer in range (personality_model[property]):
			var onion_b = {}
			for character in characters:
				if (0 == layer):
					onion_b[character.id] = onion
				else:
					onion_b[character.id] = onion.duplicate()
			onion = onion_b.duplicate()
		bnumber_properties[property] = onion

func initialize_bnumber_properties(characters = storyworld.characters, personality_model = storyworld.personality_model):
	for property in personality_model.keys():
		add_property_to_bnumber_properties(property, characters, personality_model)

func get_bnumber_property(keyring):
#	print ("Fetching bounded number property from " + char_name)
	var first_loop = true
	var coefficient = 1
	var property = keyring[0]
	var onion = null
	for key in keyring:
		if (first_loop):
			first_loop = false
			if ("-" == property.left(1)):
				property = property.substr(1)
				coefficient = -1
			if (!bnumber_properties.has(property)):
				print ("Property '" + property + "' not found.")
				return null
			else:
				onion = bnumber_properties[property]
		else:
			if (TYPE_DICTIONARY == typeof(onion) and onion.has(key)):
				onion = onion[key]
			else:
				print ("Character '" + storyworld.character_directory[key] + "' not found.")
				return null
#	print (str(coefficient * onion))
	return coefficient * onion

func set_bnumber_property(keyring, value):
	if (!(TYPE_INT == typeof(value) or TYPE_REAL == typeof(value))):
		return false #Let the calling function know an error occurred.
	var coefficient = 1
	var property = keyring[0]
	var onion = null
	for index in range(keyring.size()):
		var key = keyring[index]
		if (0 == index):
			#First pass through loop.
			if ("-" == property.left(1)):
				property = property.substr(1)
				coefficient = -1
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
		return false #Let the calling function know an error occurred.

func add_to_onion(dictionary, new_key, layer, additions):
	if (TYPE_DICTIONARY != typeof(dictionary) or 0 > layer or layer >= additions.size()):
		#Validate input variables.
		return false
	for each_key in dictionary.keys():
		var each_value = dictionary[each_key]
		if (TYPE_DICTIONARY == typeof(each_value)):
			add_to_onion(each_value, new_key, layer + 1, additions)
	dictionary[new_key] = additions[layer]

func add_character_to_bnumber_property(new_character, property, layers, default_value = 0, characters = storyworld.characters):
	if (!(TYPE_DICTIONARY == typeof(property)) or !(TYPE_INT == typeof(default_value) or TYPE_REAL == typeof(default_value))):
		#Validate input types.
		return false
	var onion = default_value
	var onions = [] #Each array entry represents a version of the onion at a certain layer.
	for layer in range(layers):
		var onion_b = {}
		for character in characters:
			if (0 == layer):
				onion_b[character.id] = onion
			else:
				onion_b[character.id] = onion.duplicate()
		onion = onion_b.duplicate()
		onions[layer] = onion.duplicate()
	onions.invert()
	add_to_onion(bnumber_properties[property], new_character.id, 0, onions)
	return true

func add_character_to_bnumber_properties(new_character, default_value = 0, characters = storyworld.characters, personality_model = storyworld.personality_model):
	for property in personality_model.keys():
		var layers = personality_model[property] #Number of perception layers deep this property tracks.
		add_character_to_bnumber_property(new_character, property, layers, default_value, characters)

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
