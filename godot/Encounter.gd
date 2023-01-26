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

#Variables for editor:
var creation_index = 0
var creation_time = OS.get_unix_time()
var modified_time = OS.get_unix_time()
var graph_position = Vector2(40, 40)
var word_count = 0
var graphview_node = null
var occurrences = 0 #Number of times this encounter occurs during a rehearsal.

func _init(in_storyworld, in_id, in_title, in_text, in_creation_index, in_creation_time = OS.get_unix_time(), in_modified_time = OS.get_unix_time(), in_graph_position = Vector2(40, 40)):
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
	return -1

func get_text(leaf = null):
	if (text_script is ScriptManager):
		if (text_script.sw_script_data_types.STRING == text_script.output_type):
			return text_script.get_value(leaf)
	return ""

func set_text(new_text):
	if (text_script is ScriptManager):
		if (text_script.contents is StringConstant):
			text_script.contents.set_value(new_text)

func calculate_desirability(leaf, report):
	var result = null
	if (null != desirability_script and desirability_script is ScriptManager):
		#If everything is working as intended, desirability_script will always contain either a ScriptManager object or a null value.
		result = desirability_script.get_value(leaf, report)
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
	modified_time = OS.get_unix_time()
	graph_position = Vector2(40, 40)
	acceptability_script.clear()
#	acceptability_script.call_deferred("free")
	acceptability_script = null
	desirability_script.clear()
#	desirability_script.call_deferred("free")
	desirability_script = null
	for option in options:
		option.clear()
		option.call_deferred("free")

func set_as_copy_of(original, copy_id = true, create_mutual_links = true):
	#Sets the properties of this encounter equal to the properties of the input encounter.
	if (copy_id):
		id = original.id
	title = original.title
	text_script.set_as_copy_of(original.text_script)
	earliest_turn = original.earliest_turn
	latest_turn = original.latest_turn
	modified_time = OS.get_unix_time()
	acceptability_script.set_as_copy_of(original.acceptability_script)
	desirability_script.set_as_copy_of(original.desirability_script)
	options = []
	for option in original.options:
		var id = ""
		if (copy_id):
			id = option.id
		elif (null != storyworld):
			id = storyworld.unique_id("option", 32)
		else:
			id = "o" + UUID.v4()
		var option_copy = Option.new(self, id, "")
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

func has_search_text(searchterm):
	if (searchterm in title):
		return true
	elif (text_script.has_search_text(searchterm)):
		return true
	for option in options:
		if (option.has_search_text(searchterm)):
			return true
	return false

func connected_characters():
	var characters = {}
	if (null != acceptability_script and acceptability_script is ScriptManager):
		characters.merge(acceptability_script.find_all_characters_involved())
	if (null != desirability_script and desirability_script is ScriptManager):
		characters.merge(desirability_script.find_all_characters_involved())
	if (null != text_script and text_script is ScriptManager):
		characters.merge(text_script.find_all_characters_involved())
	for option in options:
		if (null != option.visibility_script and option.visibility_script is ScriptManager):
			characters.merge(option.visibility_script.find_all_characters_involved())
		if (null != option.performability_script and option.performability_script is ScriptManager):
			characters.merge(option.performability_script.find_all_characters_involved())
		if (null != option.text_script and option.text_script is ScriptManager):
			characters.merge(option.text_script.find_all_characters_involved())
		for reaction in option.reactions:
			if (null != reaction.desirability_script and reaction.desirability_script is ScriptManager):
				characters.merge(reaction.desirability_script.find_all_characters_involved())
			if (null != reaction.text_script and reaction.text_script is ScriptManager):
				characters.merge(reaction.text_script.find_all_characters_involved())
			for effect in reaction.after_effects:
				if (effect is BNumberEffect):
					if (null != effect.assignee and effect.assignee is BNumberPointer and null != effect.assignee.character and effect.assignee.character is Actor):
						characters[effect.assignee.character.id] = effect.assignee.character
					if (null != effect.assignment_script and effect.assignment_script is ScriptManager):
						characters.merge(effect.assignment_script.find_all_characters_involved())
				elif (effect is SpoolEffect):
					if (null != effect.assignment_script and effect.assignment_script is ScriptManager):
						characters.merge(effect.assignment_script.find_all_characters_involved())
	return characters

func compile(parent_storyworld, include_editor_only_variables = false):
	var result = {}
	result["id"] = id
	result["title"] = title
	result["text_script"] = text_script.compile(parent_storyworld, include_editor_only_variables)
	result["acceptability_script"] = null
	if (null != acceptability_script and acceptability_script is ScriptManager):
		result["acceptability_script"] = acceptability_script.compile(parent_storyworld, include_editor_only_variables)
	result["desirability_script"] = null
	if (null != desirability_script and desirability_script is ScriptManager):
		result["desirability_script"] = desirability_script.compile(parent_storyworld, include_editor_only_variables)
	result["earliest_turn"] = earliest_turn
	result["latest_turn"] = latest_turn
	result["options"] = []
	for each in options:
		result["options"].append(each.compile(parent_storyworld, include_editor_only_variables))
	result["connected_spools"] = []
	for spool in connected_spools:
		result["connected_spools"].append(spool.id)
	if (include_editor_only_variables):
		#Editor only variables:
		result["creation_index"] = creation_index
		result["creation_time"] = creation_time
		result["modified_time"] = modified_time
		result["graph_position_x"] = graph_position.x
		result["graph_position_y"] = graph_position.y
		result["word_count"] = wordcount()
	return result

func log_update():
	modified_time = OS.get_unix_time()
