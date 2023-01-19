extends SWOperator
class_name BooleanComparator
#Takes boolean values or operators as inputs and outputs true, false, or null.

enum operator_subtypes {AND, OR, XOR}
var operator_subtype = operator_subtypes.AND

func _init(in_operator_subtype = "And", in_operands = [true]):
	operator_type = "Boolean Comparator"
	input_type = sw_script_data_types.BOOLEAN
	output_type = sw_script_data_types.BOOLEAN
	set_operator_subtype(in_operator_subtype)
	for operand in in_operands:
		add_operand(operand)

func operator_subtype_to_string():
	if (operator_subtypes.AND == operator_subtype):
		return "And"
	elif (operator_subtypes.OR == operator_subtype):
		return "Or"
	elif (operator_subtypes.XOR == operator_subtype):
		return "XOr"
	else:
		return "NULL"

func test_operand(operand, leaf = null):
	if (null == operand or null == operator_subtype):
		print ("Cannot evaluate boolean operator.")
		return null
	var result = null
	if (operand is SWScriptElement):
		result = operand.get_value(leaf)
		if (TYPE_BOOL != typeof(result)):
			if (TYPE_INT == typeof(result) or TYPE_REAL == typeof(result)):
				result = bool(result)
			else:
				return null
	elif (TYPE_INT == typeof(operand) or TYPE_REAL == typeof(operand)):
		result = bool(operand)
	elif (TYPE_BOOL == typeof(operand)):
		result = operand
	else:
		return null
	return result

func get_value(leaf = null):
	if (operator_subtypes.AND == operator_subtype):
		for operand in operands:
			var value = test_operand(operand, leaf)
			if (null == value):
				continue
			elif (!value):
				return false
		return true
	elif (operator_subtypes.OR == operator_subtype):
		for operand in operands:
			var value = test_operand(operand, leaf)
			if (null == value):
				continue
			elif (value):
				return true
		return false
	elif (operator_subtypes.XOR == operator_subtype):
		if (2 <= operands.size()):
			var value_0 = test_operand(operands[0], leaf)
			var value_1 = test_operand(operands[1], leaf)
			if (null == value_0 or null == value_1):
				return null
			elif (value_0 != value_1):
				return true
			else:
				return false
		else:
			return null
	else:
		return null

func set_operator_subtype(in_operator_subtype):
	if (in_operator_subtype.matchn("And")):
		can_add_operands = true
		minimum_number_of_operands = 2
		operator_subtype = operator_subtypes.AND
	elif (in_operator_subtype.matchn("Or")):
		can_add_operands = true
		minimum_number_of_operands = 2
		operator_subtype = operator_subtypes.OR
	elif (in_operator_subtype.matchn("XOr")):
		can_add_operands = false
		minimum_number_of_operands = 2
		operator_subtype = operator_subtypes.XOR
	else:
		operator_subtype = null

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Operator"
	output["operator_type"] = operator_type
	output["operator_subtype"] = operator_subtype_to_string()
	if (!include_editor_only_variables):
		output["input_type"] = stringify_input_type()
	output["operands"] = []
	for operand in operands:
		if (null == operand):
			output["operands"].append(null)
		elif (TYPE_BOOL == typeof(operand)):
			output["operands"].append(operand)
		elif (TYPE_INT == typeof(operand) or TYPE_REAL == typeof(operand)):
			output["operands"].append(bool(operand))
		elif (operand is SWScriptElement):
			output["operands"].append(operand.compile(parent_storyworld, include_editor_only_variables))
	return output

func data_to_string():
	var result = operator_subtype_to_string()
	return result
