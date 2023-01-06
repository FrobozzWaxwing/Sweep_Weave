extends SWPointer
class_name SpoolPointer

var spool = null

func _init(in_spool = null):
	pointer_type = "Spool Pointer"
	output_type = sw_script_data_types.VARIANT
	set_value(in_spool)

func get_value(leaf = null):
	return spool

func set_value(in_spool):
	if (in_spool is Spool):
		spool = in_spool
	else:
		spool = null

func set_as_copy_of(original):
	if (null == original.spool):
		spool = null
	elif (original.spool is Spool):
		spool = original.spool
	else:
		spool = null

func remap(to_storyworld):
	if (spool is Spool and to_storyworld.spool_directory.has(spool.id)):
		spool = to_storyworld.spool_directory[spool.id]
		return true
	else:
		spool = null
		return false

func clear():
	spool = null

func activate():
	if (spool is Spool):
		spool.activate()
		return true
	else:
		return false

func deactivate():
	if (spool is Spool):
		spool.deactivate()
		return true
	else:
		return false

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Pointer"
	output["pointer_type"] = pointer_type
	if (spool is Spool):
		output["spool"] = spool.id
	else:
		output["spool"] = null
	return output

func data_to_string():
	if (spool is Spool):
		return spool.spool_name
	else:
		return "Invalid SpoolPointer"

func validate(intended_script_output_datatype):
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
		return pointer_type + " errors:" + report
