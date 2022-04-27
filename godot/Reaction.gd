extends Object
class_name Reaction

var option = null #The option this reaction is associated with.
var text = ""
#Use 2 desiderata to determine which pValues to blend together,
#and whether or not to negate their values.
var blend_x = null
var blend_y = null
var blend_weight = 0.0
var consequence = null
var pValue_changes = []#{"character": character, "pValue": pValue name (string), "change": blend change amount (float)}.
#Variables for editor:
var graph_offset = Vector2(0, 0)
var occurrences = 0 #Number of times this reaction occurs during a rehearsal.

func _init(in_option, in_text, in_blend_x, in_blend_y, in_blend_weight = 0,
		   in_graph_offset = Vector2(0, 0)):
	option = in_option
	text = in_text
	if (null != in_option):
		if (TYPE_DICTIONARY == typeof(in_blend_x)):
			blend_x = Desideratum.new(in_option.encounter.antagonist, in_blend_x["pValue"], in_blend_x["point"])
		elif (in_blend_x is Desideratum):
			blend_x = in_blend_x
		elif (TYPE_STRING == typeof(in_blend_x)):
			if ("-" == in_blend_x.left(1)):
				blend_x = Desideratum.new(in_option.encounter.antagonist, in_blend_x.substr(1), -1)
			else:
				blend_x = Desideratum.new(in_option.encounter.antagonist, in_blend_x, 1)
		if (TYPE_DICTIONARY == typeof(in_blend_y)):
			blend_y = Desideratum.new(in_option.encounter.antagonist, in_blend_y["pValue"], in_blend_y["point"])
		elif (in_blend_y is Desideratum):
			blend_y = in_blend_y
		elif (TYPE_STRING == typeof(in_blend_y)):
			if ("-" == in_blend_y.left(1)):
				blend_y = Desideratum.new(in_option.encounter.antagonist, in_blend_y.substr(1), -1)
			else:
				blend_y = Desideratum.new(in_option.encounter.antagonist, in_blend_y, 1)
	blend_weight = in_blend_weight
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

func compile(character_list, include_editor_only_variables = false):
	var result = {}
	result["text"] = text
	result["blend_x"] = blend_x.sign_and_pValue()#compile(character_list) May change this to the compile function later on.
	result["blend_y"] = blend_y.sign_and_pValue()#compile(character_list)
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

func set_as_copy_of(original):
	option = original.option
	text = original.text
	if (blend_x is Desideratum):
		blend_x.call_deferred("free")
	blend_x = Desideratum.new(original.blend_x.character, original.blend_x.pValue, original.blend_x.point)
	if (blend_y is Desideratum):
		blend_y.call_deferred("free")
	blend_y = Desideratum.new(original.blend_y.character, original.blend_y.pValue, original.blend_y.point)
	blend_weight = original.blend_weight
	consequence = original.consequence
	graph_offset = original.graph_offset
	var copy_pValue_changes = pValue_changes.duplicate()
	for each in copy_pValue_changes:
		each.call_deferred("free")
	pValue_changes = []
	for change in original.pValue_changes:
		var new_pValueChange = Desideratum.new(change.character, change.pValue, change.point)
		pValue_changes.append(new_pValueChange)

func set_blend_x(text):
	if (!(blend_x is Desideratum)):
		blend_x = Desideratum.new(option.encounter.antagonist, "", 1)
	if ("-" == text.left(1)):
		text = text.substr(1)
		blend_x.pValue = text
		blend_x.point = -1
	else:
		blend_x.pValue = text
		blend_x.point = 1

func set_blend_y(text):
	if (!(blend_y is Desideratum)):
		blend_y = Desideratum.new(option.encounter.antagonist, "", 1)
	if ("-" == text.left(1)):
		text = text.substr(1)
		blend_y.pValue = text
		blend_y.point = -1
	else:
		blend_y.pValue = text
		blend_y.point = 1
