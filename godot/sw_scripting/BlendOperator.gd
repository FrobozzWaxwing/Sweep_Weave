extends SWOperator
class_name BlendOperator

func _init(in_operand_0, in_operand_1, in_weight):
	operator_type = "Blend"
	minimum_number_of_operands = 3
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	can_add_operands = false
	minimum_number_of_operands = 3
	add_operand(in_operand_0)
	add_operand(in_operand_1)
	add_operand(in_weight)

func get_value(leaf = null, report = false):
	var value_0 = evaluate_operand_at_index(0, leaf, report)
	var value_1 = evaluate_operand_at_index(1, leaf, report)
	var value_weight = evaluate_operand_at_index(2, leaf, report)
	var normalized_weight = ((value_weight + 1) / 2)
	var output = (value_0 * (1 - normalized_weight)) + (value_1 * normalized_weight)
	if (report):
		report_value(output)
	return output

func data_to_string():
	var result = "Blend of "
	result += stringify_operand_at_index(0) + " and "
	result += stringify_operand_at_index(1) + " with weight "
	result += stringify_operand_at_index(2)
	return result
