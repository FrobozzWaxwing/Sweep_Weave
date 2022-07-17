extends SWScriptElement
class_name SWPointer
# A pointer, for use in SweepWeave scripts.

var pointer_type = "Generic Pointer"

func _init():
	pass

func data_to_string():
	return "SweepWeave Pointer"

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Pointer"
	output["pointer_type"] = pointer_type
	return output
