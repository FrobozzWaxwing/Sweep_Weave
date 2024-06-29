extends MarginContainer

var storyworld = null
var script_to_edit = null
@export var title = ""

@onready var WeightSelector = $Rows/WeightDisplay/WeightSelector
@onready var Trait0NegationToggle = $Rows/TraitsDisplay/Trait0/NegationToggle
@onready var Trait0Selector = $Rows/TraitsDisplay/Trait0/Selector
@onready var Trait1NegationToggle = $Rows/TraitsDisplay/Trait1/NegationToggle
@onready var Trait1Selector = $Rows/TraitsDisplay/Trait1/Selector

signal sw_script_changed(sw_script)

func set_error_message(text = ""):
	$Rows/Title.set_text(text)
	if ("" != text):
		$Rows/Title.set_visible(true)
		$Rows/WeightDisplay.set_visible(false)
		$Rows/TraitsDisplay.set_visible(false)

func refresh_trait_editor(script_element, negation_toggle, selector):
	if (script_element is BNumberPointer):
		negation_toggle.set_text(" ")
		selector.selected_property.set_as_copy_of(script_element)
		selector.refresh()
		return true
	elif (script_element is ArithmeticNegationOperator and script_element.operands.front() is BNumberPointer):
		negation_toggle.set_text("-")
		selector.selected_property.set_as_copy_of(script_element.operands.front())
		selector.refresh()
		return true
	else:
		return false

func refresh():
	WeightSelector.set_layout("", 1)
	WeightSelector.refresh()
	Trait0Selector.storyworld = storyworld
	Trait0Selector.reset()
	Trait1Selector.storyworld = storyworld
	Trait1Selector.reset()
	if (null == storyworld):
		Trait0Selector.refresh()
		Trait1Selector.refresh()
		set_error_message("Null Storyworld.")
	elif (!(script_to_edit is ScriptManager)):
		Trait0Selector.refresh()
		Trait1Selector.refresh()
		set_error_message("Invalid Script.")
	else:
		var show_interface = false
		$Rows/Title.set_text(title)
		if (script_to_edit.contents is BNumberConstant):
			show_interface = true
			WeightSelector.set_reference_operator(script_to_edit.contents)
			$Rows/Title.set_visible(true)
			$Rows/WeightDisplay.set_visible(true)
			$Rows/WeightDisplay/Label.set_visible(false)
			$Rows/WeightDisplay/Label2.set_visible(false)
			$Rows/TraitsDisplay.set_visible(false)
		elif (script_to_edit.contents is BNumberPointer or script_to_edit.contents is ArithmeticNegationOperator):
			show_interface = refresh_trait_editor(script_to_edit.contents, Trait0NegationToggle, Trait0Selector)
			$Rows/Title.set_visible(true)
			$Rows/WeightDisplay.set_visible(false)
			$Rows/TraitsDisplay.set_visible(true)
			$Rows/TraitsDisplay/VSeparator.set_visible(false)
			$Rows/TraitsDisplay/Trait1.set_visible(false)
		elif (script_to_edit.contents is ArithmeticMeanOperator and 2 == script_to_edit.contents.operands.size()):
			show_interface = refresh_trait_editor(script_to_edit.contents.operands[0], Trait0NegationToggle, Trait0Selector)
			show_interface = show_interface and refresh_trait_editor(script_to_edit.contents.operands[1], Trait1NegationToggle, Trait1Selector)
			$Rows/Title.set_visible(true)
			$Rows/WeightDisplay.set_visible(false)
			$Rows/TraitsDisplay.set_visible(true)
			$Rows/TraitsDisplay/VSeparator.set_visible(true)
			$Rows/TraitsDisplay/Trait1.set_visible(true)
		elif (script_to_edit.contents is BlendOperator and 3 == script_to_edit.contents.operands.size() and script_to_edit.contents.operands[2] is BNumberConstant):
			WeightSelector.set_reference_operator(script_to_edit.contents.operands[2])
			show_interface = refresh_trait_editor(script_to_edit.contents.operands[0], Trait0NegationToggle, Trait0Selector)
			show_interface = show_interface and refresh_trait_editor(script_to_edit.contents.operands[1], Trait1NegationToggle, Trait1Selector)
			$Rows/Title.set_visible(true)
			$Rows/WeightDisplay.set_visible(true)
			$Rows/WeightDisplay/Label.set_visible(true)
			$Rows/WeightDisplay/WeightSelector.set_visible(true)
			$Rows/WeightDisplay/Label2.set_visible(true)
			$Rows/TraitsDisplay.set_visible(true)
			$Rows/TraitsDisplay/VSeparator.set_visible(true)
			$Rows/TraitsDisplay/Trait1.set_visible(true)
		$Rows.set_visible(show_interface)

func refresh_bnumber_property_lists():
	if (script_to_edit is ScriptManager):
		if ((script_to_edit.contents is ArithmeticMeanOperator or script_to_edit.contents is BlendOperator) and 2 <= script_to_edit.contents.operands.size()):
			Trait0Selector.storyworld = storyworld
			Trait0Selector.reset()
			refresh_trait_editor(script_to_edit.contents.operands[0], Trait0NegationToggle, Trait0Selector)
			Trait0Selector.refresh()
			Trait1Selector.storyworld = storyworld
			Trait1Selector.reset()
			refresh_trait_editor(script_to_edit.contents.operands[1], Trait1NegationToggle, Trait1Selector)
			Trait1Selector.refresh()
		elif (script_to_edit.contents is BNumberPointer or script_to_edit.contents is ArithmeticNegationOperator):
			Trait0Selector.storyworld = storyworld
			Trait0Selector.reset()
			refresh_trait_editor(script_to_edit.contents, Trait0NegationToggle, Trait0Selector)
			Trait0Selector.refresh()

func replace_element(old_element, new_element):
	if (old_element is SWScriptElement and new_element is SWScriptElement):
		var parent = old_element.parent_operator
		var index = old_element.script_index
		if (parent is SWOperator):
			parent.operands[index] = new_element
			new_element.parent_operator = parent
			new_element.script_index = index
		elif (parent is ScriptManager):
			parent.contents = new_element
			new_element.parent_operator = parent
			new_element.script_index = 0
			old_element.call_deferred("free")

func negate_element(child):
	if (child is SWScriptElement):
		var old_parent = child.parent_operator
		var index = child.script_index
		var new_parent = ArithmeticNegationOperator.new(child)
		if (old_parent is SWOperator):
			old_parent.operands[index] = new_parent
		elif (old_parent is ScriptManager):
			old_parent.contents = new_parent
		new_parent.parent_operator = old_parent
		new_parent.script_index = index

func _on_WeightSelector_bnumber_value_changed(operator, new_value):
	if (operator is BNumberConstant and (TYPE_INT == typeof(new_value) or TYPE_FLOAT == typeof(new_value))):
		operator.set_value(new_value)
		sw_script_changed.emit(script_to_edit)

func _on_trait0_negation_toggle_pressed():
	if (script_to_edit is ScriptManager):
		var root = script_to_edit.contents
		if (root is ArithmeticMeanOperator or root is BlendOperator):
			var script_element = root.operands.front()
			if (script_element is BNumberPointer):
				negate_element(script_element)
				Trait0NegationToggle.set_text("-")
				sw_script_changed.emit(script_to_edit)
			elif (script_element is ArithmeticNegationOperator and script_element.operands.front() is BNumberPointer):
				replace_element(script_element, script_element.operands.front())
				Trait0NegationToggle.set_text(" ")
				sw_script_changed.emit(script_to_edit)
		elif (root is BNumberPointer):
			negate_element(root)
			Trait0NegationToggle.set_text("-")
			sw_script_changed.emit(script_to_edit)
		elif (root is ArithmeticNegationOperator and root.operands.front() is BNumberPointer):
			replace_element(root, root.operands.front())
			Trait0NegationToggle.set_text(" ")
			sw_script_changed.emit(script_to_edit)

func _on_trait0_selector_bnumber_property_selected(selected_property):
	if (selected_property is BNumberPointer and script_to_edit is ScriptManager):
		if (script_to_edit.contents is ArithmeticMeanOperator or script_to_edit.contents is BlendOperator):
			var script_element = script_to_edit.contents.operands.front()
			if (script_element is BNumberPointer):
				script_element.set_as_copy_of(selected_property)
				sw_script_changed.emit(script_to_edit)
			elif (script_element is ArithmeticNegationOperator and script_element.operands.front() is BNumberPointer):
				script_element.operands.front().set_as_copy_of(selected_property)
				sw_script_changed.emit(script_to_edit)
		elif (script_to_edit.contents is BNumberPointer):
			script_to_edit.contents.set_as_copy_of(selected_property)
			sw_script_changed.emit(script_to_edit)
		elif (script_to_edit.contents is ArithmeticNegationOperator and script_to_edit.contents.operands.front() is BNumberPointer):
			script_to_edit.contents.operands.front().set_as_copy_of(selected_property)
			sw_script_changed.emit(script_to_edit)

func _on_trait1_negation_toggle_pressed():
	if (script_to_edit is ScriptManager):
		if (script_to_edit.contents is ArithmeticMeanOperator or script_to_edit.contents is BlendOperator):
			var script_element = script_to_edit.contents.operands[1]
			if (script_element is BNumberPointer):
				negate_element(script_element)
				Trait1NegationToggle.set_text("-")
				sw_script_changed.emit(script_to_edit)
			elif (script_element is ArithmeticNegationOperator and script_element.operands.front() is BNumberPointer):
				replace_element(script_element, script_element.operands.front())
				Trait1NegationToggle.set_text(" ")
				sw_script_changed.emit(script_to_edit)

func _on_trait1_selector_bnumber_property_selected(selected_property):
	if (selected_property is BNumberPointer and script_to_edit is ScriptManager):
		if ((script_to_edit.contents is ArithmeticMeanOperator or script_to_edit.contents is BlendOperator) and 2 <= script_to_edit.contents.operands.size()):
			var script_element = script_to_edit.contents.operands[1]
			if (script_element is BNumberPointer):
				script_element.set_as_copy_of(selected_property)
				sw_script_changed.emit(script_to_edit)
			elif (script_element is ArithmeticNegationOperator and script_element.operands.front() is BNumberPointer):
				script_element.operands.front().set_as_copy_of(selected_property)
				sw_script_changed.emit(script_to_edit)

