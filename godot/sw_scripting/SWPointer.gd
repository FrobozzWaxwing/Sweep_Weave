extends SWScriptElement
class_name SWPointer
# A pointer, for use in SweepWeave scripts.

func _init():
	pass

func data_to_string():
	return "SweepWeave Pointer"

static func get_pointer_type():
	return "Generic Pointer"

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Pointer"
	output["pointer_type"] = get_pointer_type()
	return output

func validate(intended_script_output_datatype):
	return "Passed."
