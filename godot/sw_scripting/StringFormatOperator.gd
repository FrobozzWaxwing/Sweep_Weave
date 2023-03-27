extends SWOperator
class_name StringFormatOperator
#Formats a string using html tags.
#Used for dynamic text generation.

var value = ""

func _init(in_value = ""):
#	pointer_type = "String Constant"
	input_type = sw_script_data_types.STRING
	output_type = sw_script_data_types.STRING
	set_value(in_value)

func get_value(leaf = null, report = false):
	if (report):
		report_value(value)
	return value

func set_value(in_value):
	if (TYPE_STRING == typeof(in_value)):
		value = in_value
	else:
		print ("Cannot set a string constant to a non-string value.")
		value = ""

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = value
	return output

func data_to_string():
	return value
