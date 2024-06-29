extends SWOperator
class_name SWMinOperator

func _init(in_operands = []):
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	can_add_operands = true
	minimum_number_of_operands = 2
	for operand in in_operands:
		add_operand(operand)

func get_operator_type():
	return "Minimum of"

func get_value():
	var output = null
	if (0 == operands.size()):
		print ("Warning: minimum operator has no operands.")
	else:
		for operand in operands:
			var operand_value = evaluate_operand(operand)
			if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_FLOAT == typeof(operand_value))):
				if (null == output or operand_value < output):
					output = operand_value
	return output

func get_and_report_value():
	var output = null
	if (0 == operands.size()):
		print ("Warning: minimum operator has no operands.")
	else:
		for operand in operands:
			var operand_value = evaluate_and_report_operand(operand)
			if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_FLOAT == typeof(operand_value))):
				if (null == output or operand_value < output):
					output = operand_value
	return output

func data_to_string():
	var result = "Minimum of ("
	for n in range(operands.size()):
		result += stringify_operand_at_index(n) + ", "
	result += ")"
	return result
