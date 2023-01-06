extends SWOperator
class_name ArithmeticAbsoluteValueOperator

func _init(in_operand = null):
	operator_type = "Absolute Value"
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	can_add_operands = false
	if (null != in_operand):
		add_operand(in_operand)

func get_value(leaf = null):
	if (0 == operands.size()):
		print ("Warning: absolute value operator has no operands.")
		return null
	var operand_value = evaluate_operand(operands.front(), leaf)
	if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_REAL == typeof(operand_value))):
		return abs(operand_value)
