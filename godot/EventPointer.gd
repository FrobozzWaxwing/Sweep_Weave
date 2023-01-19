extends SWPointer
class_name EventPointer
# This operator tests whether or not an event has occurred.

var negated = false #Do we negate the result of the evaluation?
var spool = null
var encounter = null #Only for historybook lookups. Translated into a string for interpreter.
var option = null #Only for historybook lookups. Translated into a numerical index for interpreter.
var reaction = null #Only for historybook lookups. Translated into a numerical index for interpreter.

func _init(in_encounter = null, in_option = null, in_reaction = null):
	pointer_type = "Event Pointer"
	output_type = sw_script_data_types.BOOLEAN
	encounter = in_encounter
	option = in_option
	reaction = in_reaction

func clear():
	negated = false
	spool = null
	encounter = null
	option = null
	reaction = null

func has_occurred_on_branch(leaf):
	#Checks whether an encounter has occurred.
	#Optionally checks whether the player chose a given option,
	#and / or whether the antagonist chose a given reaction.
	#null for wildcarding option and reaction.
	if (null == encounter):
		return null
	elif (null == leaf):
		#Playthrough has only just begun.
		return false
	elif (null == option && null == reaction):
		var node = leaf
		while (null != node):
			if (null != node.get_metadata(0).encounter and node.get_metadata(0).encounter == encounter):
				return true
			#No match for this node.
			#Go farther towards the root of the tree.
			node = node.get_parent()
	else:
		var node = leaf
		while (null != node and null != node.get_parent()):
			if (node.get_parent().get_metadata(0).encounter == encounter):
				if (null == option && reaction == node.get_metadata(0).antagonist_choice):
					return true
				elif (option == node.get_metadata(0).player_choice && null == reaction):
					return true
				elif (option == node.get_metadata(0).player_choice && reaction == node.get_metadata(0).antagonist_choice):
					return true
			#No match for this node.
			#Go farther towards the root of the tree.
			node = node.get_parent()
	return false

func get_value(leaf = null):
	var has_occurred = has_occurred_on_branch(leaf)
	if (null == negated or null == has_occurred):
		return null
	elif (negated != has_occurred):
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
	output["pointer_type"] = pointer_type
	output["negated"] = negated
	if (null == spool):
		output["spool"] = null
	else:
		output["spool"] = spool.id
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
	spool = original.spool
	encounter = original.encounter
	option = original.option
	reaction = original.reaction

func remap(storyworld):
	if (null != spool):
		if (storyworld.spool_directory.has(spool.id)):
			spool = storyworld.spool_directory[spool.id]
		else:
			clear()
			return false
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
	if (null == spool and null == encounter and null == option and null == reaction):
		report += "\n" + "Spool, encounter, option, and reaction are all null."
	if ("" == report):
		return "Passed."
	else:
		return pointer_type + " errors:" + report
