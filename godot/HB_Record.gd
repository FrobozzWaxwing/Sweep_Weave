extends Object
class_name HB_Record
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
var fully_explored = false
var relationship_values = {}
# {character id: copy of bnumber_properties}
var spool_statuses = {}
# {spool id: copy of is_active}
var parent_record = null
var branch_records = []

func record_character_states(storyworld):
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

func get_parent():
	return parent_record

func get_children():
	return branch_records

func add_branch(page):
	page.parent_record = self
	branch_records.append(page)

func get_fully_explored():
	if (fully_explored):
		return true
	elif (is_an_ending_leaf):
		return true
	if (0 < branch_records.size()):
		for each in branch_records:
			if (false == each.fully_explored):
				return false
		return true
	return false

func _init(in_parent = null):
	parent_record = in_parent

func clear():
	var children = get_children().duplicate()
	for child in children:
		child.clear()
		child.call_deferred("free")
	player_choice = null
	antagonist_choice = null
	encounter = null
	is_an_ending_leaf = false
	turn = 0
	fully_explored = false
	relationship_values.clear()
	spool_statuses.clear()
	parent_record = null
	branch_records.clear()

func set_as_copy_of(original):
	clear()
	player_choice = original.player_choice
	antagonist_choice = original.antagonist_choice
	encounter = original.encounter
	is_an_ending_leaf = original.is_an_ending_leaf
	turn = original.turn
	fully_explored = original.fully_explored
	relationship_values = original.relationship_values
	spool_statuses = original.spool_statuses
	parent_record = original.parent_record
	for page in original.branch_records:
		#Branches will still have original parent.
		branch_records.append(page)

func stringify_option(cutoff = 50):
	var result = ""
	if (null == player_choice):
		result += "null"
	else:
		var fulltext = player_choice.get_text(self)
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
		var fulltext = antagonist_choice.get_text(self)
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
