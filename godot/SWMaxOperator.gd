extends SWOperator
class_name SWMaxOperator

func _init(in_operands = []):
	operator_type = "Maximum of"
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	can_add_operands = true
	minimum_number_of_operands = 2
	for operand in in_operands:
		add_operand(operand)

func get_value(leaf = null, report = false):
	var output = null
	if (0 == operands.size()):
		print ("Warning: maximum operator has no operands.")
	else:
		for operand in operands:
			var operand_value = evaluate_operand(operand, leaf, report)
			if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_REAL == typeof(operand_value))):
				if (null == output or operand_value > output):
					output = operand_value
	if (report):
		report_value(output)
	return output

func data_to_string():
	var result = "Maximum of ("
	for n in range(operands.size()):
		result += stringify_operand_at_index(n) + ", "
	result += ")"
	return result
