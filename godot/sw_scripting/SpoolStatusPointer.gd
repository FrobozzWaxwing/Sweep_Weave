extends SWPointer
class_name SpoolStatusPointer
#A script element used to check whether or not a spool is active.

var spool = null
var negated = false

func _init(in_spool = null, in_negated = false):
	output_type = sw_script_data_types.BOOLEAN
	if (in_spool is Spool):
		spool = in_spool
	negated = in_negated

func get_pointer_type():
	return "Spool Status Pointer"

func get_value():
	var output = null
	if (spool is Spool):
		output = spool.is_active
	else:
		output = null
	return output

func set_as_copy_of(original):
	if (null == original.spool):
		spool = null
	elif (original.spool is Spool):
		spool = original.spool
	else:
		spool = null
	negated = original.negated

func remap(to_storyworld):
	if (spool is Spool and to_storyworld.spool_directory.has(spool.id)):
		spool = to_storyworld.spool_directory[spool.id]
		return true
	else:
		spool = null
		return false

func clear():
	treeview_node = null
	spool = null
	negated = false

func compile(_parent_storyworld, _include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Pointer"
	output["pointer_type"] = get_pointer_type()
	if (spool is Spool):
		output["spool"] = spool.id
	else:
		output["spool"] = null
	output["negated"] = negated
	return output

func data_to_string():
	if (spool is Spool):
		var output = spool.spool_name + " is "
		if (negated):
			output += "not active."
		else:
			output += "active."
		return output
	else:
		return "Invalid Spool Status Pointer"

func validate(_intended_script_output_datatype):
	var report = ""
	#Check spool:
	if (null == spool):
		report += "\n" + "Null spool."
	elif (!(spool is Spool)):
		report += "\n" + "Invalid spool."
	elif (!is_instance_valid(spool)):
		report += "\n" + "Spool has been deleted."
	if ("" == report):
		return "Passed."
	else:
		return get_pointer_type() + " errors:" + report

func is_parallel_to(sibling):
	return negated == sibling.negated and spool == sibling.spool
