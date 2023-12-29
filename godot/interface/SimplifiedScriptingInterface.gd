extends MarginContainer

var storyworld = null
var script_to_edit = null
export var title = ""

onready var WeightSelector = $Rows/WeightDisplay/WeightSelector
onready var Trait1Selector = $Rows/TraitsDisplay/Trait1Selector
onready var Trait2Selector = $Rows/TraitsDisplay/Trait2Selector

signal sw_script_changed(sw_script)

func set_error_message(text = ""):
	$Rows/Title.set_text(text)
	if ("" != text):
		$Rows/Title.set_visible(true)
		$Rows/WeightDisplay.set_visible(false)
		$Rows/TraitsDisplay.set_visible(false)

func refresh():
	WeightSelector.set_layout("", 1)
	WeightSelector.refresh()
	Trait1Selector.allow_coefficient_editing = false
	Trait1Selector.storyworld = storyworld
	Trait1Selector.reset()
	Trait2Selector.allow_coefficient_editing = false
	Trait2Selector.storyworld = storyworld
	Trait2Selector.reset()
	if (null == storyworld):
		Trait1Selector.refresh()
		Trait2Selector.refresh()
		set_error_message("Null Storyworld.")
	elif (script_to_edit is ScriptManager):
		$Rows.set_visible(true)
		$Rows/Title.set_text(title)
		if (script_to_edit.contents is ArithmeticMeanOperator
			and 2 == script_to_edit.contents.operands.size()
			and script_to_edit.contents.operands[0] is BNumberPointer
			and script_to_edit.contents.operands[1] is BNumberPointer):
			Trait1Selector.selected_property.set_as_copy_of(script_to_edit.contents.operands[0])
			Trait1Selector.refresh()
			Trait2Selector.selected_property.set_as_copy_of(script_to_edit.contents.operands[1])
			Trait2Selector.refresh()
			$Rows/Title.set_visible(true)
			$Rows/WeightDisplay.set_visible(false)
			$Rows/TraitsDisplay.set_visible(true)
			$Rows/TraitsDisplay/VSeparator.set_visible(true)
			Trait2Selector.set_visible(true)
		elif (script_to_edit.contents is BlendOperator
			and 3 == script_to_edit.contents.operands.size()
			and script_to_edit.contents.operands[0] is BNumberPointer
			and script_to_edit.contents.operands[1] is BNumberPointer
			and script_to_edit.contents.operands[2] is BNumberConstant):
			WeightSelector.set_reference_operator(script_to_edit.contents.operands[2])
			Trait1Selector.selected_property.set_as_copy_of(script_to_edit.contents.operands[0])
			Trait1Selector.refresh()
			Trait2Selector.selected_property.set_as_copy_of(script_to_edit.contents.operands[1])
			Trait2Selector.refresh()
			$Rows/Title.set_visible(true)
			$Rows/WeightDisplay.set_visible(true)
			$Rows/WeightDisplay/Label.set_visible(true)
			$Rows/WeightDisplay/WeightSelector.set_visible(true)
			$Rows/WeightDisplay/Label2.set_visible(true)
			$Rows/TraitsDisplay.set_visible(true)
			$Rows/TraitsDisplay/VSeparator.set_visible(true)
			Trait2Selector.set_visible(true)
		elif (script_to_edit.contents is BNumberConstant):
			WeightSelector.set_reference_operator(script_to_edit.contents)
			$Rows/Title.set_visible(true)
			$Rows/WeightDisplay.set_visible(true)
			$Rows/WeightDisplay/Label.set_visible(false)
			$Rows/WeightDisplay/Label2.set_visible(false)
			$Rows/TraitsDisplay.set_visible(false)
		elif (script_to_edit.contents is BNumberPointer):
			Trait1Selector.selected_property.set_as_copy_of(script_to_edit.contents)
			Trait1Selector.refresh()
			$Rows/Title.set_visible(true)
			$Rows/WeightDisplay.set_visible(false)
			$Rows/TraitsDisplay.set_visible(true)
			$Rows/TraitsDisplay/VSeparator.set_visible(false)
			Trait2Selector.set_visible(false)
		else:
			$Rows.set_visible(false)
	else:
		Trait1Selector.refresh()
		Trait2Selector.refresh()
		set_error_message("Invalid Script.")

func refresh_bnumber_property_lists():
	Trait1Selector.allow_coefficient_editing = false
	Trait1Selector.storyworld = storyworld
	Trait1Selector.reset()
	Trait2Selector.allow_coefficient_editing = false
	Trait2Selector.storyworld = storyworld
	Trait2Selector.reset()
	if (script_to_edit is ScriptManager):
		if ((script_to_edit.contents is ArithmeticMeanOperator or script_to_edit.contents is BlendOperator) and 2 <= script_to_edit.contents.operands.size()):
			if (script_to_edit.contents.operands[0] is BNumberPointer):
				Trait1Selector.selected_property.set_as_copy_of(script_to_edit.contents.operands[0])
			if (script_to_edit.contents.operands[1] is BNumberPointer):
				Trait2Selector.selected_property.set_as_copy_of(script_to_edit.contents.operands[1])
		elif (script_to_edit.contents is BNumberPointer):
			Trait1Selector.selected_property.set_as_copy_of(script_to_edit.contents)
	Trait1Selector.refresh()
	Trait2Selector.refresh()

func _on_WeightSelector_bnumber_value_changed(operator, new_value):
	if (operator is BNumberConstant and (TYPE_INT == typeof(new_value) or TYPE_REAL == typeof(new_value))):
		operator.set_value(new_value)
		emit_signal("sw_script_changed", script_to_edit)

func _on_Trait1Selector_bnumber_property_selected(selected_property):
	if (selected_property is BNumberPointer and script_to_edit is ScriptManager):
		if ((script_to_edit.contents is ArithmeticMeanOperator or script_to_edit.contents is BlendOperator)
			and script_to_edit.contents.operands.front() is BNumberPointer):
			script_to_edit.contents.operands.front().set_as_copy_of(selected_property)
			emit_signal("sw_script_changed", script_to_edit)
		elif (script_to_edit.contents is BNumberPointer):
			script_to_edit.contents.set_as_copy_of(selected_property)
			emit_signal("sw_script_changed", script_to_edit)

func _on_Trait2Selector_bnumber_property_selected(selected_property):
	if (selected_property is BNumberPointer and script_to_edit is ScriptManager):
		if (script_to_edit.contents is BlendOperator and 3 == script_to_edit.contents.operands.size() and script_to_edit.contents.operands[1] is BNumberPointer):
			script_to_edit.contents.operands[1].set_as_copy_of(selected_property)
			emit_signal("sw_script_changed", script_to_edit)
