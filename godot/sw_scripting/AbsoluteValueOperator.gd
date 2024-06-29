extends SWOperator
class_name AbsoluteValueOperator

func _init(in_operand = null):
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	can_add_operands = false
	minimum_number_of_operands = 1
	if (null != in_operand):
		add_operand(in_operand)

func get_operator_type():
	return "Absolute Value"

func get_value():
	var output = null
	if (0 == operands.size()):
		print ("Warning: absolute value operator has no operands.")
	var operand_value = evaluate_operand(operands.front())
	if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_FLOAT == typeof(operand_value))):
		output = abs(operand_value)
	return output

func get_and_report_value():
	var output = null
	if (0 == operands.size()):
		print ("Warning: absolute value operator has no operands.")
	var operand_value = evaluate_and_report_operand(operands.front())
	if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_FLOAT == typeof(operand_value))):
		output = abs(operand_value)
	return output
