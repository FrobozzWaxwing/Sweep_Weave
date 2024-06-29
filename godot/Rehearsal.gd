extends Object
class_name Rehearsal

var starting_page = null
var turn = 0
var current_page = null
var storyworld = null
var initial_pValues = null

func _init(in_storyworld:Storyworld):
	storyworld = Storyworld.new()
	if (null != in_storyworld):
		storyworld.set_as_copy_of(in_storyworld)
	initial_pValues = HB_Record.new()
	initial_pValues.record_character_states(storyworld)

func select_page(reaction = null):
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
						if (0 == encounter.occurrences and encounter.acceptability_script.get_value()):
							#If the encounter has not yet occurred and is acceptable, then calculate its desirability.
							var encounter_desirability = encounter.calculate_desirability()
							if (null != encounter_desirability and encounter_desirability > greatest_desirability):
								greatest_desirability = encounter_desirability
								selection = encounter
		return selection

func find_open_options(leaf:HB_Record):
	if (null == leaf.encounter):
		return []
	var all_options = leaf.encounter.options
	var open_options = []
	for option in all_options:
		if (option.visibility_script.get_value() && option.performability_script.get_value()):
			open_options.append(option)
	return open_options

func select_reaction(option:Option):
	#This determines how a character reacts to a choice made by the player.
	var topInclination = -1
	var workingChoice = null
	for reaction in option.reactions:
		var latestInclination = reaction.calculate_desirability()
		if (null != latestInclination and latestInclination > topInclination):
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

func reset_occurrences_to(record:HB_Record):
	for encounter in storyworld.encounters:
		encounter.occurrences = 0
		for option in encounter.options:
			option.occurrences = 0
			for reaction in option.reactions:
				reaction.occurrences = 0
	var node = record
	while (null != node):
		if (null != node.encounter):
			node.encounter.occurrences += 1
		if (null != node.antagonist_choice):
			node.antagonist_choice.occurrences += 1
		if (null != node.player_choice):
			node.player_choice.occurrences += 1
		#Go farther towards the start of the story.
		node = node.get_parent()

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
	turn = 0
	for encounter in storyworld.encounters:
		encounter.occurrences = 0
		encounter.reachable = false
		encounter.yielding_paths = 0
		encounter.potential_ending = false
		for option in encounter.options:
			option.occurrences = 0
			option.reachable = false
			option.yielding_paths = 0
			for reaction in option.reactions:
				reaction.occurrences = 0
				reaction.reachable = false
				reaction.yielding_paths = 0

func begin_playthrough():
	clear_history()
	starting_page = HB_Record.new()
	starting_page.encounter = select_page()
	if (null != starting_page.encounter):
		starting_page.encounter.occurrences += 1
		starting_page.encounter.reachable = true
	starting_page.turn = turn
	starting_page.record_character_states(storyworld)
	starting_page.record_spool_statuses(storyworld)
	current_page = starting_page

func turn_to_page(leaf:HB_Record):
	#Turns to a specific page of the history book, setting all variables appropriately. Used for playtesting.
	reset_occurrences_to(leaf)
	step_playthrough(leaf)

func step_playthrough(leaf:HB_Record):
	current_page = leaf
	reset_pValues_to(leaf)
	reset_spools_to(leaf)
	turn = leaf.turn
	if (null != leaf.encounter):
		leaf.encounter.reachable = true
	if (leaf.explored_branches.is_empty() and leaf.unexplored_branches.is_empty()):
		var options = find_open_options(leaf)
		if (options.is_empty()):
			leaf.set_as_ending_leaf()
		else:
			for option in options:
				#Add new branch to history tree.
				var new_page = HB_Record.new(leaf)
				leaf.add_branch(new_page)
				new_page.turn = turn + 1
				#Execute option:
				option.occurrences += 1
				option.reachable = true
				#Execute reaction:
				var reaction = select_reaction(option)
				reaction.occurrences += 1
				reaction.reachable = true
				var characters_changed = false
				var spools_changed = false
				for change in reaction.after_effects:
					if (change is SWEffect):
						change.enact()
						if (change is BNumberEffect):
							characters_changed = true
						if (change is SpoolEffect):
							spools_changed = true
				#Select the next encounter:
				new_page.encounter = select_page(reaction)
				if (null == new_page.encounter):
					#"The End" screen has been reached.
					new_page.set_as_ending_leaf()
				#Record option, reaction, and encounter to the history book.
				new_page.player_choice = option
				new_page.antagonist_choice = reaction
				new_page.record_character_states(storyworld)
				new_page.record_spool_statuses(storyworld)
				#Rewind:
				option.occurrences -= 1
				reaction.occurrences -= 1
				if (characters_changed):
					reset_pValues_to(leaf)
				if (spools_changed):
					reset_spools_to(leaf)
			if (leaf.encounter.parallels_detected):
				#Some branches may be parallel.
				for first_branch_index in range(leaf.unexplored_branches.size()):
					var first_branch = leaf.unexplored_branches[first_branch_index]
					if (!first_branch.can_be_skipped):
						for second_branch_index in range(first_branch_index + 1, leaf.unexplored_branches.size()):
							var second_branch = leaf.unexplored_branches[second_branch_index]
							if (first_branch.is_parallel_to(second_branch)):
								first_branch.parallel_to.append(second_branch)
								second_branch.can_be_skipped = true
			var nonskippable = []
			for branch in leaf.unexplored_branches:
				branch.path_multiplier = leaf.path_multiplier * (1 + leaf.parallel_to.size())
				if (branch.can_be_skipped):
					leaf.explored_branches.append(branch)
				else:
					nonskippable.append(branch)
			leaf.unexplored_branches = nonskippable

func rehearse_depth_first():
	if (null == starting_page or null == current_page):
		begin_playthrough()
	step_playthrough(current_page)
	if (current_page.is_an_ending_leaf):
		#An ending has been reached.
		#Add the record's branch count to the yielding path count of each of the record's events.
		current_page.record_yielding_paths()
		#Rewind
		current_page.decrement_occurrences()
		current_page = current_page.get_parent()
		if (null == current_page):
			#All paths have been explored and we have returned to the beginning. Rehearsal complete.
			return true
	else:
		while (!current_page.unexplored_branches.is_empty()):
			var branch = current_page.unexplored_branches.pop_back()
			current_page.explored_branches.append(branch)
			if (branch.is_an_ending_leaf):
				#Add the record's branch count to the yielding path count of each of the record's events.
				branch.record_yielding_paths()
			else:
				current_page = branch
				current_page.increment_occurrences()
				#Rehearsal incomplete.
				return false
		current_page.path_count = 0
		for branch in current_page.explored_branches:
			current_page.path_count += branch.path_count
		#All of the current page's branches have been explored.
		#Add the record's branch count to the yielding path count of each of the record's events.
		current_page.record_yielding_paths()
		current_page.clear_children()
		#Rewind
		current_page.decrement_occurrences()
		current_page = current_page.get_parent()
		if (null == current_page):
			#All paths have been explored and we have returned to the beginning. Rehearsal complete.
			return true
	#Rehearsal incomplete.
	return false

#func randomly_rehearse_depth_first():
#	if (null == starting_page or null == current_page):
#		begin_playthrough()
#	step_playthrough(current_page)
#	if (current_page.is_an_ending_leaf):
#		current_page.fully_explored = true
#		current_page.record_yielding_paths(yielding_path_multiplier) #Add the record's branch count to the yielding path count of each of the record's events.
#		current_page.decrement_occurrences()
#		current_page = current_page.get_parent()
#		if (null == current_page):
#			#Rehearsal complete.
#			return true
#	else:
#		var branches = current_page.get_children()
#		var left_to_explore = []
#		current_page.path_count = 0
#		for branch in branches:
#			if (branch.fully_explored):
#				current_page.path_count += branch.path_count
#			elif (branch.is_an_ending_leaf):
#				branch.fully_explored = true
#				branch.record_yielding_paths(yielding_path_multiplier)
#				current_page.path_count += branch.path_count
#			else:
#				left_to_explore.append(branch)
#		if (0 < left_to_explore.size()):
#			current_page = left_to_explore[randi() % left_to_explore.size()]
#			current_page.increment_occurrences()
#		else:
#			current_page.fully_explored = true
#			current_page.record_yielding_paths(yielding_path_multiplier) #Add the record's branch count to the yielding path count of each of the record's events.
#			current_page.clear_children()
#			current_page.decrement_occurrences()
#			current_page = current_page.get_parent()
#			if (null == current_page):
#				#Rehearsal complete.
#				return true
#	#Rehearsal incomplete.
#	return false
