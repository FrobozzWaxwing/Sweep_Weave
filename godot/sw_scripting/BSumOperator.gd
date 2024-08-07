extends SWOperator
class_name BSumOperator

func _init(in_operands = []):
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	can_add_operands = true
	minimum_number_of_operands = 2
	for operand in in_operands:
		add_operand(operand)

func get_operator_type():
	return "Bounded Sum"

func convert_bounded_to_normal(x):
	if (0 == x):
		return 0
	elif (0 < x):
		return (1/(1-x))-1
	else:
		return (1/(-1-x))+1

func convert_normal_to_bounded(x):
	if (0 == x):
		return 0
	elif (0 < x):
		return 1-(1/(x+1))
	else:
		return -1-(1/(x-1))

func get_value():
	var output = 0
	for operand in operands:
		var operand_value = evaluate_operand(operand)
		if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_FLOAT == typeof(operand_value))):
			output += convert_bounded_to_normal(operand_value)
	output = convert_normal_to_bounded(output)
	return output

func get_and_report_value():
	var output = 0
	for operand in operands:
		var operand_value = evaluate_and_report_operand(operand)
		if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_FLOAT == typeof(operand_value))):
			output += convert_bounded_to_normal(operand_value)
	output = convert_normal_to_bounded(output)
	return output
