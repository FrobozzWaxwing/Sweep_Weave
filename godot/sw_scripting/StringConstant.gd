extends SWPointer
class_name StringConstant
#Holds a string constant.
#Used for dynamic text generation.

var value = ""

func _init(in_value = ""):
	pointer_type = "String Constant"
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

func clear():
	treeview_node = null
	value = ""

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Pointer"
	output["pointer_type"] = pointer_type
	output["value"] = value
	return output

func data_to_string():
	return value

func find_occurrences(searchterm):
	var results = []
	var index = 0
	while (-1 != index):
		index = value.find(searchterm, index)
		if (-1 != index):
			results.append(index)
			index += 1
	return results
