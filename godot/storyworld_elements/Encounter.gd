extends Object
class_name Encounter
#Encounters are events that can occur during the course of a playthrough. When an encounter occurs, the "main_text" is first presented, then the player chooses an option, then a character chooses a reaction to the player character's actions. Once a reaction is chosen by the npc, the text of the reaction is displayed and the effects of the reaction are enacted. Then the system either selects another encounter to present, or the playthrough ends.

var storyworld = null
var connected_spools = []
var id = ""
var title = ""
var text_script = null
var acceptability_script = null
var desirability_script = null
var earliest_turn = 0
var latest_turn = 1000
var options = []

#Variables for Editor:
var creation_index = 0
var creation_time = Time.get_unix_time_from_system()
var modified_time = Time.get_unix_time_from_system()
var graph_position = Vector2(40, 40)
var word_count = 0
var graphview_node = null
var connected_characters = [] #Used for sorting encounters by connected characters.
var linked_scripts = []

#Playtesting and Rehearsal:
var occurrences = 0 #The number of times that this encounter has occurred on the current branch. Used by the engine to check whether or not an encounter has occurred.
var reachable = false #Used by the automated rehearsal system to keep track of whether or not an encounter can be reached by the player.
var yielding_paths = 0 #The estimated number of possible paths through the storyworld that reach this encounter.
var potential_ending = false #True if the story ends upon reaching this encounter on at least one possible path through the storyworld.
var parallels_detected = false
var impact = 0 # An estimate of the difference between the outcomes of this option and the outcomes of this option's siblings.

func _init(in_storyworld, in_id:String, in_title:String, in_text:String, in_creation_index:int, in_creation_time = Time.get_unix_time_from_system(), in_modified_time = Time.get_unix_time_from_system(), in_graph_position = Vector2(40, 40)):
	storyworld = in_storyworld
	id = in_id
	title = in_title
	text_script = ScriptManager.new(StringConstant.new(in_text))
	var default = BooleanConstant.new(true)
	acceptability_script = ScriptManager.new(default)
	default = BNumberConstant.new(0)
	desirability_script = ScriptManager.new(default)
	creation_index = in_creation_index
	creation_time = in_creation_time
	modified_time = in_modified_time
	graph_position = in_graph_position

func get_index():
	if (null != storyworld):
		return storyworld.encounters.find(self)
	return -1

func get_text():
	if (text_script is ScriptManager):
		if (text_script.sw_script_data_types.STRING == text_script.output_type):
			return text_script.get_value()
	return ""

func set_text(new_text:String):
	if (text_script is ScriptManager):
		if (text_script.contents is StringConstant):
			text_script.contents.set_value(new_text)

func get_listable_text(maximum_output_length:int = 200):
	var text = title
	if ("" == text):
		return "[Untitled Encounter]"
	elif (maximum_output_length >= text.length()):
		return text
	else:
		return text.left(maximum_output_length - 3) + "..."

func get_excerpt(maximum_output_length:int = 256):
	var text = get_text()
	if (maximum_output_length >= text.length()):
		return text
	else:
		text = text.left(maximum_output_length - 3)
		text = text.substr(0, text.rfind(" "))
		return text + "..."

func find_option_by_id(id):
	for option in options:
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

func clear():
	connected_spools = []
	storyworld = null
	id = ""
	title = ""
	text_script.clear()
	text_script = null
	earliest_turn = 0
	latest_turn = 0
	modified_time = Time.get_unix_time_from_system()
	graph_position = Vector2(40, 40)
	linked_scripts.clear()
	acceptability_script.clear()
#	acceptability_script.call_deferred("free")
	acceptability_script = null
	desirability_script.clear()
#	desirability_script.call_deferred("free")
	desirability_script = null
	occurrences = 0
	reachable = false
	yielding_paths = 0
	for option in options:
		option.clear()
		option.call_deferred("free")

func set_as_copy_of(original, copy_id:bool = true, create_mutual_links:bool = true):
	#Sets the properties of this encounter equal to the properties of the input encounter.
	if (copy_id):
		id = original.id
	title = original.title
	text_script.set_as_copy_of(original.text_script)
	earliest_turn = original.earliest_turn
	latest_turn = original.latest_turn
	modified_time = Time.get_unix_time_from_system()
	acceptability_script.set_as_copy_of(original.acceptability_script)
	desirability_script.set_as_copy_of(original.desirability_script)
	options = []
	for option in original.options:
		var o_id = ""
		if (copy_id):
			o_id = option.id
		elif (null != storyworld):
			o_id = storyworld.unique_id("option", 32)
		else:
			o_id = "o" + UUID.v4()
		var option_copy = Option.new(self, o_id, "")
		option_copy.set_as_copy_of(option, false)
		option_copy.encounter = self
		options.append(option_copy)
	for spool in original.connected_spools:
		if (is_instance_valid(spool)):
			connected_spools.append(spool)
			if (create_mutual_links):
				if (!spool.encounters.has(self)):
					spool.encounters.append(self)

func remap(to_storyworld):
	storyworld = to_storyworld
	text_script.remap(to_storyworld)
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
	var new_connected_spools = []
	for spool in connected_spools:
		if (to_storyworld.spool_directory.has(spool.id)):
			new_connected_spools.append(to_storyworld.spool_directory[spool.id])
	connected_spools = new_connected_spools.duplicate()
	acceptability_script.remap(to_storyworld)
	desirability_script.remap(to_storyworld)

func wordcount():
	var sum = 0
	var regex = RegEx.new()
	regex.compile("\\S+") # Negated whitespace character class.
	sum += regex.search_all(title).size()
	sum += text_script.wordcount()
	for option in options:
		sum += option.text_script.wordcount()
		for reaction in option.reactions:
			sum += reaction.text_script.wordcount()
	word_count = sum
	return sum

func has_search_text(searchterm:String):
	if (searchterm in title):
		return true
	elif (text_script.has_search_text(searchterm)):
		return true
	for option in options:
		if (option.has_search_text(searchterm)):
			return true
	return false

func get_connected_characters():
	var characters = {}
	if (acceptability_script is ScriptManager):
		characters.merge(acceptability_script.find_all_characters_involved())
	if (desirability_script is ScriptManager):
		characters.merge(desirability_script.find_all_characters_involved())
	if (text_script is ScriptManager):
		characters.merge(text_script.find_all_characters_involved())
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

func compile(_parent_storyworld, _include_editor_only_variables:bool = false):
	var result = {}
	result["id"] = id
	result["title"] = title
	result["text_script"] = text_script.compile(_parent_storyworld, _include_editor_only_variables)
	result["acceptability_script"] = null
	if (acceptability_script is ScriptManager):
		result["acceptability_script"] = acceptability_script.compile(_parent_storyworld, _include_editor_only_variables)
	result["desirability_script"] = null
	if (desirability_script is ScriptManager):
		result["desirability_script"] = desirability_script.compile(_parent_storyworld, _include_editor_only_variables)
	result["earliest_turn"] = earliest_turn
	result["latest_turn"] = latest_turn
	result["options"] = []
	for each in options:
		result["options"].append(each.compile(_parent_storyworld, _include_editor_only_variables))
	result["connected_spools"] = []
	for spool in connected_spools:
		result["connected_spools"].append(spool.id)
	if (_include_editor_only_variables):
		#Editor only variables:
		result["creation_index"] = creation_index
		result["creation_time"] = creation_time
		result["modified_time"] = modified_time
		result["graph_position_x"] = graph_position.x
		result["graph_position_y"] = graph_position.y
		result["word_count"] = wordcount()
	return result

func log_update():
	modified_time = Time.get_unix_time_from_system()

func export_to_txt():
	var result = "\n=== " + title + " ===\n"
	result += get_text() + "\n"
	for option in options:
		result += "*\t" + option.get_text() + "\n"
		for reaction in option.reactions:
			result += "**\t" + reaction.get_text() + "\n"
	return result
