extends SWPointer
class_name BNumberConstant

var value = 0
const lower_boundary = -0.99
const upper_boundary = 0.99

func _init(in_value):
	output_type = sw_script_data_types.BNUMBER
	set_value(in_value)

static func get_pointer_type():
	return "Bounded Number Constant"

func get_value():
	var output = clamp(value, lower_boundary, upper_boundary)
	return output

func set_value(in_value):
	if (TYPE_INT == typeof(in_value) or TYPE_REAL == typeof(in_value)):
		value = clamp(in_value, lower_boundary, upper_boundary)
	else:
		print ("Cannot set a bounded number constant to a non-numerical value.")
		value = null

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Pointer"
	output["pointer_type"] = get_pointer_type()
	output["value"] = get_value()
	return output

func data_to_string():
	return str(value)

func is_parallel_to(sibling):
	return value == sibling.value
