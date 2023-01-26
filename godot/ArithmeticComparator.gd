extends SWOperator
class_name ArithmeticComparator

enum operator_subtypes {GT, GTE, LT, LTE, EQUALS}
var operator_subtype = operator_subtypes.GT

func _init(in_operator_subtype = "GT", in_x = null, in_y = null):
	operator_type = "Arithmetic Comparator"
	input_type = sw_script_data_types.BNUMBER
	output_type = sw_script_data_types.BOOLEAN
	can_add_operands = false
	minimum_number_of_operands = 2
	set_operator_subtype(in_operator_subtype)
	add_operand(in_x)
	add_operand(in_y)

func get_value(leaf = null, report = false):
	var output = null
	if (0 == operands.size()):
		print ("Warning: arithmetic comparator has no operands.")
	var x = evaluate_operand_at_index(0, leaf, report)
	var y = evaluate_operand_at_index(1, leaf, report)
	if ((TYPE_INT == typeof(x) or TYPE_REAL == typeof(x)) and (TYPE_INT == typeof(y) or TYPE_REAL == typeof(y))):
		if (operator_subtypes.GT == operator_subtype):
			output = (x > y)
		elif (operator_subtypes.GTE == operator_subtype):
			output = (x >= y)
		elif (operator_subtypes.LT == operator_subtype):
			output = (x < y)
		elif (operator_subtypes.LTE == operator_subtype):
			output = (x <= y)
		elif (operator_subtypes.EQUALS == operator_subtype):
			#Unused.
			output = (x == y)
	if (report):
		report_value(output)
	return output

func operator_subtype_to_longstring():
	if (operator_subtypes.GT == operator_subtype):
		return "Greater than"
	elif (operator_subtypes.GTE == operator_subtype):
		return "Greater than or Equal to"
	elif (operator_subtypes.LT == operator_subtype):
		return "Less than"
	elif (operator_subtypes.LTE == operator_subtype):
		return "Less than or Equal to"
	elif (operator_subtypes.EQUALS == operator_subtype):
		return "Equal to"
	else:
		return "Invalid arithmetic comparator"

func operator_subtype_to_string():
	if (operator_subtypes.GT == operator_subtype):
		return "GT"
	elif (operator_subtypes.GTE == operator_subtype):
		return "GTE"
	elif (operator_subtypes.LT == operator_subtype):
		return "LT"
	elif (operator_subtypes.LTE == operator_subtype):
		return "LTE"
	elif (operator_subtypes.EQUALS == operator_subtype):
		return "EQUALS"
	else:
		return "NULL"

func operator_subtype_to_symbol():
	if (operator_subtypes.GT == operator_subtype):
		return ">"
	elif (operator_subtypes.GTE == operator_subtype):
		return ">="
	elif (operator_subtypes.LT == operator_subtype):
		return "<"
	elif (operator_subtypes.LTE == operator_subtype):
		return "<="
	elif (operator_subtypes.EQUALS == operator_subtype):
		return "=="
	else:
		return "?"

func set_operator_subtype(in_operator_subtype):
	if (in_operator_subtype.matchn("GT")):
		operator_subtype = operator_subtypes.GT
	elif (in_operator_subtype.matchn("GTE")):
		operator_subtype = operator_subtypes.GTE
	elif (in_operator_subtype.matchn("LT")):
		operator_subtype = operator_subtypes.LT
	elif (in_operator_subtype.matchn("LTE")):
		operator_subtype = operator_subtypes.LTE
	elif (in_operator_subtype.matchn("EQUALS")):
		operator_subtype = operator_subtypes.EQUALS
	else:
		operator_subtype = operator_subtypes.GT

func data_to_string():
	var result = operator_subtype_to_longstring()
	#var result = stringify_operand_at_index(0) + " " + operator_subtype_to_symbol() + " " + stringify_operand_at_index(1)
	return result

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
