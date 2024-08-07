extends SWPointer
class_name BooleanConstant
#Holds a boolean constant, either true or false.
#Mainly necessary to make constructing and editing scripts easier.
#Sometimes it is useful to be able to obtain the parent operator of a boolean constant in a script. Making a "boolean constant" class lets us do that.

var value = null

func _init(in_value):
	output_type = sw_script_data_types.BOOLEAN
	set_value(in_value)

func get_pointer_type():
	return "Boolean Constant"

func get_value():
	return value

func set_value(in_value):
	if (TYPE_BOOL == typeof(in_value)):
		value = in_value
	else:
		print ("Cannot set a boolean constant to a non-boolean value.")
		value = null

func compile(_parent_storyworld, _include_editor_only_variables = false):
	var output = value
	return output

func data_to_string():
	return str(value)

func is_parallel_to(sibling):
	return value == sibling.value
