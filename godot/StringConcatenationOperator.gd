extends SWOperator
class_name StringConcatenationOperator
#Concatenates strings.
#Used for dynamic text generation.

func _init(in_operands = []):
	operator_type = "Concatenate"
	input_type = sw_script_data_types.STRING
	output_type = sw_script_data_types.STRING
	for operand in in_operands:
		add_operand(operand)

func get_value(leaf = null):
	var value = ""
	for operand in operands:
		value += evaluate_operand(operand, leaf)
	return value

func data_to_string():
	return get_value(null)
