extends Object
class_name Option

var encounter = null #The encounter this option is associatied with.
var text = ""
var visibility_prerequisites = []
var performability_prerequisites = []
var reactions = []
#Variables for editor:
var graph_offset = Vector2(0, 0)

func _init(in_encounter, in_text, in_graph_offset = Vector2(0, 0)):
	encounter = in_encounter
	text = in_text
	graph_offset = in_graph_offset

func get_index():
	if (null != encounter):
		return encounter.options.find(self)
	return -1

func compile(character_list, include_editor_only_variables = false):
	var result = {}
	result["text"] = text
	result["visibility_prerequisites"] = []
	for prerequisite in visibility_prerequisites:
		result["visibility_prerequisites"].append(prerequisite.compile())
	result["performability_prerequisites"] = []
	for prerequisite in performability_prerequisites:
		result["performability_prerequisites"].append(prerequisite.compile())
	result["reactions"] = []
	for reaction in reactions:
		result["reactions"].append(reaction.compile(character_list, include_editor_only_variables))
	#Editor only variables:
	if (include_editor_only_variables):
		result["graph_offset_x"] = graph_offset.x
		result["graph_offset_y"] = graph_offset.y
	return result
