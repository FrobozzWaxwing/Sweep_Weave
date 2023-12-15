extends SWOperator
class_name StringConcatenationOperator
#Concatenates strings.
#Used for dynamic text generation.

func _init(in_operands = []):
	input_type = sw_script_data_types.STRING
	output_type = sw_script_data_types.STRING
	for operand in in_operands:
		add_operand(operand)

static func get_operator_type():
	return "Concatenate"

func get_value():
	var output = ""
	for operand in operands:
		output += evaluate_operand(operand)
	return output

func get_and_report_value():
	var output = ""
	for operand in operands:
		output += evaluate_and_report_operand(operand)
	return output

func data_to_string():
	return get_value()
