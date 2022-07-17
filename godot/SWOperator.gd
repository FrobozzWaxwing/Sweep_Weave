extends SWScriptElement
class_name SWOperator

var input_type = sw_script_data_types.VARIANT
var operator_type = "Generic Operation"
var operands = []
#If "can_add_operands" is true, this operator can employ an arbitrarily long list of operands, though it will require at least one operand to work as intended.
#If "can_add_operands" is false, this operator has a set number of operands.
var can_add_operands = false

func _init():
	pass

func add_operand(operand):
	operands.append(operand)
	if (operand is SWScriptElement):
		operand.parent_operator = self
		operand.script_index = operands.size() - 1

func remap(storyworld):
	var result = true
	for operand in operands:
		if (operand is SWScriptElement):
			var check = operand.remap(storyworld)
			result = (result and check)
	return result

func evaluate_operand(operand, leaf):
	var result = null
	if (null == operand):
		result = null
	elif (TYPE_BOOL == typeof(operand) or TYPE_INT == typeof(operand) or TYPE_REAL == typeof(operand)):
		result = operand
	elif (operand is SWScriptElement):
		result = operand.get_value(leaf)
	if (null == result):
		print ("Warning: Invalid operand.")
	return result

func evaluate_operand_at_index(operand_index, leaf):
	if (null == operand_index or operand_index >= operands.size()):
		#Operator does not contain an operand at the index specified.
		return null
	var operand = operands[operand_index]
	return evaluate_operand(operand, leaf)

#func get_value(leaf = null):
#	# Some operators, particularly EventPointers and BooleanOperators that contain EventPointers, need access to the historybook.
#	# The "leaf" variable grants EventPointers this access.
#	return null

func clear():
	for operand in operands:
		if (operand is SWScriptElement):
			operand.clear()
			operand.call_deferred("free")
	operands.clear()

func stringify_input_type():
	#This is used for compiling storyworlds, so the strings are javascript data types.
	if (sw_script_data_types.BOOLEAN == input_type):
		return "boolean"
	elif (sw_script_data_types.BNUMBER == input_type):
		return "number"
	else:
		return ""

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Operator"
	output["operator_type"] = operator_type
	if (!include_editor_only_variables):
		output["input_type"] = stringify_input_type()
	output["operands"] = []
	for operand in operands:
		if (null == operand):
			output["operands"].append(null)
		elif (TYPE_BOOL == typeof(operand)):
			output["operands"].append(operand)
		elif (TYPE_INT == typeof(operand) or TYPE_REAL == typeof(operand)):
			output["operands"].append(operand)
		elif (operand is SWScriptElement):
			output["operands"].append(operand.compile(parent_storyworld, include_editor_only_variables))
	return output

func stringify_operand_at_index(operand_index):
	if (null == operand_index or operand_index >= operands.size()):
		#Operator does not contain an operand at the index specified.
		return "null"
	var operand = operands[operand_index]
	var result = "null"
	if (null == operand):
		pass
	elif (TYPE_BOOL == typeof(operand) or TYPE_INT == typeof(operand) or TYPE_REAL == typeof(operand)):
		result = str(operand)
	elif (TYPE_STRING == typeof(operand)):
		result = "\"" + operand + "\""
	elif (operand is SWScriptElement):
		result = operand.data_to_string()
	return result

func data_to_string():
	return "SweepWeave Script Operator"
