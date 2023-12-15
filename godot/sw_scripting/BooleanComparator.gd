extends SWOperator
class_name BooleanComparator
#Takes boolean values or operators as inputs and outputs true, false, or null.

enum operator_subtypes {AND, OR}
var operator_subtype = operator_subtypes.AND

func _init(in_operator_subtype = "And", in_operands = []):
	input_type = sw_script_data_types.BOOLEAN
	output_type = sw_script_data_types.BOOLEAN
	set_operator_subtype(in_operator_subtype)
	for operand in in_operands:
		add_operand(operand)

static func get_operator_type():
	return "Boolean Comparator"

func operator_subtype_to_string():
	if (operator_subtypes.AND == operator_subtype):
		return "And"
	elif (operator_subtypes.OR == operator_subtype):
		return "Or"
	else:
		return "NULL"

func get_value():
	var output = null
	if (operator_subtypes.AND == operator_subtype):
		output = true
		for operand in operands:
			var value = evaluate_operand(operand)
			if (null == value or TYPE_BOOL != typeof(value)):
				#Poison
				continue
			elif (!value):
				output = false
				break
	elif (operator_subtypes.OR == operator_subtype):
		output = false
		for operand in operands:
			var value = evaluate_operand(operand)
			if (null == value or TYPE_BOOL != typeof(value)):
				#Poison
				continue
			elif (value):
				output = true
				break
	return output

func get_and_report_value():
	var output = null
	if (operator_subtypes.AND == operator_subtype):
		output = true
		for operand in operands:
			var value = evaluate_and_report_operand(operand)
			if (null == value or TYPE_BOOL != typeof(value)):
				#Poison
				continue
			elif (!value):
				output = false
				break
	elif (operator_subtypes.OR == operator_subtype):
		output = false
		for operand in operands:
			var value = evaluate_and_report_operand(operand)
			if (null == value or TYPE_BOOL != typeof(value)):
				#Poison
				continue
			elif (value):
				output = true
				break
	return output

func set_operator_subtype(in_operator_subtype):
	if (in_operator_subtype.matchn("And")):
		can_add_operands = true
		minimum_number_of_operands = 2
		operator_subtype = operator_subtypes.AND
	elif (in_operator_subtype.matchn("Or")):
		can_add_operands = true
		minimum_number_of_operands = 2
		operator_subtype = operator_subtypes.OR
	else:
		operator_subtype = null

func compile(parent_storyworld, include_editor_only_variables = false):
	var output = {}
	output["script_element_type"] = "Operator"
	output["operator_type"] = get_operator_type()
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
