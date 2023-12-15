extends SWOperator
class_name Desideratum

func _init(in_operand_0 = null, in_operand_1 = null):
	minimum_number_of_operands = 2
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	can_add_operands = false
	minimum_number_of_operands = 2
	add_operand(in_operand_0)
	add_operand(in_operand_1)

static func get_operator_type():
	return "Desideratum"

func get_value():
	var value_0 = evaluate_operand_at_index(0)
	var value_1 = evaluate_operand_at_index(1)
	var distance = 1.98
	if ((TYPE_INT == typeof(value_0) or TYPE_REAL == typeof(value_0)) and (TYPE_INT == typeof(value_1) or TYPE_REAL == typeof(value_1))):
		distance = abs(value_0 - value_1)
	else:
		print ("Error evaluating desideratum.")
	var output = 0.99 - distance
	output = clamp(output, -0.99, 0.99)
	return output

func get_and_report_value():
	var value_0 = evaluate_and_report_operand_at_index(0)
	var value_1 = evaluate_and_report_operand_at_index(1)
	var distance = 1.98
	if ((TYPE_INT == typeof(value_0) or TYPE_REAL == typeof(value_0)) and (TYPE_INT == typeof(value_1) or TYPE_REAL == typeof(value_1))):
		distance = abs(value_0 - value_1)
	else:
		print ("Error evaluating desideratum.")
	var output = 0.99 - distance
	output = clamp(output, -0.99, 0.99)
	return output

func data_to_string():
	if (2 != operands.size()):
		return "Invalid Proximity-to operator."
	var result = "How close is "
	if (operands[0] is SWScriptElement):
		result += operands[0].data_to_string()
	else:
		result += str(operands[0])
	result += " to "
	if (operands[1] is SWScriptElement):
		result += operands[1].data_to_string()
	else:
		result += str(operands[1])
	result += "?"
	return result
