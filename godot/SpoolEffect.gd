extends SWEffect
class_name SpoolEffect
#An object used to activate and deactivate spools.


enum sw_script_data_types {BOOLEAN, BNUMBER, STRING, VARIANT}

func _init(in_assignee = null, in_assignment_script = null):
	effect_type = "Spool Effect"
	if (in_assignee is SpoolPointer):
		assignee = in_assignee
		assignee.parent_operator = self
	if (in_assignment_script is ScriptManager):
		assignment_script = in_assignment_script

func enact(leaf = null):
	if (null != assignee and assignee is SpoolPointer and null != assignment_script and assignment_script is ScriptManager):
		var activate_spool = null
		activate_spool = assignment_script.get_value(leaf, false)
		if (null != activate_spool):
			if (true == activate_spool):
				print("test")
				assignee.activate()
			else:
				assignee.deactivate()
			return true
	return false #An error occurred.

func set_as_copy_of(original):
	var success = true
	if (assignee is SpoolPointer and original.assignee is SpoolPointer):
		assignee.set_as_copy_of(original.assignee)
	elif (null == assignee and original.assignee is SpoolPointer):
		assignee = SpoolPointer.new()
		assignee.set_as_copy_of(original.assignee)
	else:
		success = false
	if (assignment_script is ScriptManager and original.assignment_script is ScriptManager):
		assignment_script.set_as_copy_of(original.assignment_script)
	elif (null == assignment_script and original.assignment_script is ScriptManager):
		assignment_script = ScriptManager.new()
		assignment_script.set_as_copy_of(original.assignment_script)
	else:
		success = false
	return success

func remap(storyworld):
	var result = true
	if (assignee is SWScriptElement):
		var check = assignee.remap(storyworld)
		result = (result and check)
	if (assignment_script is ScriptManager):
		var check = assignment_script.remap(storyworld)
		result = (result and check)
	return result

func data_to_string():
	var result = "Set "
	if (assignee is SWScriptElement):
		result += assignee.data_to_string() + " is_active"
	else:
		result += "[invalid operand]"
	result += " to "
	if (assignment_script is ScriptManager):
		result += assignment_script.data_to_string()
	else:
		result += "[invalid script]"
	result += "."
	return result

func compile(parent_storyworld, include_editor_only_variables = false):
	if (!(assignee is SpoolPointer and assignment_script is ScriptManager)):
		print ("Error, attempted to compile invalid Setter.")
		return null
	var output = {}
	output["effect_type"] = effect_type
	output["Set"] = assignee.compile(parent_storyworld, include_editor_only_variables)
	output["to"] = assignment_script.compile(parent_storyworld, include_editor_only_variables)
	return output

func load_from_json_v0_0_34_through_v0_0_37(storyworld, data_to_load):
	clear()
	if (data_to_load.has_all(["Set", "to"])):
		if (TYPE_STRING == typeof(data_to_load["Set"]) and storyworld.spool_directory.has(data_to_load["Set"])):
			var script_element = SpoolPointer.new(storyworld.spool_directory[data_to_load["Set"]])
			script_element.parent_operator = self
			assignee = script_element
		var script = ScriptManager.new()
		var output_datatype = sw_script_data_types.VARIANT
		if (null != assignee and assignee is SWPointer):
			if (assignee.output_type == sw_script_data_types.BNUMBER):
				output_datatype = sw_script_data_types.BNUMBER
			elif (assignee.output_type == sw_script_data_types.BOOLEAN):
				output_datatype = sw_script_data_types.BOOLEAN
		script.load_from_json_v0_0_34_through_v0_0_37(storyworld, data_to_load["to"], output_datatype)
		assignment_script = script
	if (null != assignee and assignee is SpoolPointer and null != assignment_script and assignment_script is ScriptManager):
		return true
	else:
		return false

func validate(intended_script_output_datatype):
	var validation_report = ""
	if (null == assignee):
		validation_report += "Null spool."
	elif (assignee is SWPointer):
		var set_report = assignee.validate(intended_script_output_datatype)
		if ("Passed." != set_report):
			validation_report += "\"Set\" operand errors:\n" + set_report
		if (null == assignment_script):
			validation_report += "\"To\" operand is null."
		elif (assignment_script is ScriptManager):
			var to_report = assignment_script.validate(sw_script_data_types.BOOLEAN)
			if ("Passed." != to_report):
				validation_report += "\"To\" operand errors:\n" + to_report
		else:
			validation_report += "\"To\" operand is invalid."
	else:
		validation_report += "Invalid spool."
	if ("" == validation_report):
		return "Passed."
	else:
		return effect_type + " errors:\n" + validation_report
