extends SWOperator
class_name SWNotOperator
#Returns the Boolean negation of the input.

func _init(in_operand = null):
	operator_type = "Not"
	input_type = sw_script_data_types.BOOLEAN
	output_type = sw_script_data_types.BOOLEAN
	can_add_operands = false
	minimum_number_of_operands = 1
	if (null != in_operand):
		add_operand(in_operand)

func get_value(leaf = null, report = false):
	var output = null
	if (1 <= operands.size()):
		output = evaluate_operand_at_index(0, leaf, report)
		if (true == output):
			output = false
		elif (false == output):
			output = true
	else:
		print ("Warning: not operator has no operands.")
	if (report):
		report_value(output)
	return output

func data_to_string():
	var result = "Not ("
	result += stringify_operand_at_index(0)
	result += ")"
	return result

