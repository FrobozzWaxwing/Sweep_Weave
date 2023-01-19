extends SWOperator
class_name ArithmeticNegationOperator

func _init(in_operand = null):
	operator_type = "Arithmetic Negation"
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	can_add_operands = false
	minimum_number_of_operands = 1
	if (null != in_operand):
		add_operand(in_operand)

func get_value(leaf = null):
	if (0 == operands.size()):
		print ("Warning: arithmetic negation operator has no operands.")
		return null
	var operand_value = evaluate_operand(operands.front(), leaf)
	if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_REAL == typeof(operand_value))):
		return -1 * operand_value
