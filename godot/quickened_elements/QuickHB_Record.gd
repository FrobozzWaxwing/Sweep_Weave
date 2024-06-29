extends Object
class_name QuickHB_Record
#A class for history book records, or for nodes of the tree created by the rehearsal system.

#Option and reaction should actually come before encounter.
#In other words, each record keeps track of the option and reaction chosen in one encounter,
#and the encounter selected after that, because everything is deterministic except for player choices,
#so player choices should be the start of each branch.
var player_choice = null
var antagonist_choice = null
var encounter = null
var is_an_ending_leaf = false
var turn = 0
var relationship_values = []
var active_spools = []
var parent_record = null
var explored_branches = []
var unexplored_branches = []
var parallel_to = []
var can_be_skipped = false
var path_multiplier = 1
var path_count = 0 #The number of paths branching off from this record. The count is recursive: if this record has only one child but the child record has two children, both of which are ending leaves, then this record's branch count should be 2.

func record_character_states(rehearsal):
	relationship_values = rehearsal.cast_traits.duplicate()

func record_yielding_paths():
	#Add the record's branch count to the yielding path count of each of the record's events.
	var additional_paths = path_count * path_multiplier
	if (null != player_choice):
		player_choice.yielding_paths += additional_paths
	if (null != antagonist_choice):
		antagonist_choice.yielding_paths += additional_paths
	if (null != encounter):
		encounter.yielding_paths += additional_paths
	for each in parallel_to:
		each.path_count = path_count
		each.record_yielding_paths()

func set_as_ending_leaf():
	is_an_ending_leaf = true
	path_count = 1
	if (null != encounter):
		encounter.potential_ending = true

func increment_occurrences():
	if (null != player_choice):
		player_choice.occurrences += 1
	if (null != antagonist_choice):
		antagonist_choice.occurrences += 1
	if (null != encounter):
		encounter.occurrences += 1

func decrement_occurrences():
	if (null != player_choice):
		player_choice.occurrences -= 1
	if (null != antagonist_choice):
		antagonist_choice.occurrences -= 1
	if (null != encounter):
		encounter.occurrences -= 1

func record_spool_statuses(rehearsal):
	active_spools = rehearsal.active_spools.duplicate()

func get_parent():
	return parent_record

func add_branch(page):
	page.parent_record = self
	unexplored_branches.append(page)

func is_parallel_to(sibling):
	if (null != antagonist_choice and null != sibling.antagonist_choice):
		if (antagonist_choice.is_parallel_to(sibling.antagonist_choice)):
			return true
	return false

func _init(in_parent = null):
	parent_record = in_parent

func clear_children():
	for child in explored_branches:
		child.clear()
		child.call_deferred("free")
	explored_branches.clear()
	for child in unexplored_branches:
		child.clear()
		child.call_deferred("free")
	unexplored_branches.clear()

func clear():
	clear_children()
	player_choice = null
	antagonist_choice = null
	encounter = null
	is_an_ending_leaf = false
	turn = 0
	relationship_values.clear()
	active_spools.clear()
	parent_record = null

func set_as_copy_of(original):
	clear()
	player_choice = original.player_choice
	antagonist_choice = original.antagonist_choice
	encounter = original.encounter
	is_an_ending_leaf = original.is_an_ending_leaf
	turn = original.turn
	relationship_values = original.relationship_values.duplicate()
	active_spools = original.active_spools.duplicate()
	parent_record = original.parent_record
	for page in original.explored_branches:
		#Branches will still have original parent.
		explored_branches.append(page)
	for page in original.unexplored_branches:
		#Branches will still have original parent.
		unexplored_branches.append(page)

func stringify_option(cutoff = 50):
	var result = ""
	if (null == player_choice):
		result += "null"
	else:
		var fulltext = player_choice.get_text()
		if ("" == fulltext):
			result += "[Blank Option]"
		else:
			var cuttext = fulltext.left(cutoff)
			if (cuttext != fulltext):
				cuttext += "..."
			result += cuttext
	return result

func stringify_reaction(cutoff = 50):
	var result = ""
	if (null == antagonist_choice):
		result += "null"
	else:
		var fulltext = antagonist_choice.get_text()
		if ("" == fulltext):
			result += "[Blank Reaction]"
		else:
			var cuttext = fulltext.left(cutoff)
			if (cuttext != fulltext):
				cuttext += "..."
			result += cuttext
	return result

func stringify_encounter(cutoff = 100):
	var result = ""
	if (null == encounter):
		result += "The End."
	else:
		var fulltext = encounter.title
		if ("" == fulltext):
			result += "[Blank Encounter]"
		else:
			var cuttext = fulltext.left(cutoff)
			if (cuttext != fulltext):
				cuttext += "..."
			result += cuttext
	return result

func data_to_string(cutoff = 25):
	var result = ""
	if (null == player_choice and null == antagonist_choice):
		result += "Start."
	else:
		result = "O: " + stringify_option(cutoff)
		result += " R: " + stringify_reaction(cutoff)
	result += " E: " + stringify_encounter(cutoff)
	if (is_an_ending_leaf):
		result += "(end)"
	result += "."
	return result
