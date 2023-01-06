extends Object
class_name HB_Record
#A class for history book records, or for nodes of the tree created by the rehearsal system.

var tree_node = null
#Option and reaction should actually come before encounter.
#In other words, each record keeps track of the option and reaction chosen in one encounter,
#and the encounter selected after that, because everything is deterministic except for player choices,
#so player choices should be the start of each branch.
var player_choice = null
var antagonist_choice = null
var encounter = null
var is_an_ending_leaf = false
var turn = 0
var fully_explored = false
var relationship_values = {}
# {character id: copy of bnumber_properties}
var spool_statuses = {}
# {spool id: copy of is_active}

func set_pValues(storyworld):
	#Clear out any old data.
	relationship_values = {}
	#Add new data.
	for character in storyworld.characters:
		relationship_values[character.id] = character.bnumber_properties.duplicate(true)

func record_occurrences():
	if (null != player_choice):
		player_choice.occurrences += 1
	if (null != antagonist_choice):
		antagonist_choice.occurrences += 1
	if (null != encounter):
		encounter.occurrences += 1

func record_spool_statuses(storyworld):
	#Clear out any old data.
	spool_statuses = {}
	#Add new data.
	for spool in storyworld.spools:
		spool_statuses[spool.id] = spool.is_active

#https://github.com/godotengine/godot/issues/19796
#Trees have a strange system for getting the children of a tree item.
func get_item_children(item:TreeItem)->Array:
	item = item.get_children()
	var children = []
	while item:
		children.append(item)
		item = item.get_next()
	return children

func get_tree_node_children():
	if (null == tree_node):
		return []
	else:
		return get_item_children(tree_node)

func get_fully_explored():
	if (fully_explored):
		return true
	elif (is_an_ending_leaf):
		return true
	var children = get_tree_node_children()
	if (0 < children.size()):
		for each in children:
			if (false == each.get_metadata(0).fully_explored):
				return false
		return true
	return false

func _init():
	pass

func data_to_string(cutoff = 20):
	var result = ""
	if (null == player_choice and null == antagonist_choice):
		result += "Start."
	else:
		result = "O: "
		if (null == player_choice):
			result += "null"
		else:
			result += player_choice.text.left(cutoff)
		result += " R: "
		if (null == antagonist_choice):
			result += "null"
		else:
			result += antagonist_choice.text.left(cutoff)
	result += " E: "
	if (null == encounter):
		result += "null"
	else:
		result += encounter.title.left(cutoff)
	if (is_an_ending_leaf):
		result += "(end)"
	result += "."
	#print (result)
	return result
