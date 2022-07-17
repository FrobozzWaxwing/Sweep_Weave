extends SWOperator
class_name BooleanOperator
#Takes boolean values or operators as inputs and outputs true, false, or null.

enum operator_subtypes {NOT, AND, OR, XOR, EQUALS}
var operator_subtype = operator_subtypes.NOT

func _init(in_operator_subtype = "NOT", in_operands = [true]):
	operator_type = "Boolean Comparator"
	input_type = sw_script_data_types.BOOLEAN
	output_type = sw_script_data_types.BOOLEAN
	set_operator_subtype(in_operator_subtype)
	for operand in in_operands:
		add_operand(operand)

func operator_subtype_to_string():
	if (operator_subtypes.NOT == operator_subtype):
		return "NOT"
	elif (operator_subtypes.AND == operator_subtype):
		return "AND"
	elif (operator_subtypes.OR == operator_subtype):
		return "OR"
	elif (operator_subtypes.XOR == operator_subtype):
		return "XOR"
	elif (operator_subtypes.EQUALS == operator_subtype):
		return "EQUALS"
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
	if (operator_subtypes.NOT == operator_subtype):
		if (1 <= operands.size()):
			var value_0 = test_operand(operands[0], leaf)
			if (true == value_0):
				return false
			elif (false == value_0):
				return true
			elif (null == value_0):
				return null
		else:
			return null
	elif (operator_subtypes.AND == operator_subtype):
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
	elif (operator_subtypes.EQUALS == operator_subtype):
		if (1 == operands.size()):
			var value = test_operand(operands[0], leaf)
			if (null == value):
				return null
			else:
				return true
		elif (2 <= operands.size()):
			var first_loop = true
			var value_0 = null
			var value_1 = null
			for operand in operands:
				if (first_loop):
					value_0 = test_operand(operand, leaf)
					first_loop = false
				else:
					value_1 = test_operand(operand, leaf)
					if (null == value_0 or null == value_1 or value_0 == value_1):
						#Skip over null values when comparing each value to the next. When neither value is null, check whether they are equal.
						if (null == value_0):
							value_0 = value_1
					elif (value_0 != value_1):
						#If any two non-null values are not equal, return false.
						return false
			if (null == value_0):
				#If all values are null, return null.
				return null
			else:
				#If all non-null values are equal to each other, and at least one is not null, return true.
				return true
		else:
			return null
	else:
		return null

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

func set_operator_subtype(in_operator_subtype):
	if (in_operator_subtype.matchn("NOT")):
		can_add_operands = false
		operator_subtype = operator_subtypes.NOT
	elif (in_operator_subtype.matchn("AND")):
		can_add_operands = true
		operator_subtype = operator_subtypes.AND
	elif (in_operator_subtype.matchn("OR")):
		can_add_operands = true
		operator_subtype = operator_subtypes.OR
	elif (in_operator_subtype.matchn("XOR")):
		can_add_operands = false
		operator_subtype = operator_subtypes.XOR
	elif (in_operator_subtype.matchn("EQUALS")):
		can_add_operands = true
		operator_subtype = operator_subtypes.EQUALS
	else:
		operator_subtype = null
