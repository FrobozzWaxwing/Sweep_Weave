extends Control

var branch_first_reaction = null
var branch_mean = null
var branch_x = null
var branch_y = null
var branch_second_reaction = null
var branch_z

func _ready():
	$VBC/Tree.set_column_expand(0, true)
	$VBC/Tree.set_column_custom_minimum_width(0, 4)
	$VBC/Tree.set_column_expand(1, true)
	$VBC/Tree.set_column_custom_minimum_width(1, 1)
	var root = $VBC/Tree.create_item()
	branch_first_reaction = $VBC/Tree.create_item(root)
	branch_first_reaction.set_text(0, "Absolutely!")
	branch_mean = $VBC/Tree.create_item(branch_first_reaction)
	branch_mean.set_text(0, "Arithmetic Mean of")
	branch_x = $VBC/Tree.create_item(branch_mean)
	branch_x.set_text(0, "Brynn [Affection, Aileen]")
	branch_x.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
	branch_x.set_range_config (1, -0.99, 0.99, 0.01)
	branch_x.set_range(1, 0.6)
	branch_x.set_editable(1, true)
	branch_y = $VBC/Tree.create_item(branch_mean)
	branch_y.set_text(0, "Brynn [Shyness_Boldness]")
	branch_y.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
	branch_y.set_range_config (1, -0.99, 0.99, 0.01)
	branch_y.set_range(1, -0.2)
	branch_y.set_editable(1, true)
	branch_second_reaction = $VBC/Tree.create_item(root)
	branch_second_reaction.set_text(0, "No thanks, I'm good.")
	branch_z = $VBC/Tree.create_item(branch_second_reaction)
	branch_z.set_text(0, "BNumber Constant")
	branch_z.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
	branch_z.set_range_config (1, -0.99, 0.99, 0.01)
	branch_z.set_range(1, 0)
	branch_z.set_editable(1, true)
	refresh()
	$VBC/Tree.item_edited.connect(refresh)

func refresh():
	var inclination_a = (branch_x.get_range(1) + branch_y.get_range(1)) / 2
	var inclination_b = branch_z.get_range(1)
	branch_mean.set_text(1, str(inclination_a))
	branch_first_reaction.set_text(1, str(inclination_a))
	branch_second_reaction.set_text(1, str(inclination_b))
	$VBC/Legend.clear()
	var text = ""
	if (inclination_a >= inclination_b or abs(inclination_a - inclination_b) < 0.001):
		#Floating point math is a bit imperfect when testing for equalities.
		text += "[i]Illustration 2:[/i] Brynn will select \"Absolutely!\""
	else:
		text += "[i]Illustration 2:[/i] Brynn will select \"No thanks, I'm good.\""
	$VBC/Legend.append_text(text)
