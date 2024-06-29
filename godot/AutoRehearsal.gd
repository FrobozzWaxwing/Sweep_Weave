extends Object
class_name AutoRehearsal

var starting_page = null
var current_page = null
var storyworld = null

var cast_traits = []
var cast_traits_max = []
var cast_traits_min = []
var cast_traits_legend = []
var cast_trait_constants = []

var active_spools = []

var checklist = []

func _init(in_storyworld:Storyworld):
	storyworld = QuickStoryworld.new()
	if (null != in_storyworld):
		storyworld.set_as_quickened_copy_of(in_storyworld)
	quicken_bnumberpointers()
	quicken_reactions()
	checklist.resize(storyworld.encounters.size())
	checklist.fill(false)

func reset(in_storyworld:Storyworld):
	clear_all_data()
	if (null != in_storyworld):
		storyworld.set_as_quickened_copy_of(in_storyworld)
	quicken_bnumberpointers()
	quicken_reactions()
	checklist.resize(storyworld.encounters.size())
	checklist.fill(false)

func quicken_bnumberpointers():
	cast_traits_legend.clear()
	cast_trait_constants.clear()
	var altered_variables = []
	var employed_variables = []
	for encounter in storyworld.encounters:
		employed_variables.append_array(encounter.acceptability_script.find_all_bnumberpointers())
		employed_variables.append_array(encounter.desirability_script.find_all_bnumberpointers())
		for option in encounter.get_options():
			employed_variables.append_array(option.visibility_script.find_all_bnumberpointers())
			employed_variables.append_array(option.performability_script.find_all_bnumberpointers())
			for reaction in option.reactions:
				employed_variables.append_array(reaction.desirability_script.find_all_bnumberpointers())
				for effect in reaction.after_effects:
					if (effect is BNumberEffect):
						altered_variables.append(effect.assignee)
					if (effect is SWEffect):
						employed_variables.append_array(effect.assignment_script.find_all_bnumberpointers())
	var unique_altered_variables = []
	var unique_employed_variables = []
	for character in storyworld.characters:
		for bnumber_property in character.authored_properties:
			var onion = character.bnumber_properties[bnumber_property.id]
			if (TYPE_DICTIONARY == typeof(onion) and onion.is_empty()):
				continue
			if (0 == bnumber_property.depth):
				for pointer in altered_variables:
					if (pointer.character == character and pointer.keyring.front() == bnumber_property.id):
						unique_altered_variables.append(pointer)
						break
				for pointer in employed_variables:
					if (pointer.character == character and pointer.keyring.front() == bnumber_property.id):
						unique_employed_variables.append(pointer)
						break
			elif (1 == bnumber_property.depth):
				for subject in storyworld.characters:
					for pointer in altered_variables:
						if (pointer.character == character and pointer.keyring.front() == bnumber_property.id and pointer.keyring[1] == subject.id):
							unique_altered_variables.append(pointer)
							break
					for pointer in employed_variables:
						if (pointer.character == character and pointer.keyring.front() == bnumber_property.id and pointer.keyring[1] == subject.id):
							unique_employed_variables.append(pointer)
							break
			elif (2 == bnumber_property.depth):
				for first_subject in storyworld.characters:
					for second_subject in storyworld.characters:
						for pointer in altered_variables:
							if (pointer.character == character and pointer.keyring.front() == bnumber_property.id and pointer.keyring[1] == first_subject.id and pointer.keyring[2] == second_subject.id):
								unique_altered_variables.append(pointer)
								break
						for pointer in employed_variables:
							if (pointer.character == character and pointer.keyring.front() == bnumber_property.id and pointer.keyring[1] == first_subject.id and pointer.keyring[2] == second_subject.id):
								unique_employed_variables.append(pointer)
								break
	for pointer in unique_employed_variables:
		var record = BNumberPointer.new(pointer.character, pointer.keyring)
		var constant = true
		for each in unique_altered_variables:
			if (pointer.is_parallel_to(each)):
				cast_traits_legend.append(record)
				constant = false
				break
		if (constant):
			cast_trait_constants.append(record)
	initialize_cast_traits()
	for encounter in storyworld.encounters:
		encounter.acceptability_script.quicken_bnumberpointers(self)
		encounter.desirability_script.quicken_bnumberpointers(self)
		for option in encounter.get_options():
			option.visibility_script.quicken_bnumberpointers(self)
			option.performability_script.quicken_bnumberpointers(self)
			for reaction in option.reactions:
				reaction.desirability_script.quicken_bnumberpointers(self)
				for effect in reaction.after_effects:
					if (effect is BNumberEffect):
						for index in range(cast_traits_legend.size()):
							var pointer = cast_traits_legend[index]
							if (effect.assignee.is_parallel_to(pointer)):
								effect.assignee = QuickBNPointer.new(self, index)
								break
					if (effect is SWEffect):
						effect.assignment_script.quicken_bnumberpointers(self)

func quicken_reactions():
	for encounter in storyworld.encounters:
		for option in encounter.get_options():
			for reaction in option.reactions:
				for effect in reaction.after_effects:
					if (effect is BNumberEffect):
						reaction.changes_cast = true
					if (effect is SpoolEffect):
						reaction.changes_spools = true

#func select_page(reaction = null):
#	if (null != reaction and null != reaction.consequence):
#		#Check for a direct link from the most recent reaction, (if any have yet occurred,) to an encounter.
#		return reaction.consequence
#	else:
#		var checked = {}
#		var greatest_desirability = -1
#		var selection = null
#		for spool in storyworld.spools:
#			if (spool.is_active):
#				#Run through active spools and check connected encounters.
#				for encounter in spool.get_encounters():
#					if (!checked.has(encounter.id)):
#						checked[encounter.id] = true
#						if (0 == encounter.occurrences and encounter.acceptability_script.get_value()):
#							#If the encounter has not yet occurred and is acceptable, then calculate its desirability.
#							var encounter_desirability = encounter.calculate_desirability()
#							if (null != encounter_desirability and encounter_desirability > greatest_desirability):
#								greatest_desirability = encounter_desirability
#								selection = encounter
#		return selection

#func select_page(reaction = null):
	#if (null != reaction and null != reaction.consequence):
		##Check for a direct link from the most recent reaction, (if any have yet occurred,) to an encounter.
		#return reaction.consequence
	#else:
		#var checked = {}
		#var greatest_desirability = -1
		#var selection = null
		#for spool in storyworld.spools:
			#if (spool.is_active):
				##Run through active spools and check connected encounters.
				#for encounter in spool.unsorted_encounters:
					#if (!checked.has(encounter.id)):
						#checked[encounter.id] = true
						#if (0 == encounter.occurrences and encounter.acceptability_script.get_value()):
							##If the encounter has not yet occurred and is acceptable, then calculate its desirability.
							#var encounter_desirability = encounter.calculate_desirability()
							#if (null != encounter_desirability and encounter_desirability > greatest_desirability):
								#greatest_desirability = encounter_desirability
								#selection = encounter
				#for encounter in spool.sorted_encounters:
					#if (!checked.has(encounter.id)):
						#checked[encounter.id] = true
						#if (0 == encounter.occurrences and encounter.acceptability_script.get_value()):
							##If the encounter has not yet occurred and is acceptable, then calculate its desirability.
							#var encounter_desirability = encounter.calculate_desirability()
							#if (null != encounter_desirability and encounter_desirability > greatest_desirability):
								#greatest_desirability = encounter_desirability
								#selection = encounter
							#break
		#return selection

#func select_page():
	#checklist.fill(false)
	#var greatest_desirability = -1
	#var selection = null
	#for spool in storyworld.spools:
		#if (spool.is_active):
			##Run through active spools and check connected encounters.
			#for encounter in spool.unsorted_encounters:
				#if (!checklist[encounter.checklist_id]):
					#checklist[encounter.checklist_id] = true
					#if (0 == encounter.occurrences and encounter.acceptability_script.get_value()):
						##If the encounter has not yet occurred and is acceptable, then calculate its desirability.
						#var encounter_desirability = encounter.calculate_desirability()
						#if (null != encounter_desirability and encounter_desirability > greatest_desirability):
							#greatest_desirability = encounter_desirability
							#selection = encounter
			#for encounter in spool.sorted_encounters:
				#if (!checklist[encounter.checklist_id]):
					#checklist[encounter.checklist_id] = true
					#if (0 == encounter.occurrences and encounter.acceptability_script.get_value()):
						##If the encounter has not yet occurred and is acceptable, then calculate its desirability.
						#var encounter_desirability = encounter.calculate_desirability()
						#if (null != encounter_desirability and encounter_desirability > greatest_desirability):
							#greatest_desirability = encounter_desirability
							#selection = encounter
						#break
	#return selection

func select_page(leaf:QuickHB_Record = null):
	checklist.fill(false)
	var greatest_desirability = -1
	var selection = null
	for spool in active_spools:
		#Run through active spools and check connected encounters.
		for encounter in spool.unsorted_encounters:
			if (!checklist[encounter.checklist_id]):
				checklist[encounter.checklist_id] = true
				if (0 == encounter.occurrences and encounter.acceptability_script.get_value()):
					#If the encounter has not yet occurred and is acceptable, then calculate its desirability.
					var encounter_desirability = encounter.calculate_desirability()
					if (null != encounter_desirability and encounter_desirability > greatest_desirability):
						greatest_desirability = encounter_desirability
						selection = encounter
		for encounter in spool.sorted_encounters:
			if (!checklist[encounter.checklist_id]):
				checklist[encounter.checklist_id] = true
				if (0 == encounter.occurrences and encounter.acceptability_script.get_value()):
					#If the encounter has not yet occurred and is acceptable, then calculate its desirability.
					var encounter_desirability = encounter.calculate_desirability()
					if (null != encounter_desirability and encounter_desirability > greatest_desirability):
						greatest_desirability = encounter_desirability
						selection = encounter
					break
	return selection

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

func initialize_cast_traits():
	cast_traits.clear()
	cast_traits_max.clear()
	cast_traits_min.clear()
	for cast_trait in cast_traits_legend:
		var starting_value = cast_trait.get_value()
		cast_traits.append(starting_value)
		cast_traits_max.append(starting_value)
		cast_traits_min.append(starting_value)

func update_active_spools():
	active_spools.clear()
	for spool in storyworld.spools:
		if (spool.is_active):
			active_spools.append(spool)

func reset_pValues_to(record:QuickHB_Record):
	cast_traits = record.relationship_values.duplicate()

func reset_spools_to(record:QuickHB_Record):
	active_spools = record.active_spools.duplicate()
	for spool in storyworld.spools:
		spool.is_active = false
	for spool in active_spools:
		spool.is_active = true

func reset_occurrences_to(record:QuickHB_Record):
	for encounter in storyworld.encounters:
		encounter.occurrences = 0
		for option in encounter.get_options():
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

func clear_history():
	for spool in storyworld.spools:
		spool.is_active = spool.starts_active
	if (null != starting_page):
		starting_page.clear()
		starting_page.call_deferred("free")
	starting_page = null
	current_page = null
	for encounter in storyworld.encounters:
		encounter.occurrences = 0
		encounter.reachable = false
		encounter.yielding_paths = 0
		encounter.potential_ending = false
		for option in encounter.get_options():
			option.occurrences = 0
			option.reachable = false
			option.yielding_paths = 0
			option.notable_outcomes.clear()
			for reaction in option.reactions:
				reaction.occurrences = 0
				reaction.reachable = false
				reaction.yielding_paths = 0

func clear_all_data():
	clear_history()
	storyworld.clear()

func begin_playthrough():
	clear_history()
	initialize_cast_traits()
	update_active_spools()
	starting_page = QuickHB_Record.new()
	starting_page.encounter = select_page()
	if (null != starting_page.encounter):
		starting_page.encounter.occurrences += 1
		starting_page.encounter.reachable = true
	starting_page.turn = 0
	starting_page.record_character_states(self)
	starting_page.record_spool_statuses(self)
	current_page = starting_page

func turn_to_page(leaf:QuickHB_Record):
	#Turns to a specific page of the history book, setting all variables appropriately. Used for playtesting.
	current_page = leaf
	reset_occurrences_to(leaf)
	reset_pValues_to(leaf)
	reset_spools_to(leaf)
	step_playthrough(leaf)

func step_playthrough(leaf:QuickHB_Record):
	if (null != leaf.encounter):
		leaf.encounter.reachable = true
	if (leaf.explored_branches.is_empty() and leaf.unexplored_branches.is_empty()):
		var options = leaf.encounter.get_open_options()
		if (options.is_empty()):
			leaf.set_as_ending_leaf()
		else:
			var next_turn = leaf.turn + 1
			for option in options:
				#Add new branch to history tree.
				var new_page = QuickHB_Record.new(leaf)
				leaf.add_branch(new_page)
				new_page.turn = next_turn
				#Execute option:
				option.occurrences += 1
				option.reachable = true
				#Execute reaction:
				var reaction = select_reaction(option)
				reaction.occurrences += 1
				reaction.reachable = true
				#var characters_changed = false
				#var spools_changed = false
				for change in reaction.after_effects:
					change.enact()
				if (reaction.changes_spools):
					update_active_spools()
				# Select the next encounter:
				# Check for a direct link from the most recent reaction to an encounter.
				if (null == reaction.consequence):
					new_page.encounter = select_page()
				else:
					new_page.encounter = reaction.consequence
				if (null == new_page.encounter):
					#"The End" screen has been reached.
					new_page.set_as_ending_leaf()
				#Record option, reaction, and encounter to the history book.
				new_page.player_choice = option
				new_page.antagonist_choice = reaction
				new_page.record_character_states(self)
				new_page.record_spool_statuses(self)
				#Rewind:
				option.occurrences -= 1
				reaction.occurrences -= 1
				if (reaction.changes_cast):
					reset_pValues_to(leaf)
				if (reaction.changes_spools):
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

func rewind(leaf:QuickHB_Record):
	current_page.decrement_occurrences()
	var parent = leaf.get_parent()
	if (null != parent and null != leaf.antagonist_choice):
		if (leaf.antagonist_choice.changes_cast):
			reset_pValues_to(parent)
		if (leaf.antagonist_choice.changes_spools):
			reset_spools_to(parent)
	return parent

func record_notable_outcome(leaf:QuickHB_Record):
	var encounter = leaf.encounter
	if (null != encounter):
		var page = leaf.get_parent()
		while (null != page and null != page.player_choice):
			if (page.player_choice.notable_outcomes.has(encounter)):
				page.player_choice.notable_outcomes[encounter] += page.path_multiplier
			else:
				page.player_choice.notable_outcomes[encounter] = page.path_multiplier
			for each in page.parallel_to:
				if (each.player_choice.notable_outcomes.has(encounter)):
					each.player_choice.notable_outcomes[encounter] += page.path_multiplier
				else:
					each.player_choice.notable_outcomes[encounter] = page.path_multiplier
			page = page.get_parent()

func rehearse_depth_first():
	if (null == starting_page or null == current_page):
		begin_playthrough()
	step_playthrough(current_page)
	if (current_page.is_an_ending_leaf):
		#An ending has been reached.
		#Add the record's branch count to the yielding path count of each of the record's events.
		current_page.record_yielding_paths()
		record_notable_outcome(current_page)
		#Rewind
		#current_page.decrement_occurrences()
		#current_page = current_page.get_parent()
		current_page = rewind(current_page)
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
				record_notable_outcome(branch)
			else:
				current_page = branch
				current_page.increment_occurrences()
				reset_pValues_to(current_page)
				reset_spools_to(current_page)
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
		#current_page.decrement_occurrences()
		#current_page = current_page.get_parent()
		current_page = rewind(current_page)
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
