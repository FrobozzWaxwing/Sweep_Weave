extends MarginContainer

var storyworld = null
var script_to_edit = null

onready var BNumberConstantEditor = $BNumberConstantEditor
onready var BNumberPointerEditor = $BNumberPointerEditor

signal sw_script_changed(sw_script)

func set_error_message(text = ""):
	$ErrorMessage.set_text(text)
	$ErrorMessage.set_visible("" != text)
	$BNumberConstantEditor.set_visible(false)
	$BNumberPointerEditor.set_visible(false)

func refresh():
	BNumberConstantEditor.set_layout("", 1)
	BNumberConstantEditor.refresh()
	BNumberPointerEditor.allow_coefficient_editing = false
	BNumberPointerEditor.storyworld = storyworld
	BNumberPointerEditor.reset()
	if (null == storyworld):
		BNumberPointerEditor.refresh()
		set_error_message("Null Storyworld.")
	elif (script_to_edit is ScriptManager):
		$ErrorMessage.set_visible(false)
		if (script_to_edit.contents is BNumberConstant):
			BNumberConstantEditor.set_reference_operator(script_to_edit.contents)
			BNumberConstantEditor.set_visible(true)
			BNumberPointerEditor.set_visible(false)
		elif (script_to_edit.contents is BNumberPointer):
			BNumberPointerEditor.selected_property.set_as_copy_of(script_to_edit.contents)
			BNumberPointerEditor.refresh()
			BNumberConstantEditor.set_visible(false)
			BNumberPointerEditor.set_visible(true)
		else:
			BNumberConstantEditor.set_visible(false)
			BNumberPointerEditor.set_visible(false)
	else:
		BNumberPointerEditor.refresh()
		set_error_message("Invalid Script.")

func refresh_bnumber_property_lists():
	BNumberPointerEditor.allow_coefficient_editing = false
	BNumberPointerEditor.storyworld = storyworld
	BNumberPointerEditor.reset()
	if (script_to_edit is ScriptManager):
		if (script_to_edit.contents is BNumberPointer):
			BNumberPointerEditor.selected_property.set_as_copy_of(script_to_edit.contents)
	BNumberPointerEditor.refresh()

func _on_BNumberConstantEditor_bnumber_value_changed(reference_operator, value):
	if (reference_operator is BNumberConstant and (TYPE_INT == typeof(value) or TYPE_REAL == typeof(value))):
		reference_operator.set_value(value)
		emit_signal("sw_script_changed", script_to_edit)

func _on_BNumberPointerEditor_bnumber_property_selected(selected_property):
	if (selected_property is BNumberPointer and script_to_edit is ScriptManager and script_to_edit.contents is BNumberPointer):
		script_to_edit.contents.set_as_copy_of(selected_property)
		emit_signal("sw_script_changed", script_to_edit)
