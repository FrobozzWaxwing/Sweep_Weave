extends Object
class_name BNumberBlueprint
# Authored Property Blueprint.
# This contains information about a bounded number property that a storyworld author has chosen to include in their storyworld.

var storyworld = null
var id = null
var property_name = ""
var depth = 0
var default_value = 0
var attribution_target = possible_attribution_targets.ENTIRE_CAST
enum possible_attribution_targets {STORYWORLD, CAST_MEMBERS, ENTIRE_CAST}
var affected_characters = []
#Variables for editor:
var creation_index = 0
var creation_time = Time.get_unix_time_from_system()
var modified_time = Time.get_unix_time_from_system()

func _init(in_storyworld, in_creation_index:int, in_id:String, in_property_name:String, in_depth:int = 0, in_default_value = 0):
	storyworld = in_storyworld
	id = in_id
	property_name = in_property_name
	depth = in_depth
	default_value = in_default_value
	creation_index = in_creation_index
	creation_time = Time.get_unix_time_from_system()
	modified_time = Time.get_unix_time_from_system()

func get_index():
	if (null != storyworld):
		return storyworld.authored_properties.find(self)
	return -1

func get_property_name():
	if ("" != property_name):
		return property_name
	else:
		return "[Unnamed Property]"

func applies_to(character):
	if (possible_attribution_targets.ENTIRE_CAST == attribution_target):
		return true
	elif (possible_attribution_targets.CAST_MEMBERS == attribution_target):
		if (affected_characters.has(character)):
			return true
	return false

func log_update():
	modified_time = Time.get_unix_time_from_system()

func set_as_copy_of(original, create_mutual_links:bool = true):
	id = original.id
	property_name = original.property_name
	depth = original.depth
	default_value = original.default_value
	attribution_target = original.attribution_target
	affected_characters = []
	for character in original.affected_characters:
		if (is_instance_valid(character)):
			affected_characters.append(character)
			if (create_mutual_links):
				if (!character.authored_property_directory.has(self)):
					character.index_authored_property(self)
	modified_time = Time.get_unix_time_from_system()

func remap(to_storyworld):
	storyworld = to_storyworld
	var old_affected_characters = affected_characters.duplicate()
	affected_characters = []
	for character in old_affected_characters:
		if (storyworld.character_directory.has(character.id)):
			affected_characters.append(storyworld.character_directory[character.id])

func replace_character_with_character(character_to_delete, replacement):
	if (possible_attribution_targets.CAST_MEMBERS == attribution_target):
		if (affected_characters.has(character_to_delete)):
			affected_characters.erase(character_to_delete)
			if (is_instance_valid(replacement) and !affected_characters.has(replacement)):
				affected_characters.append(replacement)
	elif (possible_attribution_targets.ENTIRE_CAST == attribution_target):
		affected_characters.erase(character_to_delete)

func compile(_parent_storyworld, _include_editor_only_variables:bool = false):
	var output = {}
	output["property_type"] = "bounded number"
	output["id"] = id
	output["property_name"] = property_name
	output["depth"] = depth
	output["default_value"] = default_value
	if (attribution_target == possible_attribution_targets.STORYWORLD):
		output["attribution_target"] = "storyworld"
	elif (attribution_target == possible_attribution_targets.CAST_MEMBERS):
		output["attribution_target"] = "some cast members"
	elif (attribution_target == possible_attribution_targets.ENTIRE_CAST):
		output["attribution_target"] = "all cast members"
	output["affected_characters"] = []
	for character in affected_characters:
		output["affected_characters"].append(character.id)
	if (_include_editor_only_variables):
		#Editor only variables:
		output["creation_index"] = creation_index
		output["creation_time"] = creation_time
		output["modified_time"] = modified_time
	return output
