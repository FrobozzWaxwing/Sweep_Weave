extends Object
class_name Option

var encounter = null #The encounter this option is associatied with.
var id = ""
var text_script = null
var visibility_script = null
var performability_script = null
var reactions = []
#Variables for editor:
var graph_offset = Vector2(0, 0)
var linked_scripts = []

#Playtesting and Rehearsal:
var occurrences = 0 #The number of times that this encounter has occurred on the current branch. Used by the engine to check whether or not an encounter has occurred.
var reachable = false #Used by the automated rehearsal system to keep track of whether or not an encounter can be reached by the player.
var yielding_paths #The estimated number of possible paths through the storyworld that reach this encounter.
var notable_outcomes = {} # Used to keep track of how often specific events occur after this option is chosen by the player.
var special_ending_count = 0 # Used to keep track of the number of times that the special "The End" page follows this option. Since "The End" is represented in history book entries by null instead of by an encounter, we need a different variable for this than the notable_outcomes variable.
var impact = 0 # An estimate of the difference between the outcomes of this option and the outcomes of this option's siblings.
var outcome_range = 0

func _init(in_encounter, in_id:String, in_text:String, in_graph_offset = Vector2(0, 0)):
	encounter = in_encounter
	id = in_id
	text_script = ScriptManager.new(StringConstant.new(in_text))
	var default = BooleanConstant.new(true)
	visibility_script = ScriptManager.new(default)
	default = BooleanConstant.new(true)
	performability_script = ScriptManager.new(default)
	graph_offset = in_graph_offset

func get_index():
	if (null != encounter):
		return encounter.options.find(self)
	return -1

func get_text():
	if (text_script is ScriptManager):
		if (text_script.sw_script_data_types.STRING == text_script.output_type):
			return text_script.get_value()
	return ""

func set_text(new_text):
	if (text_script is ScriptManager):
		if (text_script.contents is StringConstant):
			text_script.contents.set_value(new_text)

func get_truncated_text(maximum_output_length = 20):
	var text = get_text()
	if (maximum_output_length >= text.length()):
		return text
	else:
		return text.left(maximum_output_length - 3) + "..."

func get_listable_text(maximum_output_length = 200):
	var text = get_text()
	if ("" == text):
		return "[Blank Option]"
	elif (maximum_output_length >= text.length()):
		return text
	else:
		return text.left(maximum_output_length - 3) + "..."

func has_search_text(searchterm):
	if (text_script.has_search_text(searchterm)):
		return true
	else:
		for reaction in reactions:
			if (reaction.has_search_text(searchterm)):
				return true
	return false

func get_listable_impact():
	var estimate = impact * 1000
	estimate = floor(estimate)
	estimate = float(estimate)
	estimate = estimate / 1000
	estimate = str(estimate)
	return estimate

func get_listable_outcome_range():
	var estimate = outcome_range * 1000
	estimate = floor(estimate)
	estimate = float(estimate)
	estimate = estimate / 1000
	estimate = str(estimate)
	return estimate

func compile(_parent_storyworld, _include_editor_only_variables = false):
	var result = {}
	result["id"] = id
	result["text_script"] = text_script.compile(_parent_storyworld, _include_editor_only_variables)
	result["visibility_script"] = null
	if (null != visibility_script and visibility_script is ScriptManager):
		result["visibility_script"] = visibility_script.compile(_parent_storyworld, _include_editor_only_variables)
	result["performability_script"] = null
	if (null != performability_script and performability_script is ScriptManager):
		result["performability_script"] = performability_script.compile(_parent_storyworld, _include_editor_only_variables)
	result["reactions"] = []
	for reaction in reactions:
		result["reactions"].append(reaction.compile(_parent_storyworld, _include_editor_only_variables))
	#Editor only variables:
	if (_include_editor_only_variables):
		result["graph_offset_x"] = graph_offset.x
		result["graph_offset_y"] = graph_offset.y
	return result

func clear():
	encounter = null
	text_script.clear()
	graph_offset = Vector2(0, 0)
	linked_scripts.clear()
	visibility_script.clear()
	visibility_script.call_deferred("free")
	visibility_script = null
	performability_script.clear()
	performability_script.call_deferred("free")
	performability_script = null
	occurrences = 0
	reachable = false
	yielding_paths = 0
	notable_outcomes.clear()
	for reaction in reactions:
		reaction.clear()
		reaction.call_deferred("free")

func set_as_copy_of(original, copy_id = true):
	encounter = original.encounter
	if (copy_id):
		id = original.id
	text_script.set_as_copy_of(original.text_script)
	graph_offset = original.graph_offset
	if (null == visibility_script):
		visibility_script = ScriptManager.new()
	visibility_script.set_as_copy_of(original.visibility_script)
	if (null == performability_script):
		performability_script = ScriptManager.new()
	performability_script.set_as_copy_of(original.performability_script)
	reactions = []
	for reaction in original.reactions:
		var new_desirability_script = ScriptManager.new()
		var r_id = ""
		if (copy_id):
			r_id = reaction.id
		elif (null != encounter and null != encounter.storyworld):
			r_id = encounter.storyworld.unique_id("reaction", 32)
		else:
			r_id = "r" + UUID.v4()
		var new_reaction = Reaction.new(self, r_id, "", new_desirability_script)
		new_reaction.set_as_copy_of(reaction, false)
		new_reaction.option = self
		reactions.append(new_reaction)
