extends SWOperator
class_name NudgeOperator

func _init(in_operand_0 = null, in_operand_1 = null):
	operator_type = "Nudge"
	minimum_number_of_operands = 2
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	add_operand(in_operand_0)
	add_operand(in_operand_1)

func get_value(leaf = null):
	var value_0 = evaluate_operand_at_index(0, leaf)
	var value_1 = evaluate_operand_at_index(1, leaf)
	var result = (value_0 * (1 - abs(value_1))) + value_1
	return result

func data_to_string():
	var result = "Nudge ("
	result += stringify_operand_at_index(0) + ","
	result += stringify_operand_at_index(1) + ")"
	return result

#func explain_adjustment():
#	var property_description = ""
#	if (null != operands[0] and operands[0] is SWScriptElement):
#		property_description += operands[0].data_to_string()
#	var output = ""
#	if (0 == operands[1]):
#		output += "Leave " + property_description + " the same."
#	elif (0 < operands[1]):
#		var percentage = operands[1] * 100
#		output += "Increase " + property_description + " " + str(percentage) + "% of the distance from its present value to 1."
#	else:
#		var percentage = operands[1] * 100
#		output += "Decrease " + property_description + " " + str(percentage) + "% of the distance from its present value to -1."
#	return output
