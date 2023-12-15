extends Tree

#Display modes: Single script, reaction inclinations, option visibility and performability, encounter selection, text.

var storyworld = null

func _ready():
	pass

func recursively_add_to_script_display(root_display_branch, operator_to_add, prefix = ""):
	var new_branch = create_item(root_display_branch)
	#Store operator into script display via tree item metadata.
	new_branch.set_metadata(0, operator_to_add)
	if (operator_to_add is SWScriptElement):
		operator_to_add.treeview_node = new_branch
	#Set text of item based on operator type, and recursively add operands as tree branches.
	var text = " " + prefix
	if (null == operator_to_add):
		text += "Null"
	elif (operator_to_add is AbsoluteValueOperator):
		text += "Absolute Value of"
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is ArithmeticComparator):
		text += operator_to_add.operator_subtype_to_longstring()
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is ArithmeticMeanOperator):
		text += "Average of"
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is ArithmeticNegationOperator):
		text += "Arithmetic Negation of"
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is BlendOperator):
		text += "Blend of"
		for each in operator_to_add.operands:
			if (2 > each.script_index):
				recursively_add_to_script_display(new_branch, each)
			else:
				recursively_add_to_script_display(new_branch, each, "(Weight) ")
	elif (operator_to_add is BNumberConstant):
		text += operator_to_add.data_to_string()
	elif (operator_to_add is BNumberPointer):
		text += operator_to_add.data_to_string()
	elif (operator_to_add is BooleanConstant):
		text += operator_to_add.data_to_string()
	elif (operator_to_add is BooleanComparator):
		text += operator_to_add.operator_subtype_to_string()
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is BSumOperator):
		text += "Bounded Sum of"
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is Desideratum):
		text += "Proximity to"
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is EventPointer):
		text += operator_to_add.summarize()
	elif (operator_to_add is NudgeOperator):
		text += "Nudge"
		for each in operator_to_add.operands:
			if (1 > each.script_index):
				recursively_add_to_script_display(new_branch, each)
			else:
				recursively_add_to_script_display(new_branch, each, "(Weight) ")
	elif (operator_to_add is SpoolStatusPointer):
		text += operator_to_add.data_to_string()
	elif (operator_to_add is SWEqualsOperator):
		text += "Equals"
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is SWIfOperator):
		text += "If Then"
		for n in range(operator_to_add.operands.size()):
			var operand = operator_to_add.operands[n]
			if (0 == n):
				recursively_add_to_script_display(new_branch, operand, "(If) ")
			elif (1 == n % 2):
				recursively_add_to_script_display(new_branch, operand, "(Then) ")
			elif (0 == n % 2 and n != (operator_to_add.operands.size()-1)):
				recursively_add_to_script_display(new_branch, operand, "(Else If) ")
			else:
				recursively_add_to_script_display(new_branch, operand, "(Else) ")
	elif (operator_to_add is SWMaxOperator):
		text += "Maximum of"
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is SWMinOperator):
		text += "Minimum of"
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is SWNotOperator):
		text += "Not"
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	new_branch.set_text(0, text)
	return new_branch
