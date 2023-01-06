extends Object
class_name Rehearsal

var history = Tree.new()
var starting_page = null
var playthrough_transcript = ""
var turn = 0
var current_page = null
var ending_leaves = []
var storyworld = null
var initial_pValues = null
var hb_record_list = []

#var occurrences = {} #Tracks how often encounters, options, and reactions occur.
#Each dictionary entry uses an encounter id as the key. The value is an array.
#Entry 0 of this array is an int tracking how many times the encounter occurs on the rehearsal tree.
#Entry 1 is an array of arrays, where each low level array includes an option as [0] and the number of occurrences of the option as [1].
#Entry 2 is an array of arrays, but tracking reactions, [0], and the number of times they occur, [1].
#E.g. {"Encounter1": [7, [[Option1, 1], [Option2, 1]], [Reaction1, 1]]}

func _init(in_storyworld):
	#history.set_hide_root(true)
	storyworld = Storyworld.new()
	if (null != in_storyworld):
		storyworld.set_as_copy_of(in_storyworld)
	initial_pValues = HB_Record.new()
	initial_pValues.set_pValues(storyworld)

#func has_occurred_on_branch(encounter, option, reaction, leaf):
func has_occurred_on_branch(encounter, leaf):
	#Checks whether an encounter has occurred.
	#Optionally checks whether the player chose a given option,
	#and / or whether the antagonist chose a given reaction.
	#null for wildcarding option and reaction.
	if (null == encounter):
		return null
	elif (null == leaf):
		#Playthrough has only just begun.
		return false
	var node = leaf
	while (null != node):
		if (null != node.get_metadata(0).encounter and node.get_metadata(0).encounter == encounter):
			return true
		#No match for this node.
		#Go farther towards the root of the tree.
		if (node != starting_page):
			node = node.get_parent()
		else:
			break
	return false

func select_most_desirable_encounter(acceptableEncounters):
	#Choose an encounter from the pool of acceptable encounters.
	#Find one that has a desirability greater than or equal to that of all the others.
	var flag = true
	var greatest_desirability = -1
	var result = null
#	acceptableEncounters.sort_custom(EncounterSorter, "sort_a_z")
	for encounter in acceptableEncounters:
		if (flag):
			#First iteration of loop.
			greatest_desirability = encounter.desirability_script.get_value()
			result = encounter
			flag = false
		else:
			var encounter_desirability = encounter.desirability_script.get_value()
			if (encounter_desirability > greatest_desirability):
				greatest_desirability = encounter_desirability
				result = encounter
	return result

#func select_next_page(reaction, leaf = null):
#	if (null != reaction and null != reaction.consequence):
#		#If the reaction of the last encounter led to a consequence, that consequence occurs next.
#		return reaction.consequence
#	else:
#		#Otherwise:
#		var acceptable_encounters_inc = []#These encounters are acceptable for the current turn.
#		var acceptable_encounters_exc = []#These encounters are acceptable except for their turn range.
#		var earliest_acceptable_turn = 0#If no encounters are acceptable for the present turn, but some are acceptable for later turns, what must we set the turn count to?
#		for encounter in storyworld.encounters:
#			#Check whether an encounter is acceptable.
#			var acceptable = true
#			#Acceptability checks:
#			#Has encounter already occured once before?
#			#Test encounter history against prerequisites and disqualifiers.
#			#pValue ranges.
#			#Turn range.
#			#If encounter has occured before, then it is not acceptable.
#			if (has_occurred_on_branch(encounter, leaf)):
#			#The encounter has occured before.
#				acceptable = false
#			#The following code evaluates prerequisites. For example, we may check whether a character's pValues are within a certain range.
#			if (acceptable):
#				if (!encounter.acceptability_script.get_value(leaf)):
#					acceptable = false
#			if (acceptable):
#				if (turn <= encounter.latest_turn):
#					if (encounter.earliest_turn <= turn):
#						#console.log("Encounter: " + encounter.title + " deemed acceptable for current turn.");
#						acceptable_encounters_inc.append(encounter)
#					else:
#						if (0 == acceptable_encounters_exc.size()):
#							earliest_acceptable_turn = encounter.earliest_turn
#						else:
#							if (earliest_acceptable_turn > encounter.earliest_turn):
#								earliest_acceptable_turn = encounter.earliest_turn
#						#console.log("Encounter: " + encounter.title + " deemed acceptable for later turn.");
#						acceptable_encounters_exc.append(encounter)
#		#//end of for (each in encounters)
#		#//If no encounters are deemed acceptable, display a message saying "THE END" instead of an encounter.
#		if (0 == acceptable_encounters_inc.size()):
#			if (0 == acceptable_encounters_exc.size()):
#				#Load The End
#				return null
#			else:
#				if (turn < earliest_acceptable_turn):
#					turn = earliest_acceptable_turn
#				acceptable_encounters_inc = []
#				for encounter in acceptable_encounters_exc:
#					if (encounter.earliest_turn <= turn):
#						acceptable_encounters_inc.append(encounter)
#				return select_most_desirable_encounter(acceptable_encounters_inc)
#		else:
#			return select_most_desirable_encounter(acceptable_encounters_inc)

func select_first_page():
	#Used when starting or restarting rehearsal to select the first page of the playthrough.
	var acceptable_encounters = []
	var checked = {}
	for spool in storyworld.spools:
		if (spool.starts_active):
			for encounter in spool.encounters:
				if (!checked.has(encounter.id)):
					checked[encounter.id] = true
					if (encounter.acceptability_script.get_value(null)):
						acceptable_encounters.append(encounter)
	if (0 == acceptable_encounters.size()):
		#Display "The End."
		return null
	else:
		return select_most_desirable_encounter(acceptable_encounters)

func select_next_page(reaction, leaf = null):
	if (null != reaction and null != reaction.consequence):
		#If the reaction of the last encounter led to a consequence, that consequence occurs next.
		return reaction.consequence
	else:
		#Otherwise:
		var acceptable_encounters = []
		var checked = {}
		for spool in storyworld.spools:
			if (spool.is_active):
				for encounter in spool.encounters:
					if (!checked.has(encounter.id)):
						checked[encounter.id] = true
						if (!has_occurred_on_branch(encounter, leaf) and encounter.acceptability_script.get_value(leaf)):
							acceptable_encounters.append(encounter)
		if (0 == acceptable_encounters.size()):
			#Display "The End."
			return null
		else:
			return select_most_desirable_encounter(acceptable_encounters)

func find_open_options(leaf):
	if (null == leaf.get_metadata(0).encounter):
		return []
	var all_options = leaf.get_metadata(0).encounter.options
	var open_options = []
	for option in all_options:
		if (option.visibility_script.get_value(leaf) && option.performability_script.get_value(leaf)):
			open_options.append(option)
	return open_options

func select_reaction(option, leaf):
	#This determines how a character reacts to a choice made by the player.
	var topInclination = -1
	var workingChoice = null
	for reaction in option.reactions:
		var latestInclination = reaction.calculate_desirability()
		if (latestInclination >= topInclination):
			topInclination = latestInclination
			workingChoice = reaction
	return workingChoice

func reset_pValues_to(record:HB_Record):
	for character_id in record.relationship_values.keys():
		var character = storyworld.character_directory[character_id]
		character.bnumber_properties = record.relationship_values[character_id].duplicate(true)

func reset_spools_to(record:HB_Record):
	for spool_id in record.spool_statuses.keys():
		var spool = storyworld.spool_directory[spool_id]
		spool.is_active = record.spool_statuses[spool_id]

func execute_reaction(reaction):
	for change in reaction.after_effects:
		if (change is SWEffect):
			change.enact()

func execute_option(root_page, option, new_page):
	reset_pValues_to(root_page.get_metadata(0))
	reset_spools_to(root_page.get_metadata(0))
	turn = root_page.get_metadata(0).turn + 1
	var reaction = select_reaction(option, root_page)
	execute_reaction(reaction)
	#next_page will be null if "The End" screen is reached.
	#Record option, reaction, and resulting encounter to new branch.
	var record = new_page.get_metadata(0)
	record.player_choice = option
	record.antagonist_choice = reaction
	record.set_pValues(storyworld)
	record.record_spool_statuses(storyworld)
	record.turn = turn
	var next_page = select_next_page(reaction, new_page)
	record.encounter = next_page
	record.record_occurrences() #Useful for tracking whether an event can occur. Intended for use with automatic rehearsal.
	if (null == next_page):
		record.is_an_ending_leaf = true
		record.fully_explored = true
	return record

func clear_all_data():
	clear_history()
	storyworld.clear()

func clear_history():
	reset_pValues_to(initial_pValues)
	for spool in storyworld.spools:
		spool.is_active = spool.starts_active
	var copy_hb_record_list = hb_record_list.duplicate()
	for entry in copy_hb_record_list:
		entry.call_deferred("free")
	hb_record_list = []
	history.clear()
	starting_page = null
	current_page = null
	ending_leaves = []
	playthrough_transcript = ""
	turn = 0
	for encounter in storyworld.encounters:
		encounter.occurrences = 0
		for option in encounter.options:
			option.occurrences = 0
			for reaction in option.reactions:
				reaction.occurrences = 0

func begin_playthrough():
	clear_history()
	starting_page = history.create_item()
	var record = HB_Record.new()
	hb_record_list.append(record)
	record.encounter = select_first_page()
	record.turn = turn
	record.set_pValues(storyworld)
	record.record_spool_statuses(storyworld)
	record.record_occurrences()
	starting_page.set_metadata(0, record)
	current_page = starting_page

func step_playthrough(leaf):
	current_page = leaf
	reset_pValues_to(leaf.get_metadata(0))
	reset_spools_to(leaf.get_metadata(0))
	turn = leaf.get_metadata(0).turn + 1
	if (null == leaf.get_children()):
		var options = find_open_options(leaf)
		if (0 == options.size()):
			if (-1 == ending_leaves.find(leaf)):
				ending_leaves.append(leaf)
			var record = leaf.get_metadata(0)
			record.is_an_ending_leaf = true
			record.fully_explored = true
			leaf.set_metadata(0, record)
		elif (0 < options.size()):
			for option in options:
				#Add new branch to history tree.
				var page = history.create_item(leaf)
				var record = HB_Record.new()
				hb_record_list.append(record)
				record.tree_node = page
				page.set_metadata(0, record)
				execute_option(leaf, option, page)
				page.set_text(0, record.data_to_string())
		reset_pValues_to(leaf.get_metadata(0))
		reset_spools_to(leaf.get_metadata(0))
		turn = leaf.get_metadata(0).turn + 1

#https://github.com/godotengine/godot/issues/19796
#Trees have a strange system for getting the children of a tree item.
func get_item_children(item:TreeItem)->Array:
	item = item.get_children()
	var children = []
	while item:
		children.append(item)
		item = item.get_next()
	return children

func rehearse_depth_first():
	if (null == starting_page or null == current_page):
		begin_playthrough()
	step_playthrough(current_page)
	if (current_page.get_metadata(0).is_an_ending_leaf):
		current_page.get_metadata(0).fully_explored = true
		current_page = current_page.get_parent()
	else:
		var branches = get_item_children(current_page)
		var left_to_explore = []
		for each in branches:
			if (false == each.get_metadata(0).fully_explored):
				left_to_explore.append(each)
		if (0 < left_to_explore.size()):
			left_to_explore.shuffle()
			current_page = left_to_explore.front()
		else:
			current_page.get_metadata(0).fully_explored = true
			current_page = current_page.get_parent()
			if (null == current_page):
				return true
	return false
