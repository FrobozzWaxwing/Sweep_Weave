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

func has_occured_on_branch(encounter, option, reaction, leaf):
	#Checks whether an encounter has occurred.
	#Optionally checks whether the player chose a given option,
	#and / or whether the antagonist chose a given reaction.
	#null for wildcarding option and reaction.
	if (null == encounter):
		return null
	elif (null == leaf):
		#Playthrough has only just begun.
		return false
	elif (null == option && null == reaction):
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
	else:
		var node = leaf
		while (null != node and null != node.get_parent()):
			if (node.get_parent().get_metadata(0).encounter == encounter):
				if (null == option && reaction == node.get_metadata(0).antagonist_choice):
					return true
				elif (option == node.get_metadata(0).player_choice && null == reaction):
					return true
				elif (option == node.get_metadata(0).player_choice && reaction == node.get_metadata(0).antagonist_choice):
					return true
			#No match for this node.
			#Go farther towards the root of the tree.
			if (node != starting_page && node.get_parent() != starting_page):
				node = node.get_parent()
			else:
				break
	return false

func evaluate_prerequisite(prerequisite, leaf):
	var prereqStatus = false
	match prerequisite.prereq_type:
		0:
			#Ask whether or not an event has occurred.
			prereqStatus = has_occured_on_branch(prerequisite["encounter"], prerequisite["option"], prerequisite["reaction"], leaf)
		_:
			#Default:
			prereqStatus = false
	if (false == prerequisite["negated"] && !(prereqStatus)):
		return false
	elif (true == prerequisite["negated"] && prereqStatus):
		return false
	else:
		return true

func desirability(encounter):
	var distance = 0
	for desideratum in encounter.desiderata:
		var difference = desideratum.character.get_bnumber_property([desideratum.pValue]) - desideratum.point
		distance += (difference * difference)
	#console.log("Distance from encounter to target conditions: " + encounter.title + " = " + distance.toString() + ".");
	return distance

func select_most_desirable_encounter(acceptableEncounters):
	#Choose an encounter from the pool of acceptable encounters.
	#Find one that has a desirability greater than or equal to that of all the others.
	#print("select_most_desirable_encounter")
	var flag = true
	var shortest_distance = 0
	var result = null
	acceptableEncounters.sort_custom(EncounterSorter, "sort_a_z")
	for encounter in acceptableEncounters:
		if (flag):
			#First iteration of loop.
			shortest_distance = desirability(encounter)
			result = encounter
			flag = false
		else:
			var target_distance = desirability(encounter)
			if (target_distance < shortest_distance):
				shortest_distance = target_distance
				result = encounter
	return result

func select_next_page(reaction, leaf = null):
	if (null != reaction and null != reaction.consequence):
		#If the reaction of the last encounter led to a consequence, that consequence occurs next.
		return reaction.consequence
	else:
		#Otherwise:
		var acceptable_encounters_inc = []#These encounters are acceptable for the current turn.
		var acceptable_encounters_exc = []#These encounters are acceptable except for their turn range.
		var earliest_acceptable_turn = 0#If no encounters are acceptable for the present turn, but some are acceptable for later turns, what must we set the turn count to?
		for encounter in storyworld.encounters:
			#Check whether an encounter is acceptable.
			var acceptable = false
			#console.log("Checking acceptability of: " + encounter.title + " | " + encounter.earliest_turn.toString() + " <= " +  turn.toString() + " <= " +  encounter.latest_turn.toString());
			#Acceptability checks:
			#Has encounter already occured once before?
			#Test encounter history against prerequisites and disqualifiers.
			#pValue ranges.
			#Turn range.
			#If encounter has occured before, then it is not acceptable.
			if (has_occured_on_branch(encounter, null, null, leaf)):
			#The encounter has occured before.
			#console.log("The encounter has occured before, and therefore cannot occur again.");
				pass
			else:
				acceptable = true
			#The following code evaluates prerequisites. For example, we may check whether a character's pValues are within a certain range.
			if (acceptable):
				for each in encounter.prerequisites:
					var prereqStatus = evaluate_prerequisite(each, leaf)
					if (false == prereqStatus):
						acceptable = false
						break
			if (acceptable):
				if (turn <= encounter.latest_turn):
					if (encounter.earliest_turn <= turn):
						#console.log("Encounter: " + encounter.title + " deemed acceptable for current turn.");
						acceptable_encounters_inc.append(encounter)
					else:
						if (0 == acceptable_encounters_exc.size()):
							earliest_acceptable_turn = encounter.earliest_turn
						else:
							if (earliest_acceptable_turn > encounter.earliest_turn):
								earliest_acceptable_turn = encounter.earliest_turn
						#console.log("Encounter: " + encounter.title + " deemed acceptable for later turn.");
						acceptable_encounters_exc.append(encounter)
			else:
				#console.log("Encounter: " + encounter.title + " deemed unacceptable.");
				pass
		#//end of for (each in encounters)
		#//If no encounters are deemed acceptable, display a message saying "THE END" instead of an encounter.
		if (0 == acceptable_encounters_inc.size()):
			if (0 == acceptable_encounters_exc.size()):
				#loadTheEnd(true)
				#print ("loadTheEnd(true)")
				return null
			else:
				if (turn < earliest_acceptable_turn):
					#console.log("Increasing turn from " + turn + " to " + earliest_acceptable_turn + ".");
					turn = earliest_acceptable_turn
				acceptable_encounters_inc = []
				for encounter in acceptable_encounters_exc:
					if (encounter.earliest_turn <= turn):
						acceptable_encounters_inc.append(encounter)
				return select_most_desirable_encounter(acceptable_encounters_inc)
		else:
			return select_most_desirable_encounter(acceptable_encounters_inc)

func find_open_options(leaf):
	if (null == leaf.get_metadata(0).encounter):
		#print ("Null Encounter.")
		return []
	var all_options = leaf.get_metadata(0).encounter.options
	var open_options = []
	for option in all_options:
		var flag = true
		for prerequisite in option.visibility_prerequisites:
			if(prerequisite.negated == evaluate_prerequisite(prerequisite, leaf)):
				flag = false
		for prerequisite in option.performability_prerequisites:
			if(prerequisite.negated == evaluate_prerequisite(prerequisite, leaf)):
				flag = false
		if (flag):
			open_options.append(option)
	return open_options

func calculate_inclination(character, reaction):
	if (null == character or null == reaction):
		return -2
	var weight = ((reaction.blend_weight + 1) / 2)
	var blend_x_value = reaction.blend_x.point * character.get_bnumber_property([reaction.blend_x.pValue])
	var blend_y_value = reaction.blend_y.point * character.get_bnumber_property([reaction.blend_y.pValue])
	var inclination = (blend_x_value * (1 - weight)) + (blend_y_value * weight)
	return inclination

func select_reaction(option, leaf):
	#This determines how a character reacts to a choice made by the player.
	var topInclination = -1
	var workingChoice = null
	for reaction in option.reactions:
		var latestInclination = calculate_inclination(option.encounter.antagonist, reaction)
		if (latestInclination >= topInclination):
			topInclination = latestInclination
			workingChoice = reaction
#			console.log('Reaction: "' + each.text.substr(0, 9) + '..." Inclination: ' + latestInclination.toString() + " Blended " + each.blend_x + " (" + blend_x_value + ") and " + each.blend_y + " (" + blend_y_value + ") with weight " + each.blend_weight + ".");
	return workingChoice

func apply_change(change):
	if (change is Desideratum and null != change.character):
		var initial_value = change.character.get_bnumber_property([change.pValue])
		var new_value = (initial_value * (1 - abs(change.point))) + change.point
		change.character.set_bnumber_property([change.pValue], new_value)

func reset_pValues_to(record):
	for entry in record.relationship_values:
		entry.character.set_bnumber_property([entry.pValue], entry.point)

func execute_reaction(reaction):
	for entry in reaction.pValue_changes:
		apply_change(entry)

func execute_option(root_page, option):
	reset_pValues_to(root_page.get_metadata(0))
	turn = root_page.get_metadata(0).turn + 1
	var reaction = select_reaction(option, root_page)
	execute_reaction(reaction)
	var next_page = select_next_page(reaction, root_page)
	#next_page will be null if "The End" screen is reached.
	#Record option, reaction, and resulting encounter to new branch.
	var record = HB_Record.new()
	hb_record_list.append(record)
	record.player_choice = option
	record.antagonist_choice = reaction
	record.encounter = next_page
	record.turn = turn
	record.set_pValues(storyworld)
	record.record_occurrences()
	if (null == next_page):
		record.is_an_ending_leaf = true
		record.fully_explored = true
	return record

func clear_all_data():
	clear_history()
	storyworld.clear()

func clear_history():
	reset_pValues_to(initial_pValues)
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
	record.encounter = select_next_page(null, null)
	record.turn = turn
	record.set_pValues(storyworld)
	record.record_occurrences()
	starting_page.set_metadata(0, record)
	current_page = starting_page

func step_playthrough(leaf):
	current_page = leaf
	reset_pValues_to(leaf.get_metadata(0))
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
				var record = execute_option(leaf, option)
				record.tree_node = page
				page.set_text(0, record.data_to_string())
				page.set_metadata(0, record)
		reset_pValues_to(leaf.get_metadata(0))
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
		print ("Start of Rehearsal.")
		begin_playthrough()
	step_playthrough(current_page)
	if (current_page.get_metadata(0).is_an_ending_leaf):
		#current_page.get_metadata(0).data_to_string()
		current_page.get_metadata(0).fully_explored = true
		current_page = current_page.get_parent()
	else:
		#current_page.get_metadata(0).data_to_string()
		var branches = get_item_children(current_page)
		var left_to_explore = []
		#current_page = current_page.get_parent()
		#print ("Branches:")
		for each in branches:
			#each.get_metadata(0).data_to_string()
			if (false == each.get_metadata(0).fully_explored):
				left_to_explore.append(each)
				#print ("(Needs explored.)")
		if (0 < left_to_explore.size()):
			left_to_explore.shuffle()
			current_page = left_to_explore.front()
		else:
			current_page.get_metadata(0).fully_explored = true
			current_page = current_page.get_parent()
			if (null == current_page):
				print ("End of Rehearsal.")
				return true
	return false
