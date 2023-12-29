extends Control

var reference_operator = null
var value = 0

onready var ControlDial = $VBC/GridContainer/SpinBox
onready var ControlSlider = $VBC/GridContainer/Slidebar

signal bnumber_value_changed(reference_operator, value)

func _ready():
	$VBC/GridContainer/SpinBox.share($VBC/GridContainer/Slidebar)

func set_layout(label, number_of_columns):
	if ("" == label):
		$VBC/Label.visible = false
	else:
		$VBC/Label.visible = true
	$VBC/Label.text = label
	$VBC/GridContainer.columns = number_of_columns

func refresh():
	$VBC/GridContainer/Slidebar.set_value(value)

func set_value(new_value):
	value = new_value
	refresh()

func set_reference_operator(new_reference_operator):
	if (new_reference_operator is BNumberConstant):
		reference_operator = new_reference_operator
		set_value(reference_operator.get_value())
	else:
		reference_operator = null

func _on_Slidebar_value_changed(new_value):
	set_value(new_value)
	emit_signal("bnumber_value_changed", reference_operator, new_value)

