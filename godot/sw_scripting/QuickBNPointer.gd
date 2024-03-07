extends SWPointer
class_name QuickBNPointer

var rehearsal = null
var ct_index = 0

func _init(in_rehearsal, in_index):
	rehearsal = in_rehearsal
	ct_index = in_index

static func get_pointer_type():
	return "Quick Bounded Number Pointer"

func get_value():
	return rehearsal.cast_traits[ct_index]

func set_value(value):
	rehearsal.cast_traits[ct_index] = value
	if (value > rehearsal.cast_traits_max[ct_index]):
		rehearsal.cast_traits_max[ct_index] = value
	if (value < rehearsal.cast_traits_min[ct_index]):
		rehearsal.cast_traits_min[ct_index] = value

func validate(intended_script_output_datatype):
	var report = ""
	#Check rehearsal:
	if (null == rehearsal):
		report += "\n" + "Null rehearsal."
	#Check ct_index:
	if (TYPE_INT != typeof(ct_index)):
		report += "\n" + "ct_index is not an integer."
	if (0 > ct_index):
		report += "\n" + "ct_index is out of bounds."
	#Return report.
	if ("" == report):
		return "Passed."
	else:
		return get_pointer_type() + " errors:" + report

func is_parallel_to(sibling):
	return ct_index == sibling.ct_index
