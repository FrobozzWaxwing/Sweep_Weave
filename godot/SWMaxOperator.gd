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

func get_value(leaf = null):
	if (0 == operands.size()):
		print ("Warning: maximum operator has no operands.")
		return null
	var result = null
	for operand in operands:
		var operand_value = evaluate_operand(operand, leaf)
		if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_REAL == typeof(operand_value))):
			if (null == result or operand_value > result):
				result = operand_value
	return result

func data_to_string():
	var result = "Maximum of ("
	for n in range(operands.size()):
		result += stringify_operand_at_index(n) + ", "
	result += ")"
	return result
