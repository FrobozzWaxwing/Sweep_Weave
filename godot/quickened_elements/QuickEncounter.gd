extends Object
class_name QuickEncounter

var storyworld = null
#var connected_spools = []
var id = ""
var title = ""
var acceptability_script = null
var desirability_script = null
var pretallied_options = [] #These options are always visible and performable.
var mercurial_options = [] #These options may or may not be either visible or performable, depending on world state.

#Variables for Editor:
var connected_characters = [] #Used for sorting encounters by connected characters.
var linked_scripts = []
var connected_spools = [] #Used for sorting encounters by connected spools.

#Playtesting and Rehearsal:
var occurrences = 0 #The number of times that this encounter has occurred on the current branch. Used by the engine to check whether or not an encounter has occurred.
var reachable = false #Used by the automated rehearsal system to keep track of whether or not an encounter can be reached by the player.
var yielding_paths = 0 #The estimated number of possible paths through the storyworld that reach this encounter.
var potential_ending = false #True if the story ends upon reaching this encounter on at least one possible path through the storyworld.
var parallels_detected = false
var impact = 0 # An estimate of the average impact of this encounter's options.
var outcome_range = 0

var has_constant_desirability = false

var checklist_id = -1

func _init(in_storyworld, original_encounter):
	storyworld = in_storyworld
	id = original_encounter.id
	title = original_encounter.title
	#Initialize scripts with default values so that output types are set correctly.
	acceptability_script = ScriptManager.new(BooleanConstant.new(true))
	acceptability_script.set_as_copy_of(original_encounter.acceptability_script)
	desirability_script = ScriptManager.new(BNumberConstant.new(0))
	desirability_script.set_as_copy_of(original_encounter.desirability_script)
	for option in original_encounter.options:
		var option_copy = Option.new(self, option.id, "")
		option_copy.set_as_copy_of(option, false)
		option_copy.encounter = self
		if (option.visibility_script.contents is BooleanConstant and option.performability_script.contents is BooleanConstant):
			if (option.visibility_script.get_value() and option.performability_script.get_value()):
				pretallied_options.append(option_copy)
		else:
			mercurial_options.append(option_copy)

func get_listable_text(maximum_output_length:int = 70):
	var text = title
	if ("" == text):
		return "[Untitled Encounter]"
	elif (maximum_output_length >= text.length()):
		return text
	else:
		return text.left(maximum_output_length - 3) + "..."

func get_options():
	var options = pretallied_options.duplicate()
	options.append_array(mercurial_options)
	return options

func get_open_options():
	var options = pretallied_options.duplicate()
	for option in mercurial_options:
		if (option.visibility_script.get_value() && option.performability_script.get_value()):
			options.append(option)
	return options

func find_option_by_id(id):
	for option in pretallied_options:
		if (option.id == id):
			return option
	for option in mercurial_options:
		if (option.id == id):
			return option

func calculate_desirability():
	var result = null
	if (desirability_script is ScriptManager):
		#If everything is working as intended, desirability_script will always contain either a ScriptManager object or a null value.
		result = desirability_script.get_value()
	return result

func calculate_and_report_desirability():
	var result = null
	if (desirability_script is ScriptManager):
		#If everything is working as intended, desirability_script will always contain either a ScriptManager object or a null value.
		result = desirability_script.get_and_report_value()
	return result

func get_listable_impact():
	var estimate = impact * 1000
	estimate = floor(estimate)
	estimate = float(estimate)
	estimate = estimate / 1000
	estimate = str(estimate)
	return estimate

func get_listable_outcome_range():
	var estimate = outcome_range * 1000
	estimate = floor(estimate)
	estimate = float(estimate)
	estimate = estimate / 1000
	estimate = str(estimate)
	return estimate

func clear():
	storyworld = null
	id = ""
	title = ""
	linked_scripts.clear()
	acceptability_script.clear()
	acceptability_script.call_deferred("free")
	acceptability_script = null
	desirability_script.clear()
	desirability_script.call_deferred("free")
	desirability_script = null
	occurrences = 0
	reachable = false
	yielding_paths = 0
	for option in pretallied_options:
		option.clear()
		option.call_deferred("free")
	for option in mercurial_options:
		option.clear()
		option.call_deferred("free")

func remap(to_storyworld):
	storyworld = to_storyworld
	var options = get_options()
	for option in options:
		for reaction in option.reactions:
			for effect in reaction.after_effects:
				effect.remap(to_storyworld)
				effect.cause = reaction
			if (null != reaction.consequence and null != reaction.consequence.id):
				if (storyworld.encounter_directory.has(reaction.consequence.id)):
					reaction.consequence = storyworld.encounter_directory[reaction.consequence.id]
			reaction.text_script.remap(to_storyworld)
			reaction.desirability_script.remap(to_storyworld)
			reaction.option = option
		option.text_script.remap(to_storyworld)
		option.visibility_script.remap(to_storyworld)
		option.performability_script.remap(to_storyworld)
		option.encounter = self
	acceptability_script.remap(to_storyworld)
	desirability_script.remap(to_storyworld)

func get_connected_characters():
	var characters = {}
	if (acceptability_script is ScriptManager):
		characters.merge(acceptability_script.find_all_characters_involved())
	if (desirability_script is ScriptManager):
		characters.merge(desirability_script.find_all_characters_involved())
	var options = get_options()
	for option in options:
		if (option.visibility_script is ScriptManager):
			characters.merge(option.visibility_script.find_all_characters_involved())
		if (option.performability_script is ScriptManager):
			characters.merge(option.performability_script.find_all_characters_involved())
		if (option.text_script is ScriptManager):
			characters.merge(option.text_script.find_all_characters_involved())
		for reaction in option.reactions:
			if (reaction.desirability_script is ScriptManager):
				characters.merge(reaction.desirability_script.find_all_characters_involved())
			if (reaction.text_script is ScriptManager):
				characters.merge(reaction.text_script.find_all_characters_involved())
			for effect in reaction.after_effects:
				if (effect is BNumberEffect):
					if (effect.assignee is BNumberPointer and effect.assignee.character is Actor):
						characters[effect.assignee.character.id] = effect.assignee.character
					if (effect.assignment_script is ScriptManager):
						characters.merge(effect.assignment_script.find_all_characters_involved())
				elif (effect is SpoolEffect):
					if (effect.assignment_script is ScriptManager):
						characters.merge(effect.assignment_script.find_all_characters_involved())
	return characters

func check_for_parallels():
	parallels_detected = false
	var options = get_options()
	for first_option_index in range(options.size()):
		for second_option_index in range(first_option_index + 1, options.size()):
			var first_option = options[first_option_index]
			var second_option = options[second_option_index]
			for reaction in first_option.reactions:
				for sibling in second_option.reactions:
					if (reaction.is_parallel_to(sibling)):
						parallels_detected = true
						return true
	return false
