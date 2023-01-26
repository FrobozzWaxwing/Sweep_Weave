extends SWPointer
class_name BNumberConstant

var value = 0
var lower_boundary = -0.99
var upper_boundary = 0.99

func _init(in_value):
	pointer_type = "Bounded Number Constant"
	output_type = sw_script_data_types.BNUMBER
	set_value(in_value)

func get_value(leaf = null, report = false):
	var output = clamp(value, lower_boundary, upper_boundary)
	if (report):
		report_value(output)
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
	output["pointer_type"] = pointer_type
	output["value"] = get_value()
	return output

func data_to_string():
	return str(value)
