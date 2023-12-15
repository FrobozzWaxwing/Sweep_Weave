extends Control

var value_0 = 0
var value_1 = 0

func _ready():
	display_output()

func display_output():
	var output = (value_0 * (1 - abs(value_1))) + value_1
	$GridContainer/OutputSlider.set_value(output)
	$GridContainer/Result.set_text(str(output))

func _on_XSlider_value_changed(value):
	value_0 = $GridContainer/XSlider.get_value()
	$GridContainer/XSpinBox.set_value(value_0)
	display_output()

func _on_XSpinBox_value_changed(value):
	value_0 = $GridContainer/XSpinBox.get_value()
	$GridContainer/XSlider.set_value(value_0)
	display_output()

func _on_YSlider_value_changed(value):
	value_1 = $GridContainer/YSlider.get_value()
	$GridContainer/YSpinBox.set_value(value_1)
	display_output()

func _on_YSpinBox_value_changed(value):
	value_1 = $GridContainer/YSpinBox.get_value()
	$GridContainer/YSlider.set_value(value_1)
	display_output()
