extends Object
class_name Prerequisite

#Prerequisite types:
#A different Encounter occurred.
#	Optional: action was chosen by player,
#	and reaction was chosen by character.
#Scene is active.
#pValue is within a range, where the minimum and maximum are both constants.
#pValue compares in some way with another pValue.
#	E.g. Sam loves the player more than Lucy.
#	May use statistical operators to stand in for specific characters, as in:
#	Sam loves the player more than anyone else.
#
#Variable types:
#	Event (encounter, action, reaction.)
#	Scene.
#	Constant.
#	pValue (Who and which?)
#	pValue statistic (maximum, minimum, median, mean. Which pValue?)
#Possible comparisons:
#	0	Event to boolean for hasOccurred
#	1	Scene to boolean for active
#	2	pValue to constant
#	3	pValue to pValue
#	4	pValueStat to constant
#	5	pValueStat to pValue

var prereq_type = 0
var negated = false #Do we negate the result of the evaluation?
var encounter = null #Only for historybook lookups. Translated into a string for interpreter.
var option = null #Only for historybook lookups. Translated into a numerical index for interpreter.
var reaction = null #Only for historybook lookups. Translated into a numerical index for interpreter.
var encounter_scene = "" #Only for scene inqueries.
var who1 = null
var pValue1 = null#"pBad_Good"
var operator = ">="
var constant = 0
var who2 = null
var pValue2 = null#"pBad_Good"

func _init(in_prereq_type, in_negated):
	prereq_type = in_prereq_type
	negated = in_negated

func summarize():
	var output = ""
	if (0 == prereq_type):
		if (false == negated):
			output = "Event has occurred: "
		else:
			output = "Event has not occurred: "
		output += encounter.title
		if (null != option):
			output += " / " + option.text.left(20)
			if (null != reaction):
				output += " / " + reaction.text.left(20)
		output += "."
	return output

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = {}
	output["prereq_type"] = prereq_type
	output["negated"] = negated
	output["encounter"] = encounter.id
	if (null == option):
		output["option"] = -1
	else:
		output["option"] = option.get_index()
	if (null == reaction):
		output["reaction"] = -1
	else:
		output["reaction"] = reaction.get_index()
	return output

func set_as_copy_of(original):
	prereq_type = original.prereq_type
	negated = original.negated
	encounter = original.encounter
	option = original.option
	reaction = original.reaction
	encounter_scene = original.encounter_scene
	who1 = original.who1
	pValue1 = original.pValue1
	operator = original.operator
	constant = original.constant
	who2 = original.who2
	pValue2 = original.pValue2

func remap(storyworld):
	#Returns false if an error occurs, and true if everything goes as planned.
	if (null != encounter):
		if (storyworld.encounter_directory.has(encounter.id)):
			encounter = storyworld.encounter_directory[encounter.id]
			if (null != option):
				option = encounter.options[option.get_index()]
				if (null != reaction):
					reaction = option.reactions[reaction.get_index()]
			else:
				reaction = null
		else:
			return false
	else:
		option = null
		reaction = null
	return true
