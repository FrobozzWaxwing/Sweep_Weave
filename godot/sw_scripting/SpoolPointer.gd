extends SWPointer
class_name SpoolPointer

var spool = null

func _init(in_spool = null):
	output_type = sw_script_data_types.VARIANT
	set_value(in_spool)

func get_pointer_type():
	return "Spool Pointer"

func get_value():
	return spool

func set_value(in_spool):
	if (in_spool is Spool or in_spool is QuickSpool):
		spool = in_spool
	else:
		spool = null

func set_as_copy_of(original):
	if (null == original.spool):
		spool = null
	elif (original.spool is Spool or original.spool is QuickSpool):
		spool = original.spool
	else:
		spool = null

func remap(to_storyworld):
	if ((spool is Spool or spool is QuickSpool) and to_storyworld.spool_directory.has(spool.id)):
		spool = to_storyworld.spool_directory[spool.id]
		return true
	else:
		spool = null
		return false

func clear():
	treeview_node = null
	spool = null

func activate():
	if (spool is Spool or spool is QuickSpool):
		spool.activate()
		return true
	else:
		return false

func deactivate():
	if (spool is Spool or spool is QuickSpool):
		spool.deactivate()
		return true
	else:
		return false

func compile(_parent_storyworld, _include_editor_only_variables = false):
	var output = null
	if (spool is Spool or spool is QuickSpool):
		output = spool.id
	return output

func data_to_string():
	if (spool is Spool or spool is QuickSpool):
		return spool.spool_name
	else:
		return "Invalid SpoolPointer"

func validate(_intended_script_output_datatype):
	var report = ""
	#Check spool:
	if (null == spool):
		report += "\n" + "Null spool."
	elif (!(spool is Spool or spool is QuickSpool)):
		report += "\n" + "Invalid spool."
	elif (!is_instance_valid(spool)):
		report += "\n" + "Spool has been deleted."
	if ("" == report):
		return "Passed."
	else:
		return get_pointer_type() + " errors:" + report

func is_parallel_to(sibling):
	return spool == sibling.spool
