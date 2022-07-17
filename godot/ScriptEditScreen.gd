extends Control

var storyworld = null
var script_to_edit = null
var current_operator = null
var allow_root_character_editing = false
var allow_coefficient_editing = true
var bnumberpointer_editor_scene = load("res://BNumberPropertySelector.tscn")
var bnumberconstant_editor_scene = load("res://BNumberConstantEditingInterface.tscn")

signal sw_script_changed(sw_script)

func _ready():
	pass

func recursively_add_to_script_display(root_display_branch, operator_to_add):
	var new_branch = $Background/VBC/HBC/VBC1/ScriptDisplay.create_item(root_display_branch)
	#Store operator into script display via tree item metadata.
	new_branch.set_metadata(0, operator_to_add)
	if (operator_to_add is SWScriptElement):
		operator_to_add.treeview_node = new_branch
	#Set text of item based on operator type, and recursively add operands as tree branches.
	if (null == operator_to_add):
		new_branch.set_text(0, "Null")
	elif (TYPE_BOOL == typeof(operator_to_add)):
		new_branch.set_text(0, str(operator_to_add))
	elif (TYPE_INT == typeof(operator_to_add) or TYPE_REAL == typeof(operator_to_add)):
		new_branch.set_text(0, str(operator_to_add))
	elif (TYPE_ARRAY == typeof(operator_to_add)):
		new_branch.set_text(0, "List")
		for each in operator_to_add:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is ArithmeticMeanOperator):
		new_branch.set_text(0, "Arithmetic Mean of")
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is AssignmentOperator):
		new_branch.set_text(0, "Set")
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is BlendOperator):
		new_branch.set_text(0, "Blend of")
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is BNumberConstant):
		new_branch.set_text(0, operator_to_add.data_to_string())
	elif (operator_to_add is BNumberPointer):
		new_branch.set_text(0, operator_to_add.data_to_string())
	elif (operator_to_add is BooleanConstant):
		new_branch.set_text(0, operator_to_add.data_to_string())
	elif (operator_to_add is BooleanOperator):
		new_branch.set_text(0, operator_to_add.operator_subtype_to_string())
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is BSumOperator):
		new_branch.set_text(0, "Bounded Sum of")
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is Desideratum):
		new_branch.set_text(0, "Proximity to")
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	elif (operator_to_add is EventPointer):
		new_branch.set_text(0, operator_to_add.summarize())
	elif (operator_to_add is NudgeOperator):
		new_branch.set_text(0, "Nudge")
		for each in operator_to_add.operands:
			recursively_add_to_script_display(new_branch, each)
	return new_branch

func refresh_script_display():
	$Background/VBC/HBC/VBC1/ScriptDisplay.clear()
	var root = $Background/VBC/HBC/VBC1/ScriptDisplay.create_item()
	$Background/VBC/HBC/VBC1/ScriptDisplay.set_hide_root(true)
	#Fill out the script display by using a recursive algorithm to run through the script tree.
	if (null != script_to_edit and null != script_to_edit.contents):
		recursively_add_to_script_display(root, script_to_edit.contents)
	load_operator(null)

func refresh_operator_options_display(operator):
	$Background/VBC/HBC/AvailableOperatorList.clear()
	if (null == operator):
		return
	if (TYPE_BOOL == typeof(operator) or (operator is SWScriptElement and operator.sw_script_data_types.BOOLEAN == operator.output_type)):
		$Background/VBC/HBC/AvailableOperatorList.add_item("True")
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(0, "Boolean constant: true.")
		$Background/VBC/HBC/AvailableOperatorList.add_item("False")
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(1, "Boolean constant: false.")
		$Background/VBC/HBC/AvailableOperatorList.add_item("Event")
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(2, "Has an encounter, option, and / or reaction occurred or not?")
		$Background/VBC/HBC/AvailableOperatorList.add_item("Not")
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(3, "Logical inverse of operand.")
		$Background/VBC/HBC/AvailableOperatorList.add_item("And")
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(4, "Produces true if all operands are true.")
		$Background/VBC/HBC/AvailableOperatorList.add_item("Or")
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(5, "Produces true if at least one operand is true.")
#		$Background/VBC/HBC/AvailableOperatorList.add_item("XOr")
#		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(6, "\"Exclusive or\" of two operands. Produces true if, and only if, one operand is true and the other is false.")
#		$Background/VBC/HBC/AvailableOperatorList.add_item("Equals")
#		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(7, "Produces true if all operands are equal, and false otherwise.")
	elif (TYPE_INT == typeof(operator) or TYPE_REAL == typeof(operator) or (operator is SWScriptElement and operator.sw_script_data_types.BNUMBER == operator.output_type)):
		$Background/VBC/HBC/AvailableOperatorList.add_item("Constant")
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(0, "A number above -1 and below 1, specified by the author.")
		$Background/VBC/HBC/AvailableOperatorList.add_item("BNumber Property")
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(1, "A bounded number property associated with a specified character. Useful for tracking character traits and relationships between characters.")
		$Background/VBC/HBC/AvailableOperatorList.add_item("Arithmetic Mean")
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(2, "The arithmetic mean, or average, of all operands.")
		$Background/VBC/HBC/AvailableOperatorList.add_item("Blend")
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(3, "The weighted, arithmetic mean of two operands.")
#		$Background/VBC/HBC/AvailableOperatorList.add_item("Bounded Sum")
#		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(4, "Converts each operand to a normal number, adds them all together, and converts the result back to a bounded number.")
		$Background/VBC/HBC/AvailableOperatorList.add_item("Proximity to")
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(4, "Returns a bounded number that is higher when the two operands are closer to equality and lower when the two operands are farther apart.")
		$Background/VBC/HBC/AvailableOperatorList.add_item("Nudge")
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(5, "Returns x when delta equals 0, blends x with 1 when delta is greater than 0, and blends x with -1 when delta is less than 0.")
	if (TYPE_ARRAY == typeof(operator)
		or (operator is SWOperator and operator.can_add_operands)):
		#Operator can handle a varying number of operands. Each will need at least one operand to work as intended.
		$Background/VBC/HBC/AvailableOperatorList.add_item("Add new operand")
		var index = $Background/VBC/HBC/AvailableOperatorList.get_item_count() - 1
		$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(index, "Add a new operand to the selected operator.")
	if (operator is SWScriptElement):
		if ((operator.parent_operator is ScriptManager and TYPE_ARRAY == typeof(operator.parent_operator.contents))
			or (operator.parent_operator is SWOperator and operator.parent_operator.can_add_operands and 2 <= operator.parent_operator.operands.size())):
			#Parent operator can handle a varying number of operands. Each will need at least one operand to work as intended.
			$Background/VBC/HBC/AvailableOperatorList.add_item("Delete")
			var index = $Background/VBC/HBC/AvailableOperatorList.get_item_count() - 1
			$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(index, "Delete the selected operator and all nested operands from the script.")

func load_operator(operator):
	current_operator = operator
	refresh_operator_options_display(operator)
	var nodes_to_delete = $Background/VBC/HBC/VBC1/OperatorEditPanel.get_children()
	for each in nodes_to_delete:
		each.call_deferred("free")
	if (null == operator):
		$Background/VBC/HBC/VBC1/OperatorEditPanel.visible = false
	elif (operator is BNumberConstant):
		$Background/VBC/HBC/VBC1/OperatorEditPanel.visible = true
		var operator_editing_interface = bnumberconstant_editor_scene.instance()
		operator_editing_interface.storyworld = storyworld
		operator_editing_interface.reset()
		operator_editing_interface.operator.set_value(operator.get_value())
		operator_editing_interface.set_layout("Bounded number constant:", 2)
		operator_editing_interface.refresh()
		operator_editing_interface.connect("bnumber_value_changed", self, "on_operator_changed")
		$Background/VBC/HBC/VBC1/OperatorEditPanel.add_child(operator_editing_interface)
	elif (operator is BNumberPointer):
		$Background/VBC/HBC/VBC1/OperatorEditPanel.visible = true
		var operator_editing_interface = bnumberpointer_editor_scene.instance()
		operator_editing_interface.storyworld = storyworld
		operator_editing_interface.reset()
		operator_editing_interface.allow_root_character_editing = allow_root_character_editing
		operator_editing_interface.allow_coefficient_editing = allow_coefficient_editing
		operator_editing_interface.selected_property.set_as_copy_of(operator)
		operator_editing_interface.refresh()
		operator_editing_interface.connect("bnumber_property_selected", self, "on_operator_changed")
		$Background/VBC/HBC/VBC1/OperatorEditPanel.add_child(operator_editing_interface)
	else:
		$Background/VBC/HBC/VBC1/OperatorEditPanel.visible = false
	if (operator is SWScriptElement and operator.treeview_node is TreeItem):
		operator.treeview_node.select(0)

func replace_element(old_element, new_element):
	if (old_element is SWScriptElement and new_element is SWScriptElement):
		var parent = old_element.parent_operator
		var index = old_element.script_index
		if (parent is SWOperator):
			parent.operands[index] = new_element
		elif (parent is ScriptManager):
			if (parent.contents is SWScriptElement):
				parent.contents = new_element
			elif (TYPE_ARRAY == typeof(parent.contents)):
				parent.contents[index] = new_element
		new_element.parent_operator = parent
		new_element.script_index = index
#		new_element.treeview_node = old_element.treeview_node
		old_element.clear()
		old_element.call_deferred("free")

func _on_ScriptDisplay_item_selected():
	var operator = $Background/VBC/HBC/VBC1/ScriptDisplay.get_selected().get_metadata(0)
	load_operator(operator)

func on_operator_changed(new_operator):
	if (current_operator is BNumberConstant and new_operator is BNumberConstant):
		current_operator.set_value(new_operator.get_value())
	elif (current_operator is BNumberPointer and new_operator is BNumberPointer):
		current_operator.set_as_copy_of(new_operator)
	var selected_display_element = $Background/VBC/HBC/VBC1/ScriptDisplay.get_selected()
	if (null != selected_display_element and selected_display_element is TreeItem):
		selected_display_element.set_text(0, current_operator.data_to_string())
	emit_signal("sw_script_changed", script_to_edit)

func _on_AvailableOperatorList_item_activated(index):
	var operator_class = $Background/VBC/HBC/AvailableOperatorList.get_item_text(index)
	var new_element = null
	var change_made = false
	match operator_class:
		#Boolean operators and pointers:
		"True":
			new_element = BooleanConstant.new(true)
			replace_element(current_operator, new_element)
			change_made = true
		"False":
			new_element = BooleanConstant.new(false)
			replace_element(current_operator, new_element)
			change_made = true
		"Event":
			$EventSelectionDialog/EventSelectionInterface.storyworld = storyworld
			$EventSelectionDialog/EventSelectionInterface.searchterm = ""
			$EventSelectionDialog/EventSelectionInterface.blacklist.clear()
			$EventSelectionDialog/EventSelectionInterface.refresh()
			$EventSelectionDialog.popup()
		"Not":
			var new_operands = []
			new_operands.append(BooleanConstant.new(true))
			new_element = BooleanOperator.new("NOT", new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"And":
			var new_operands = []
			new_operands.append(BooleanConstant.new(true))
			new_operands.append(BooleanConstant.new(true))
			new_element = BooleanOperator.new("AND", new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"Or":
			var new_operands = []
			new_operands.append(BooleanConstant.new(true))
			new_operands.append(BooleanConstant.new(true))
			new_element = BooleanOperator.new("OR", new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"XOr":
			var new_operands = []
			new_operands.append(BooleanConstant.new(true))
			new_operands.append(BooleanConstant.new(true))
			new_element = BooleanOperator.new("XOR", new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"Equals":
			var new_operands = []
			new_operands.append(BooleanConstant.new(true))
			new_operands.append(BooleanConstant.new(true))
			new_element = BooleanOperator.new("EQUALS", new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		#Bounded number operators and pointers:
		"Constant":
			new_element = BNumberConstant.new(0)
			replace_element(current_operator, new_element)
			change_made = true
		"BNumber Property":
			new_element = storyworld.create_default_bnumber_pointer()
			replace_element(current_operator, new_element)
			change_made = true
		"Arithmetic Mean":
			var new_operands = []
			new_operands.append(BNumberConstant.new(0))
			new_element = ArithmeticMeanOperator.new(new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"Blend":
			new_element = BlendOperator.new(BNumberConstant.new(0), BNumberConstant.new(0), BNumberConstant.new(0))
			replace_element(current_operator, new_element)
			change_made = true
		"Proximity to":
			new_element = Desideratum.new(storyworld.create_default_bnumber_pointer(), BNumberConstant.new(0))
			replace_element(current_operator, new_element)
			change_made = true
		"Nudge":
			new_element = NudgeOperator.new(storyworld.create_default_bnumber_pointer(), BNumberConstant.new(0))
			replace_element(current_operator, new_element)
			change_made = true
		#Add and delete
		"Add new operand":
			if (current_operator is SWOperator and current_operator.can_add_operands):
				if (current_operator.sw_script_data_types.BOOLEAN == current_operator.input_type):
					new_element = BooleanConstant.new(true)
					current_operator.add_operand(new_element)
					change_made = true
				elif (current_operator.sw_script_data_types.BNUMBER == current_operator.input_type):
					new_element = BNumberConstant.new(0)
					current_operator.add_operand(new_element)
					change_made = true
		"Delete":
			if (current_operator is SWScriptElement):
				if ((current_operator.parent_operator is ScriptManager and TYPE_ARRAY == typeof(current_operator.parent_operator.contents))
					or (current_operator.parent_operator is SWOperator and current_operator.parent_operator.can_add_operands and 2 <= current_operator.parent_operator.operands.size())):
					print ("Delete")
					new_element = current_operator.parent_operator
					current_operator.parent_operator.operands.erase(current_operator)
					current_operator.clear()
					current_operator.call_deferred("free")
					change_made = true
	if (change_made):
		refresh_script_display()
		load_operator(new_element)
		emit_signal("sw_script_changed", script_to_edit)

func _on_EventSelectionDialog_confirmed():
	if (current_operator is SWScriptElement and (current_operator.sw_script_data_types.VARIANT == current_operator.output_type or current_operator.sw_script_data_types.BOOLEAN == current_operator.output_type)):
		var new_element = EventPointer.new()
		new_element.set_as_copy_of($EventSelectionDialog/EventSelectionInterface.selected_event)
		replace_element(current_operator, new_element)
		refresh_script_display()
		load_operator(new_element)
		emit_signal("sw_script_changed", script_to_edit)
