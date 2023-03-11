extends Control

var storyworld = null
var operator = null

onready var ControlDial = $Background/VBC/GridContainer/SpinBox
onready var ControlSlider = $Background/VBC/GridContainer/Slidebar

signal bnumber_value_changed(operator)

func _ready():
	pass # Replace with function body.

func set_layout(label, number_of_columns):
	if ("" == label):
		$Background/VBC/Label.visible = false
	else:
		$Background/VBC/Label.visible = true
	$Background/VBC/Label.text = label
	$Background/VBC/GridContainer.columns = number_of_columns

func reset():
	if (null != storyworld and storyworld is Storyworld):
		if (null == operator):
			operator = BNumberConstant.new(0)
			#Since this is a temporary pointer used by the interface, we need not set the "parent_operator" property.
		operator.set_value(0)

func refresh():
	if (null == operator or null == storyworld):
		$Background/VBC/GridContainer/Slidebar.value = 0
		$Background/VBC/GridContainer/SpinBox.value = 0
		return false
	else:
		var value = operator.get_value()
		$Background/VBC/GridContainer/Slidebar.value = value
		$Background/VBC/GridContainer/SpinBox.value = value
		return true

func _on_Slidebar_value_changed(value):
	operator.set_value(value) # This automatically clamps the value to be within bounds.
	ControlDial.value = (operator.get_value())
	emit_signal("bnumber_value_changed", operator)

func _on_SpinBox_value_changed(value):
	operator.set_value(value) # This automatically clamps the value to be within bounds.
	ControlSlider.value = (operator.get_value())
	emit_signal("bnumber_value_changed", operator)

#GUI Themes:

func set_gui_theme(theme_name, background_color):
	$Background.color = background_color

