extends Object
class_name Encounter
#Encounters are events that can occur during the course of a playthrough. When an encounter occurs, the "main_text" is first presented, then the player chooses an option, then the antagonist of the encounter chooses a reaction to the player character's actions. Once a reaction is chosen by the npc, the text of the reaction is displayed and the effects of the reaction are enacted. Then the system either selects another encounter to present, or the playthrough ends.

var storyworld = null
var connected_spools = []
var id = ""
var title = ""
var main_text = ""
var acceptability_script = null
var desirability_script = null
var earliest_turn = 0
var latest_turn = 1000
var antagonist = null
var options = []

#Variables for editor:
var creation_index = 0
var creation_time = OS.get_unix_time()
var modified_time = OS.get_unix_time()
var graph_position = Vector2(40, 40)
var word_count = 0
var graphview_node = null
var occurrences = 0 #Number of times this encounter occurs during a rehearsal.

func _init(in_storyworld, in_id, in_title, in_main_text, in_earliest_turn, in_latest_turn, in_antagonist, in_options,
		   in_creation_index, in_creation_time = OS.get_unix_time(), in_modified_time = OS.get_unix_time(), in_graph_position = Vector2(40, 40)):
	storyworld = in_storyworld
	id = in_id
	title = in_title
	main_text = in_main_text
	var default = BooleanConstant.new(true)
#	var and_operator = BooleanOperator.new("AND", [default])
#	acceptability_script = ScriptManager.new(and_operator)
	acceptability_script = ScriptManager.new(default)
	default = BNumberConstant.new(0)
#	desirability_script = ScriptManager.new(ArithmeticMeanOperator.new([default]))
	desirability_script = ScriptManager.new(default)
	earliest_turn = in_earliest_turn
	latest_turn = in_latest_turn
	antagonist = in_antagonist
	options = in_options
	creation_index = in_creation_index
	creation_time = in_creation_time
	modified_time = in_modified_time
	graph_position = in_graph_position

func get_index():
	if (null != storyworld):
		return storyworld.encounters.find(self)
	return -1

func clear():
	connected_spools = []
	storyworld = null
	id = ""
	title = ""
	main_text = ""
	earliest_turn = 0
	latest_turn = 0
	antagonist = null
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

func set_as_copy_of(original, create_mutual_links = true):
	#Sets the properties of this encounter equal to the properties of the input encounter.
	id = original.id
	title = original.title
	main_text = original.main_text
	earliest_turn = original.earliest_turn
	latest_turn = original.latest_turn
	antagonist = original.antagonist
	modified_time = OS.get_unix_time()
	acceptability_script.set_as_copy_of(original.acceptability_script)
	desirability_script.set_as_copy_of(original.desirability_script)
	options = []
	for option in original.options:
		var option_copy = Option.new(self, option.text)
		option_copy.set_as_copy_of(option)
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
	if (null != antagonist and antagonist is Actor):
		if(storyworld.character_directory.has(antagonist.id)):
			antagonist = storyworld.character_directory[antagonist.id]
		else:
			print ("Error! " + antagonist.char_name + " not in character directory.")
	else:
		print ("Error! Invalid antagonist.")
	for option in options:
		for reaction in option.reactions:
			reaction.desirability_script.remap(to_storyworld)
			for effect in reaction.after_effects:
				effect.remap(to_storyworld)
			if (null != reaction.consequence and null != reaction.consequence.id):
				if (storyworld.encounter_directory.has(reaction.consequence.id)):
					reaction.consequence = storyworld.encounter_directory[reaction.consequence.id]
			reaction.option = option
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
	var sum_words = 0
	var regex = RegEx.new()
	regex.compile("\\S+") # Negated whitespace character class.
	#I initially intended to make this a recursive algorithm,
	#but I'm not sure whether or not compiling multiple copies of the same regex would slow down the function too much.
	for y in options:
		for z in y.reactions:
			sum_words += regex.search_all(z.text).size()
		sum_words += regex.search_all(y.text).size()
	sum_words += regex.search_all(title).size()
	sum_words += regex.search_all(main_text).size()
	word_count = sum_words
	return sum_words

func has_search_text(searchterm):
	if (searchterm in title):
		return true
	elif (searchterm in main_text):
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
	for option in options:
		if (null != option.visibility_script and option.visibility_script is ScriptManager):
			characters.merge(option.visibility_script.find_all_characters_involved())
		if (null != option.performability_script and option.performability_script is ScriptManager):
			characters.merge(option.performability_script.find_all_characters_involved())
		for reaction in option.reactions:
			if (null != reaction.desirability_script and reaction.desirability_script is ScriptManager):
				characters.merge(reaction.desirability_script.find_all_characters_involved())
			for effect in reaction.after_effects:
				if (effect is BNumberEffect):
					if (null != effect.operand_0 and effect.operand_0 is BNumberPointer and null != effect.operand_0.character and effect.operand_0.character is Actor):
						characters[effect.operand_0.character.char_name] = effect.operand_0.character
					if (null != effect.operand_1 and effect.operand_1 is ScriptManager):
						characters.merge(effect.operand_1.find_all_characters_involved())
				elif (effect is SpoolEffect):
					if (null != effect.setter_script and effect.setter_script is ScriptManager):
						characters.merge(effect.setter_script.find_all_characters_involved())
	return characters

func compile(parent_storyworld, include_editor_only_variables = false):
	var result = {}
	result["id"] = id
	result["title"] = title
	result["main_text"] = main_text
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
	if (include_editor_only_variables):
		result["antagonist"] = antagonist.id
		#Editor only variables:
		result["creation_index"] = creation_index
		result["creation_time"] = creation_time
		result["modified_time"] = modified_time
		result["graph_position_x"] = graph_position.x
		result["graph_position_y"] = graph_position.y
		result["word_count"] = wordcount()
	else:
		result["antagonist"] = parent_storyworld.characters.find(antagonist)
	return result

func log_update():
	modified_time = OS.get_unix_time()
