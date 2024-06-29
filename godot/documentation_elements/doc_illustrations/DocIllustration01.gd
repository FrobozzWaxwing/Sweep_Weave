extends Control

var branch_divide = null
var branch_add = null
var branch_x = null
var branch_y = null

func _ready():
	$VBC/Tree.set_column_expand(0, true)
	$VBC/Tree.set_column_custom_minimum_width(0, 4)
	$VBC/Tree.set_column_expand(1, true)
	$VBC/Tree.set_column_custom_minimum_width(1, 1)
	branch_divide = $VBC/Tree.create_item()
	branch_divide.set_text(0, "Divide")
	branch_add = $VBC/Tree.create_item(branch_divide)
	branch_add.set_text(0, "Add")
	branch_x = $VBC/Tree.create_item(branch_add)
	branch_x.set_text(0, "x")
	branch_x.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
	branch_x.set_range_config (1, -0.99, 0.99, 0.01)
	branch_x.set_range(1, 0.8)
	branch_x.set_editable(1, true)
	branch_y = $VBC/Tree.create_item(branch_add)
	branch_y.set_text(0, "y")
	branch_y.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
	branch_y.set_range_config (1, -0.99, 0.99, 0.01)
	branch_y.set_range(1, 0.2)
	branch_y.set_editable(1, true)
	var two = $VBC/Tree.create_item(branch_divide)
	two.set_text(0, "2")
	two.set_text(1, "2")
	refresh()
	$VBC/Tree.item_edited.connect(refresh)

func refresh():
	var sum = branch_x.get_range(1) + branch_y.get_range(1)
	branch_add.set_text(1, str(sum))
	branch_divide.set_text(1, str(sum / 2))
