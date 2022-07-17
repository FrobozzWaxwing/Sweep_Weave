extends Object
class_name Reaction

var option = null #The option this reaction is associated with.
var text = ""
# The desirability script holds the "script" for calculating an antagonist's inclination to select this reaction.
var desirability_script = null
var consequence = null
var after_effects = [] #Each array entry should be an AssignmentOperator.
#Variables for editor:
var graph_offset = Vector2(0, 0)
var occurrences = 0 #Number of times this reaction occurs during a rehearsal.

func _init(in_option, in_text, in_desirability_script = null, in_graph_offset = Vector2(0, 0)):
	option = in_option
	text = in_text
	if (null == in_desirability_script):
		var default = BNumberConstant.new(0)
		desirability_script = ScriptManager.new(ArithmeticMeanOperator.new([default]))
	else:
		desirability_script = in_desirability_script
	graph_offset = in_graph_offset

func get_index():
	if (null != option):
		return option.reactions.find(self)
	return -1

func get_antagonist():
	if (null != option):
		if (null != option.encounter):
			if (null != option.encounter.antagonist):
				return option.encounter.antagonist
	return null

func calculate_desirability():
	var result = null
	if (null == desirability_script):
		result = null
	elif (desirability_script is ScriptManager):
		#If everything is working as intended, desirability_script will always contain either a ScriptManager object or a null value.
		result = desirability_script.get_value()
	else:
		result = null
	return result

func has_search_text(searchterm):
	if (searchterm in text):
		return true
	else:
		return false

func compile(parent_storyworld, include_editor_only_variables = false):
	var result = {}
	result["text"] = text
	result["desirability_script"] = null
	if (null != desirability_script and desirability_script is ScriptManager):
		result["desirability_script"] = desirability_script.compile(parent_storyworld, include_editor_only_variables)
	if (null == consequence):
		result["consequence_id"] = "wild"
	else:
		result["consequence_id"] = consequence.id
	result["after_effects"] = []
	for change in after_effects:
		result["after_effects"].append(change.compile(parent_storyworld, include_editor_only_variables))
	#Editor only variables:
	if (include_editor_only_variables):
		result["graph_offset_x"] = graph_offset.x
		result["graph_offset_y"] = graph_offset.y
	return result

func clear():
	option = null
	text = ""
#	if (desirability_script is ScriptManager):
#		desirability_script.clear()
#		desirability_script.call_deferred("free")
#		desirability_script = null
	consequence = null
	graph_offset = Vector2(0, 0)
#	for change in after_effects:
#		change.clear()
#		change.call_deferred("free")
#	after_effects.clear()

func set_as_copy_of(original):
	option = original.option
	text = original.text
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
		var change_copy = AssignmentOperator.new()
		var succeeded = change_copy.set_as_copy_of(change)
		if (succeeded):
			after_effects.append(change_copy)
		else:
			change_copy.call_deferred("free")
