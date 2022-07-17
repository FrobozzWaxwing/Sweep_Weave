extends Control

var storyworld = null
var operator = null

onready var ControlDial = $Panel/VBC/GridContainer/SpinBox
onready var ControlSlider = $Panel/VBC/GridContainer/Slidebar

signal bnumber_value_changed(operator)

func _ready():
	pass # Replace with function body.

func set_layout(label, number_of_columns):
	if ("" == label):
		$Panel/VBC/Label.visible = false
	else:
		$Panel/VBC/Label.visible = true
	$Panel/VBC/Label.text = label
	$Panel/VBC/GridContainer.columns = number_of_columns

func reset():
	if (null != storyworld and storyworld is Storyworld):
		if (null == operator):
			operator = BNumberConstant.new(0)
			#Since this is a temporary pointer used by the interface, we need not set the "parent_operator" property.
		operator.set_value(0)

func refresh():
	if (null == operator or null == storyworld):
		$Panel/VBC/GridContainer/Slidebar.value = 0
		$Panel/VBC/GridContainer/SpinBox.value = 0
		return false
	else:
		var value = operator.get_value()
		$Panel/VBC/GridContainer/Slidebar.value = value
		$Panel/VBC/GridContainer/SpinBox.value = value
		return true

func _on_Slidebar_value_changed(value):
	operator.set_value(value) # This automatically clamps the value to be within bounds.
	ControlDial.value = (operator.get_value())
	emit_signal("bnumber_value_changed", operator)

func _on_SpinBox_value_changed(value):
	operator.set_value(value) # This automatically clamps the value to be within bounds.
	ControlSlider.value = (operator.get_value())
	emit_signal("bnumber_value_changed", operator)
