extends SWScriptElement
class_name SWOperator

var input_type = sw_script_data_types.VARIANT
var operands = []
#If "can_add_operands" is true, this operator can employ an arbitrarily long list of operands, though it will require at least one operand to work as intended.
#If "can_add_operands" is false, this operator has a set number of operands.
var can_add_operands = false
var minimum_number_of_operands = 0

func _init():
	pass

func add_operand(operand):
	operands.append(operand)
	if (operand is SWScriptElement):
		operand.parent_operator = self
		operand.script_index = operands.size() - 1

func erase_operand(operand_to_erase):
	operands.remove_at(operand_to_erase.script_index)
	for i in range(operand_to_erase.script_index, operands.size()):
		var operand = operands[i]
		if (operand is SWScriptElement):
			operand.script_index = i
	operand_to_erase.clear()
	operand_to_erase.call_deferred("free")

func remap(storyworld):
	var result = true
	for operand in operands:
		if (operand is SWScriptElement):
			var check = operand.remap(storyworld)
			result = (result and check)
	return result

func evaluate_operand(operand):
	var result = null
	if (operand is SWScriptElement):
		result = operand.get_value()
	if (null == result):
		print ("Warning: Invalid operand.")
	return result

func evaluate_operand_at_index(operand_index):
	if (null == operand_index or operand_index >= operands.size()):
		#Operator does not contain an operand at the index specified.
		return null
	var operand = operands[operand_index]
	return evaluate_operand(operand)

func evaluate_and_report_operand(operand):
	var result = null
	if (operand is SWScriptElement):
		result = operand.get_and_report_value()
	if (null == result):
		print ("Warning: Invalid operand.")
	return result

func evaluate_and_report_operand_at_index(operand_index):
	if (null == operand_index or operand_index >= operands.size()):
		#Operator does not contain an operand at the index specified.
		return null
	var operand = operands[operand_index]
	return evaluate_and_report_operand(operand)

func clear():
	treeview_node = null
	for operand in operands:
		if (operand is SWScriptElement):
			operand.clear()
			operand.call_deferred("free")
	operands.clear()

func get_operator_type():
	return "Generic Operation"

func stringify_input_type():
	if (sw_script_data_types.BOOLEAN == input_type):
		return "boolean" #Javascript datatype
	elif (sw_script_data_types.BNUMBER == input_type):
		return "number" #Javascript datatype
	elif (sw_script_data_types.STRING == output_type):
		return "string" #Javascript datatype
	elif (sw_script_data_types.VARIANT == input_type):
		return "variant"
	else:
		return ""

func compile(_parent_storyworld, _include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Operator"
	output["operator_type"] = get_operator_type()
	if (!_include_editor_only_variables):
		output["input_type"] = stringify_input_type()
	output["operands"] = []
	for operand in operands:
		if (null == operand):
			output["operands"].append(null)
		elif (TYPE_BOOL == typeof(operand)):
			output["operands"].append(operand)
		elif (TYPE_INT == typeof(operand) or TYPE_FLOAT == typeof(operand)):
			output["operands"].append(operand)
		elif (operand is SWScriptElement):
			output["operands"].append(operand.compile(_parent_storyworld, _include_editor_only_variables))
	return output

func stringify_operand_at_index(operand_index):
	if (null == operand_index or operand_index >= operands.size()):
		#Operator does not contain an operand at the index specified.
		return "null"
	var operand = operands[operand_index]
	var result = "null"
	if (null == operand):
		pass
	elif (TYPE_BOOL == typeof(operand) or TYPE_INT == typeof(operand) or TYPE_FLOAT == typeof(operand)):
		result = str(operand)
	elif (TYPE_STRING == typeof(operand)):
		result = "\"" + operand + "\""
	elif (operand is SWScriptElement):
		result = operand.data_to_string()
	return result

func data_to_string():
	return "SweepWeave Script Operator"

func validate(_intended_script_output_datatype):
	var validation_report = ""
	if (operands.is_empty()):
		validation_report += " contains no operands."
	elif (minimum_number_of_operands > operands.size()):
		validation_report += " contains only " + str(operands.size()) + " operands, while requiring at least " + str(minimum_number_of_operands) + " operands."
	var index = 0
	for operand in operands:
		if (!(operand is SWScriptElement)):
			if (null == operand):
				validation_report += "\n" + "Operand is null."
			if (TYPE_BOOL == typeof(operand) or TYPE_INT == typeof(operand) or TYPE_FLOAT == typeof(operand)):
				validation_report += "\n" + "Operand is raw data, (" + str(operand) + ",) rather than a SweepWeave script element."
		elif (!is_instance_valid(operand)):
			validation_report += "\n" + "Operand has been deleted, but not properly nullified."
		else:
			if (null == operand.parent_operator):
				validation_report += "\n" + "Operand " + str(index) + " has null parent operator."
			elif (!is_instance_valid(operand.parent_operator)):
				validation_report += "\n" + "The parent operator of operand " + str(index) + " is an invalid instance."
			elif (operand.parent_operator != self):
				validation_report += "\n" + "Operand " + str(index) + " has incorrect parent operator."
			if (operand.script_index != index):
				validation_report += "\n" + "Operand " + str(index) + " has incorrect script index."
			var operand_report = operand.validate(_intended_script_output_datatype)
			if ("Passed." != operand_report):
				validation_report += "\n" + operand_report
		index += 1
	if ("" == validation_report):
		return "Passed."
	else:
		return get_operator_type() + validation_report

func is_parallel_to(sibling):
	if (get_operator_type() == sibling.get_operator_type() and operands.size() == sibling.operands.size()):
		for index in range(operands.size()):
			if (!operands[index].is_parallel_to(sibling.operands[index])):
				return false
		return true
	return false
