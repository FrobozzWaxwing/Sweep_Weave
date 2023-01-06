extends SWOperator
class_name SWIfOperator

func _init(in_condition, in_outcome1, in_outcome2):
	operator_type = "If Then"
	minimum_number_of_operands = 3
	input_type = sw_script_data_types.VARIANT
	output_type = sw_script_data_types.VARIANT
	add_operand(in_condition)
	add_operand(in_outcome1)
	add_operand(in_outcome2)

func get_value(leaf = null):
	var condition_result = evaluate_operand_at_index(0, leaf)
	if (null == condition_result):
		return null
	elif (condition_result):
		var value = evaluate_operand_at_index(1, leaf)
		return value
	else:
		var value = evaluate_operand_at_index(2, leaf)
		return value

func data_to_string():
	var result = "If "
	result += stringify_operand_at_index(0) + " then "
	result += stringify_operand_at_index(1) + ", otherwise "
	result += stringify_operand_at_index(2) + "."
	return result
