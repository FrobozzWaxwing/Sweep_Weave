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

func remap(storyworld):
	treeview_node = null
	return true

func get_value(leaf = null, report = false):
	# Some operators, particularly EventPointers and BooleanComparators that contain EventPointers, need access to the historybook.
	# The "leaf" variable grants EventPointers this access.
	var output = null
	if (report):
		report_value(output)
	return output

func report_value(output):
	if (null != treeview_node and treeview_node is TreeItem):
		treeview_node.set_text(1, str(output))

func compile(parent_storyworld, include_editor_only_variables = false):
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

func validate(intended_script_output_datatype):
	return "Generic script element found."
