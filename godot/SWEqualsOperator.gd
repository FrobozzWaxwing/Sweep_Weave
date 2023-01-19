extends SWOperator
class_name SWEqualsOperator

func _init(in_operands = []):
	operator_type = "Equals"
	input_type = sw_script_data_types.VARIANT
	if (0 < in_operands.size()):
		var operand = in_operands[0]
		if (operand is SWScriptElement):
			if (sw_script_data_types.BNUMBER == operand.output_type):
				input_type = sw_script_data_types.BNUMBER
			elif (sw_script_data_types.BOOLEAN == operand.output_type):
				input_type = sw_script_data_types.BOOLEAN
	output_type = sw_script_data_types.BOOLEAN
	can_add_operands = true
	minimum_number_of_operands = 2
	for operand in in_operands:
		add_operand(operand)

func get_value(leaf = null):
	var target_value = null
	for operand in operands:
		var operand_value = evaluate_operand(operand, leaf)
		if (null == target_value):
			target_value = operand_value
			continue
		elif (null == operand_value):
			continue
		elif (typeof(target_value) != typeof(operand_value)):
			#Poison.
			return null
		elif (target_value == operand_value):
			continue
		elif (target_value != operand_value):
			return false
	if (null != target_value):
		return true
	else:
		#Poison.
		return null

func data_to_string():
	var result = "Equals ("
	for n in range(operands.size()):
		result += stringify_operand_at_index(n) + ", "
	result += ")"
	return result
