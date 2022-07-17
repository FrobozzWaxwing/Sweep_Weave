extends Object
class_name SWScriptElement

enum sw_script_data_types {BOOLEAN, BNUMBER, VARIANT}

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
	pass

func remap(storyworld):
	return true

func get_value(leaf = null):
	# Some operators, particularly EventPointers and BooleanOperators that contain EventPointers, need access to the historybook.
	# The "leaf" variable grants EventPointers this access.
	return null

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Element"
	return output

func data_to_string():
	return "SweepWeave Script Element"
