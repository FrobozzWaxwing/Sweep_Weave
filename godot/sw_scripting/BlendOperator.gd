extends SWOperator
class_name BlendOperator

func _init(in_operand_0, in_operand_1, in_weight):
	minimum_number_of_operands = 3
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	can_add_operands = false
	minimum_number_of_operands = 3
	add_operand(in_operand_0)
	add_operand(in_operand_1)
	add_operand(in_weight)

static func get_operator_type():
	return "Blend"

func get_value():
	var value_0 = evaluate_operand_at_index(0)
	var value_1 = evaluate_operand_at_index(1)
	var value_weight = evaluate_operand_at_index(2)
#	var normalized_weight = ((value_weight + 1) / 2)
#	var output = (value_0 * (1 - normalized_weight)) + (value_1 * normalized_weight)
	var output = lerp(value_0, value_1, ((value_weight + 1) / 2))
	return output

func get_and_report_value():
	var value_0 = evaluate_and_report_operand_at_index(0)
	var value_1 = evaluate_and_report_operand_at_index(1)
	var value_weight = evaluate_and_report_operand_at_index(2)
#	var normalized_weight = ((value_weight + 1) / 2)
#	var output = (value_0 * (1 - normalized_weight)) + (value_1 * normalized_weight)
	var output = lerp(value_0, value_1, ((value_weight + 1) / 2))
	return output

func data_to_string():
	var result = "Blend of "
	result += stringify_operand_at_index(0) + " and "
	result += stringify_operand_at_index(1) + " with weight "
	result += stringify_operand_at_index(2)
	return result
