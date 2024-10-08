extends Object
class_name Reaction

var option = null #The option this reaction is associated with.
var id = ""
var text_script = null
# The desirability script holds the "script" for calculating an antagonist's inclination to select this reaction.
var desirability_script = null
var consequence = null
var after_effects = [] #Each array entry should be a SWEffect.
#Variables for editor:
var graph_offset = Vector2(0, 0)
var linked_scripts = []

#Playtesting and Rehearsal:
var occurrences = 0 #The number of times that this event has occurred on the current branch. Used by the engine to check whether or not an event has occurred.
var reachable = false #Used by the automated rehearsal system to keep track of whether or not an event can be reached by the player.
var yielding_paths #The estimated number of possible paths through the storyworld that reach this event.

var changes_cast = false
var changes_spools = false

func _init(in_option, in_id:String, in_text:String, in_desirability_script = null, in_graph_offset = Vector2(0, 0)):
	option = in_option
	id = in_id
	text_script = ScriptManager.new(StringConstant.new(in_text))
	if (null == in_desirability_script):
		var default = BNumberConstant.new(0)
		desirability_script = ScriptManager.new(default)
	else:
		desirability_script = in_desirability_script
	graph_offset = in_graph_offset

func get_index():
	if (null != option):
		return option.reactions.find(self)
	return -1

func get_text():
	if (text_script is ScriptManager):
		if (text_script.sw_script_data_types.STRING == text_script.output_type):
			return text_script.get_value()
	return ""

func set_text(new_text:String):
	if (text_script is ScriptManager):
		if (text_script.contents is StringConstant):
			text_script.contents.set_value(new_text)

func get_truncated_text(maximum_output_length:int = 20):
	var text = get_text()
	if (maximum_output_length >= text.length()):
		return text
	else:
		return text.left(maximum_output_length - 3) + "..."

func get_listable_text(maximum_output_length:int = 200):
	var text = get_text()
	if ("" == text):
		return "[Blank Reaction]"
	text = text.get_slice("\n", 0)
	if (maximum_output_length >= text.length()):
		return text
	else:
		return text.left(maximum_output_length - 3) + "..."

func calculate_desirability():
	var result = null
	if (desirability_script is ScriptManager):
		#If everything is working as intended, desirability_script will always contain either a ScriptManager object or a null value.
		result = desirability_script.get_value()
	return result

func calculate_and_report_desirability():
	var result = null
	if (desirability_script is ScriptManager):
		#If everything is working as intended, desirability_script will always contain either a ScriptManager object or a null value.
		result = desirability_script.get_and_report_value()
	return result

func has_search_text(searchterm:String):
	if (text_script.has_search_text(searchterm)):
		return true
	else:
		return false

func add_effect(effect):
	if (effect is SWEffect):
		after_effects.append(effect)
		effect.cause = self

func compile(_parent_storyworld, _include_editor_only_variables:bool = false):
	var result = {}
	result["id"] = id
	result["text_script"] = text_script.compile(_parent_storyworld, _include_editor_only_variables)
	result["desirability_script"] = null
	if (desirability_script is ScriptManager):
		result["desirability_script"] = desirability_script.compile(_parent_storyworld, _include_editor_only_variables)
	if (null == consequence):
		result["consequence_id"] = "wild"
	else:
		result["consequence_id"] = consequence.id
	result["after_effects"] = []
	for change in after_effects:
		result["after_effects"].append(change.compile(_parent_storyworld, _include_editor_only_variables))
	#Editor only variables:
	if (_include_editor_only_variables):
		result["graph_offset_x"] = graph_offset.x
		result["graph_offset_y"] = graph_offset.y
	return result

func clear():
	option = null
	text_script.clear()
	if (is_instance_valid(desirability_script) and desirability_script is ScriptManager):
		desirability_script.clear()
		desirability_script.call_deferred("free")
		desirability_script = null
	consequence = null
	graph_offset = Vector2(0, 0)
	linked_scripts.clear()
	occurrences = 0
	reachable = false
	yielding_paths = 0
	for change in after_effects:
		if (is_instance_valid(change) and change is SWEffect):
			change.clear()
			change.call_deferred("free")
	after_effects.clear()

func set_as_copy_of(original, copy_id:bool = true):
	option = original.option
	if (copy_id):
		id = original.id
	text_script.set_as_copy_of(original.text_script)
	if (null == desirability_script):
		desirability_script = ScriptManager.new()
	desirability_script.set_as_copy_of(original.desirability_script)
	consequence = original.consequence
	graph_offset = original.graph_offset
	for change in after_effects:
		change.clear()
		change.call_deferred("free")
	after_effects.clear()
	for change in original.after_effects:
		if (change is BNumberEffect):
			var change_copy = BNumberEffect.new()
			var succeeded = change_copy.set_as_copy_of(change)
			if (succeeded):
				add_effect(change_copy)
			else:
				change_copy.call_deferred("free")
		elif (change is SpoolEffect):
			var change_copy = SpoolEffect.new()
			var succeeded = change_copy.set_as_copy_of(change)
			if (succeeded):
				add_effect(change_copy)
			else:
				change_copy.call_deferred("free")

func is_parallel_to(sibling):
	#Returns true if this reaction causes the same effects as the sibling in question, and false if some difference is detected.
	if (!linked_scripts.is_empty() or !option.linked_scripts.is_empty()):
		return false
	if (consequence != sibling.consequence):
		return false
	if (after_effects.size() != sibling.after_effects.size()):
		return false
	for index in range(after_effects.size()):
		if (!after_effects[index].is_parallel_to(sibling.after_effects[index])):
			return false
	return true
