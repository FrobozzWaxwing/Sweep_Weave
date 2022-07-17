extends SWOperator
class_name BSumOperator

func _init(in_operands = []):
	operator_type = "Bounded Sum"
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BNUMBER
	can_add_operands = true
	for operand in in_operands:
		add_operand(operand)

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

func get_value(leaf = null):
	var result = 0
	for operand in operands:
		var operand_value = evaluate_operand(operand, leaf)
		if (null != operand_value and (TYPE_INT == typeof(operand_value) or TYPE_REAL == typeof(operand_value))):
			result += convert_bounded_to_normal(operand_value)
	return convert_normal_to_bounded(result)
