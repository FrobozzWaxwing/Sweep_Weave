extends Object
class_name Option

var encounter = null #The encounter this option is associatied with.
var text = ""
var visibility_script = null
var performability_script = null
var reactions = []
#Variables for editor:
var graph_offset = Vector2(0, 0)
var occurrences = 0 #Number of times this option occurs during a rehearsal.

func _init(in_encounter, in_text, in_graph_offset = Vector2(0, 0)):
	encounter = in_encounter
	text = in_text
	var default = BooleanConstant.new(true)
	visibility_script = ScriptManager.new(default)
	default = BooleanConstant.new(true)
	performability_script = ScriptManager.new(default)
	graph_offset = in_graph_offset

func get_index():
	if (null != encounter):
		return encounter.options.find(self)
	return -1

func get_truncated_text(maximum_output_length = 20):
	if (maximum_output_length >= text.length()):
		return text
	else:
		return text.left(maximum_output_length - 3) + "..."

func get_antagonist():
	return encounter.antagonist

func has_search_text(searchterm):
	if (searchterm in text):
		return true
	else:
		for reaction in reactions:
			if (reaction.has_search_text(searchterm)):
				return true
	return false

func compile(parent_storyworld, include_editor_only_variables = false):
	var result = {}
	result["text"] = text
	result["visibility_script"] = null
	if (null != visibility_script and visibility_script is ScriptManager):
		result["visibility_script"] = visibility_script.compile(parent_storyworld, include_editor_only_variables)
	result["performability_script"] = null
	if (null != performability_script and performability_script is ScriptManager):
		result["performability_script"] = performability_script.compile(parent_storyworld, include_editor_only_variables)
	result["reactions"] = []
	for reaction in reactions:
		result["reactions"].append(reaction.compile(parent_storyworld, include_editor_only_variables))
	#Editor only variables:
	if (include_editor_only_variables):
		result["graph_offset_x"] = graph_offset.x
		result["graph_offset_y"] = graph_offset.y
	return result

func clear():
	encounter = null
	text = ""
	graph_offset = Vector2(0, 0)
	visibility_script.clear()
	visibility_script.call_deferred("free")
	visibility_script = null
	performability_script.clear()
	performability_script.call_deferred("free")
	performability_script = null
	for reaction in reactions:
		reaction.clear()
		reaction.call_deferred("free")

func set_as_copy_of(original):
	encounter = original.encounter
	text = original.text
	graph_offset = original.graph_offset
	if (null == visibility_script):
		visibility_script = ScriptManager.new()
	visibility_script.set_as_copy_of(original.visibility_script)
	if (null == performability_script):
		performability_script = ScriptManager.new()
	performability_script.set_as_copy_of(original.performability_script)
	reactions = []
	for each in original.reactions:
		var new_desirability_script = ScriptManager.new(0)
		var new_reaction = Reaction.new(null, "", new_desirability_script)
		new_reaction.set_as_copy_of(each)
		new_reaction.option = self
		reactions.append(new_reaction)
