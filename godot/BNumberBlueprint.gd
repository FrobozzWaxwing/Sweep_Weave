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
var creation_time = OS.get_unix_time()
var modified_time = OS.get_unix_time()

func _init(in_storyworld, in_creation_index, in_id, in_property_name, in_depth = 0, in_default_value = 0):
	storyworld = in_storyworld
	id = in_id
	property_name = in_property_name
	depth = in_depth
	default_value = in_default_value
	creation_time = OS.get_unix_time()
	modified_time = OS.get_unix_time()

func get_property_name():
	if ("" != property_name):
		return property_name
	else:
		return "[Unnamed Property]"

func log_update():
	modified_time = OS.get_unix_time()

func set_as_copy_of(original):
	id = original.id
	property_name = original.property_name
	depth = original.depth
	default_value = original.default_value
	attribution_target = original.attribution_target
	affected_characters = []
	for character in original.affected_characters:
		affected_characters.append(character)
#	creation_index = original.creation_index
#	creation_time = original.creation_time
	modified_time = OS.get_unix_time()

func remap(to_storyworld):
	storyworld = to_storyworld
	var old_affected_characters = affected_characters.duplicate()
	affected_characters = []
	for character in old_affected_characters:
		if (storyworld.character_directory.has(character.id)):
			affected_characters.append(storyworld.character_directory[character.id])

func compile(parent_storyworld, include_editor_only_variables = false):
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
	if (include_editor_only_variables):
		#Editor only variables:
		output["creation_index"] = creation_index
		output["creation_time"] = creation_time
		output["modified_time"] = modified_time
	return output
