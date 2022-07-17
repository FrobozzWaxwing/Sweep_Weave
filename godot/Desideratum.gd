extends SWOperator
class_name Desideratum

func _init(in_operand_0 = null, in_operand_1 = null):
	operator_type = "Desideratum"
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	add_operand(in_operand_0)
	add_operand(in_operand_1)

func get_distance_between_operands(leaf = null):
	var value_0 = evaluate_operand_at_index(0, leaf)
	var value_1 = evaluate_operand_at_index(1, leaf)
	if ((TYPE_INT == typeof(value_0) or TYPE_REAL == typeof(value_0)) and (TYPE_INT == typeof(value_1) or TYPE_REAL == typeof(value_1))):
		return abs(value_0 - value_1)
	else:
		print ("Error evaluating desideratum.")
		return 1.98

func get_value(leaf = null):
	var result = 0.99 - get_distance_between_operands(leaf)
	return clamp(result, -0.99, 0.99)

func data_to_string():
	if (2 != operands.size()):
		return "Invalid Proximity-to operator."
	var result = "How close is "
	if (null != operands[0] and operands[0] is SWScriptElement):
		result += operands[0].data_to_string()
	else:
		result += str(operands[0])
	result += " to "
	if (null != operands[1] and operands[1] is SWScriptElement):
		result += operands[1].data_to_string()
	else:
		result += str(operands[1])
	result += "?"
	return result
