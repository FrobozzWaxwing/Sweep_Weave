extends SWEffect
class_name BNumberEffect
#An object used to set variables, such as bounded number properties.

# Variable to set: assignee (Should be a BNumberPointer.)
# What to set it to: assignment_script (Should be a ScriptManager.)

enum sw_script_data_types {BOOLEAN, BNUMBER, STRING, VARIANT}

func _init(in_assignee = null, in_assignment_script = null):
	effect_type = "Bounded Number Effect"
	if (in_assignee is BNumberPointer):
		assignee = in_assignee
		assignee.parent_operator = self
	if (in_assignment_script is ScriptManager):
		assignment_script = in_assignment_script

func enact(leaf = null):
	if (null != assignee and assignee is BNumberPointer and assignment_script is ScriptManager):
		var result = assignment_script.get_value(leaf, false)
		if (null != result):
			assignee.set_value(result)
			return true
	return false #An error occurred.

func set_as_copy_of(original):
	var success = true
	if (assignee is BNumberPointer and original.assignee is BNumberPointer):
		assignee.set_as_copy_of(original.assignee)
	elif (null == assignee and original.assignee is BNumberPointer):
		assignee = BNumberPointer.new()
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
	cause = original.cause
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
	if (assignee is BNumberPointer):
		result += assignee.data_to_string()
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
	if (!(assignee is BNumberPointer and assignment_script is ScriptManager)):
		print ("Error, attempted to compile invalid Setter.")
		return null
	var output = {}
	output["effect_type"] = effect_type
	output["Set"] = assignee.compile(parent_storyworld, include_editor_only_variables)
	output["to"] = assignment_script.compile(parent_storyworld, include_editor_only_variables)
	return output

func load_from_json_v0_0_21_through_v0_0_29(storyworld, data_to_load):
	clear()
	if (data_to_load.has_all(["Set", "to"])):
		if (data_to_load["Set"].has_all(["pointer_type", "character", "coefficient", "keyring"]) and "Bounded Number Pointer" == data_to_load["Set"]["pointer_type"] and TYPE_STRING == typeof(data_to_load["Set"]["character"]) and storyworld.character_directory.has(data_to_load["Set"]["character"])):
			var character = storyworld.character_directory[data_to_load["Set"]["character"]]
			var script_element = BNumberPointer.new(character, data_to_load["Set"]["keyring"])
			script_element.coefficient = data_to_load["Set"]["coefficient"]
			script_element.parent_operator = self
			assignee = script_element
		if (data_to_load["to"].has("script_element_type")):
			var script = ScriptManager.new()
			var output_datatype = sw_script_data_types.VARIANT
			if (null != assignee and assignee is SWPointer):
				if (assignee.output_type == sw_script_data_types.BNUMBER):
					output_datatype = sw_script_data_types.BNUMBER
				elif (assignee.output_type == sw_script_data_types.BOOLEAN):
					output_datatype = sw_script_data_types.BOOLEAN
			script.load_from_json_v0_0_21_through_v0_0_29(storyworld, data_to_load["to"], output_datatype)
			assignment_script = script
	if (null != assignee and assignee is BNumberPointer and null != assignment_script and assignment_script is ScriptManager):
		return true
	else:
		return false

func load_from_json_v0_0_34_through_v0_0_38(storyworld, data_to_load):
	clear()
	if (data_to_load.has_all(["Set", "to"])):
		if (data_to_load["Set"].has_all(["pointer_type", "character", "coefficient", "keyring"]) and "Bounded Number Pointer" == data_to_load["Set"]["pointer_type"] and TYPE_STRING == typeof(data_to_load["Set"]["character"]) and storyworld.character_directory.has(data_to_load["Set"]["character"])):
			var character = storyworld.character_directory[data_to_load["Set"]["character"]]
			var script_element = BNumberPointer.new(character, data_to_load["Set"]["keyring"])
			script_element.coefficient = data_to_load["Set"]["coefficient"]
			script_element.parent_operator = self
			assignee = script_element
		if (data_to_load["to"].has("script_element_type")):
			var script = ScriptManager.new()
			var output_datatype = sw_script_data_types.VARIANT
			if (null != assignee and assignee is SWPointer):
				if (assignee.output_type == sw_script_data_types.BNUMBER):
					output_datatype = sw_script_data_types.BNUMBER
				elif (assignee.output_type == sw_script_data_types.BOOLEAN):
					output_datatype = sw_script_data_types.BOOLEAN
			script.load_from_json_v0_0_34_through_v0_0_38(storyworld, data_to_load["to"], output_datatype)
			assignment_script = script
	if (null != assignee and assignee is BNumberPointer and null != assignment_script and assignment_script is ScriptManager):
		return true
	else:
		return false

func validate(intended_script_output_datatype):
	var validation_report = ""
	if (null == assignee):
		validation_report += "Effect \"set\" operand is null."
	elif (assignee is SWPointer):
		var set_report = assignee.validate(intended_script_output_datatype)
		if ("Passed." != set_report):
			validation_report += "Effect \"set\" operand errors:\n" + set_report
		if (null == assignment_script):
			validation_report += "Effect \"to\" operand is null."
		else:
			var to_report = assignment_script.validate(sw_script_data_types.BNUMBER)
			if ("Passed." != to_report):
				validation_report += "Effect \"to\" operand errors:\n" + to_report
	if ("" == validation_report):
		return "Passed."
	else:
		return "Setter errors:\n" + validation_report
