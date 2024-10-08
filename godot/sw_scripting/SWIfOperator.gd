extends SWOperator
class_name SWIfOperator

func _init(in_condition = null, in_outcome1 = null, in_outcome2 = null):
	input_type = sw_script_data_types.VARIANT
	output_type = sw_script_data_types.VARIANT
	can_add_operands = true
	minimum_number_of_operands = 3
	if (null != in_condition and null != in_outcome1 and null != in_outcome2):
		add_operand(in_condition)
		add_operand(in_outcome1)
		add_operand(in_outcome2)

func get_operator_type():
	return "If Then"

func add_conditional(condition, conditional_result):
	if (null != condition and null != conditional_result):
		var last_operand = operands.pop_back()
		add_operand(condition)
		add_operand(conditional_result)
		add_operand(last_operand)

func remove_conditional(in_index):
	var index = in_index
	if (1 == in_index % 2):
		#index refers to a conditional result.
		index = in_index -1
	#Remove condition.
	var operand = operands[index]
	operands.remove_at(index)
	operand.clear()
	operand.call_deferred("free")
	#Remove conditional result.
	operand = operands[index]
	operands.remove_at(index)
	operand.clear()
	operand.call_deferred("free")
	for i in range(index, operands.size()):
		operand = operands[i]
		if (operand is SWScriptElement):
			operand.script_index = i

func get_value():
	var output = null
	var stop = operands.size() - 1
	for index in range(0, stop, 2):
		var condition_result = evaluate_operand_at_index(index)
		if (condition_result):
			var result_index = index + 1
			output = evaluate_operand_at_index(result_index)
			break
	if (null == output):
		output = evaluate_operand_at_index(stop)
	return output

func get_and_report_value():
	var output = null
	var stop = operands.size() - 1
	for index in range(0, stop, 2):
		var condition_result = evaluate_and_report_operand_at_index(index)
		if (condition_result):
			var result_index = index + 1
			output = evaluate_and_report_operand_at_index(result_index)
			break
	if (null == output):
		output = evaluate_and_report_operand_at_index(stop)
	return output

func data_to_string():
	var result = "If "
	result += stringify_operand_at_index(0) + " then "
	result += stringify_operand_at_index(1) + ", else "
	result += stringify_operand_at_index(2) + "."
	return result
