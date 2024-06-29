extends SWOperator
class_name SWNotOperator
#Returns the Boolean negation of the input.

func _init(in_operand = null):
	input_type = sw_script_data_types.BOOLEAN
	output_type = sw_script_data_types.BOOLEAN
	can_add_operands = false
	minimum_number_of_operands = 1
	if (null != in_operand):
		add_operand(in_operand)

func get_operator_type():
	return "Not"

func get_value():
	var output = null
	if (1 <= operands.size()):
		output = evaluate_operand_at_index(0)
		if (true == output):
			output = false
		elif (false == output):
			output = true
	else:
		print ("Warning: not operator has no operands.")
	return output

func get_and_report_value():
	var output = null
	if (1 <= operands.size()):
		output = evaluate_and_report_operand_at_index(0)
		if (true == output):
			output = false
		elif (false == output):
			output = true
	else:
		print ("Warning: not operator has no operands.")
	return output

func data_to_string():
	var result = "Not ("
	result += stringify_operand_at_index(0)
	result += ")"
	return result

