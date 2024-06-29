extends SWPointer
class_name StringConstant
#Holds a string constant.
#Used for dynamic text generation.

var value = ""

func _init(in_value = ""):
	output_type = sw_script_data_types.STRING
	set_value(in_value)

func get_pointer_type():
	return "String Constant"

func get_value():
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

func compile(_parent_storyworld, _include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Pointer"
	output["pointer_type"] = get_pointer_type()
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

func is_parallel_to(sibling):
	return value == sibling.value
