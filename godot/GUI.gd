extends Control

var project_saved = true
var characters = [Actor.new("Null", "", 0, 0, 0, 0, 0, 0)]
var encounters = []
var encounters_directory = {}#Used for quick lookup.
#var first_page = "wild"
var wild_encounter = Encounter.new("wild", "Wild", 'If the consequence of a reaction is set to "wild," then the next page chosen will be random. This encounter is used only by the editor to represent this situation, and will not be saved to exported game_data.', 0, 1000, characters[0], [], -1)
var current_project_path = ""
var current_html_template_path = OS.get_executable_path().get_base_dir() + "\\interpreter_template.html"
var current_encounter = wild_encounter
var current_option = -1
var current_reaction = -1
var unique_id_seed = 0
var current_character = 0
var char_unique_id_seed = 0
var storyworld_title = "New Storyworld"
var storyworld_author = "Anonymous"
var storyworld_debug_mode_on = false
var sweepweave_version_number = "0.0.10"


func unique_id():
	var result = "%x" % unique_id_seed
	result += "_" + str(OS.get_unix_time())
	result = result.sha1_text()
	result = result.left(32)
	unique_id_seed += 1
	return result

func char_unique_id():
	var result = "%x" % char_unique_id_seed
	char_unique_id_seed += 1
	return result

func add_new_encounter(new_encounter):
	update_wordcount(new_encounter)
	encounters.append(new_encounter)
	encounters_directory[new_encounter.id] = new_encounter

func delete_encounter(encounter):
	print("Deleting encounter: " + encounter.title)
	encounters.erase(encounter)
	encounters_directory.erase(encounter)
	for each1 in encounters:
		for prereq in each1.prerequisites:
			if (prereq.encounter == encounter):
				each1.prerequisites.erase(prereq)
				prereq.call_deferred("free")
				log_update(each1)
		for each2 in each1.options:
			for each3 in each2.reactions:
				if (each3.consequence == encounter):
					each3.consequence = wild_encounter
					log_update(each1)
	#To do: Add some code to destroy the encounter itself, and its options and reactions.
	encounter.call_deferred("free")

class EncounterSorter:
	static func sort_a_z(a, b):
		if a.title < b.title:
			return true
		return false
	static func sort_z_a(a, b):
		if a.title > b.title:
			return true
		return false
	static func sort_created(a, b):
		if a.creation_time < b.creation_time:
			return true
		return false
	static func sort_r_created(a, b):
		if a.creation_time > b.creation_time:
			return true
		return false
	static func sort_modified(a, b):
		if a.modified_time > b.modified_time:
			return true
		return false
	static func sort_r_modified(a, b):
		if a.modified_time < b.modified_time:
			return true
		return false
	static func sort_e_turn(a, b):
		if a.earliest_turn < b.earliest_turn:
			return true
		return false
	static func sort_r_e_turn(a, b):
		if a.earliest_turn > b.earliest_turn:
			return true
		return false
	static func sort_l_turn(a, b):
		if a.latest_turn < b.latest_turn:
			return true
		return false
	static func sort_r_l_turn(a, b):
		if a.latest_turn > b.latest_turn:
			return true
		return false
	static func sort_antagonist(a, b):
		if a.antagonist.char_name < b.antagonist.char_name:
			return true
		return false
	static func sort_r_antagonist(a, b):
		if a.antagonist.char_name > b.antagonist.char_name:
			return true
		return false
	static func sort_options(a, b):
		if a.options.size() < b.options.size():
			return true
		return false
	static func sort_r_options(a, b):
		if a.options.size() > b.options.size():
			return true
		return false
	static func sort_reactions(a, b):
		var a_count = 0
		for option in a.options:
			for reaction in option.reactions:
				a_count += 1
		var b_count = 0
		for option in b.options:
			for reaction in option.reactions:
				b_count += 1
		if a_count < b_count:
			return true
		return false
	static func sort_r_reactions(a, b):
		var a_count = 0
		for option in a.options:
			for reaction in option.reactions:
				a_count += 1
		var b_count = 0
		for option in b.options:
			for reaction in option.reactions:
				b_count += 1
		if a_count > b_count:
			return true
		return false
	static func sort_word_count(a, b):
		if a.word_count > b.word_count:
			return true
		return false
	static func sort_r_word_count(a, b):
		if a.word_count < b.word_count:
			return true
		return false

func refresh_encounter_list():
	$VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.clear()
	var sort_method_id = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/SortMenu.get_selected_id()
	var sort_method = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/SortMenu.get_popup().get_item_text(sort_method_id)
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
	var index = 0
	for entry in encounters:
		if ("" == entry.title):
			$VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.add_item("[Untitled]")
		else:
			$VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.add_item(entry.title)
	if (0 == encounters.size()):
		Clear_Encounter_Editing_Screen()

func _on_SortMenu_item_selected(index):
	var sort_method_id = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/SortMenu.get_selected_id()
	var sort_method = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/SortMenu.get_popup().get_item_text(sort_method_id)
	if ("Word Count" == sort_method || "Rev. Word Count" == sort_method):
		for each in encounters:
			update_wordcount(each)
	refresh_encounter_list()

func refresh_option_list():
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.clear()
	for each in current_encounter.options:
		if ("" == each.text):
			$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.add_item("[Blank Option]")
		else:
			$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.add_item(each.text)

func refresh_reaction_list():
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.clear()
	for each in current_option.reactions:
		if ("" == each.text):
			$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.add_item("[Blank Reaction]")
		else:
			$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.add_item(each.text.left(30) + "...")

func refresh_character_list():
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC3/AntagonistPicker.clear()
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.clear()
	$EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.clear()
	$pValueChangeSelection/VBC/HBC/CharacterSelect.clear()
	for entry in characters:
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC3/AntagonistPicker.add_item(entry.char_name)
		$VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.add_item(entry.char_name)
		$EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.add_item(entry.char_name)
		$pValueChangeSelection/VBC/HBC/CharacterSelect.add_item(entry.char_name)
	if (null != current_encounter):
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC3/AntagonistPicker.select(characters.find(current_encounter.antagonist))
	else:
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC3/AntagonistPicker.select(0)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.select(0)
	$EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.select(0)
	$pValueChangeSelection/VBC/HBC/CharacterSelect.select(0)

func refresh_settings_tab():
	$VBC/Bookspine/EditorTabs/Settings/VBC/TitleEdit.text = storyworld_title
	$VBC/Bookspine/EditorTabs/Settings/VBC/AuthorEdit.text = storyworld_author
	$VBC/Bookspine/EditorTabs/Settings/VBC/TemplatePathDisplay.text = "Current html template path: " + current_html_template_path
	$VBC/Bookspine/EditorTabs/Settings/VBC/SavePathDisplay.text = "Current project save path: " + current_project_path
	$VBC/Bookspine/EditorTabs/Settings/VBC/HBC/DBMSwitch.pressed = storyworld_debug_mode_on

func load_Reaction(reaction):
	current_reaction = reaction
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionText.text = reaction.text
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/IncBlendWeightLabel.text = "Inclination blend weight: " + str(reaction.blend_weight)
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCLSL/InclinationHSlider.value = (reaction.blend_weight * 100)
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCTT/Trait1.select(trait_index(reaction.blend_x))
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCTT/Trait2.select(trait_index(reaction.blend_y))
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCConsequence/CurrentConsequence.text = reaction.consequence.title
	refresh_pValue_Change_List()

func load_Option(option):
	current_option = option
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionText.text = option.text
	if (0 < option.reactions.size()):
		load_Reaction(option.reactions[0])
	refresh_reaction_list()

func load_Encounter(encounter):
	current_encounter = encounter
	print("Loading Encounter: " + encounter.title)
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTitle/LineEdit.text = encounter.title
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/TextEdit.text = encounter.main_text
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC/EarliestTurn.value = encounter.earliest_turn
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC2/LatestTurn.value = encounter.latest_turn
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC3/AntagonistPicker.select(characters.find(encounter.antagonist))
	refresh_option_list()
	if (0 < encounter.options.size()):
		load_Option(encounter.options[0])
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.select(0)
	if (0 < current_option.reactions.size()):
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(0)

func Clear_Encounter_Editing_Screen():
	current_encounter = null
	current_option = null
	current_reaction = null
	print("Clearing Encounter Editing Screen.")
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTitle/LineEdit.text = ""
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/TextEdit.text = ""
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC/EarliestTurn.value = 0
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC2/LatestTurn.value = 0
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC3/AntagonistPicker.select(0)
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.clear()
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.clear()
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionText.text = ""
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionText.text = ""
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/IncBlendWeightLabel.text = "Inclination blend weight: 0"
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCLSL/InclinationHSlider.value = 0
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCTT/Trait1.select(0)
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCTT/Trait2.select(0)
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCConsequence/CurrentConsequence.text = ""

#File Management

func parse_reactions_data(data, incomplete_reactions, option):
	var result = []
	for each in data:
		var graph_offset = Vector2(0, 0)
		if (each.has("graph_offset_x") && each.has("graph_offset_y")):
			graph_offset = Vector2(each["graph_offset_x"], each["graph_offset_y"])
		var reaction = Reaction.new(option, each["text"], each["blend_x"], each["blend_y"], each["blend_weight"], graph_offset)
		if ("wild" == each["consequence_id"]):
			reaction.consequence = wild_encounter
		elif (encounters_directory.has(each["consequence_id"])):
			reaction.consequence = encounters_directory[each["consequence_id"]]
		else:
			incomplete_reactions.append([reaction, each["consequence_id"]])
		for x in each["pValue_changes"]:
			print (str(x["character"]) + x["pValue"] + str(x["point"]))
			var character = characters[x["character"]]
			var new_pValueChange = Desideratum.new(character, x["pValue"], x["point"])
			reaction.pValue_changes.append(new_pValueChange)
		result.append(reaction)
	return result

func load_project(file_text):
	clear_storyworld()
	var incomplete_reactions = []
	var incomplete_encounters = []
	var data_to_load = JSON.parse(file_text).result
	for entry in data_to_load.characters:
		characters.append(Actor.new(entry["name"], entry["pronoun"], entry["Bad_Good"], entry["False_Honest"], entry["Timid_Dominant"], entry["pBad_Good"], entry["pFalse_Honest"], entry["pTimid_Dominant"]))
	#Begin loading encounters.
	#This must proceed in stages, so that encounters which have other encounters associated with them as prerequisites or consequences can be loaded in correctly.
	for entry in data_to_load.encounters:
		#Create encounter:
		var new_encounter = Encounter.new(entry["id"], entry["title"], entry["main_text"], entry["earliest_turn"], entry["latest_turn"], characters[entry["antagonist"]], [],
		   entry["creation_index"], entry["creation_time"], entry["modified_time"], Vector2(entry["graph_position_x"], entry["graph_position_y"]), entry["word_count"])
		#Parse prerequisites:
		var incomplete = false
		for each in entry["prerequisites"]:
			if (encounters_directory.has(each["encounter"])):
				var new_prerequisite = Prerequisite.new(each["prereq_type"], each["negated"])
				new_prerequisite.encounter = encounters_directory[each["encounter"]]
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
		add_new_encounter(new_encounter)
	for entry in incomplete_reactions:
		if (encounters_directory.has(entry[1])):
			entry[0].consequence = encounters_directory[entry[1]]
	for entry in incomplete_encounters:
		var to_remove = []
		for prereq in entry.prerequisites:
			if (typeof(prereq) == TYPE_DICTIONARY):
				if (encounters_directory.has(prereq["encounter"])):
					var new_prerequisite = Prerequisite.new(prereq["prereq_type"], prereq["negated"])
					new_prerequisite.encounter = encounters_directory[prereq["encounter"]]
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
					if (encounters_directory.has(prereq["encounter"])):
						var new_prerequisite = Prerequisite.new(prereq["prereq_type"], prereq["negated"])
						new_prerequisite.encounter = encounters_directory[prereq["encounter"]]
						new_prerequisite.option = new_prerequisite.encounter.options[prereq["option"]]
						new_prerequisite.reaction = new_prerequisite.option.reactions[prereq["reaction"]]
						option.visibility_prerequisites.append(new_prerequisite)
					to_remove.append(prereq)
			for prereq in option.performability_prerequisites:
				if (typeof(prereq) == TYPE_DICTIONARY):
					if (encounters_directory.has(prereq["encounter"])):
						var new_prerequisite = Prerequisite.new(prereq["prereq_type"], prereq["negated"])
						new_prerequisite.encounter = encounters_directory[prereq["encounter"]]
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
	print("Project Loaded: " + storyworld_title + " by " + storyworld_author)
	refresh_encounter_list()
	Clear_Encounter_Editing_Screen()
	refresh_character_list()
	current_character = 0
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.select(0)
	load_character(characters[0])
	refresh_settings_tab()
	project_saved = true
	OS.set_window_title("Encounter Editor - " + storyworld_title)
	refresh_graphview()
	refresh_statistical_overview()

func save_project(save_as = false):
	var file_data = {}
	file_data["characters"] = []
	for entry in characters:
		file_data["characters"].append(entry.compile())
	file_data["encounters"] = []
	for entry in encounters:
		file_data["encounters"].append(entry.compile(characters, true))
	file_data["unique_id_seed"] = unique_id_seed
	file_data["char_unique_id_seed"] = char_unique_id_seed
	file_data["storyworld_title"] = storyworld_title
	file_data["storyworld_author"] = storyworld_author
	file_data["debug_mode"] = storyworld_debug_mode_on
	file_data["sweepweave_version"] = sweepweave_version_number
	var file_text = ""
	if (storyworld_debug_mode_on):
		file_text += JSON.print(file_data, "\t")
	else:
		file_text += JSON.print(file_data)
	var file = File.new()
	file.open(current_project_path, File.WRITE)
	file.store_string(file_text)
	file.close()
	project_saved = true
	OS.set_window_title("Encounter Editor - " + storyworld_title)

func _on_ChooseTemplateDialog_file_selected(path):
	current_html_template_path = path
	print("New html template path set: " + path)
	refresh_settings_tab()

func _on_ChangeTemplate_pressed():
	$ChooseTemplateDialog.popup()

func compile_storyworld_to_html(path):
	var file_data = {}
	file_data["characters"] = []
	for entry in characters:
		file_data["characters"].append(entry.compile())
	file_data["encounters"] = []
	for entry in encounters:
		file_data["encounters"].append(entry.compile(characters))
	file_data["debug_mode"] = storyworld_debug_mode_on
	var file_text = "var storyworld_data = "
	if (storyworld_debug_mode_on):
		file_text += JSON.print(file_data, "\t")
	else:
		file_text += JSON.print(file_data)
	var compiler = Compiler.new(file_text, storyworld_title, storyworld_author, current_html_template_path)
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(compiler.output)
	file.close()

# Functions to import from Chris Crawford's XML format

#func _on_ImportXMLFileDialog_file_selected(path):
#	pass # 

# On Startup

func clear_storyworld():
	characters.clear()
	for each in encounters:
		delete_encounter(each)
	encounters.clear()
	encounters_directory.clear()

func new_storyworld():
	clear_storyworld()
	char_unique_id_seed = 0
	_on_AddCharacter_pressed()
	current_character = characters[0]
	current_project_path = ""
	unique_id_seed = 0
	storyworld_title = "New Storyworld"
	OS.set_window_title("Encounter Editor - " + storyworld_title)
	storyworld_author = "Anonymous"
	storyworld_debug_mode_on = false
	refresh_settings_tab()
	wild_encounter = Encounter.new("wild", "Wild", 'If the consequence of a reaction is set to "wild," then the next page chosen will be random. This encounter is used only by the editor to represent this situation, and will not be saved to exported game_data.', [], [], 0, 0, characters[0], [], -1)
	refresh_encounter_list()
	Clear_Encounter_Editing_Screen()
	refresh_statistical_overview()
	refresh_graphview()
	project_saved = true

func _ready():
	get_tree().set_auto_accept_quit(false)
	$LoadFileDialog.set_current_dir(OS.get_executable_path().get_base_dir())
	$LoadFileDialog.set_current_file("story.json")
	$LoadFileDialog.set_filters(PoolStringArray(["*.json ; JSON Files"]))
	$SaveAsFileDialog.set_current_dir(OS.get_executable_path().get_base_dir())
	$SaveAsFileDialog.set_current_file("story.json")
	$SaveAsFileDialog.set_filters(PoolStringArray(["*.json ; JSON Files"]))
	$CompileFileDialog.set_current_dir(OS.get_executable_path().get_base_dir())
	$CompileFileDialog.set_current_file("story.html")
	$CompileFileDialog.set_filters(PoolStringArray(["*.html ; HTML Files","*.htm ; HTM Files"]))
	new_storyworld()
	refresh_encounter_list()
	$VBC/Menu.get_popup().connect("id_pressed", self, "_on_mainmenu_item_pressed")
	var traits = ["Bad_Good", "-Bad_Good", "False_Honest", "-False_Honest", "Timid_Dominant", "-Timid_Dominant", "pBad_Good", "-pBad_Good", "pFalse_Honest", "-pFalse_Honest", "pTimid_Dominant", "-pTimid_Dominant"]
	for each in traits:
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCTT/Trait1.add_item(each)
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCTT/Trait2.add_item(each)
	var traits2 = ["pBad_Good", "pFalse_Honest", "pTimid_Dominant"]
	$EditEncounterSettings/DesideratumSelection/HBC/pValueSelect.clear()
	$pValueChangeSelection/VBC/HBC/pValueSelect.clear()
	for each in traits2:
		$EditEncounterSettings/DesideratumSelection/HBC/pValueSelect.add_item(each)
		$pValueChangeSelection/VBC/HBC/pValueSelect.add_item(each)
	$About/VBoxContainer/VersionMessage.text = "SweepWeave v." + sweepweave_version_number

#GUI Functions

func _notification(what):
	if (what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		if(false == project_saved):
			$ConfirmQuit.popup()
		else:
			get_tree().quit()

func _on_ConfirmQuit_confirmed():
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("project_save_as"):
		#This check must come before the Control + S check, otherwise Control + S will take precedence.
		print("Control + Alt + S pressed")
		$SaveAsFileDialog.popup()
	elif event.is_action_pressed("project_save_overwrite"):
		print("Control + S pressed")
		if ("" != current_project_path):
			save_project()
		else:
			$SaveAsFileDialog.popup()
	elif event.is_action_pressed("project_new"):
		print("Control + N pressed")
		new_storyworld()
	elif event.is_action_pressed("project_load"):
		print("Control + O pressed")
		if(false == project_saved):
			$ConfirmOpenWhenUnsaved.popup()
		else:
			$LoadFileDialog.popup()

func log_update(encounter = wild_encounter):
	#If encounter == wild_encounter, then the project as a whole is being updated, rather than a specific encounter, or an encounter has been added, deleted, or duplicated.
	encounter.modified_time = OS.get_unix_time()
	OS.set_window_title("Encounter Editor - " + storyworld_title + "*")
	project_saved = false

func _on_AddButton_pressed():
	var new_encounter = Encounter.new("encounter_" + unique_id(), "Encounter " + str(unique_id_seed-1), "", 0, 1000, characters[0], [], unique_id_seed-1)
	var new_option = Option.new(new_encounter, "What does the user do?")
	var new_reaction = Reaction.new(new_option, "How does the antagonist respond?", "Bad_Good", "False_Honest", 0)
	new_reaction.consequence = wild_encounter
	new_encounter.options.append(new_option)
	new_option.reactions.append(new_reaction)
	add_new_encounter(new_encounter)
	log_update(new_encounter)
	refresh_encounter_list()
	refresh_graphview()

func _on_Edit_pressed():
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.get_selected_items()
		var encounter_id = selection[0]
		var encounter_to_edit = encounters[encounter_id]
		load_Encounter(encounter_to_edit)

func _on_EncountersList_item_activated(index):
	var encounter_to_edit = encounters[index]
	print("Loading Encounter: " + encounter_to_edit.title)
	load_Encounter(encounter_to_edit)

func _on_Duplicate_pressed():
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.get_selected_items()
		var encounters_to_duplicate = []
		for entry in selection:
			encounters_to_duplicate.append(encounters[entry])
		var encounter_to_edit = encounters[selection[0]]
		for entry in encounters_to_duplicate:
			print("Duplicating Encounter: " + entry.title)
			var new_encounter = Encounter.new("enc_" + unique_id(), entry.title + " copy", entry.main_text, entry.earliest_turn, entry.latest_turn, entry.antagonist, [], unique_id_seed-1)
			for prereq in entry.prerequisites:
				var prereq_copy = Prerequisite.new(prereq.prereq_type, prereq.negated)
				prereq_copy.encounter = prereq.encounter
				prereq_copy.option = prereq.option
				prereq_copy.reaction = prereq.reaction
				prereq_copy.encounter_scene = prereq.encounter_scene
				prereq_copy.who1 = prereq.who1
				prereq_copy.pValue1 = prereq.pValue1
				prereq_copy.operator = prereq.operator
				prereq_copy.constant = prereq.constant
				prereq_copy.who2 = prereq.who2
				prereq_copy.pValue2 = prereq.pValue2
				new_encounter.prerequisites.append(prereq_copy)
			for desid in entry.desiderata:
				var desid_copy = Desideratum.new(desid.character, desid.pValue, desid.point)
				new_encounter.desiderata.append(desid_copy)
			for option in entry.options:
				var option_copy = Option.new(new_encounter, option.text)
				for reaction in option.reactions:
					var reaction_copy = Reaction.new(option_copy, reaction.text, reaction.blend_x, reaction.blend_y, reaction.blend_weight)
					reaction_copy.consequence = reaction.consequence
					for x in reaction.pValue_changes:
						var new_pValueChange = Desideratum.new(x.character, x.pValue, x.point)
						reaction_copy.pValue_changes.append(new_pValueChange)
					option_copy.reactions.append(reaction_copy)
				new_encounter.options.append(option_copy)
			add_new_encounter(new_encounter)
			if (encounter_to_edit == encounters[selection[0]]):
				encounter_to_edit = new_encounter
		log_update(wild_encounter)
		refresh_encounter_list()
		refresh_graphview()
		load_Encounter(encounter_to_edit)

func _on_mainmenu_item_pressed(id):
	var item_name = $VBC/Menu.get_popup().get_item_text(id)
	if ("About" == item_name):
		$About.popup()
	elif ("New Storyworld" == item_name):
		if(false == project_saved):
			$ConfirmNewStoryworld.popup()
		else:
			new_storyworld()
	elif ("Open" == item_name):
		if(false == project_saved):
			$ConfirmOpenWhenUnsaved.popup()
		else:
			$LoadFileDialog.popup()
	elif ("Import from XML" == item_name):
		$ImportXMLFileDialog.popup()
	elif ("Save" == item_name):
		if ("" != current_project_path):
			save_project()
		else:
			$SaveAsFileDialog.popup()
	elif ("Save As" == item_name):
		$SaveAsFileDialog.popup()
	elif ("Compile to HTML" == item_name):
		$CompileFileDialog.popup()
	elif ("Playtest" == item_name):
		playtest()
	elif ("Quit" == item_name):
		if(false == project_saved):
			$ConfirmQuit.popup()
		else:
			get_tree().quit()
	print(item_name + " pressed")

func _on_OpenPatreonButton_pressed():
	#This button is in the "About" popup.
	OS.shell_open("https://www.patreon.com/sasha_fenn")

func _on_ConfirmNewStoryworld_confirmed():
	new_storyworld()

func _on_ConfirmOpenWhenUnsaved_confirmed():
	$LoadFileDialog.popup()

func _on_LoadFileDialog_file_selected(path):
	current_project_path = path
	print("Opening: " + path)
	var file = File.new()
	file.open(path, 1)
	var json_string = file.get_as_text().replacen("var storyworld_data = ", "")
	load_project(json_string)
	file.close()

func _on_SaveAsFileDialog_file_selected(path):
	current_project_path = path
	save_project(true)

func _on_CompileFileDialog_file_selected(path):
	compile_storyworld_to_html(path)

func playtest():
	compile_storyworld_to_html("user://SW_playtests/playtest.html")
	var test_path = ProjectSettings.globalize_path("user://SW_playtests/playtest.html")
	print("Playtesting: file:///" + test_path)
	OS.shell_open("file:///" + test_path)

func _on_LineEdit_text_changed(new_text):
	#Change encounter title
	if (null != current_encounter):
		current_encounter.title = new_text
		update_wordcount(current_encounter)
		log_update(current_encounter)
		refresh_encounter_list()
		refresh_graphview()

func _on_TextEdit_text_changed():
	#Change encounter main text
	if (null != current_encounter):
		current_encounter.main_text = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/TextEdit.text
		update_wordcount(current_encounter)
		log_update(current_encounter)
		refresh_graphview()

func _on_ConfirmEncounterDeletion_confirmed():
	var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.get_selected_items()
	var selected_encounters = []
	for each in selection:
		selected_encounters.append(encounters[each])
	for each in selected_encounters:
		delete_encounter(each)
	log_update(wild_encounter)
	refresh_encounter_list()
	refresh_graphview()

func _on_DeleteButton_pressed():
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.get_selected_items()
		var selected_encounters = []
		for each in selection:
			selected_encounters.append(encounters[each])
		if (0 == selected_encounters.size()):
			$CannotDelete.dialog_text = 'No encounters can be deleted.'
			$CannotDelete.popup()
		else:
			var dialog_text = 'Are you sure you wish to delete the following encounter(s)?'
			for each in selected_encounters:
				dialog_text += " (" + each.title + ")"
			$ConfirmEncounterDeletion.dialog_text = dialog_text
			$ConfirmEncounterDeletion.popup()

func _on_PrereqAdd_pressed():
	refresh_event_selection()
	$EditEncounterSettings/EventSelection.popup()

func _on_PrereqDelete_pressed():
	if ($EditEncounterSettings/VBC/HBC/VBC/Scroll/PrerequisiteList.is_anything_selected()):
		var selection = $EditEncounterSettings/VBC/HBC/VBC/Scroll/PrerequisiteList.get_selected_items()
		var selected_prerequisites = []
		for each in selection:
			selected_prerequisites.append(current_encounter.prerequisites[each])
		for each in selected_prerequisites:
			current_encounter.prerequisites.erase(each)
		$EditEncounterSettings/VBC/HBC/VBC/Scroll/PrerequisiteList.clear()
		for entry in current_encounter.prerequisites:
			$EditEncounterSettings/VBC/HBC/VBC/Scroll/PrerequisiteList.add_item(entry.summarize())
		log_update(current_encounter)

func _on_EarliestTurn_value_changed(value):
	if (null != current_encounter):
		current_encounter.earliest_turn = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC/EarliestTurn.value
		log_update(current_encounter)

func _on_LatestTurn_value_changed(value):
	if (null != current_encounter):
		current_encounter.latest_turn = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC2/LatestTurn.value
		log_update(current_encounter)

func _on_AntagonistPicker_item_selected(index):
	if (null != current_encounter):
		current_encounter.antagonist = characters[index]
		log_update(current_encounter)



#Character Edit Interface Elements:
func _on_AddCharacter_pressed():
	var new_name = "So&So " + str(char_unique_id_seed)
	var new_character = Actor.new(new_name, "they", 0, 0, 0, 0, 0, 0)
	print("New character: " + new_character.char_name)
	characters.append(new_character)
	load_character(new_character)
	log_update(wild_encounter)
	refresh_character_list()
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.select($VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.get_item_count() - 1)
	char_unique_id()

func load_character(who):
	current_character = who
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/CharNameEdit.text = current_character.char_name
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/CharPronounEdit.text = current_character.pronoun
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/Bad_GoodLabel.text = "Bad_Good: " + str(current_character.Bad_Good)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/Bad_GoodEdit.value = (100 * current_character.Bad_Good)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/False_HonestLabel.text = "False_Honest: " + str(current_character.False_Honest)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/False_HonestEdit.value = (100 * current_character.False_Honest)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/Timid_DominantLabel.text = "Timid_Dominant: " + str(current_character.Timid_Dominant)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/Timid_DominantEdit.value = (100 * current_character.Timid_Dominant)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/pBad_GoodLabel.text = "pBad_Good: " + str(current_character.pBad_Good)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/pBad_GoodEdit.value = (100 * current_character.pBad_Good)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/pFalse_HonestLabel.text = "pFalse_Honest: " + str(current_character.pFalse_Honest)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/pFalse_HonestEdit.value = (100 * current_character.pFalse_Honest)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/pTimid_DominantLabel.text = "pTimid_Dominant: " + str(current_character.pTimid_Dominant)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/pTimid_DominantEdit.value = (100 * current_character.pTimid_Dominant)

func _on_CharNameEdit_text_changed(new_text):
	current_character.char_name = $VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/CharNameEdit.text
	var selection = $VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.get_selected_items()
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.set_item_text(selection[0], current_character.char_name)
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC3/AntagonistPicker.set_item_text(selection[0], current_character.char_name)
	log_update(wild_encounter)

func _on_CharPronounEdit_text_changed(new_text):
	current_character.pronoun = $VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/CharPronounEdit.text
	log_update(wild_encounter)

func _on_Bad_GoodEdit_value_changed(value):
	current_character.Bad_Good = ($VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/Bad_GoodEdit.value / 100)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/Bad_GoodLabel.text = "Bad_Good: " + str(current_character.Bad_Good)
	log_update(wild_encounter)

func _on_False_HonestEdit_value_changed(value):
	current_character.False_Honest = ($VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/False_HonestEdit.value / 100)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/False_HonestLabel.text = "False_Honest: " + str(current_character.False_Honest)
	log_update(wild_encounter)

func _on_Timid_DominantEdit_value_changed(value):
	current_character.Timid_Dominant = ($VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/Timid_DominantEdit.value / 100)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/Timid_DominantLabel.text = "Timid_Dominant: " + str(current_character.Timid_Dominant)
	log_update(wild_encounter)

func _on_pBad_GoodEdit_value_changed(value):
	current_character.pBad_Good = ($VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/pBad_GoodEdit.value / 100)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/pBad_GoodLabel.text = "pBad_Good: " + str(current_character.pBad_Good)
	log_update(wild_encounter)

func _on_pFalse_HonestEdit_value_changed(value):
	current_character.pFalse_Honest = ($VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/pFalse_HonestEdit.value / 100)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/pFalse_HonestLabel.text = "pFalse_Honest: " + str(current_character.pFalse_Honest)
	log_update(wild_encounter)

func _on_pTimid_DominantEdit_value_changed(value):
	current_character.pTimid_Dominant = ($VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/pTimid_DominantEdit.value / 100)
	$VBC/Bookspine/EditorTabs/Characters/HBC/VBC2/pTimid_DominantLabel.text = "pTimid_Dominant: " + str(current_character.pTimid_Dominant)
	log_update(wild_encounter)

func _on_DeleteCharacter_pressed():
	if ($VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.is_anything_selected()):
		if (1 < characters.size()):
			var selection = $VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.get_selected_items()
			var dialog_text = 'Are you sure you wish to delete the character: "'
			var character_to_delete = characters[selection[0]]
			dialog_text += character_to_delete.char_name + '"? If so, please select a new character to serve as the antagonist for every encounter currently employing "' + character_to_delete.char_name + '" as antagonist.'
			$ConfirmCharacterDeletion.dialog_text = dialog_text
			$ConfirmCharacterDeletion/Center/AntagonistReplacementPicker.clear()
			for each in characters:
				if (each != character_to_delete):
					$ConfirmCharacterDeletion/Center/AntagonistReplacementPicker.add_item(each.char_name)
			$ConfirmCharacterDeletion/Center/AntagonistReplacementPicker.select(0)
			$ConfirmCharacterDeletion.popup()
		else:
			print("The storyworld must have at least one character.")

func _on_ConfirmCharacterDeletion_confirmed():
	if ($VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.get_selected_items()
		var character_to_delete = characters[selection[0]]
		var replacement = characters[$ConfirmCharacterDeletion/Center/AntagonistReplacementPicker.get_selected_id()]
		print("Deleting: " + character_to_delete.char_name)
		for encounter in encounters:
			for desid in encounter.desiderata:
				if (desid.character == character_to_delete):
					desid.character = replacement
					log_update(encounter)
			if (encounter.antagonist == character_to_delete):
				encounter.antagonist = replacement
				log_update(encounter)
		characters.erase(character_to_delete)
		character_to_delete.call_deferred("free")
		log_update(wild_encounter)
		refresh_character_list()
		$VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.select(selection[0])
		load_character(characters[0])

func _on_CharacterList_item_selected(index):
	var selection = $VBC/Bookspine/EditorTabs/Characters/HBC/VBC/Scroll/CharacterList.get_selected_items()
	var who = characters[selection[0]]
	load_character(who)


#Options and Reactions interface elements:

func _on_AddOption_pressed():
	if (null != current_encounter):
		current_option = Option.new(current_encounter, "What does the user do?")
		var new_reaction = Reaction.new(current_option, "How does the antagonist respond?", "Bad_Good", "False_Honest", 0)
		new_reaction.consequence = wild_encounter
		current_option.reactions.append(new_reaction)
		current_encounter.options.append(current_option)
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.add_item(current_option.text)
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.select($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_item_count() - 1)
		load_Option(current_option)
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(0)
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_ConfirmOptionDeletion_confirmed():
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		var option_to_delete = current_encounter.options[selection[0]]
		print("Deleting option: " + option_to_delete.text.left(10))
		for encounter in encounters:
			for prereq in encounter.prerequisites:
				if (prereq.option == option_to_delete):
					prereq.option = null
					log_update(encounter)
		current_encounter.options.erase(option_to_delete)
		option_to_delete.call_deferred("free")
		refresh_option_list()
		if (0 < current_encounter.options.size()):
			current_option = current_encounter.options[0]
			$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.select(0)
			load_Option(current_option)
		update_wordcount(current_encounter)
		log_update(current_encounter)
		refresh_graphview()

func _on_DeleteOption_pressed():
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		var dialog_text = "Are you sure you wish to delete the option: \""
		dialog_text += current_encounter.options[selection[0]].text + "\"?"
		$ConfirmOptionDeletion.dialog_text = dialog_text
		$ConfirmOptionDeletion.popup()

func _on_MoveOptionUpButton_pressed():
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		if (0 == selection[0]):
			#Cannot move option up any farther.
			print("Cannot move option up any farther: " + current_encounter.options[selection[0]].text)
		else:
			print("Moving option up: " + current_encounter.options[selection[0]].text)
			var swap = current_encounter.options[selection[0]]
			current_encounter.options[selection[0]] = current_encounter.options[selection[0]-1]
			current_encounter.options[selection[0]-1] = swap
			refresh_option_list()
			if (0 < current_encounter.options.size()):
				current_option = current_encounter.options[selection[0]-1]
				$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.select(selection[0]-1)
				load_Option(current_option)
				$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(0)
				load_Reaction(current_option.reactions[0])
			log_update(current_encounter)

func _on_MoveOptionDownButton_pressed():
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		if ((current_encounter.options.size()-1) == selection[0]):
			#Cannot move option down any farther.
			print("Cannot move option down any farther: " + current_encounter.options[selection[0]].text)
		else:
			print("Moving option down: " + current_encounter.options[selection[0]].text)
			var swap = current_encounter.options[selection[0]]
			current_encounter.options[selection[0]] = current_encounter.options[selection[0]+1]
			current_encounter.options[selection[0]+1] = swap
			refresh_option_list()
			if (0 < current_encounter.options.size()):
				current_option = current_encounter.options[selection[0]+1]
				$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.select(selection[0]+1)
				load_Option(current_option)
				$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(0)
				load_Reaction(current_option.reactions[0])
			log_update(current_encounter)

func trait_index(trait_text):
	match trait_text:
		"Bad_Good":
			return 0
		"-Bad_Good":
			return 1
		"False_Honest":
			return 2
		"-False_Honest":
			return 3
		"Timid_Dominant":
			return 4
		"-Timid_Dominant":
			return 5
		"pBad_Good":
			return 6
		"-pBad_Good":
			return 7
		"pFalse_Honest":
			return 8
		"-pFalse_Honest":
			return 9
		"pTimid_Dominant":
			return 10
		"-pTimid_Dominant":
			return 11

func _on_OptionsList_item_selected(index):
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		current_option = current_encounter.options[selection[0]]
		load_Option(current_option)
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(0)
		load_Reaction(current_option.reactions[0])

func _on_OptionText_text_changed(new_text):
	if (null != current_option):
		current_option.text = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionText.text
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		var which = 0
		if (0 < selection.size()):
			which = selection[0]
		refresh_option_list()
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.select(which)
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_AddReaction_pressed():
	if (null != current_option):
		current_reaction = Reaction.new(current_option, "How does the antagonist respond?", "Bad_Good", "False_Honest", 0)
		current_reaction.consequence = wild_encounter
		current_option.reactions.append(current_reaction)
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.add_item(current_reaction.text.left(30) + "...")
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_item_count() - 1)
		load_Reaction(current_reaction)
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_ConfirmReactionDeletion_confirmed():
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		current_reaction = current_option.reactions[selection[0]]
		print("Deleting reaction: " + current_reaction.text.left(25))
		for encounter in encounters:
			for prereq in encounter.prerequisites:
				if (prereq.reaction == current_reaction):
					prereq.reaction = null
					log_update(encounter)
		current_option.reactions.erase(current_reaction)
		current_reaction.call_deferred("free")
		load_Option(current_option)
		current_reaction = current_option.reactions[0]
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(0)
		load_Reaction(current_reaction)
		update_wordcount(current_encounter)
		log_update(current_encounter)
		refresh_graphview()

func _on_DeleteReaction_pressed():
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		if (1 < current_option.reactions.size()):
			var dialog_text = "Are you sure you wish to delete the reaction: \""
			dialog_text += current_option.reactions[selection[0]].text + "\"?"
			$ConfirmReactionDeletion.dialog_text = dialog_text
			$ConfirmReactionDeletion.popup()
			log_update(current_encounter)
		else:
			print("Each option must have at least one reaction.")

func _on_MoveReactionUpButton_pressed():
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		if (0 == selection[0]):
			#Cannot move reaction up any farther.
			print("Cannot move reaction up any farther: " + current_option.reactions[selection[0]].text)
		else:
			print("Moving reaction up: " + current_option.reactions[selection[0]].text)
			var swap = current_option.reactions[selection[0]]
			current_option.reactions[selection[0]] = current_option.reactions[selection[0]-1]
			current_option.reactions[selection[0]-1] = swap
			refresh_reaction_list()
			if (0 < current_option.reactions.size()):
				current_reaction = current_option.reactions[selection[0]-1]
				$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(selection[0]-1)
				load_Reaction(current_reaction)
			log_update(current_encounter)

func _on_MoveReactionDownButton_pressed():
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		if ((current_option.reactions.size()-1) == selection[0]):
			#Cannot move reaction down any farther.
			print("Cannot move reaction down any farther: " + current_option.reactions[selection[0]].text)
		else:
			print("Moving reaction down: " + current_option.reactions[selection[0]].text)
			var swap = current_option.reactions[selection[0]]
			current_option.reactions[selection[0]] = current_option.reactions[selection[0]+1]
			current_option.reactions[selection[0]+1] = swap
			refresh_reaction_list()
			if (0 < current_option.reactions.size()):
				current_reaction = current_option.reactions[selection[0]+1]
				$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(selection[0]+1)
				load_Reaction(current_reaction)
			log_update(current_encounter)

func _on_ReactionList_item_selected(index):
	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		current_reaction = current_option.reactions[selection[0]]
		load_Reaction(current_reaction)

func _on_ReactionText_text_changed():
	if (null != current_reaction):
		current_reaction.text = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionText.text
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		var which = 0
		if (0 < selection.size()):
			which = selection[0]
		refresh_reaction_list()
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(which)
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_InclinationHSlider_value_changed(value):
	if (null != current_reaction):
		current_reaction.blend_weight = ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCLSL/InclinationHSlider.value / 100)
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/IncBlendWeightLabel.text = "Inclination blend weight: " + str(current_reaction.blend_weight)
		log_update(current_encounter)

func _on_Trait1_item_selected(index):
	if (null != current_reaction):
		var traits = ["Bad_Good", "-Bad_Good", "False_Honest", "-False_Honest", "Timid_Dominant", "-Timid_Dominant", "pBad_Good", "-pBad_Good", "pFalse_Honest", "-pFalse_Honest", "pTimid_Dominant", "-pTimid_Dominant"]
		current_reaction.blend_x = traits[$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCTT/Trait1.get_selected_id()]
		log_update(current_encounter)

func _on_Trait2_item_selected(index):
	if (null != current_reaction):
		var traits = ["Bad_Good", "-Bad_Good", "False_Honest", "-False_Honest", "Timid_Dominant", "-Timid_Dominant", "pBad_Good", "-pBad_Good", "pFalse_Honest", "-pFalse_Honest", "pTimid_Dominant", "-pTimid_Dominant"]
		current_reaction.blend_y = traits[$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCTT/Trait2.get_selected_id()]
		log_update(current_encounter)

func _on_ChangeConsequence_pressed():
	if (null != current_reaction):
		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.get_selected_items()
		if (encounters[selection[0]] == current_encounter):
			print("An encounter cannot serve as a consequence for itself.")
		else:
			current_reaction.consequence = encounters[selection[0]]
			$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCConsequence/CurrentConsequence.text = current_reaction.consequence.title
			log_update(current_encounter)
			refresh_graphview()

func _on_RemoveConsequenceButton_pressed():
	if (null != current_reaction):
		current_reaction.consequence = wild_encounter
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCConsequence/CurrentConsequence.text = current_reaction.consequence.title
		log_update(current_encounter)
		refresh_graphview()

func _on_pValueChangeAdd_pressed():
	if (null != current_reaction):
		$pValueChangeSelection.popup()
	else:
		print("No reaction currently selected.")

func _on_pValueChangeSelection_confirmed():
	if (null != current_reaction):
		var des_character_id = $pValueChangeSelection/VBC/HBC/CharacterSelect.get_selected_id()
		var des_character = characters[des_character_id]
		var des_pValue_id = $pValueChangeSelection/VBC/HBC/pValueSelect.get_selected_id()
		var des_pValue = $pValueChangeSelection/VBC/HBC/pValueSelect.get_item_text(des_pValue_id)
		var des_point = $pValueChangeSelection/VBC/HBC/PointSet.value
		var new_pValueChange = Desideratum.new(des_character, des_pValue, des_point)
		current_reaction.pValue_changes.append(new_pValueChange)
		refresh_pValue_Change_List()
		log_update(current_encounter)
	else:
		print("No reaction currently selected.")

func _on_pValueChangeDelete_pressed():
	var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/pValueChangeList.get_selected_items()
	if (0 < selection.size()):
		var change_to_delete = current_reaction.pValue_changes[selection[0]]
		current_reaction.pValue_changes.erase(change_to_delete)
		refresh_pValue_Change_List()

func refresh_pValue_Change_List():
	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/pValueChangeList.clear()
	for change in current_reaction.pValue_changes:
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/pValueChangeList.add_item(change.explain_pValue_change())
	if (0 != $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/pValueChangeList.get_item_count()):
		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/pValueChangeList.select(0)

#Settings tab interface elements:
func _on_TitleEdit_text_changed(new_text):
	storyworld_title = $VBC/Bookspine/EditorTabs/Settings/VBC/TitleEdit.text
	log_update(wild_encounter)

func _on_AuthorEdit_text_changed(new_text):
	storyworld_author = $VBC/Bookspine/EditorTabs/Settings/VBC/AuthorEdit.text
	log_update(wild_encounter)

func _on_DBMSwitch_toggled(button_pressed):
	if (button_pressed):
		storyworld_debug_mode_on = true
	else:
		storyworld_debug_mode_on = false
	log_update(wild_encounter)


#Statistical Overview interface elements.
func refresh_statistical_overview():
	var sum_options = 0
	var sum_reactions = 0
	var sum_words = 0
	var earliest_turn = 0
	var latest_turn = 0
	var regex = RegEx.new()
	regex.compile("\\S+") # Negated whitespace character class.
	for x in encounters:
		for y in x.options:
			for z in y.reactions:
				sum_words += regex.search_all(z.text).size()
			sum_reactions += y.reactions.size()
			sum_words += regex.search_all(y.text).size()
		sum_options += x.options.size()
		sum_words += regex.search_all(x.title).size()
		sum_words += regex.search_all(x.main_text).size()
		if (x.earliest_turn < earliest_turn):
			earliest_turn = x.earliest_turn
		if (x.latest_turn > latest_turn):
			latest_turn = x.latest_turn
	for x in characters:
		sum_words += regex.search_all(x.char_name).size()
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatEncounters.text = "Total number of encounters: " + str(encounters.size())
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatOptions.text = "Total number of options: " + str(sum_options)
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatReactions.text = "Total number of reactions: " + str(sum_reactions)
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatCharacters.text = "Total number of characters: " + str(characters.size())
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatWords.text = "Total number of words: " + str(sum_words)
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatEarliestTurn.text = "Earliest Turn: " + str(earliest_turn)
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatLatestTurn.text = "Latest Turn: " + str(latest_turn)

func _on_RefreshStats_pressed():
	refresh_statistical_overview()

func update_wordcount(encounter):
	#In order to try to avoid sluggishness, we only do this if sort_by is set to word count or rev. word count.
	var sort_method_id = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/SortMenu.get_selected_id()
	var sort_method = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/SortMenu.get_popup().get_item_text(sort_method_id)
	if ("Word Count" == sort_method || "Rev. Word Count" == sort_method):
#		encounter.word_count = wordcount(encounter)
		var word_count = encounter.wordcount()
		print("check. " + str(word_count))
		log_update(encounter)
		refresh_encounter_list()

#Graphview Functionality
var node_scene = load("res://graphview_node.tscn")

func load_encounter_in_graphview(encounter, zoom_level):
	var encounter_graph_node = node_scene.instance()
	encounter_graph_node.set_my_encounter(encounter)
	encounter_graph_node.offset += encounter.graph_position
	encounter_graph_node.title = encounter.title
	encounter_graph_node.set_excerpt(encounter.main_text.left(64))
	encounter_graph_node.add_to_group("graphview_nodes")
	encounter_graph_node.connect("load_encounter_from_graphview", self, "load_Encounter")
	$VBC/Bookspine/InterpreterTabs/GraphView/VBC/GraphEdit.add_child(encounter_graph_node)
	encounter.graphview_node = encounter_graph_node

func load_connections_in_graphview(encounter, zoom_level):
	var encounter_graph_node = encounter.graphview_node
	for each in encounter.prerequisites:
		$VBC/Bookspine/InterpreterTabs/GraphView/VBC/GraphEdit.connect_node(each.encounter.graphview_node.get_name(), 0, encounter_graph_node.get_name(), 0)
	for option in encounter.options:
		for reaction in option.reactions:
			if (!(reaction.consequence == null || reaction.consequence == wild_encounter)):
				$VBC/Bookspine/InterpreterTabs/GraphView/VBC/GraphEdit.connect_node(encounter_graph_node.get_name(), 1, reaction.consequence.graphview_node.get_name(), 1)

func clear_graphview():
	$VBC/Bookspine/InterpreterTabs/GraphView/VBC/GraphEdit.clear_connections()
	get_tree().call_group("graphview_nodes", "delete")

func refresh_graphview():
	clear_graphview()
	for each in encounters:
		load_encounter_in_graphview(each, 0)
	for each in encounters:
		#Two passes are required to ensure that all nodes are loaded before attempting to load connections.
		load_connections_in_graphview(each, 0)

func _on_GraphEdit__end_node_move():
	get_tree().call_group("graphview_nodes", "save_position")

# Encounter settings interface elements.
#onready var event_selection_tree = get_node("EditEncounterSettings/EventSelection/VScrollBar/EventTree")
onready var event_selection_tree = get_node("EditEncounterSettings/EventSelection/VBC/EventTree")

func refresh_event_selection():
	event_selection_tree.clear()
	var root = event_selection_tree.create_item()
	root.set_text(0, "Encounters: ")
	for encounter in encounters:
		if (encounter != current_encounter):
			var entry_e = event_selection_tree.create_item(root)
			if ("" == encounter.title):
				entry_e.set_text(0, "[Untitled]")
			else:
				entry_e.set_text(0, encounter.title)
			entry_e.set_metadata(0, {"encounter": encounter, "option": null, "reaction": null})
			for option in encounter.options:
				var entry_o = event_selection_tree.create_item(entry_e)
				entry_o.set_text(0, option.text)
				entry_o.set_metadata(0, {"encounter": encounter, "option": option, "reaction": null})
				for reaction in option.reactions:
					var entry_r = event_selection_tree.create_item(entry_o)
					entry_r.set_text(0, reaction.text)
					entry_r.set_metadata(0, {"encounter": encounter, "option": option, "reaction": reaction})

func _on_Edit_Encounter_Settings_Button_pressed():
	if (null != current_encounter):
		refresh_encounter_settings_screen()
		refresh_event_selection()
		$EditEncounterSettings.popup()
	else:
		print("You must open an encounter before you can edit its settings.")

func _on_EventSelection_confirmed():
	var event = event_selection_tree.get_selected()
	if(null != event && null != event.get_metadata(0)):
		var metadata = event.get_metadata(0)
		var encounter = metadata["encounter"]
		var option = metadata["option"]
		var reaction = metadata["reaction"]
		var option_index = ""
		if (null != option):
			option_index = " / " + str(option.get_index())
		var reaction_index = ""
		if (null != reaction):
			reaction_index = " / " + str(reaction.get_index())
		print ("Adding prerequisite for encounter: " + current_encounter.title)
		print ("Prerequisite: " + encounter.title + option_index + reaction_index)
		#Add an event prerequisite to the current encounter.
		var new_prereq_negated = $EditEncounterSettings/EventSelection/VBC/NegatedCheckBox.is_pressed()
		var new_prerequisite = Prerequisite.new(0, new_prereq_negated)
		new_prerequisite.encounter = encounter
		new_prerequisite.option = option
		new_prerequisite.reaction = reaction
		current_encounter.prerequisites.append(new_prerequisite)
		log_update(current_encounter)
		refresh_encounter_settings_screen()

func refresh_encounter_settings_screen():
	$EditEncounterSettings.window_title = current_encounter.title + " Settings"
	$EditEncounterSettings/VBC/HBC/VBC/Scroll/PrerequisiteList.clear()
	$EditEncounterSettings/VBC/HBC/VBC2/Scroll/DesiderataList.clear()
	for each in current_encounter.prerequisites:
		$EditEncounterSettings/VBC/HBC/VBC/Scroll/PrerequisiteList.add_item(each.summarize())
	for each in current_encounter.desiderata:
		$EditEncounterSettings/VBC/HBC/VBC2/Scroll/DesiderataList.add_item(each.summarize())

func _on_AddDesideratum_pressed():
	refresh_character_list()
	$EditEncounterSettings/DesideratumSelection.popup()

func _on_DesideratumSelection_confirmed():
	var des_character_id = $EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.get_selected_id()
	var des_character = characters[des_character_id]
	var des_pValue_id = $EditEncounterSettings/DesideratumSelection/HBC/pValueSelect.get_selected_id()
	var des_pValue = $EditEncounterSettings/DesideratumSelection/HBC/pValueSelect.get_item_text(des_pValue_id)
	var des_point = $EditEncounterSettings/DesideratumSelection/HBC/PointSet.value
	var new_desideratum = Desideratum.new(des_character, des_pValue, des_point)
	current_encounter.desiderata.append(new_desideratum)
	log_update(current_encounter)
	refresh_encounter_settings_screen()

func _on_DeleteDesideratum_pressed():
	if ($EditEncounterSettings/VBC/HBC/VBC2/Scroll/DesiderataList.is_anything_selected()):
		var selection = $EditEncounterSettings/VBC/HBC/VBC2/Scroll/DesiderataList.get_selected_items()
		var selected_desiderata = []
		for each in selection:
			selected_desiderata.append(current_encounter.desiderata[each])
		for each in selected_desiderata:
			current_encounter.desiderata.erase(each)
		$EditEncounterSettings/VBC/HBC/VBC2/Scroll/DesiderataList.clear()
		for entry in current_encounter.desiderata:
			$EditEncounterSettings/VBC/HBC/VBC2/Scroll/DesiderataList.add_item(entry.summarize())
		log_update(current_encounter)


#Option Settings Interface Elements
onready var option_event_select = get_node("EditOptionSettings/EventSelection/VBC/EventTree")

func refresh_option_event_selection(list):
	option_event_select.clear()
	var root = option_event_select.create_item()
	root.set_text(0, "Encounters: ")
	root.set_metadata(0, list)
	for encounter in encounters:
		if (encounter != current_encounter):
			var entry_e = option_event_select.create_item(root)
			if ("" == encounter.title):
				entry_e.set_text(0, "[Untitled]")
			else:
				entry_e.set_text(0, encounter.title)
			entry_e.set_metadata(0, {"encounter": encounter, "option": null, "reaction": null})
			for option in encounter.options:
				var entry_o = option_event_select.create_item(entry_e)
				entry_o.set_text(0, option.text)
				entry_o.set_metadata(0, {"encounter": encounter, "option": option, "reaction": null})
				for reaction in option.reactions:
					var entry_r = option_event_select.create_item(entry_o)
					entry_r.set_text(0, reaction.text)
					entry_r.set_metadata(0, {"encounter": encounter, "option": option, "reaction": reaction})

func refresh_option_settings_screen():
	$EditOptionSettings.window_title = current_option.text + " Settings"
	$EditOptionSettings/VBC/HBC/VBC/Scroll/VisibilityPrerequisiteList.clear()
	$EditOptionSettings/VBC/HBC/VBC2/Scroll/PerformabilityPrerequisiteList.clear()
	for each in current_option.visibility_prerequisites:
		$EditOptionSettings/VBC/HBC/VBC/Scroll/VisibilityPrerequisiteList.add_item(each.summarize())
	for each in current_option.performability_prerequisites:
		$EditOptionSettings/VBC/HBC/VBC2/Scroll/PerformabilityPrerequisiteList.add_item(each.summarize())

func _on_OptionSettingsButton_pressed():
	if (null != current_option):
		refresh_option_settings_screen()
		$EditOptionSettings.popup()

func _on_VisibilityPrereqAdd_pressed():
	if (null != current_option):
		refresh_option_event_selection("visibility")
		$EditOptionSettings/EventSelection.popup()

func _on_PerformabilityPrereqAdd_pressed():
	if (null != current_option):
		refresh_option_event_selection("performability")
		$EditOptionSettings/EventSelection.popup()

func _on_OptionEventSelection_confirmed():
	var event = option_event_select.get_selected()
	if(null != event && null != event.get_metadata(0) && null != current_option):
		var metadata = event.get_metadata(0)
		var encounter = metadata["encounter"]
		var option = metadata["option"]
		var reaction = metadata["reaction"]
		var option_index = ""
		if (null != option):
			option_index = " / " + str(option.get_index())
		var reaction_index = ""
		if (null != reaction):
			reaction_index = " / " + str(reaction.get_index())
		print ("Adding prerequisite for option: " + current_encounter.title + " / " + current_option.text)
		print ("Prerequisite: " + encounter.title + option_index + reaction_index)
		#Add an event prerequisite to the current option.
		var new_prereq_negated = $EditOptionSettings/EventSelection/VBC/NegatedCheckBox.is_pressed()
		var new_prerequisite = Prerequisite.new(0, new_prereq_negated)
		new_prerequisite.encounter = encounter
		new_prerequisite.option = option
		new_prerequisite.reaction = reaction
		var list = option_event_select.get_root().get_metadata(0)
		if ("visibility" == list):
			current_option.visibility_prerequisites.append(new_prerequisite)
		else:
			current_option.performability_prerequisites.append(new_prerequisite)
		log_update(current_encounter)
		refresh_option_settings_screen()

func _on_VisibilityPrereqDelete_pressed():
	if ($EditOptionSettings/VBC/HBC/VBC/Scroll/VisibilityPrerequisiteList.is_anything_selected()):
		var selection = $EditOptionSettings/VBC/HBC/VBC/Scroll/VisibilityPrerequisiteList.get_selected_items()
		var selected_prerequisites = []
		for each in selection:
			selected_prerequisites.append(current_option.visibility_prerequisites[each])
		for each in selected_prerequisites:
			current_option.visibility_prerequisites.erase(each)
		$EditOptionSettings/VBC/HBC/VBC/Scroll/VisibilityPrerequisiteList.clear()
		for entry in current_option.visibility_prerequisites:
			$EditOptionSettings/VBC/HBC/VBC/Scroll/VisibilityPrerequisiteList.add_item(entry.summarize())
		log_update(current_encounter)

func _on_PerformabilityPrereqDelete_pressed():
	if ($EditOptionSettings/VBC/HBC/VBC2/Scroll/PerformabilityPrerequisiteList.is_anything_selected()):
		var selection = $EditOptionSettings/VBC/HBC/VBC2/Scroll/PerformabilityPrerequisiteList.get_selected_items()
		var selected_prerequisites = []
		for each in selection:
			selected_prerequisites.append(current_option.performability_prerequisites[each])
		for each in selected_prerequisites:
			current_option.performability_prerequisites.erase(each)
		$EditOptionSettings/VBC/HBC/VBC2/Scroll/PerformabilityPrerequisiteList.clear()
		for entry in current_option.performability_prerequisites:
			$EditOptionSettings/VBC/HBC/VBC2/Scroll/PerformabilityPrerequisiteList.add_item(entry.summarize())
		log_update(current_encounter)







