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

func get_value(leaf = null, report = false):
	var output = ""
	for operand in operands:
		output += evaluate_operand(operand, leaf, report)
	if (report):
		report_value(output)
	return output

func data_to_string():
	return get_value(null, false)
