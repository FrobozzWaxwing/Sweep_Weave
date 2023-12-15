extends SWOperator
class_name NudgeOperator

func _init(in_operand_0 = null, in_operand_1 = null):
	minimum_number_of_operands = 2
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	can_add_operands = false
	minimum_number_of_operands = 2
	add_operand(in_operand_0)
	add_operand(in_operand_1)

static func get_operator_type():
	return "Nudge"

func get_value():
	var output = null
	var value_0 = evaluate_operand_at_index(0)
	var value_1 = evaluate_operand_at_index(1)
	if (null != value_0 and null != value_1):
		output = (value_0 * (1 - abs(value_1))) + value_1
	return output

func get_and_report_value():
	var output = null
	var value_0 = evaluate_and_report_operand_at_index(0)
	var value_1 = evaluate_and_report_operand_at_index(1)
	if (null != value_0 and null != value_1):
		output = (value_0 * (1 - abs(value_1))) + value_1
	return output

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
