extends SWPointer
class_name EventPointer
# This operator tests whether or not an event has occurred.

var negated = false #Do we negate the result of the evaluation?
var encounter = null #Only for historybook lookups. Translated into a string for interpreter.
var option = null #Only for historybook lookups. Translated into a numerical index for interpreter.
var reaction = null #Only for historybook lookups. Translated into a numerical index for interpreter.

func _init(in_encounter = null, in_option = null, in_reaction = null):
	output_type = sw_script_data_types.BOOLEAN
	encounter = in_encounter
	option = in_option
	reaction = in_reaction

static func get_pointer_type():
	return "Event Pointer"

func clear():
	treeview_node = null
	negated = false
	encounter = null
	option = null
	reaction = null

func get_value():
	if (null == encounter):
		return null
	var has_occurred = false
	if (0 < encounter.occurrences):
		if (null == option or 0 < option.occurrences):
			if (null == reaction or 0 < reaction.occurrences):
				has_occurred = true
	if (negated != has_occurred):
		return true
	else:
		return false

func data_to_string():
	return summarize()

func summarize():
	var output = ""
	if (false == negated):
		output += "Event has occurred: "
	else:
		output += "Event has not occurred: "
	if (null != encounter):
		output += encounter.title
	else:
		output += "Null"
	if (null != option):
		output += " / " + option.get_text().left(25)
	if (null != reaction):
		output += " / " + reaction.get_text().left(25)
	output += "."
	return output

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Pointer"
	output["pointer_type"] = get_pointer_type()
	output["negated"] = negated
	if (null == encounter):
		output["encounter"] = null
	else:
		output["encounter"] = encounter.id
	if (include_editor_only_variables):
		#Saving to json:
		if (null == option):
			output["option"] = null
		else:
			output["option"] = option.id
		if (null == reaction):
			output["reaction"] = null
		else:
			output["reaction"] = reaction.id
	else:
		#Compiling to html:
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
	negated = original.negated
	encounter = original.encounter
	option = original.option
	reaction = original.reaction

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
			clear()
			return false
	else:
		option = null
		reaction = null
	return true

func validate(intended_script_output_datatype):
	var report = ""
	#Check negated:
	if (TYPE_BOOL != typeof(negated)):
		report += "\n" + "Negated is not a boolean."
	if (null == encounter and null == option and null == reaction):
		report += "\n" + "Encounter, option, and reaction are all null."
	if ("" == report):
		return "Passed."
	else:
		return get_pointer_type() + " errors:" + report

func is_parallel_to(sibling):
	return negated == sibling.negated and encounter == sibling.encounter and option == sibling.option and reaction == sibling.reaction
