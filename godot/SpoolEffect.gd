extends SWEffect
class_name SpoolEffect
#An object used to activate and deactivate spools.

var spool = null
var setter_script = null

enum sw_script_data_types {BOOLEAN, BNUMBER, VARIANT}

func _init(in_spool = null, in_setter_script = null):
	effect_type = "Spool Effect"
	if (in_spool is SpoolPointer):
		spool = in_spool
		spool.parent_operator = self
	if (in_setter_script is ScriptManager):
		setter_script = in_setter_script

func enact(leaf = null):
	if (null != spool and spool is SpoolPointer and null != setter_script and setter_script is ScriptManager):
		var activate_spool = null
		activate_spool = setter_script.get_value(leaf)
		if (null != activate_spool):
			if (true == activate_spool):
				print("test")
				spool.activate()
			else:
				spool.deactivate()
			return true
	return false #An error occurred.

func set_as_copy_of(original):
	var success = true
	if (spool is SpoolPointer and original.spool is SpoolPointer):
		spool.set_as_copy_of(original.spool)
	elif (null == spool and original.spool is SpoolPointer):
		spool = SpoolPointer.new()
		spool.set_as_copy_of(original.spool)
	else:
		success = false
	if (setter_script is ScriptManager and original.setter_script is ScriptManager):
		setter_script.set_as_copy_of(original.setter_script)
	elif (null == setter_script and original.setter_script is ScriptManager):
		setter_script = ScriptManager.new()
		setter_script.set_as_copy_of(original.setter_script)
	else:
		success = false
	return success

func remap(storyworld):
	var result = true
	if (spool is SWScriptElement):
		var check = spool.remap(storyworld)
		result = (result and check)
	if (setter_script is ScriptManager):
		var check = setter_script.remap(storyworld)
		result = (result and check)
	return result

func clear():
	if (spool is SWScriptElement):
		spool.clear()
		spool.call_deferred("free")
	spool = null
	if (setter_script is ScriptManager):
		setter_script.clear()
		setter_script.call_deferred("free")
	setter_script = null

func data_to_string():
	var result = "Set "
	if (spool is SWScriptElement):
		result += spool.data_to_string() + " is_active"
	else:
		result += "[invalid operand]"
	result += " to "
	if (setter_script is ScriptManager):
		result += setter_script.data_to_string()
	else:
		result += "[invalid script]"
	result += "."
	return result

func compile(parent_storyworld, include_editor_only_variables = false):
	if (!(spool is SpoolPointer and setter_script is ScriptManager)):
		print ("Error, attempted to compile invalid Setter.")
		return null
	var output = {}
	output["effect_type"] = effect_type
	output["Set"] = spool.compile(parent_storyworld, include_editor_only_variables)
	output["to"] = setter_script.compile(parent_storyworld, include_editor_only_variables)
	return output

func load_from_json_v0_0_30(storyworld, data_to_load):
	clear()
	if (data_to_load.has_all(["Set", "to"])):
		if (data_to_load["Set"].has_all(["pointer_type", "spool"]) and "Spool Pointer" == data_to_load["Set"]["pointer_type"] and TYPE_STRING == typeof(data_to_load["Set"]["spool"]) and storyworld.spool_directory.has(data_to_load["Set"]["spool"])):
			var script_element = SpoolPointer.new(storyworld.spool_directory[data_to_load["Set"]["spool"]])
			script_element.parent_operator = self
			spool = script_element
		if (data_to_load["to"].has("script_element_type")):
			var script = ScriptManager.new()
			var output_datatype = sw_script_data_types.VARIANT
			if (null != spool and spool is SWPointer):
				if (spool.output_type == sw_script_data_types.BNUMBER):
					output_datatype = sw_script_data_types.BNUMBER
				elif (spool.output_type == sw_script_data_types.BOOLEAN):
					output_datatype = sw_script_data_types.BOOLEAN
			script.load_from_json_v0_0_21(storyworld, data_to_load["to"], output_datatype)
			setter_script = script
	if (null != spool and spool is SpoolPointer and null != setter_script and setter_script is ScriptManager):
		return true
	else:
		return false

func validate(intended_script_output_datatype):
	var validation_report = ""
	if (null == spool):
		validation_report += "Null spool."
	elif (spool is SWPointer):
		var set_report = spool.validate(intended_script_output_datatype)
		if ("Passed." != set_report):
			validation_report += "\"Set\" operand errors:\n" + set_report
		if (null == setter_script):
			validation_report += "\"To\" operand is null."
		elif (setter_script is ScriptManager):
			var to_report = setter_script.validate(spool.output_type)
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
