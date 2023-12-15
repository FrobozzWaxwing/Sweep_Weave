extends SWOperator
class_name ArithmeticNegationOperator

func _init(in_operand = null):
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	can_add_operands = false
	minimum_number_of_operands = 1
	if (null != in_operand):
		add_operand(in_operand)

static func get_operator_type():
	return "Arithmetic Negation"

func get_value():
	var output = null
	if (0 == operands.size()):
		print ("Warning: arithmetic negation operator has no operands.")
	else:
		var operand_value = evaluate_operand(operands.front())
		if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_REAL == typeof(operand_value))):
			output = -1 * operand_value
	return output

func get_and_report_value():
	var output = null
	if (0 == operands.size()):
		print ("Warning: arithmetic negation operator has no operands.")
	else:
		var operand_value = evaluate_and_report_operand(operands.front())
		if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_REAL == typeof(operand_value))):
			output = -1 * operand_value
	return output
