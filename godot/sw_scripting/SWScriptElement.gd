extends Object
class_name SWScriptElement

enum sw_script_data_types {BOOLEAN, BNUMBER, STRING, VARIANT}

#A script consists of a tree of operators and pointers.
#"parent_operator" refers to the operator or script manager containing the present operator or pointer.
var parent_operator = null
var script_index = 0
var output_type = sw_script_data_types.VARIANT
#Variables for editor:
var treeview_node = null

func _init():
	pass

func clear():
	treeview_node = null

func remap(_storyworld):
	treeview_node = null
	return true

func get_value():
	return null

func report_value(output):
	if (treeview_node is TreeItem):
		treeview_node.set_text(1, str(output))

func get_and_report_value():
	var output = get_value()
	report_value(output)
	return output

func compile(_parent_storyworld, _include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Element"
	return output

func stringify_output_type():
	if (sw_script_data_types.BOOLEAN == output_type):
		return "boolean" #Javascript datatype
	elif (sw_script_data_types.BNUMBER == output_type):
		return "number" #Javascript datatype
	elif (sw_script_data_types.STRING == output_type):
		return "string" #Javascript datatype
	elif (sw_script_data_types.VARIANT == output_type):
		return "variant"
	else:
		return ""

func data_to_string():
	return "SweepWeave Script Element"

func validate(_intended_script_output_datatype):
	return "Generic script element found."
