extends Object
class_name Rehearsal

#var history = Tree.new()
var starting_page = null
var turn = 0
var current_page = null
var ending_leaves = []
var storyworld = null
var initial_pValues = null

func _init(in_storyworld):
	storyworld = Storyworld.new()
	if (null != in_storyworld):
		storyworld.set_as_copy_of(in_storyworld)
	initial_pValues = HB_Record.new()
	initial_pValues.record_character_states(storyworld)

func has_occurred_on_branch(encounter, leaf):
	#Checks whether an encounter has occurred.
	if (null == encounter):
		return null
	elif (null == leaf):
		#Playthrough has only just begun.
		return false
	var node = leaf
	while (null != node):
		if (null != node.encounter and node.encounter == encounter):
			return true
		#No match for this node.
		#Go farther towards the root of the tree.
		if (node != starting_page):
			node = node.get_parent()
		else:
			break
	return false

func select_page(reaction = null, leaf = null):
	if (null != reaction and null != reaction.consequence):
		#Check for a direct link from the most recent reaction, (if any have yet occurred,) to an encounter.
		return reaction.consequence
	else:
		var checked = {}
		var greatest_desirability = -1
		var selection = null
		for spool in storyworld.spools:
			if (spool.is_active):
				#Run through active spools and check connected encounters.
				for encounter in spool.encounters:
					if (!checked.has(encounter.id)):
						checked[encounter.id] = true
						#At the start of a playthrough, leaf should be null.
						if (!has_occurred_on_branch(encounter, leaf) and encounter.acceptability_script.get_value(leaf)):
							#If the encounter has not yet occurred and is acceptable, then calculate its desirability.
							var encounter_desirability = encounter.desirability_script.get_value(leaf)
							if (encounter_desirability > greatest_desirability):
								greatest_desirability = encounter_desirability
								selection = encounter
		return selection

func find_open_options(leaf):
	if (null == leaf.encounter):
		return []
	var all_options = leaf.encounter.options
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
		var latestInclination = reaction.calculate_desirability(leaf, false)
		if (latestInclination > topInclination):
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

func execute_option(root_page, option):
	reset_pValues_to(root_page)
	reset_spools_to(root_page)
	turn = root_page.turn + 1
	var reaction = select_reaction(option, root_page)
	execute_reaction(reaction)
	#next_page will be null if "The End" screen is reached.
	#Record option, reaction, and resulting encounter to new branch.
	var new_page = HB_Record.new(root_page)
	root_page.add_branch(new_page)
	new_page.player_choice = option
	new_page.antagonist_choice = reaction
	new_page.record_character_states(storyworld)
	new_page.record_spool_statuses(storyworld)
	new_page.turn = turn
	var next_page = select_page(reaction, new_page)
	new_page.encounter = next_page
	new_page.record_occurrences() #Useful for tracking whether an event can occur. Intended for use with automatic rehearsal.
	if (null == next_page):
		new_page.is_an_ending_leaf = true
		new_page.fully_explored = true
	return new_page

func clear_all_data():
	clear_history()
	storyworld.clear()

func clear_history():
	reset_pValues_to(initial_pValues)
	for spool in storyworld.spools:
		spool.is_active = spool.starts_active
	if (null != starting_page):
		starting_page.clear()
		starting_page.call_deferred("free")
	starting_page = null
	current_page = null
	ending_leaves = []
	turn = 0
	for encounter in storyworld.encounters:
		encounter.occurrences = 0
		for option in encounter.options:
			option.occurrences = 0
			for reaction in option.reactions:
				reaction.occurrences = 0

func begin_playthrough():
	clear_history()
	starting_page = HB_Record.new()
	starting_page.encounter = select_page()
	starting_page.turn = turn
	starting_page.record_character_states(storyworld)
	starting_page.record_spool_statuses(storyworld)
	starting_page.record_occurrences()
	current_page = starting_page

func step_playthrough(leaf):
	current_page = leaf
	reset_pValues_to(leaf)
	reset_spools_to(leaf)
	turn = leaf.turn + 1
	if (leaf.get_children().empty() and !leaf.fully_explored):
		var options = find_open_options(leaf)
		if (options.empty()):
			if (!ending_leaves.has(leaf)):
				ending_leaves.append(leaf)
			leaf.is_an_ending_leaf = true
			leaf.fully_explored = true
		elif (0 < options.size()):
			for option in options:
				#Add new branch to history tree.
				execute_option(leaf, option)
		reset_pValues_to(leaf)
		reset_spools_to(leaf)
		turn = leaf.turn + 1

func rehearse_depth_first():
	if (null == starting_page or null == current_page):
		begin_playthrough()
	step_playthrough(current_page)
	if (current_page.is_an_ending_leaf):
		current_page.fully_explored = true
		current_page = current_page.get_parent()
	else:
		var branches = current_page.get_children()
		var left_to_explore = []
		for each in branches:
			if (false == each.fully_explored):
				left_to_explore.append(each)
		if (0 < left_to_explore.size()):
			current_page = left_to_explore.front()
		else:
			current_page.fully_explored = true
			current_page = current_page.get_parent()
			if (null == current_page):
				return true
	return false
