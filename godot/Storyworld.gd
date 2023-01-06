extends Object
class_name Storyworld

var characters = []
var character_directory = {}
var encounters = []
var encounter_directory = {}
var spools = []
var spool_directory = {}
var authored_properties = []
var authored_property_directory = {}
var unique_id_seeds = {"character": 0, "encounter": 0, "spool": 0, "authored_property": 0}
var storyworld_title = ""
var storyworld_author = ""
var storyworld_debug_mode_on = false
var storyworld_display_mode = 1 #0 is old display mode, (maintext, choice, reaction, next-button, clear screen, maintext...), 1 is new display mode, (maintext, choice, clear screen, reaction, maintext...)
var sweepweave_version_number = ""
var creation_time = null
var modified_time = null
var ifid = ""
#Variables for editor:
var project_saved = true

enum sw_script_data_types {BOOLEAN, BNUMBER, VARIANT}

#Basic Functions:

func _init(in_title = "New Storyworld", in_author = "Anonymous", in_sw_version = "?"):
	storyworld_title = in_title
	storyworld_author = in_author
	sweepweave_version_number = in_sw_version
	creation_time = OS.get_unix_time()
	modified_time = OS.get_unix_time()
	ifid = IFIDGenerator.IFID_from_creation_time(creation_time)

func unique_id(element_type = "encounter", length = 32):
	var result = "%x" % unique_id_seeds[element_type]
	result += "_" + str(OS.get_unix_time())
	result = result.sha1_text()
	result = result.left(length)
	unique_id_seeds[element_type] += 1
	return result

func log_update():
	modified_time = OS.get_unix_time()

func clear():
	unique_id_seeds = {"character": 0, "encounter": 0, "spool": 0, "authored_property": 0}
	storyworld_title = "New Storyworld"
	storyworld_author = "Anonymous"
	sweepweave_version_number = "?"
	storyworld_debug_mode_on = false
	storyworld_display_mode = 1
	creation_time = OS.get_unix_time()
	modified_time = OS.get_unix_time()
	ifid = IFIDGenerator.IFID_from_creation_time(creation_time)
	var copy_authored_properties = authored_properties.duplicate()
	authored_properties = []
	authored_property_directory = {}
	var copy_characters = characters.duplicate()
	characters = []
	character_directory = {}
	var copy_encounters = encounters.duplicate()
	encounters = []
	encounter_directory = {}
	var copy_spools = spools.duplicate()
	spools = []
	spool_directory = {}
	for each in copy_authored_properties:
		delete_authored_property(each)
	for each in copy_characters:
		delete_character(each)
	for each in copy_encounters:
		delete_encounter(each)
	for each in copy_spools:
		delete_spool(each)

#Personality / relationship model:

func add_authored_property(property):
	authored_properties.append(property)
	authored_property_directory[property.id] = property
	if (property.attribution_target == property.possible_attribution_targets.CAST_MEMBERS):
		for character in property.affected_characters:
			character.add_property_to_bnumber_properties(property, characters)
	if (property.attribution_target == property.possible_attribution_targets.ENTIRE_CAST):
		for character in characters:
			character.add_property_to_bnumber_properties(property, characters)

func delete_authored_property(property):
	if (null == property):
		return
#	print("Removing authored property: " + property.property_name.left(25) + " from all characters and scripts.")
	authored_properties.erase(property)
	authored_property_directory.erase(property.id)
	for character in characters:
		character.delete_property_from_bnumber_properties(property)
	property.call_deferred("free")

func init_classical_personality_model():
	var ap_names = ["Bad_Good", "False_Honest", "Timid_Dominant", "pBad_Good", "pFalse_Honest", "pTimid_Dominant"]
	for ap_name in ap_names:
		var new_index = unique_id_seeds["authored_property"]
		unique_id_seeds["authored_property"] += 1
		var new_id = ap_name
		add_authored_property(BNumberBlueprint.new(self, new_index, new_id, ap_name, 0, 0))

func add_all_authored_properties_from(original):
	for property in original.authored_properties:
		var new_index = unique_id_seeds["authored_property"]
		unique_id_seeds["authored_property"] += 1
		var copy = BNumberBlueprint.new(self, new_index, "", "", 0, 0)
		copy.set_as_copy_of(property, false) #create_mutual_links == false
		add_authored_property(copy)

#Characters:

func add_character(character):
	characters.append(character)
	character_directory[character.id] = character

func delete_character(character):
	characters.erase(character)
	character_directory.erase(character)
	for property in authored_properties:
		property.affected_characters.erase(character)
	character.call_deferred("free")

func add_all_characters_from(original):
	for character in original.characters:
		var newbie = Actor.new(self, character.char_name, character.pronoun, character.bnumber_properties)
		newbie.set_as_copy_of(character, false) #create_mutual_links == false
		newbie.creation_index = character.creation_index
		newbie.creation_time = character.creation_time
		newbie.modified_time = OS.get_unix_time()
		newbie.remap(self)
		add_character(newbie)

func import_characters(original_characters):
	for character in original_characters:
		var newbie = Actor.new(self, character.char_name, character.pronoun, character.bnumber_properties)
		newbie.set_as_copy_of(character, false) #create_mutual_links == false
		newbie.creation_index = character.creation_index
		newbie.creation_time = character.creation_time
		newbie.modified_time = OS.get_unix_time()
		newbie.remap(self)
		add_character(newbie)

#Encounters:

func add_encounter(encounter):
	encounters.append(encounter)
	encounter_directory[encounter.id] = encounter

func delete_encounter(encounter):
	#print("Deleting encounter: " + encounter.title)
	encounters.erase(encounter)
	encounter_directory.erase(encounter)
	for each1 in encounters:
		if (each1.acceptability_script.search_and_replace(encounter, null)):
			each1.log_update()
		for each2 in each1.options:
			for each3 in each2.reactions:
				if (each3.consequence == encounter):
					each3.consequence = null
					each1.log_update()
			if (each2.visibility_script.search_and_replace(encounter, null)):
				each1.log_update()
			if (each2.performability_script.search_and_replace(encounter, null)):
				each1.log_update()
	for spool in encounter.connected_spools:
		spool.encounters.erase(encounter)
	encounter.clear()
	encounter.call_deferred("free")

func add_all_encounters_from(original):
	for encounter in original.encounters:
		var copy = Encounter.new(self, "", "", "", 0, 0, null, [], 0)
		copy.set_as_copy_of(encounter, false) #create_mutual_links == false
		add_encounter(copy)

func import_encounters(original_encounters):
	for encounter in original_encounters:
		var copy = Encounter.new(self, "", "", "", 0, 0, null, [], 0)
		copy.set_as_copy_of(encounter, false) #create_mutual_links == false
		add_encounter(copy)
	for encounter in encounters:
		encounter.remap(self)

func duplicate_encounter(encounter):
	var new_id_seed = unique_id_seeds["encounter"]
	var new_id = unique_id()
	var new_encounter = Encounter.new(self, "", "", "", 0, 0, null, [], 0)
	new_encounter.set_as_copy_of(encounter)
	new_encounter.id = "enc_" + new_id
	new_encounter.title += " copy"
	new_encounter.creation_index = new_id_seed
	new_encounter.creation_time = OS.get_unix_time()
	new_encounter.modified_time = OS.get_unix_time()
	add_encounter(new_encounter)
	return new_encounter

#Spools:

func add_spool(spool):
	spools.append(spool)
	spool_directory[spool.id] = spool

func delete_spool(spool):
	for encounter in spool.encounters:
		encounter.connected_spools.erase(spool)
	spools.erase(spool)
	spool_directory.erase(spool)
	spool.call_deferred("free")

func add_all_spools_from(original):
	for spool in original.spools:
		var copy = Spool.new()
		copy.set_as_copy_of(spool, false) #create_mutual_links == false
		add_spool(copy)

#Advanced Functions:

func set_as_copy_of(original):
	unique_id_seeds = original.unique_id_seeds.duplicate(true)
	storyworld_title = original.storyworld_title
	storyworld_author = original.storyworld_author
	storyworld_debug_mode_on = original.storyworld_debug_mode_on
	storyworld_display_mode = original.storyworld_display_mode
	sweepweave_version_number = original.sweepweave_version_number
	clear()
	add_all_authored_properties_from(original)
	add_all_characters_from(original)
	for property_blueprint in authored_properties:
		property_blueprint.remap(self)
	add_all_encounters_from(original)
	add_all_spools_from(original)
	for encounter in encounters:
		encounter.remap(self)
	for spool in spools:
		spool.remap(self)

func sort_encounters(sort_method):
	match sort_method:
		"Alphabetical":
			encounters.sort_custom(EncounterSorter, "sort_a_z")
		"Rev. Alphabetical":
			encounters.sort_custom(EncounterSorter, "sort_z_a")
		"Creation Time":
			encounters.sort_custom(EncounterSorter, "sort_created")
		"Rev. Creation Time":
			encounters.sort_custom(EncounterSorter, "sort_r_created")
		"Last Modified":
			encounters.sort_custom(EncounterSorter, "sort_modified")
		"Rev. Last Modified":
			encounters.sort_custom(EncounterSorter, "sort_r_modified")
		"Earliest Turn":
			encounters.sort_custom(EncounterSorter, "sort_e_turn")
		"Rev. Earliest Turn":
			encounters.sort_custom(EncounterSorter, "sort_r_e_turn")
		"Latest Turn":
			encounters.sort_custom(EncounterSorter, "sort_l_turn")
		"Rev. Latest Turn":
			encounters.sort_custom(EncounterSorter, "sort_r_l_turn")
		"Antagonist":
			encounters.sort_custom(EncounterSorter, "sort_antagonist")
		"Rev. Antagonist":
			encounters.sort_custom(EncounterSorter, "sort_r_antagonist")
		"Fewest Options":
			encounters.sort_custom(EncounterSorter, "sort_options")
		"Most Options":
			encounters.sort_custom(EncounterSorter, "sort_r_options")
		"Fewest Reactions":
			encounters.sort_custom(EncounterSorter, "sort_reactions")
		"Most Reactions":
			encounters.sort_custom(EncounterSorter, "sort_r_reactions")
		"Word Count":
			encounters.sort_custom(EncounterSorter, "sort_word_count")
		"Rev. Word Count":
			encounters.sort_custom(EncounterSorter, "sort_r_word_count")

func create_default_bnumber_pointer():
	if (0 == authored_properties.size() or 0 == characters.size()):
		#Something has gone terribly wrong.
		return null
	var property = authored_properties[0]
	var keyring = []
	keyring.append(property.id)
	if (property.possible_attribution_targets.ENTIRE_CAST == property.attribution_target):
		for layer in range(property.depth):
			keyring.append(characters[0].id)
		var result = BNumberPointer.new(characters[0], keyring.duplicate(true))
		return result
	elif (property.possible_attribution_targets.CAST_MEMBERS == property.attribution_target):
		if (property.affected_characters.empty()):
			print ("Error when creating default bnumber pointer: chosen property has no affected characters.")
		var character = property.affected_characters[0]
		for layer in range(property.depth):
			keyring.append(character.id)
		var result = BNumberPointer.new(character, keyring.duplicate(true))
		return result

func create_default_character():
	var new_index = unique_id_seeds["character"]
	var new_name = "So&So " + str(new_index)
	var new_character = Actor.new(self, new_name, "they")
	new_character.creation_index = new_index
	new_character.id = unique_id("character", 16)
	return new_character

# Json parsing system:

#Functions for loading project files made in SweepWeave versions 0.0.07 through 0.0.15:

func parse_reactions_data_v0_0_07_through_v0_0_15(data, incomplete_reactions, option):
	var result = []
	for each in data:
		var graph_offset = Vector2(0, 0)
		if (each.has_all(["graph_offset_x", "graph_offset_y"])):
			graph_offset = Vector2(each["graph_offset_x"], each["graph_offset_y"])
		var blend_x = BNumberPointer.new(option.get_antagonist())
		var blend_y = BNumberPointer.new(option.get_antagonist())
		# Check whether or not each blend operand is negated.
		if ("-" == each["blend_x"].left(1)):
			blend_x.keyring.append(each["blend_x"].substr(1))
			blend_x.coefficient = -1
		else:
			blend_x.keyring.append(each["blend_x"])
		if ("-" == each["blend_y"].left(1)):
			blend_y.keyring.append(each["blend_y"].substr(1))
			blend_y.coefficient = -1
		else:
			blend_y.keyring.append(each["blend_y"])
		var blend_weight = BNumberConstant.new(each["blend_weight"])
		var z = BlendOperator.new(blend_x, blend_y, blend_weight)
		var script = ScriptManager.new(z)
		var reaction = Reaction.new(option, each["text"], script, graph_offset)
		if ("wild" == each["consequence_id"]):
			reaction.consequence = null
		elif (encounter_directory.has(each["consequence_id"])):
			reaction.consequence = encounter_directory[each["consequence_id"]]
		else:
			incomplete_reactions.append([reaction, each["consequence_id"]])
		if (each.has("pValue_changes")):
			for x in each["pValue_changes"]:
				var character:Actor = characters[x["character"]]
				var pointer1 = BNumberPointer.new(character, [x["pValue"]])
				var point = BNumberConstant.new(x["point"])
				var new_nudge_operator = NudgeOperator.new(pointer1, point)
				var new_script = ScriptManager.new(new_nudge_operator)
				var pointer2 = BNumberPointer.new(character, [x["pValue"]])
				var new_effect = BNumberEffect.new(pointer2, new_script)
				reaction.after_effects.append(new_effect)
		elif (each.has_all(["deltaLove", "deltaTrust", "deltaFear"])):
			#This section is included for backwards compatibility.
			if (0 != each["deltaLove"]):
				var pointer1 = BNumberPointer.new(reaction.get_antagonist(), ["pBad_Good"])
				var point = BNumberConstant.new(each["deltaLove"])
				var new_nudge_operator = NudgeOperator.new(pointer1, point)
				var new_script = ScriptManager.new(new_nudge_operator)
				var pointer2 = BNumberPointer.new(reaction.get_antagonist(), ["pBad_Good"])
				var new_effect = BNumberEffect.new(pointer2, new_script)
				reaction.after_effects.append(new_effect)
			if (0 != each["deltaTrust"]):
				var pointer1 = BNumberPointer.new(reaction.get_antagonist(), ["pFalse_Honest"])
				var point = BNumberConstant.new(each["deltaTrust"])
				var new_nudge_operator = NudgeOperator.new(pointer1, point)
				var new_script = ScriptManager.new(new_nudge_operator)
				var pointer2 = BNumberPointer.new(reaction.get_antagonist(), ["pFalse_Honest"])
				var new_effect = BNumberEffect.new(pointer2, new_script)
				reaction.after_effects.append(new_effect)
			if (0 != each["deltaFear"]):
				var pointer1 = BNumberPointer.new(reaction.get_antagonist(), ["pTimid_Dominant"])
				var point = BNumberConstant.new(each["deltaFear"])
				var new_nudge_operator = NudgeOperator.new(pointer1, point)
				var new_script = ScriptManager.new(new_nudge_operator)
				var pointer2 = BNumberPointer.new(reaction.get_antagonist(), ["pTimid_Dominant"])
				var new_effect = BNumberEffect.new(pointer2, new_script)
				reaction.after_effects.append(new_effect)
		result.append(reaction)
	return result

func parse_prerequisite_data_v0_0_07_through_v0_0_15(data):
	var new_prerequisite = EventPointer.new()
	new_prerequisite.negated = data["negated"]
	new_prerequisite.encounter = encounter_directory[data["encounter"]]
	new_prerequisite.option = new_prerequisite.encounter.options[data["option"]]
	new_prerequisite.reaction = new_prerequisite.option.reactions[data["reaction"]]
	return new_prerequisite

func load_from_json_v0_0_07_through_v0_0_15(data_to_load):
	var incomplete_reactions = []
	var incomplete_encounters = []
#	var data_to_load = JSON.parse(file_text).result
	init_classical_personality_model()
	for entry in data_to_load.characters:
		var newbie = Actor.new(self, entry["name"], entry["pronoun"])
		if (entry.has_all(["Bad_Good", "False_Honest", "Timid_Dominant", "pBad_Good", "pFalse_Honest", "pTimid_Dominant"])):
			newbie.set_classical_personality_model(entry["Bad_Good"], entry["False_Honest"], entry["Timid_Dominant"], entry["pBad_Good"], entry["pFalse_Honest"], entry["pTimid_Dominant"])
		elif (entry.has("bnumber_properties")):
			#In version 0.0.15 of SweepWeave, each character's "bnumber_properties" property should only contain 0-depth properties, specifically the 6 listed just above, so we shouldn't need to worry about character ids. Also, character ids were not yet being saved to json.
			newbie.bnumber_properties = entry["bnumber_properties"].duplicate(true)
		if (entry.has_all(["creation_time", "modified_time"])):
			newbie.creation_time = entry["creation_time"]
			newbie.modified_time = entry["modified_time"]
		else:
			newbie.creation_time = OS.get_unix_time()
			newbie.modified_time = OS.get_unix_time()
		if (entry.has_all(["creation_index"])):
			newbie.creation_index = entry["creation_index"]
		else:
			newbie.creation_index = unique_id_seeds["character"]
		newbie.id = unique_id("character", 16)
		add_character(newbie)
	#Begin loading encounters.
	#This must proceed in stages, so that encounters which have other encounters associated with them as prerequisites or consequences can be loaded in correctly.
	for entry in data_to_load.encounters:
		#Create encounter:
		var new_encounter = Encounter.new(self, entry["id"], entry["title"], entry["main_text"], entry["earliest_turn"], entry["latest_turn"], characters[entry["antagonist"]], [],
		   entry["creation_index"], entry["creation_time"], entry["modified_time"], Vector2(entry["graph_position_x"], entry["graph_position_y"]))
		#Parse prerequisites:
		if (0 < entry["prerequisites"].size()):
			new_encounter.acceptability_script.contents.clear()
		var incomplete = false
		for each in entry["prerequisites"]:
			if (encounter_directory.has(each["encounter"])):
				new_encounter.acceptability_script.contents.operands.append(parse_prerequisite_data_v0_0_07_through_v0_0_15(each))
			else:
				new_encounter.acceptability_script.contents.operands.append(each)
				incomplete = true
		if (true == incomplete):
			incomplete_encounters.append(new_encounter)
		#Parse desiderata:
		if (0 < entry["desiderata"].size()):
			new_encounter.desirability_script.contents.clear()
		for each in entry["desiderata"]:
			var d_char:Actor = characters[each["character"]]
			var d_pValue:String = each["pValue"]
			var d_point = BNumberConstant.new(each["point"])
			var pointer = BNumberPointer.new(d_char, [d_pValue])
			var new_desideratum = Desideratum.new(pointer, d_point)
			new_encounter.desirability_script.contents.operands.append(new_desideratum)
			new_desideratum.parent_operator = new_encounter.desirability_script.contents
		#Parse options:
		for each in entry["options"]:
			var graph_offset = Vector2(0, 0)
#			if (each.has("graph_offset_x") && each.has("graph_offset_y")):
#				graph_offset = Vector2(each["graph_offset_x"], each["graph_offset_y"])
			var new_option = Option.new(new_encounter, each["text"], graph_offset)
			new_option.reactions = parse_reactions_data_v0_0_07_through_v0_0_15(each["reactions"], incomplete_reactions, new_option)
			if (typeof(each) == TYPE_DICTIONARY && each.has("visibility_prerequisites") && each.has("performability_prerequisites")):
				for prerequisite in each["visibility_prerequisites"]:
					new_option.visibility_script.contents.operands.append(prerequisite)
				for prerequisite in each["performability_prerequisites"]:
					new_option.performability_script.contents.operands.append(prerequisite)
			new_encounter.options.append(new_option)
#		new_encounter.options = parse_options_data(new_encounter, entry["options"], incomplete_reactions)
		#Add encounter to database:
		add_encounter(new_encounter)
	for entry in incomplete_reactions:
		if (2 == entry.size()):
			if (encounter_directory.has(entry[1])):
				entry[0].consequence = encounter_directory[entry[1]]
	for entry in incomplete_encounters:
		var to_remove = []
		for prereq in entry.acceptability_script.contents.operands:
			if (typeof(prereq) == TYPE_DICTIONARY):
				if (encounter_directory.has(prereq["encounter"])):
					entry.acceptability_script.contents.operands.append(parse_prerequisite_data_v0_0_07_through_v0_0_15(prereq))
				to_remove.append(prereq)
		for each in to_remove:
			entry.acceptability_script.contents.operands.erase(each)
	for each in encounters:
		for option in each.options:
			var to_remove = []
			for prereq in option.visibility_script.contents.operands:
				if (typeof(prereq) == TYPE_DICTIONARY):
					if (encounter_directory.has(prereq["encounter"])):
						option.visibility_script.contents.operands.append(parse_prerequisite_data_v0_0_07_through_v0_0_15(prereq))
					to_remove.append(prereq)
			for prereq in option.performability_script.contents.operands:
				if (typeof(prereq) == TYPE_DICTIONARY):
					if (encounter_directory.has(prereq["encounter"])):
						option.performability_script.contents.operands.append(parse_prerequisite_data_v0_0_07_through_v0_0_15(prereq))
					to_remove.append(prereq)
			for each_to_remove in to_remove:
				option.visibility_script.contents.operands.erase(each_to_remove)
				option.performability_script.contents.operands.erase(each_to_remove)
	if (data_to_load.has("unique_id_seed")):
		unique_id_seeds["encounter"] = data_to_load.unique_id_seed
	if (data_to_load.has("char_unique_id_seed")):
		unique_id_seeds["character"] = data_to_load.char_unique_id_seed
	if (data_to_load.has("storyworld_title")):
		storyworld_title = data_to_load.storyworld_title
	if (data_to_load.has("storyworld_author")):
		storyworld_author = data_to_load.storyworld_author
	if (data_to_load.has("debug_mode")):
		storyworld_debug_mode_on = data_to_load.debug_mode
	if (data_to_load.has("display_mode")):
		storyworld_display_mode = data_to_load.display_mode
	if (data_to_load.has("sweepweave_version")):
		sweepweave_version_number = data_to_load.sweepweave_version
	if (data_to_load.has("creation_time")):
		creation_time = data_to_load.creation_time
	if (data_to_load.has("modified_time")):
		modified_time = data_to_load.modified_time
	ifid = IFIDGenerator.IFID_from_creation_time(creation_time)
	print("Project Loaded: " + storyworld_title + " by " + storyworld_author + ". (Storyworld SWV# " + sweepweave_version_number + ")")

#Functions for loading project files made in SweepWeave version 0.0.21:

func parse_reactions_data_v0_0_21(reactions_data, option):
	var result = []
	for reaction_data in reactions_data:
		var graph_offset = Vector2(0, 0)
		#Currently options and reactions are not visible in the graphview. This may be changed later on.
		var reaction = Reaction.new(option, reaction_data["text"], reaction_data["desirability_script"], graph_offset)
		reaction.consequence = reaction_data["consequence_id"]
		if (reaction_data.has("after_effects")):
			for effect_data in reaction_data["after_effects"]:
				if (effect_data.has_all(["Set", "to"]) and effect_data["Set"].has_all(["pointer_type", "character", "coefficient", "keyring"]) and "Bounded Number Pointer" == effect_data["Set"]["pointer_type"] and TYPE_STRING == typeof(effect_data["Set"]["character"]) and effect_data["to"].has("script_element_type")):
					reaction.after_effects.append(effect_data)
		result.append(reaction)
	return result

func load_from_json_v0_0_21(data_to_load):
	#Load characters.
	for entry in data_to_load.characters:
		if (entry.has_all(["name", "pronoun", "bnumber_properties", "id", "creation_index", "creation_time", "modified_time"])):
			var newbie = Actor.new(self, entry["name"], entry["pronoun"], entry["bnumber_properties"])
			newbie.id = entry["id"]
			newbie.creation_index = entry["creation_index"]
			newbie.creation_time = entry["creation_time"]
			newbie.modified_time = entry["modified_time"]
			add_character(newbie)
	#Begin loading encounters.
	#This must proceed in stages, so that encounters which have other encounters associated with them as prerequisites or consequences can be loaded in correctly.
	for entry in data_to_load.encounters:
		#Create encounter:
		var antagonist = null
		if (character_directory.has(entry["antagonist"])):
			antagonist = character_directory[entry["antagonist"]]
		elif (0 < characters.size()):
			antagonist = characters[0]
		var new_encounter = Encounter.new(self, entry["id"], entry["title"], entry["main_text"], entry["earliest_turn"], entry["latest_turn"], antagonist, [], entry["creation_index"], entry["creation_time"], entry["modified_time"], Vector2(entry["graph_position_x"], entry["graph_position_y"]))
		#Temporarily set each script to the dictionary version of it. Each dictionary can be parsed and used to create a ScriptManager object later on, after all encounters, options, reactions and spools have been created and references to these objects can be created.
		new_encounter.acceptability_script = entry["acceptability_script"]
		new_encounter.desirability_script = entry["desirability_script"]
		#Parse options:
		for option_data in entry["options"]:
			if (option_data.has_all(["text", "reactions", "visibility_script", "performability_script"])):
				var graph_offset = Vector2(0, 0)
				#Currently options and reactions are not visible in the graphview. This may be changed later on.
				#if (option_data.has("graph_offset_x") && option_data.has("graph_offset_y")):
				#	graph_offset = Vector2(option_data["graph_offset_x"], option_data["graph_offset_y"])
				var new_option = Option.new(new_encounter, option_data["text"], graph_offset)
				new_option.reactions = parse_reactions_data_v0_0_21(option_data["reactions"], new_option)
				new_option.visibility_script = option_data["visibility_script"]
				new_option.performability_script = option_data["performability_script"]
				new_encounter.options.append(new_option)
		#Add encounter to database:
		add_encounter(new_encounter)
	#Parse scripts:
	for encounter in encounters:
		var new_script = ScriptManager.new(true)
		new_script.load_from_json_v0_0_21(self, encounter.acceptability_script, sw_script_data_types.BOOLEAN)
		encounter.acceptability_script = new_script
		new_script = ScriptManager.new(0)
		new_script.load_from_json_v0_0_21(self, encounter.desirability_script, sw_script_data_types.BNUMBER)
		encounter.desirability_script = new_script
		for option in encounter.options:
			new_script = ScriptManager.new(true)
			new_script.load_from_json_v0_0_21(self, option.visibility_script, sw_script_data_types.BOOLEAN)
			option.visibility_script = new_script
			new_script = ScriptManager.new(true)
			new_script.load_from_json_v0_0_21(self, option.performability_script, sw_script_data_types.BOOLEAN)
			option.performability_script = new_script
			for reaction in option.reactions:
				new_script = ScriptManager.new(0)
				new_script.load_from_json_v0_0_21(self, reaction.desirability_script, sw_script_data_types.BNUMBER)
				reaction.desirability_script = new_script
				var parsed_effects = []
				for effect_data in reaction.after_effects:
					var new_effect = BNumberEffect.new()
					var effect_is_valid = new_effect.load_from_json_v0_0_21(self, effect_data)
					if (effect_is_valid):
						parsed_effects.append(new_effect)
				reaction.after_effects.clear()
				for effect in parsed_effects:
					reaction.after_effects.append(effect)
				if ("wild" == reaction.consequence):
					reaction.consequence = null
				elif (encounter_directory.has(reaction.consequence)):
					reaction.consequence = encounter_directory[reaction.consequence]
				else:
					reaction.consequence = null
	#Load authored properties:
	for entry in data_to_load["authored_properties"]:
		if (entry.has_all(["property_type", "id", "property_name", "depth", "default_value", "attribution_target", "affected_characters", "creation_index", "creation_time", "modified_time"])):
			if ("bounded number" == entry["property_type"]):
				var new_property = BNumberBlueprint.new(self, entry["creation_index"], entry["id"], entry["property_name"], entry["depth"], entry["default_value"])
				match entry["attribution_target"]:
					"storyworld":
						new_property.attribution_target = new_property.possible_attribution_targets.STORYWORLD
					"some cast members":
						new_property.attribution_target = new_property.possible_attribution_targets.CAST_MEMBERS
						for character_id in entry["affected_characters"]:
							if (character_directory.has(character_id)):
								var character = character_directory[character_id]
								character.authored_properties.append(new_property)
								character.authored_property_directory[new_property.id] = new_property
								new_property.affected_characters.append(character)
					"all cast members":
						new_property.attribution_target = new_property.possible_attribution_targets.ENTIRE_CAST
						for character in characters:
							character.authored_properties.append(new_property)
							character.authored_property_directory[new_property.id] = new_property
				new_property.creation_time = entry["creation_time"]
				new_property.modified_time = entry["modified_time"]
				authored_properties.append(new_property)
				authored_property_directory[new_property.id] = new_property
	#Load spools:
	for entry in data_to_load["spools"]:
		if (entry.has_all(["id", "spool_name", "encounters", "creation_index", "creation_time", "modified_time"])):
			var spool_to_add = Spool.new()
			spool_to_add.id = entry["id"]
			spool_to_add.spool_name = entry["spool_name"]
			for encounter_id in entry["encounters"]:
				if (encounter_directory.has(encounter_id)):
					var encounter = encounter_directory[encounter_id]
					spool_to_add.encounters.append(encounter)
					encounter.connected_spools.append(spool_to_add)
			spool_to_add.id = entry["id"]
			spool_to_add.creation_index = entry["creation_index"]
			spool_to_add.creation_time = entry["creation_time"]
			spool_to_add.modified_time = entry["modified_time"]
			add_spool(spool_to_add)
	#Add all other variables:
	if (data_to_load.has("unique_id_seeds")):
		unique_id_seeds = data_to_load.unique_id_seeds.duplicate()
	if (data_to_load.has("storyworld_title")):
		storyworld_title = data_to_load.storyworld_title
	if (data_to_load.has("storyworld_author")):
		storyworld_author = data_to_load.storyworld_author
	if (data_to_load.has("debug_mode")):
		storyworld_debug_mode_on = data_to_load.debug_mode
	if (data_to_load.has("display_mode")):
		storyworld_display_mode = data_to_load.display_mode
	if (data_to_load.has("sweepweave_version")):
		sweepweave_version_number = data_to_load.sweepweave_version
	if (data_to_load.has("creation_time")):
		creation_time = data_to_load.creation_time
	if (data_to_load.has("modified_time")):
		modified_time = data_to_load.modified_time
	if (data_to_load.has("IFID")):
		ifid = data_to_load.IFID
	else:
		ifid = IFIDGenerator.IFID_from_creation_time(creation_time)
	print("Project Loaded: " + storyworld_title + " by " + storyworld_author + ". (Storyworld SWV# " + sweepweave_version_number + ")")

#Function for determining the version of SweepWeave used to make a project file, and then loading the file via the appropriate functions:

func load_from_json(file_text):
	var data_to_load = JSON.parse(file_text).result
	if (data_to_load.has("sweepweave_version")):
		sweepweave_version_number = data_to_load.sweepweave_version
		var version = sweepweave_version_number.split(".")
		if (3 == version.size()):
			if (0 == int(version[0]) and 0 == int(version[1]) and 7 <= int(version[2]) and 15 >= int(version[2])):
				clear()
				load_from_json_v0_0_07_through_v0_0_15(data_to_load)
			elif (0 == int(version[0]) and 0 == int(version[1]) and 21 <= int(version[2])):
				clear()
				load_from_json_v0_0_21(data_to_load)
			else:
				print ("Cannot load project file.")
		else:
			print ("Cannot load project file.")
	else:
		print ("Cannot load project file.")

#func parse_reactions_data_0_0_15(data, incomplete_reactions, option):
#	var result = []
#	for each in data:
#		var graph_offset = Vector2(0, 0)
#		if (each.has_all(["graph_offset_x", "graph_offset_y"])):
#			graph_offset = Vector2(each["graph_offset_x"], each["graph_offset_y"])
#		var reaction = Reaction.new(option, each["text"], each["blend_x"], each["blend_y"], each["blend_weight"], graph_offset)
#		if ("wild" == each["consequence_id"]):
#			reaction.consequence = null
#		elif (encounter_directory.has(each["consequence_id"])):
#			reaction.consequence = encounter_directory[each["consequence_id"]]
#		else:
#			incomplete_reactions.append([reaction, each["consequence_id"]])
#		if (each.has("pValue_changes")):
#			for x in each["pValue_changes"]:
#				print (str(x["character"]) + x["pValue"] + str(x["point"]))
#				var character = characters[x["character"]]
#				var new_pValueChange = Desideratum.new(character, x["pValue"], x["point"])
#				reaction.pValue_changes.append(new_pValueChange)
#		elif (each.has_all(["deltaLove", "deltaTrust", "deltaFear"])):
#			#This section is included for backwards compatibility.
#			if (0 != each["deltaLove"]):
#				var new_deltaLove = Desideratum.new(reaction.get_antagonist(), "pBad_Good", each["deltaLove"])
#				reaction.pValue_changes.append(new_deltaLove)
#			if (0 != each["deltaTrust"]):
#				var new_deltaTrust = Desideratum.new(reaction.get_antagonist(), "pFalse_Honest", each["deltaTrust"])
#				reaction.pValue_changes.append(new_deltaTrust)
#			if (0 != each["deltaFear"]):
#				var new_deltaFear = Desideratum.new(reaction.get_antagonist(), "pTimid_Dominant", each["deltaFear"])
#				reaction.pValue_changes.append(new_deltaFear)
#		result.append(reaction)
#	return result
#
#func load_from_json_0_0_15(file_text):
#	characters = []
#	character_directory = {}
#	encounters = []
#	encounter_directory = {}
#	#clear_storyworld()
#	var incomplete_reactions = []
#	var incomplete_encounters = []
#	var data_to_load = JSON.parse(file_text).result
#	for entry in data_to_load.characters:
#		var newbie = Actor.new(self, entry["name"], entry["pronoun"])
#		if (entry.has_all(["Bad_Good", "False_Honest", "Timid_Dominant", "pBad_Good", "pFalse_Honest", "pTimid_Dominant"])):
#			newbie.set_classical_personality_model(entry["Bad_Good"], entry["False_Honest"], entry["Timid_Dominant"], entry["pBad_Good"], entry["pFalse_Honest"], entry["pTimid_Dominant"])
#		elif (entry.has("bnumber_properties")):
#			newbie.bnumber_properties = entry["bnumber_properties"].duplicate(true)
#		if (entry.has_all(["creation_index", "creation_time", "modified_time"])):
#			newbie.creation_index = entry["creation_index"]
#			newbie.creation_time = entry["creation_time"]
#			newbie.modified_time = entry["modified_time"]
#		else:
#			newbie.creation_index = char_unique_id_seed
#			newbie.creation_time = OS.get_unix_time()
#			newbie.modified_time = OS.get_unix_time()
#		if (entry.has("id")):
#			newbie.id = entry["id"]
#		else:
#			newbie.id = char_unique_id()
#		add_character(newbie)
#	#Begin loading encounters.
#	#This must proceed in stages, so that encounters which have other encounters associated with them as prerequisites or consequences can be loaded in correctly.
#	for entry in data_to_load.encounters:
#		#Create encounter:
#		var new_encounter = Encounter.new(self, entry["id"], entry["title"], entry["main_text"], entry["earliest_turn"], entry["latest_turn"], characters[entry["antagonist"]], [],
#		   entry["creation_index"], entry["creation_time"], entry["modified_time"], Vector2(entry["graph_position_x"], entry["graph_position_y"]), entry["word_count"])
#		#Parse prerequisites:
#		var incomplete = false
#		for each in entry["prerequisites"]:
#			if (encounter_directory.has(each["encounter"])):
#				var new_prerequisite = Prerequisite.new(each["prereq_type"], each["negated"])
#				new_prerequisite.encounter = encounter_directory[each["encounter"]]
#				new_prerequisite.option = new_prerequisite.encounter.options[each["option"]]
#				new_prerequisite.reaction = new_prerequisite.option.reactions[each["reaction"]]
#				new_encounter.prerequisites.append(new_prerequisite)
#			else:
#				new_encounter.prerequisites.append(each)
#				incomplete = true
#		if (true == incomplete):
#			incomplete_encounters.append(new_encounter)
#		#Parse desiderata:
#		for each in entry["desiderata"]:
#			var d_char = characters[each["character"]]
#			var d_pValue = each["pValue"]
#			var d_point = each["point"]
#			var new_desideratum = Desideratum.new(d_char, d_pValue, d_point)
#			new_encounter.desiderata.append(new_desideratum)
#		#Parse options:
#		for each in entry["options"]:
#			var graph_offset = Vector2(0, 0)
##			if (each.has("graph_offset_x") && each.has("graph_offset_y")):
##				graph_offset = Vector2(each["graph_offset_x"], each["graph_offset_y"])
#			var new_option = Option.new(new_encounter, each["text"], graph_offset)
#			new_option.reactions = parse_reactions_data(each["reactions"], incomplete_reactions, new_option)
#			if (typeof(each) == TYPE_DICTIONARY && each.has("visibility_prerequisites") && each.has("performability_prerequisites")):
#				for prerequisite in each["visibility_prerequisites"]:
#					new_option.visibility_prerequisites.append(prerequisite)
#				for prerequisite in each["performability_prerequisites"]:
#					new_option.performability_prerequisites.append(prerequisite)
#			new_encounter.options.append(new_option)
##		new_encounter.options = parse_options_data(new_encounter, entry["options"], incomplete_reactions)
#		#Add encounter to database:
#		add_encounter(new_encounter)
#	for entry in incomplete_reactions:
#		if (encounter_directory.has(entry[1])):
#			entry[0].consequence = encounter_directory[entry[1]]
#	for entry in incomplete_encounters:
#		var to_remove = []
#		for prereq in entry.prerequisites:
#			if (typeof(prereq) == TYPE_DICTIONARY):
#				if (encounter_directory.has(prereq["encounter"])):
#					var new_prerequisite = Prerequisite.new(prereq["prereq_type"], prereq["negated"])
#					new_prerequisite.encounter = encounter_directory[prereq["encounter"]]
#					new_prerequisite.option = new_prerequisite.encounter.options[prereq["option"]]
#					new_prerequisite.reaction = new_prerequisite.option.reactions[prereq["reaction"]]
#					entry.prerequisites.append(new_prerequisite)
#				to_remove.append(prereq)
#		for each in to_remove:
#			entry.prerequisites.erase(each)
#	for each in encounters:
#		for option in each.options:
#			var to_remove = []
#			for prereq in option.visibility_prerequisites:
#				if (typeof(prereq) == TYPE_DICTIONARY):
#					if (encounter_directory.has(prereq["encounter"])):
#						var new_prerequisite = Prerequisite.new(prereq["prereq_type"], prereq["negated"])
#						new_prerequisite.encounter = encounter_directory[prereq["encounter"]]
#						new_prerequisite.option = new_prerequisite.encounter.options[prereq["option"]]
#						new_prerequisite.reaction = new_prerequisite.option.reactions[prereq["reaction"]]
#						option.visibility_prerequisites.append(new_prerequisite)
#					to_remove.append(prereq)
#			for prereq in option.performability_prerequisites:
#				if (typeof(prereq) == TYPE_DICTIONARY):
#					if (encounter_directory.has(prereq["encounter"])):
#						var new_prerequisite = Prerequisite.new(prereq["prereq_type"], prereq["negated"])
#						new_prerequisite.encounter = encounter_directory[prereq["encounter"]]
#						new_prerequisite.option = new_prerequisite.encounter.options[prereq["option"]]
#						new_prerequisite.reaction = new_prerequisite.option.reactions[prereq["reaction"]]
#						option.performability_prerequisites.append(new_prerequisite)
#					to_remove.append(prereq)
#			for each_to_remove in to_remove:
#				option.visibility_prerequisites.erase(each_to_remove)
#				option.performability_prerequisites.erase(each_to_remove)
#	if (data_to_load.has("unique_id_seed")):
#		unique_id_seed = data_to_load.unique_id_seed
#	if (data_to_load.has("char_unique_id_seed")):
#		char_unique_id_seed = data_to_load.char_unique_id_seed
#	if (data_to_load.has("storyworld_title")):
#		storyworld_title = data_to_load.storyworld_title
#	if (data_to_load.has("storyworld_author")):
#		storyworld_author = data_to_load.storyworld_author
#	if (data_to_load.has("debug_mode")):
#		storyworld_debug_mode_on = data_to_load.debug_mode
#	if (data_to_load.has("display_mode")):
#		storyworld_display_mode = data_to_load.display_mode
#	if (data_to_load.has("sweepweave_version")):
#		sweepweave_version_number = data_to_load.sweepweave_version
#	if (data_to_load.has("creation_time")):
#		creation_time = data_to_load.creation_time
#	if (data_to_load.has("modified_time")):
#		modified_time = data_to_load.modified_time
#	print("Project Loaded: " + storyworld_title + " by " + storyworld_author + ". (Storyworld SWV# " + sweepweave_version_number + ")")

func save_project(file_path, save_as = false):
	var file_data = {}
	file_data["characters"] = []
	for entry in characters:
		file_data["characters"].append(entry.compile(self, true))
	file_data["authored_properties"] = []
	for entry in authored_properties:
		file_data["authored_properties"].append(entry.compile(self, true))
	encounters.sort_custom(EncounterSorter, "sort_created")
	file_data["encounters"] = []
	for entry in encounters:
		file_data["encounters"].append(entry.compile(self, true))
	file_data["spools"] = []
	for entry in spools:
		file_data["spools"].append(entry.compile(self, true))
	file_data["unique_id_seeds"] = unique_id_seeds.duplicate()
	file_data["storyworld_title"] = storyworld_title
	file_data["storyworld_author"] = storyworld_author
	file_data["debug_mode"] = storyworld_debug_mode_on
	file_data["display_mode"] = storyworld_display_mode
	file_data["sweepweave_version"] = sweepweave_version_number
	file_data["creation_time"] = creation_time
	file_data["modified_time"] = modified_time
	file_data["IFID"] = ifid
	var file_text = ""
	if (storyworld_debug_mode_on):
		file_text += JSON.print(file_data, "\t")
	else:
		file_text += JSON.print(file_data, "\t")
	var file = File.new()
	file.open(file_path, File.WRITE)
	file.store_string(file_text)
	file.close()

func compile_to_html(path):
	var file_data = {}
	file_data["characters"] = []
	for entry in characters:
		file_data["characters"].append(entry.compile(self, false))
	file_data["encounters"] = []
	for entry in encounters:
		file_data["encounters"].append(entry.compile(self, false))
	file_data["spools"] = []
	for entry in spools:
		file_data["spools"].append(entry.compile(self, false))
	file_data["debug_mode"] = storyworld_debug_mode_on
	file_data["display_mode"] = storyworld_display_mode
	file_data["IFID"] = ifid
	var file_text = "var storyworld_data = "
	if (storyworld_debug_mode_on):
		file_text += JSON.print(file_data, "\t")
	else:
		file_text += JSON.print(file_data)
	var compiler = Compiler.new(file_text, storyworld_title, storyworld_author, ifid)
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(compiler.output)
	file.close()
