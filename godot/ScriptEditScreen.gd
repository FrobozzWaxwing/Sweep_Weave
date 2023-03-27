extends Control

var storyworld = null
var script_to_edit = null
var current_operator = null
var allow_root_character_editing = false
var allow_coefficient_editing = true
var bnumberpointer_editor_scene = load("res://BNumberPropertySelector.tscn")
var bnumberconstant_editor_scene = load("res://BNumberConstantEditingInterface.tscn")
var spool_selector_scene = load("res://SpoolSelector.tscn")

#GUI theme variables:
var gui_background_color = Color(0.941406, 0.941406, 0.941406)

signal sw_script_changed(sw_script)

func _ready():
	pass

func refresh_script_display():
	if ("" == $Background/VBC/Label.text):
		$Background/VBC/Label.visible = false
	else:
		$Background/VBC/Label.visible = true
	$Background/VBC/HBC/VBC1/ScriptDisplay.clear()
	var root = $Background/VBC/HBC/VBC1/ScriptDisplay.create_item()
	$Background/VBC/HBC/VBC1/ScriptDisplay.set_hide_root(true)
	#Fill out the script display by using a recursive algorithm to run through the script tree.
	if (null != script_to_edit):
		$Background/VBC/HBC/VBC1/ScriptDisplay.recursively_add_to_script_display(root, script_to_edit.contents)
		load_operator(script_to_edit.contents)
	else:
		load_operator(null)

func add_option_to_toolbox(text, hint):
	var index = $Background/VBC/HBC/AvailableOperatorList.get_item_count()
	$Background/VBC/HBC/AvailableOperatorList.add_item(text)
	$Background/VBC/HBC/AvailableOperatorList.set_item_tooltip(index, hint)

func refresh_operator_options_display(operator):
	#This fills the options of the side panel of the script editing window.
	$Background/VBC/HBC/AvailableOperatorList.clear()
	if (null == operator):
		return
	if (operator is SWScriptElement):
		if (operator.sw_script_data_types.BOOLEAN == operator.output_type):
			add_option_to_toolbox("True", "Boolean constant: true.")
			add_option_to_toolbox("False", "Boolean constant: false.")
			add_option_to_toolbox("Event", "Has an encounter, option, and / or reaction occurred during the playthrough?")
			add_option_to_toolbox("Spool Status", "Is a spool currently active?")
			add_option_to_toolbox("Not", "Logical negation of operand.")
			add_option_to_toolbox("And", "Produces true if all operands are true.")
			add_option_to_toolbox("Or", "Produces true if at least one operand is true.")
#			add_option_to_toolbox("XOr", "\"Exclusive or\" of two operands. Produces true if, and only if, one operand is true and the other is false.")
			add_option_to_toolbox("Equals (Boolean)", "Produces true if all operands are equal in value. Takes Boolean values as inputs.")
			add_option_to_toolbox("Equals (BNumber)", "Produces true if all operands are equal in value. Takes bounded numbers as inputs.")
			add_option_to_toolbox("Greater than", "Produces true if first operand is greater than second operand.")
			add_option_to_toolbox("Greater than or Equal to", "Produces true if first operand is greater than or equal to second operand.")
			add_option_to_toolbox("Less than", "Produces true if first operand is less than second operand.")
			add_option_to_toolbox("Less than or Equal to", "Produces true if first operand is less than or equal to second operand.")
		elif (operator.sw_script_data_types.BNUMBER == operator.output_type):
			add_option_to_toolbox("Constant", "A number above -1 and below 1, specified by the author.")
			add_option_to_toolbox("BNumber Property", "A bounded number property associated with a specified character. Useful for tracking character traits and relationships between characters.")
			add_option_to_toolbox("Absolute Value", "The absolute value of the operand.")
			add_option_to_toolbox("Arithmetic Mean", "The arithmetic mean, or average, of all operands.")
			add_option_to_toolbox("Arithmetic Negation", "The product of the operand and -1.")
			add_option_to_toolbox("Blend", "The weighted, arithmetic mean of two operands.")
#			add_option_to_toolbox("Bounded Sum", "Converts each operand to a normal number, adds them all together, and converts the result back to a bounded number.")
			add_option_to_toolbox("Proximity to", "Returns a bounded number that is higher when the two operands are closer to equality and lower when the two operands are farther apart.")
			add_option_to_toolbox("Maximum", "Returns the highest value of all operands.")
			add_option_to_toolbox("Minimum", "Returns the lowest value of all operands.")
			add_option_to_toolbox("Nudge", "Returns x when delta equals 0, blends x with 1 when delta is greater than 0, and blends x with -1 when delta is less than 0.")
		add_option_to_toolbox("If Then", "If a condition is true, then return some result. Otherwise, return a different result.")
	if (operator is SWOperator and operator.can_add_operands):
		#Operator can handle a varying number of operands. Each will need at least one operand to work as intended.
		add_option_to_toolbox("Add new operand", "Add a new operand to the selected operator.")
	if (operator is SWScriptElement):
		if (operator.parent_operator is SWOperator and operator.parent_operator.can_add_operands and operator.parent_operator.minimum_number_of_operands < operator.parent_operator.operands.size()):
			#Parent operator can handle a varying number of operands. Each will need at least one operand to work as intended.
			if (operator.parent_operator is SWIfOperator):
				if (operator.script_index != (operator.parent_operator.operands.size() -1)):
					add_option_to_toolbox("Delete", "Delete the selected operator and all nested operands from the script.")
			else:
				add_option_to_toolbox("Delete", "Delete the selected operator and all nested operands from the script.")

func load_operator(operator):
	current_operator = operator
	refresh_operator_options_display(operator)
	var nodes_to_delete = $Background/VBC/HBC/VBC1/OperatorEditPanel.get_children()
	for each in nodes_to_delete:
		each.call_deferred("free")
	if (null == operator):
		$Background/VBC/HBC/VBC1/OperatorEditPanel.visible = false
	elif (operator is ArithmeticComparator):
		$Background/VBC/HBC/VBC1/OperatorEditPanel.visible = true
		var operator_editing_interface = OptionButton.new()
		operator_editing_interface.add_item("Greater than")
		operator_editing_interface.add_item("Greater than or Equal to")
		operator_editing_interface.add_item("Less than")
		operator_editing_interface.add_item("Less than or Equal to")
		operator_editing_interface.connect("item_selected", self, "on_operator_changed")
		$Background/VBC/HBC/VBC1/OperatorEditPanel.add_child(operator_editing_interface)
		operator_editing_interface.select(operator.operator_subtype)
	elif (operator is BooleanComparator):
		$Background/VBC/HBC/VBC1/OperatorEditPanel.visible = true
		var operator_editing_interface = OptionButton.new()
		operator_editing_interface.add_item("And")
		operator_editing_interface.add_item("Or")
		operator_editing_interface.connect("item_selected", self, "on_operator_changed")
		$Background/VBC/HBC/VBC1/OperatorEditPanel.add_child(operator_editing_interface)
		operator_editing_interface.select(operator.operator_subtype)
	elif (operator is BNumberConstant):
		$Background/VBC/HBC/VBC1/OperatorEditPanel.visible = true
		var operator_editing_interface = bnumberconstant_editor_scene.instance()
		operator_editing_interface.set_gui_theme("", gui_background_color)
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
	elif (operator is SpoolStatusPointer):
		$Background/VBC/HBC/VBC1/OperatorEditPanel.visible = true
		var operator_editing_interface = spool_selector_scene.instance()
		operator_editing_interface.storyworld = storyworld
		#Set the interface up to use a SpoolStatusPointer, rather than a SpoolPointer.
		operator_editing_interface.reset("SpoolStatusPointer")
		operator_editing_interface.allow_negation = true
		operator_editing_interface.selected_pointer.set_as_copy_of(operator)
		operator_editing_interface.refresh()
		operator_editing_interface.connect("spool_selected", self, "on_operator_changed")
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
		old_element.clear()
		old_element.call_deferred("free")

func _on_ScriptDisplay_item_selected():
	var operator = $Background/VBC/HBC/VBC1/ScriptDisplay.get_selected().get_metadata(0)
	load_operator(operator)

func on_operator_changed(new_operator):
	var text = " "
	if (current_operator is ArithmeticComparator and TYPE_INT == typeof(new_operator)):
		current_operator.operator_subtype = new_operator
		text += current_operator.operator_subtype_to_longstring()
	elif (current_operator is BooleanComparator and TYPE_INT == typeof(new_operator)):
		current_operator.operator_subtype = new_operator
		text += current_operator.operator_subtype_to_string()
	elif (current_operator is BNumberConstant and new_operator is BNumberConstant):
		current_operator.set_value(new_operator.get_value())
		text += current_operator.data_to_string()
	elif (current_operator is BNumberPointer and new_operator is BNumberPointer):
		current_operator.set_as_copy_of(new_operator)
		text += current_operator.data_to_string()
	elif (current_operator is SpoolStatusPointer and new_operator is SpoolStatusPointer):
		current_operator.set_as_copy_of(new_operator)
		text += current_operator.data_to_string()
	var selected_display_element = $Background/VBC/HBC/VBC1/ScriptDisplay.get_selected()
	if (null != selected_display_element and selected_display_element is TreeItem):
		if (current_operator.parent_operator is SWIfOperator):
			if (0 == current_operator.script_index):
				text = " (If)" + text
			elif (1 == current_operator.script_index % 2):
				text = " (Then)" + text
			elif (0 == current_operator.script_index % 2 and current_operator.script_index != (current_operator.parent_operator.operands.size()-1)):
				text = " (Else If)" + text
			else:
				text = " (Else)" + text
		elif (current_operator.parent_operator is BlendOperator):
			if (2 == current_operator.script_index):
				text = " (Weight)" + text
		elif (current_operator.parent_operator is NudgeOperator):
			if (1 == current_operator.script_index):
				text = " (Weight)" + text
		selected_display_element.set_text(0, text)
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
			$EventSelectionDialog/EventSelectionInterface.reset()
			$EventSelectionDialog/EventSelectionInterface.refresh()
			$EventSelectionDialog.popup_centered()
		"Spool Status":
			if (!storyworld.spools.empty()):
				new_element = SpoolStatusPointer.new(storyworld.spools.front(), false) #Second value, (negated,) being false means that the spool being active causes the pointer to return true.
				replace_element(current_operator, new_element)
				change_made = true
		"Not":
			new_element = SWNotOperator.new(BooleanConstant.new(true))
			replace_element(current_operator, new_element)
			change_made = true
		"And":
			var new_operands = []
			new_operands.append(BooleanConstant.new(true))
			new_operands.append(BooleanConstant.new(true))
			new_element = BooleanComparator.new("AND", new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"Or":
			var new_operands = []
			new_operands.append(BooleanConstant.new(true))
			new_operands.append(BooleanConstant.new(true))
			new_element = BooleanComparator.new("OR", new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"XOr":
			var new_operands = []
			new_operands.append(BooleanConstant.new(true))
			new_operands.append(BooleanConstant.new(true))
			new_element = BooleanComparator.new("XOR", new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"Equals (Boolean)":
			var new_operands = []
			new_operands.append(BooleanConstant.new(true))
			new_operands.append(BooleanConstant.new(true))
			new_element = SWEqualsOperator.new(new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"Equals (BNumber)":
			var new_operands = []
			new_operands.append(BNumberConstant.new(0))
			new_operands.append(BNumberConstant.new(0))
			new_element = SWEqualsOperator.new(new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"Greater than":
			new_element = ArithmeticComparator.new("GT", BNumberConstant.new(0), BNumberConstant.new(0))
			replace_element(current_operator, new_element)
			change_made = true
		"Greater than or Equal to":
			new_element = ArithmeticComparator.new("GTE", BNumberConstant.new(0), BNumberConstant.new(0))
			replace_element(current_operator, new_element)
			change_made = true
		"Less than":
			new_element = ArithmeticComparator.new("LT", BNumberConstant.new(0), BNumberConstant.new(0))
			replace_element(current_operator, new_element)
			change_made = true
		"Less than or Equal to":
			new_element = ArithmeticComparator.new("LTE", BNumberConstant.new(0), BNumberConstant.new(0))
			replace_element(current_operator, new_element)
			change_made = true
		"If Then":
			if (current_operator is SWScriptElement):
				if (current_operator.sw_script_data_types.BOOLEAN == current_operator.output_type):
					new_element = SWIfOperator.new(BooleanConstant.new(true), BooleanConstant.new(true), BooleanConstant.new(false))
					new_element.output_type = current_operator.output_type
					replace_element(current_operator, new_element)
					change_made = true
				elif (current_operator.sw_script_data_types.BNUMBER == current_operator.output_type):
					new_element = SWIfOperator.new(BooleanConstant.new(true), BNumberConstant.new(0), BNumberConstant.new(0))
					new_element.output_type = current_operator.output_type
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
		"Absolute Value":
			var new_operand = BNumberConstant.new(0)
			new_element = AbsoluteValueOperator.new(new_operand)
			replace_element(current_operator, new_element)
			change_made = true
		"Arithmetic Mean":
			var new_operands = []
			new_operands.append(BNumberConstant.new(0))
			new_operands.append(BNumberConstant.new(0))
			new_element = ArithmeticMeanOperator.new(new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"Arithmetic Negation":
			var new_operand = BNumberConstant.new(0)
			new_element = ArithmeticNegationOperator.new(new_operand)
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
		"Maximum":
			var new_operands = []
			new_operands.append(BNumberConstant.new(0))
			new_operands.append(BNumberConstant.new(0))
			new_element = SWMaxOperator.new(new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"Minimum":
			var new_operands = []
			new_operands.append(BNumberConstant.new(0))
			new_operands.append(BNumberConstant.new(0))
			new_element = SWMinOperator.new(new_operands)
			replace_element(current_operator, new_element)
			change_made = true
		"Nudge":
			new_element = NudgeOperator.new(storyworld.create_default_bnumber_pointer(), BNumberConstant.new(0))
			replace_element(current_operator, new_element)
			change_made = true
		#Add and delete
		"Add new operand":
			if (current_operator is SWOperator and current_operator.can_add_operands):
				if (current_operator is SWIfOperator):
					#If the selected operator is an if-then statement, then add a new conditional.
					if (current_operator.sw_script_data_types.BOOLEAN == current_operator.output_type):
						new_element = BooleanConstant.new(true)
						var conditional_result = BooleanConstant.new(true)
						current_operator.add_conditional(new_element, conditional_result)
						change_made = true
					elif (current_operator.sw_script_data_types.BNUMBER == current_operator.output_type):
						new_element = BooleanConstant.new(true)
						var conditional_result = BNumberConstant.new(0)
						current_operator.add_conditional(new_element, conditional_result)
						change_made = true
				elif (current_operator.sw_script_data_types.BOOLEAN == current_operator.input_type):
					new_element = BooleanConstant.new(true)
					current_operator.add_operand(new_element)
					change_made = true
				elif (current_operator.sw_script_data_types.BNUMBER == current_operator.input_type):
					new_element = BNumberConstant.new(0)
					current_operator.add_operand(new_element)
					change_made = true
		"Delete":
			if (current_operator is SWScriptElement):
				if (current_operator.parent_operator is SWOperator and current_operator.parent_operator.can_add_operands and current_operator.parent_operator.minimum_number_of_operands < current_operator.parent_operator.operands.size()):
					if (current_operator.parent_operator is SWIfOperator):
						new_element = current_operator.parent_operator
						new_element.remove_conditional(current_operator.script_index)
						change_made = true
					else:
						new_element = current_operator.parent_operator
						new_element.erase_operand(current_operator)
						change_made = true
	if (change_made):
		refresh_script_display()
		load_operator(new_element)
		emit_signal("sw_script_changed", script_to_edit)

func _on_EventSelectionDialog_confirmed():
	if (current_operator is SWScriptElement and (current_operator.sw_script_data_types.VARIANT == current_operator.output_type or current_operator.sw_script_data_types.BOOLEAN == current_operator.output_type)):
		if (null == $EventSelectionDialog/EventSelectionInterface.selected_event.encounter):
			#No event was selected, so there is no need to add a new operator.
			return
		var new_element = EventPointer.new()
		new_element.set_as_copy_of($EventSelectionDialog/EventSelectionInterface.selected_event)
		replace_element(current_operator, new_element)
		refresh_script_display()
		load_operator(new_element)
		emit_signal("sw_script_changed", script_to_edit)

#GUI Themes:

func set_gui_theme(theme_name, background_color):
	gui_background_color = background_color
	$Background.color = background_color
	$Background/VBC/HBC/VBC1/OperatorEditPanel.color = background_color
	$EventSelectionDialog/EventSelectionInterface.set_gui_theme(theme_name, background_color)
