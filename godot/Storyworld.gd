extends Object
class_name Storyworld

var characters = []
var character_directory = {}
var encounters = []
var encounter_directory = {}
var unique_id_seed = 0
var char_unique_id_seed = 0
var storyworld_title = ""
var storyworld_author = ""
var storyworld_debug_mode_on = false
var storyworld_display_mode = 1 #0 is old display mode, (maintext, choice, reaction, next-button, clear screen, maintext...), 1 is new display mode, (maintext, choice, clear screen, reaction, maintext...)
var sweepweave_version_number = ""
var creation_time = null
var modified_time = null
#Variables for editor:
var project_saved = true

#Personality / relationship model.
var personality_model = {"Bad_Good": 0, "False_Honest": 0, "Timid_Dominant": 0, "pBad_Good": 0, "pFalse_Honest": 0, "pTimid_Dominant": 0}
#Key is property name, value is number of perception layers deep it goes.

func _init(in_title = "New Storyworld", in_author = "Anonymous", in_sw_version = "?"):
	storyworld_title = in_title
	storyworld_author = in_author
	sweepweave_version_number = in_sw_version
	creation_time = OS.get_unix_time()
	modified_time = OS.get_unix_time()

func unique_id():
	var result = "%x" % unique_id_seed
	result += "_" + str(OS.get_unix_time())
	result = result.sha1_text()
	result = result.left(32)
	unique_id_seed += 1
	return result

func char_unique_id():
	var result = "%x" % char_unique_id_seed
	result += "_" + str(OS.get_unix_time())
	result = result.sha1_text()
	result = result.left(32)
	char_unique_id_seed += 1
	return result

func log_update():
	modified_time = OS.get_unix_time()

func add_character(character):
	characters.append(character)
	character_directory[character.id] = character

func delete_character(character):
	characters.erase(character)
	character_directory.erase(character)
	character.call_deferred("free")

func add_all_characters_from(original):
	for character in original.characters:
		var newbie = Actor.new(self, character.char_name, character.pronoun, character.bnumber_properties)
		newbie.id = character.id
		newbie.creation_index = character.creation_index
		newbie.creation_time = character.creation_time
		newbie.modified_time = OS.get_unix_time()
		add_character(newbie)

func import_characters(original_characters):
	for character in original_characters:
		var newbie = Actor.new(self, character.char_name, character.pronoun, character.bnumber_properties)
		newbie.id = character.id
		newbie.creation_index = character.creation_index
		newbie.creation_time = character.creation_time
		newbie.modified_time = OS.get_unix_time()
		add_character(newbie)

func add_encounter(encounter):
	encounters.append(encounter)
	encounter_directory[encounter.id] = encounter

func delete_encounter(encounter):
	#print("Deleting encounter: " + encounter.title)
	encounters.erase(encounter)
	encounter_directory.erase(encounter)
	for each1 in encounters:
		for prereq in each1.prerequisites:
			if (prereq.encounter == encounter):
				each1.prerequisites.erase(prereq)
				prereq.call_deferred("free")
				each1.log_update()
		for each2 in each1.options:
			for each3 in each2.reactions:
				if (each3.consequence == encounter):
					each3.consequence = null
					each1.log_update()
	for option in encounter.options:
		for reaction in option.reactions:
			for change in reaction.pValue_changes:
				change.call_deferred("free")
			reaction.call_deferred("free")
		for prereq in option.visibility_prerequisites:
			prereq.call_deferred("free")
		for prereq in option.performability_prerequisites:
			prereq.call_deferred("free")
		option.call_deferred("free")
	encounter.call_deferred("free")

func remap_prerequisite(prereq):
	#Returns false if an error occurs, and true if everything goes as planned.
	if(!(prereq is Prerequisite)):
		return false
	if (null != prereq.encounter):
		if (encounter_directory.has(prereq.encounter.id)):
			prereq.encounter = encounter_directory[prereq.encounter.id]
			if (null != prereq.option):
				prereq.option = prereq.encounter.options[prereq.option.get_index()]
				if (null != prereq.reaction):
					prereq.reaction = prereq.option.reactions[prereq.reaction.get_index()]
			else:
				prereq.reaction = null
		else:
			return false
	else:
		prereq.option = null
		prereq.reaction = null
	return true

func remap_desideratum(desideratum):
	if (character_directory.has(desideratum.character.id)):
		desideratum.character = character_directory[desideratum.character.id]
		return true
	else:
		desideratum.character = null
		return false

func add_all_encounters_from(original):
	for encounter in original.encounters:
		var copy = Encounter.new(self, "", "", "", 0, 0, null, [], 0)
		copy.set_as_copy_of(encounter)
		if (character_directory.has(copy.antagonist.id)):
			copy.antagonist = character_directory[copy.antagonist.id]
		else:
			print ("Error! " + copy.antagonist.char_name + " not in character directory.")
		for option in copy.options:
			for reaction in option.reactions:
				for change in reaction.pValue_changes:
					remap_desideratum(change)
		add_encounter(copy)
	for encounter in encounters:
		for option in encounter.options:
			for reaction in option.reactions:
				if (null != reaction.consequence and null != reaction.consequence.id):
					if (encounter_directory.has(reaction.consequence.id)):
						reaction.consequence = encounter_directory[reaction.consequence.id]
				reaction.option = option
			for prereq in option.visibility_prerequisites:
				remap_prerequisite(prereq)
			for prereq in option.performability_prerequisites:
				remap_prerequisite(prereq)
			option.encounter = encounter
		for prereq in encounter.prerequisites:
			remap_prerequisite(prereq)
		for desideratum in encounter.desiderata:
			remap_desideratum(desideratum)

func import_encounters(original_encounters):
	for encounter in original_encounters:
		var copy = Encounter.new(self, "", "", "", 0, 0, null, [], 0)
		copy.set_as_copy_of(encounter)
		if (character_directory.has(copy.antagonist.id)):
			copy.antagonist = character_directory[copy.antagonist.id]
		else:
			print ("Error! " + copy.antagonist.char_name + " not in character directory.")
		for option in copy.options:
			for reaction in option.reactions:
				for change in reaction.pValue_changes:
					remap_desideratum(change)
		add_encounter(copy)
	for encounter in encounters:
		for option in encounter.options:
			for reaction in option.reactions:
				if (null != reaction.consequence and null != reaction.consequence.id):
					if (encounter_directory.has(reaction.consequence.id)):
						reaction.consequence = encounter_directory[reaction.consequence.id]
				reaction.option = option
			for prereq in option.visibility_prerequisites:
				remap_prerequisite(prereq)
			for prereq in option.performability_prerequisites:
				remap_prerequisite(prereq)
			option.encounter = encounter
		for prereq in encounter.prerequisites:
			remap_prerequisite(prereq)
		for desideratum in encounter.desiderata:
			remap_desideratum(desideratum)

func duplicate_encounter(encounter):
	var new_id_seed = unique_id_seed
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

func clear():
	unique_id_seed = 0
	char_unique_id_seed = 0
	storyworld_title = "New Storyworld"
	storyworld_author = "Anonymous"
	sweepweave_version_number = "?"
	storyworld_debug_mode_on = false
	storyworld_display_mode = 1
	creation_time = OS.get_unix_time()
	modified_time = OS.get_unix_time()
	var copy_characters = characters.duplicate()
	for each in copy_characters:
		delete_character(each)
	var copy_encounters = encounters.duplicate()
	for each in copy_encounters:
		delete_encounter(each)
	characters = []
	character_directory = {}
	encounters = []
	encounter_directory = {}

func set_as_copy_of(original):
	unique_id_seed = original.unique_id_seed
	char_unique_id_seed = original.char_unique_id_seed
	storyworld_title = original.storyworld_title
	storyworld_author = original.storyworld_author
	storyworld_debug_mode_on = original.storyworld_debug_mode_on
	storyworld_display_mode = original.storyworld_display_mode
	sweepweave_version_number = original.sweepweave_version_number
	clear()
	add_all_characters_from(original)
	add_all_encounters_from(original)

func parse_reactions_data(data, incomplete_reactions, option):
	var result = []
	for each in data:
		var graph_offset = Vector2(0, 0)
		if (each.has_all(["graph_offset_x", "graph_offset_y"])):
			graph_offset = Vector2(each["graph_offset_x"], each["graph_offset_y"])
		var reaction = Reaction.new(option, each["text"], each["blend_x"], each["blend_y"], each["blend_weight"], graph_offset)
		if ("wild" == each["consequence_id"]):
			reaction.consequence = null
		elif (encounter_directory.has(each["consequence_id"])):
			reaction.consequence = encounter_directory[each["consequence_id"]]
		else:
			incomplete_reactions.append([reaction, each["consequence_id"]])
		if (each.has("pValue_changes")):
			for x in each["pValue_changes"]:
				print (str(x["character"]) + x["pValue"] + str(x["point"]))
				var character = characters[x["character"]]
				var new_pValueChange = Desideratum.new(character, x["pValue"], x["point"])
				reaction.pValue_changes.append(new_pValueChange)
		elif (each.has_all(["deltaLove", "deltaTrust", "deltaFear"])):
			#This section is included for backwards compatibility.
			if (0 != each["deltaLove"]):
				var new_deltaLove = Desideratum.new(reaction.get_antagonist(), "pBad_Good", each["deltaLove"])
				reaction.pValue_changes.append(new_deltaLove)
			if (0 != each["deltaTrust"]):
				var new_deltaTrust = Desideratum.new(reaction.get_antagonist(), "pFalse_Honest", each["deltaTrust"])
				reaction.pValue_changes.append(new_deltaTrust)
			if (0 != each["deltaFear"]):
				var new_deltaFear = Desideratum.new(reaction.get_antagonist(), "pTimid_Dominant", each["deltaFear"])
				reaction.pValue_changes.append(new_deltaFear)
		result.append(reaction)
	return result

func load_from_json(file_text):
	characters = []
	character_directory = {}
	encounters = []
	encounter_directory = {}
	#clear_storyworld()
	var incomplete_reactions = []
	var incomplete_encounters = []
	var data_to_load = JSON.parse(file_text).result
	for entry in data_to_load.characters:
		var newbie = Actor.new(self, entry["name"], entry["pronoun"])
		if (entry.has_all(["Bad_Good", "False_Honest", "Timid_Dominant", "pBad_Good", "pFalse_Honest", "pTimid_Dominant"])):
			newbie.set_classical_personality_model(entry["Bad_Good"], entry["False_Honest"], entry["Timid_Dominant"], entry["pBad_Good"], entry["pFalse_Honest"], entry["pTimid_Dominant"])
		elif (entry.has("bnumber_properties")):
			newbie.bnumber_properties = entry["bnumber_properties"].duplicate(true)
		if (entry.has_all(["creation_index", "creation_time", "modified_time"])):
			newbie.creation_index = entry["creation_index"]
			newbie.creation_time = entry["creation_time"]
			newbie.modified_time = entry["modified_time"]
		else:
			newbie.creation_index = char_unique_id_seed
			newbie.creation_time = OS.get_unix_time()
			newbie.modified_time = OS.get_unix_time()
		if (entry.has("id")):
			newbie.id = entry["id"]
		else:
			newbie.id = char_unique_id()
		add_character(newbie)
	#Begin loading encounters.
	#This must proceed in stages, so that encounters which have other encounters associated with them as prerequisites or consequences can be loaded in correctly.
	for entry in data_to_load.encounters:
		#Create encounter:
		var new_encounter = Encounter.new(self, entry["id"], entry["title"], entry["main_text"], entry["earliest_turn"], entry["latest_turn"], characters[entry["antagonist"]], [],
		   entry["creation_index"], entry["creation_time"], entry["modified_time"], Vector2(entry["graph_position_x"], entry["graph_position_y"]), entry["word_count"])
		#Parse prerequisites:
		var incomplete = false
		for each in entry["prerequisites"]:
			if (encounter_directory.has(each["encounter"])):
				var new_prerequisite = Prerequisite.new(each["prereq_type"], each["negated"])
				new_prerequisite.encounter = encounter_directory[each["encounter"]]
				new_prerequisite.option = new_prerequisite.encounter.options[each["option"]]
				new_prerequisite.reaction = new_prerequisite.option.reactions[each["reaction"]]
				new_encounter.prerequisites.append(new_prerequisite)
			else:
				new_encounter.prerequisites.append(each)
				incomplete = true
		if (true == incomplete):
			incomplete_encounters.append(new_encounter)
		#Parse desiderata:
		for each in entry["desiderata"]:
			var d_char = characters[each["character"]]
			var d_pValue = each["pValue"]
			var d_point = each["point"]
			var new_desideratum = Desideratum.new(d_char, d_pValue, d_point)
			new_encounter.desiderata.append(new_desideratum)
		#Parse options:
		for each in entry["options"]:
			var graph_offset = Vector2(0, 0)
#			if (each.has("graph_offset_x") && each.has("graph_offset_y")):
#				graph_offset = Vector2(each["graph_offset_x"], each["graph_offset_y"])
			var new_option = Option.new(new_encounter, each["text"], graph_offset)
			new_option.reactions = parse_reactions_data(each["reactions"], incomplete_reactions, new_option)
			if (typeof(each) == TYPE_DICTIONARY && each.has("visibility_prerequisites") && each.has("performability_prerequisites")):
				for prerequisite in each["visibility_prerequisites"]:
					new_option.visibility_prerequisites.append(prerequisite)
				for prerequisite in each["performability_prerequisites"]:
					new_option.performability_prerequisites.append(prerequisite)
			new_encounter.options.append(new_option)
#		new_encounter.options = parse_options_data(new_encounter, entry["options"], incomplete_reactions)
		#Add encounter to database:
		add_encounter(new_encounter)
	for entry in incomplete_reactions:
		if (encounter_directory.has(entry[1])):
			entry[0].consequence = encounter_directory[entry[1]]
	for entry in incomplete_encounters:
		var to_remove = []
		for prereq in entry.prerequisites:
			if (typeof(prereq) == TYPE_DICTIONARY):
				if (encounter_directory.has(prereq["encounter"])):
					var new_prerequisite = Prerequisite.new(prereq["prereq_type"], prereq["negated"])
					new_prerequisite.encounter = encounter_directory[prereq["encounter"]]
					new_prerequisite.option = new_prerequisite.encounter.options[prereq["option"]]
					new_prerequisite.reaction = new_prerequisite.option.reactions[prereq["reaction"]]
					entry.prerequisites.append(new_prerequisite)
				to_remove.append(prereq)
		for each in to_remove:
			entry.prerequisites.erase(each)
	for each in encounters:
		for option in each.options:
			var to_remove = []
			for prereq in option.visibility_prerequisites:
				if (typeof(prereq) == TYPE_DICTIONARY):
					if (encounter_directory.has(prereq["encounter"])):
						var new_prerequisite = Prerequisite.new(prereq["prereq_type"], prereq["negated"])
						new_prerequisite.encounter = encounter_directory[prereq["encounter"]]
						new_prerequisite.option = new_prerequisite.encounter.options[prereq["option"]]
						new_prerequisite.reaction = new_prerequisite.option.reactions[prereq["reaction"]]
						option.visibility_prerequisites.append(new_prerequisite)
					to_remove.append(prereq)
			for prereq in option.performability_prerequisites:
				if (typeof(prereq) == TYPE_DICTIONARY):
					if (encounter_directory.has(prereq["encounter"])):
						var new_prerequisite = Prerequisite.new(prereq["prereq_type"], prereq["negated"])
						new_prerequisite.encounter = encounter_directory[prereq["encounter"]]
						new_prerequisite.option = new_prerequisite.encounter.options[prereq["option"]]
						new_prerequisite.reaction = new_prerequisite.option.reactions[prereq["reaction"]]
						option.performability_prerequisites.append(new_prerequisite)
					to_remove.append(prereq)
			for each_to_remove in to_remove:
				option.visibility_prerequisites.erase(each_to_remove)
				option.performability_prerequisites.erase(each_to_remove)
	if (data_to_load.has("unique_id_seed")):
		unique_id_seed = data_to_load.unique_id_seed
	if (data_to_load.has("char_unique_id_seed")):
		char_unique_id_seed = data_to_load.char_unique_id_seed
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
	print("Project Loaded: " + storyworld_title + " by " + storyworld_author + ". (Storyworld SWV# " + sweepweave_version_number + ")")

func save_project(file_path, save_as = false):
	var file_data = {}
	file_data["characters"] = []
	for entry in characters:
		file_data["characters"].append(entry.compile(true))
	encounters.sort_custom(EncounterSorter, "sort_created")
	file_data["encounters"] = []
	for entry in encounters:
		file_data["encounters"].append(entry.compile(characters, true))
	file_data["unique_id_seed"] = unique_id_seed
	file_data["char_unique_id_seed"] = char_unique_id_seed
	file_data["storyworld_title"] = storyworld_title
	file_data["storyworld_author"] = storyworld_author
	file_data["debug_mode"] = storyworld_debug_mode_on
	file_data["display_mode"] = storyworld_display_mode
	file_data["sweepweave_version"] = sweepweave_version_number
	file_data["creation_time"] = creation_time
	file_data["modified_time"] = modified_time
	var file_text = ""
	if (storyworld_debug_mode_on):
		file_text += JSON.print(file_data, "\t")
	else:
		file_text += JSON.print(file_data)
	var file = File.new()
	file.open(file_path, File.WRITE)
	file.store_string(file_text)
	file.close()

func compile_to_html(path):
	var file_data = {}
	file_data["characters"] = []
	for entry in characters:
		file_data["characters"].append(entry.compile(false))
	file_data["encounters"] = []
	for entry in encounters:
		file_data["encounters"].append(entry.compile(characters))
	file_data["debug_mode"] = storyworld_debug_mode_on
	file_data["display_mode"] = storyworld_display_mode
	var file_text = "var storyworld_data = "
	if (storyworld_debug_mode_on):
		file_text += JSON.print(file_data, "\t")
	else:
		file_text += JSON.print(file_data)
	var compiler = Compiler.new(file_text, storyworld_title, storyworld_author)
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(compiler.output)
	file.close()

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

