extends Object
class_name Reaction

var option = null #The option this reaction is associated with.
var text = ""
var blend_x = ""
var blend_y = ""
var blend_weight = 0.0
var consequence = null#Encounter.new("consequence", "Consequence Title", "Consequence main text.", [], [], 0, 1000, 0, [], -1)
var pValue_changes = [];#{"character": character, "pValue": pValue name (string), "change": blend change amount (float)}.
#Variables for editor:
var graph_offset = Vector2(0, 0)

func _init(in_option, in_text, in_blend_x, in_blend_y, in_blend_weight,
		   in_graph_offset = Vector2(0, 0)):
	option = in_option
	text = in_text
	blend_x = in_blend_x
	blend_y = in_blend_y
	blend_weight = in_blend_weight
	graph_offset = in_graph_offset

func get_index():
	if (null != option):
		return option.reactions.find(self)
	return -1

func compile(character_list, include_editor_only_variables = false):
	var result = {}
	result["text"] = text
	result["blend_x"] = blend_x
	result["blend_y"] = blend_y
	result["blend_weight"] = blend_weight
	if (null == consequence):
		result["consequence_id"] = "wild"
	else:
		result["consequence_id"] = consequence.id
	result["pValue_changes"] = []
	for each in pValue_changes:
		result["pValue_changes"].append(each.compile(character_list))
	#Editor only variables:
	if (include_editor_only_variables):
		result["graph_offset_x"] = graph_offset.x
		result["graph_offset_y"] = graph_offset.y
	return result
