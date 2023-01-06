extends SWEffect
class_name BNumberEffect
#An object used to set variables, such as bounded number properties.

# Variable to set: operand_0 (Should be a BNumberPointer.)
# What to set it to: operand_1 (Should be a ScriptManager.)
var operand_0 = null
var operand_1 = null

enum sw_script_data_types {BOOLEAN, BNUMBER, VARIANT}

func _init(in_operand_0 = null, in_operand_1 = null):
	effect_type = "Bounded Number Effect"
	if (in_operand_0 is BNumberPointer):
		operand_0 = in_operand_0
		operand_0.parent_operator = self
	if (in_operand_1 is ScriptManager):
		operand_1 = in_operand_1

func get_value(leaf = null):
	#This will return the value of the second operand, but will not change the value of the first operand.
	if (null == operand_1):
		return null
	var value = 0
	if (operand_1 is ScriptManager):
		value = operand_1.get_value(leaf)
	else:
		return null
	return value

func enact(leaf = null):
	if (null != operand_0 and operand_0 is BNumberPointer):
		var result = get_value(leaf)
		if (null != result):
			operand_0.set_value(result)
			return true
	return false #An error occurred.

func set_as_copy_of(original):
	var success = true
	if (operand_0 is BNumberPointer and original.operand_0 is BNumberPointer):
		operand_0.set_as_copy_of(original.operand_0)
	elif (null == operand_0 and original.operand_0 is BNumberPointer):
		operand_0 = BNumberPointer.new()
		operand_0.set_as_copy_of(original.operand_0)
	else:
		success = false
	if (operand_1 is ScriptManager and original.operand_1 is ScriptManager):
		operand_1.set_as_copy_of(original.operand_1)
	elif (null == operand_1 and original.operand_1 is ScriptManager):
		operand_1 = ScriptManager.new()
		operand_1.set_as_copy_of(original.operand_1)
	else:
		success = false
	return success

func remap(storyworld):
	var result = true
	if (operand_0 is SWScriptElement):
		var check = operand_0.remap(storyworld)
		result = (result and check)
	if (operand_1 is ScriptManager):
		var check = operand_1.remap(storyworld)
		result = (result and check)
	return result

func clear():
	if (operand_0 is SWScriptElement):
		operand_0.clear()
		operand_0.call_deferred("free")
	operand_0 = null
	if (operand_1 is ScriptManager):
		operand_1.clear()
		operand_1.call_deferred("free")
	operand_1 = null

func data_to_string():
	var result = "Set "
	if (operand_0 is BNumberPointer):
		result += operand_0.data_to_string()
	else:
		result += "[invalid operand]"
	result += " to "
	if (operand_1 is ScriptManager):
		result += operand_1.data_to_string()
	else:
		result += "[invalid script]"
	result += "."
	return result

func compile(parent_storyworld, include_editor_only_variables = false):
	if (!(operand_0 is BNumberPointer and operand_1 is ScriptManager)):
		print ("Error, attempted to compile invalid Setter.")
		return null
	var output = {}
	output["effect_type"] = effect_type
	output["Set"] = operand_0.compile(parent_storyworld, include_editor_only_variables)
	output["to"] = operand_1.compile(parent_storyworld, include_editor_only_variables)
	return output

func load_from_json_v0_0_21(storyworld, data_to_load):
	clear()
	if (data_to_load.has_all(["Set", "to"])):
		if (data_to_load["Set"].has_all(["pointer_type", "character", "coefficient", "keyring"]) and "Bounded Number Pointer" == data_to_load["Set"]["pointer_type"] and TYPE_STRING == typeof(data_to_load["Set"]["character"]) and storyworld.character_directory.has(data_to_load["Set"]["character"])):
			var character = storyworld.character_directory[data_to_load["Set"]["character"]]
			var script_element = BNumberPointer.new(character, data_to_load["Set"]["keyring"])
			script_element.coefficient = data_to_load["Set"]["coefficient"]
			script_element.parent_operator = self
			operand_0 = script_element
		if (data_to_load["to"].has("script_element_type")):
			var script = ScriptManager.new()
			var output_datatype = sw_script_data_types.VARIANT
			if (null != operand_0 and operand_0 is SWPointer):
				if (operand_0.output_type == sw_script_data_types.BNUMBER):
					output_datatype = sw_script_data_types.BNUMBER
				elif (operand_0.output_type == sw_script_data_types.BOOLEAN):
					output_datatype = sw_script_data_types.BOOLEAN
			script.load_from_json_v0_0_21(storyworld, data_to_load["to"], output_datatype)
			operand_1 = script
	if (null != operand_0 and operand_0 is BNumberPointer and null != operand_1 and operand_1 is ScriptManager):
		return true
	else:
		return false

func validate(intended_script_output_datatype):
	var validation_report = ""
	if (null == operand_0):
		validation_report += "Effect \"set\" operand is null."
	elif (operand_0 is SWPointer):
		var set_report = operand_0.validate(intended_script_output_datatype)
		if ("Passed." != set_report):
			validation_report += "Effect \"set\" operand errors:\n" + set_report
		if (null == operand_1):
			validation_report += "Effect \"to\" operand is null."
		else:
			var to_report = operand_1.validate(operand_0.output_type)
			if ("Passed." != to_report):
				validation_report += "Effect \"to\" operand errors:\n" + to_report
	if ("" == validation_report):
		return "Passed."
	else:
		return "Setter errors:\n" + validation_report
