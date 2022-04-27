extends Control

var current_project_path = ""
var current_html_template_path = "res://custom_resources/encounter_engine.html"
var open_after_compiling = false
var current_encounter = null
var current_option = -1
var current_reaction = -1
var current_character = 0
var sweepweave_version_number = "0.0.14"
var storyworld = null
var node_scene = preload("res://graphview_node.tscn")

func refresh_settings_tab():
	$VBC/Bookspine/EditorTabs/Settings/VBC/TitleEdit.text = storyworld.storyworld_title
	$VBC/Bookspine/EditorTabs/Settings/VBC/AuthorEdit.text = storyworld.storyworld_author
	$VBC/Bookspine/EditorTabs/Settings/VBC/TemplatePathDisplay.text = "Current html template path: " + current_html_template_path
	$VBC/Bookspine/EditorTabs/Settings/VBC/SavePathDisplay.text = "Current project save path: " + current_project_path
	$VBC/Bookspine/EditorTabs/Settings/VBC/HBC/DBMSwitch.pressed = storyworld.storyworld_debug_mode_on

func on_character_name_changed(character):
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.refresh_character_names()

#File Management

func load_project(file_text):
	storyworld.clear()
	storyworld.load_from_json(file_text)
	storyworld.sweepweave_version_number = sweepweave_version_number
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.refresh_encounter_list()
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.refresh_character_lists()
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.Clear_Encounter_Editing_Screen()
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.load_and_focus_first_encounter()
	$VBC/Bookspine/EditorTabs/Characters/CharacterEditScreen.refresh_character_list()
	current_character = 0
	$VBC/Bookspine/EditorTabs/Characters/CharacterEditScreen.load_character(storyworld.characters[0])
	refresh_settings_tab()
	storyworld.project_saved = true
	OS.set_window_title("Encounter Editor - " + storyworld.storyworld_title)
	refresh_graphview()
	refresh_statistical_overview()

func save_project(save_as = false):
	storyworld.save_project(current_project_path, save_as)
	storyworld.project_saved = true
	OS.set_window_title("Encounter Editor - " + storyworld.storyworld_title)
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.refresh_encounter_list()

func _on_ChooseTemplateDialog_file_selected(path):
	current_html_template_path = path
	print("New html template path set: " + path)
	refresh_settings_tab()

func _on_ChangeTemplate_pressed():
	$ChooseTemplateDialog.popup()

# Functions to import from Chris Crawford's XML format

#func _on_ImportXMLFileDialog_file_selected(path):
#	pass # 

# On Startup

func new_storyworld():
	if (null == storyworld):
		storyworld = Storyworld.new("New Storyworld", "Anonymous", sweepweave_version_number)
		$VBC/Bookspine/EditorTabs/Characters/CharacterEditScreen.storyworld = storyworld
		$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.storyworld = storyworld
		$VBC/Bookspine/InterpreterTabs/Play/PlayScreen.reference_storyworld = storyworld
	else:
		storyworld.clear()
		storyworld.sweepweave_version_number = sweepweave_version_number
	#Initiate personality / relationship model.
	storyworld.personality_model = {"Bad_Good": 0, "False_Honest": 0, "Timid_Dominant": 0, "pBad_Good": 0, "pFalse_Honest": 0, "pTimid_Dominant": 0}
	#Add at least one character to the storyworld.
	var new_name = "So&So " + str(storyworld.char_unique_id_seed)
	var new_character = Actor.new(storyworld, new_name, "they")
	new_character.creation_index = storyworld.char_unique_id_seed
	new_character.creation_time = OS.get_unix_time()
	new_character.modified_time = OS.get_unix_time()
	new_character.id = storyworld.char_unique_id()
	print("New character: " + new_character.char_name)
	storyworld.add_character(new_character)
	$VBC/Bookspine/EditorTabs/Characters/CharacterEditScreen.load_character(new_character)
	$VBC/Bookspine/EditorTabs/Characters/CharacterEditScreen.log_update(new_character)
	$VBC/Bookspine/EditorTabs/Characters/CharacterEditScreen.refresh_character_list()
	$VBC/Bookspine/EditorTabs/Characters/CharacterEditScreen.refresh_property_list()
	current_character = storyworld.characters[0]
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen._on_AddButton_pressed() #Add at least on encounter to the storyworld.
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.refresh_encounter_list()
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.refresh_bnumber_property_lists()
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.refresh_character_lists()
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.Clear_Encounter_Editing_Screen()
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.load_and_focus_first_encounter()
	current_project_path = ""
	OS.set_window_title("Encounter Editor - " + storyworld.storyworld_title)
	refresh_settings_tab()
	refresh_statistical_overview()
	refresh_graphview()
	storyworld.project_saved = true

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
	$VBC/Menu.get_popup().connect("id_pressed", self, "_on_mainmenu_item_pressed")
	$About/VBoxContainer/VersionMessage.text = "SweepWeave v." + sweepweave_version_number
	$VBC/Bookspine/InterpreterTabs/Play/PlayScreen.connect("encounter_loaded", self, "load_Encounter_by_id")
	$VBC/Bookspine/EditorTabs/Characters/CharacterEditScreen.connect("new_character_created", $VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen, "add_character_to_lists")
	$VBC/Bookspine/EditorTabs/Characters/CharacterEditScreen.connect("character_deleted", $VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen, "replace_character")
	$VBC/Bookspine/EditorTabs/Characters/CharacterEditScreen.connect("character_name_changed", self, "on_character_name_changed")
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.connect("refresh_graphview", self, "refresh_graphview")

#GUI Functions

func _notification(what):
	if (what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		if(false == storyworld.project_saved):
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
		if(false == storyworld.project_saved):
			$ConfirmOpenWhenUnsaved.popup()
		else:
			$LoadFileDialog.popup()

func log_update(encounter = null):
	#If encounter == wild_encounter, then the project as a whole is being updated, rather than a specific encounter, or an encounter has been added, deleted, or duplicated.
	if (null != encounter):
		encounter.log_update()
	storyworld.log_update()
	OS.set_window_title("Encounter Editor - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false

func _on_mainmenu_item_pressed(id):
	var item_name = $VBC/Menu.get_popup().get_item_text(id)
	if ("About" == item_name):
		$About.popup()
	elif ("New Storyworld" == item_name):
		if(false == storyworld.project_saved):
			$ConfirmNewStoryworld.popup()
		else:
			new_storyworld()
	elif ("Open" == item_name):
		if(false == storyworld.project_saved):
			$ConfirmOpenWhenUnsaved.popup()
		else:
			$LoadFileDialog.popup()
	elif ("Import from Storyworld" == item_name):
		$ImportFromStoryworldFileDialog.popup()
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
		open_after_compiling = false
		$CompileFileDialog.popup()
	elif ("Compile and Playtest" == item_name):
		open_after_compiling = true
		$CompileFileDialog.popup()
	elif ("Playtest" == item_name):
		playtest()
	elif ("Quit" == item_name):
		if(false == storyworld.project_saved):
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
	storyworld.compile_to_html(path)
	if (open_after_compiling):
		print("Opening file in webbrowser for playtesting: " + path)
		OS.shell_open("file:///" + path)

func playtest():
	storyworld.compile_to_html("user://SW_playtests/playtest.html")
	var test_path = ProjectSettings.globalize_path("user://SW_playtests/playtest.html")
	print("Playtesting: file:///" + test_path)
	OS.shell_open("file:///" + test_path)

#func _on_LineEdit_text_changed(new_text):
#	#Change encounter title
#	if (null != current_encounter):
#		current_encounter.title = new_text
#		update_wordcount(current_encounter)
#		log_update(current_encounter)
#		refresh_encounter_list()
#		refresh_graphview()
#
#func _on_TextEdit_text_changed():
#	#Change encounter main text
#	if (null != current_encounter):
#		current_encounter.main_text = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/TextEdit.text
#		update_wordcount(current_encounter)
#		log_update(current_encounter)
#		refresh_graphview()
#
#func _on_ConfirmEncounterDeletion_confirmed():
#	var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.get_selected_items()
#	var selected_encounters = []
#	for each in selection:
#		selected_encounters.append(storyworld.encounters[each])
#	for each in selected_encounters:
#		storyworld.delete_encounter(each)
#	log_update(null)
#	refresh_encounter_list()
#	refresh_graphview()
#
#func _on_DeleteButton_pressed():
#	if ($VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.is_anything_selected()):
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.get_selected_items()
#		var selected_encounters = []
#		for each in selection:
#			selected_encounters.append(storyworld.encounters[each])
#		if (0 == selected_encounters.size()):
#			$CannotDelete.dialog_text = 'No encounters can be deleted.'
#			$CannotDelete.popup()
#		else:
#			var dialog_text = 'Are you sure you wish to delete the following encounter(s)?'
#			for each in selected_encounters:
#				dialog_text += " (" + each.title + ")"
#			$ConfirmEncounterDeletion.dialog_text = dialog_text
#			$ConfirmEncounterDeletion.popup()
#
#func _on_PrereqAdd_pressed():
#	refresh_event_selection()
#	$EditEncounterSettings/EventSelection.popup()
#
#func _on_PrereqDelete_pressed():
#	if ($EditEncounterSettings/VBC/HBC/VBC/Scroll/PrerequisiteList.is_anything_selected()):
#		var selection = $EditEncounterSettings/VBC/HBC/VBC/Scroll/PrerequisiteList.get_selected_items()
#		var selected_prerequisites = []
#		for each in selection:
#			selected_prerequisites.append(current_encounter.prerequisites[each])
#		for each in selected_prerequisites:
#			current_encounter.prerequisites.erase(each)
#		$EditEncounterSettings/VBC/HBC/VBC/Scroll/PrerequisiteList.clear()
#		for entry in current_encounter.prerequisites:
#			$EditEncounterSettings/VBC/HBC/VBC/Scroll/PrerequisiteList.add_item(entry.summarize())
#		log_update(current_encounter)
#
#func _on_EarliestTurn_value_changed(value):
#	if (null != current_encounter):
##		current_encounter.earliest_turn = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC/EarliestTurn.value
#		current_encounter.earliest_turn = value
#		log_update(current_encounter)
#
#func _on_LatestTurn_value_changed(value):
#	if (null != current_encounter):
##		current_encounter.latest_turn = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC2/LatestTurn.value
#		current_encounter.latest_turn = value
#		log_update(current_encounter)
#
#func _on_AntagonistPicker_item_selected(index):
#	if (null != current_encounter):
#		current_encounter.antagonist = storyworld.characters[index]
#		log_update(current_encounter)



#Character Edit Interface Elements:

#func replace_character(deleted_character, replacement):
#	print("Replacing " + deleted_character.char_name + " with " + replacement.char_name)
#	for encounter in storyworld.encounters:
#		for desid in encounter.desiderata:
#			if (desid.character == deleted_character):
#				desid.character = replacement
#				log_update(encounter)
#		if (encounter.antagonist == deleted_character):
#			encounter.antagonist = replacement
#			log_update(encounter)
#	storyworld.characters.erase(deleted_character)
#	deleted_character.call_deferred("free")
#	log_update(null)
#	refresh_character_list()
#
#func add_character_to_lists(character):
#	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC3/AntagonistPicker.add_item(character.char_name)
#	$pValueChangeSelection/VBC/HBC/CharacterSelect.add_item(character.char_name)

#Options and Reactions interface elements:

#func _on_AddOption_pressed():
#	if (null != current_encounter):
#		current_option = Option.new(current_encounter, "What does the user do?")
#		var new_reaction = Reaction.new(current_option, "How does the antagonist respond?", {"character": storyworld.characters[0], "pValue": "Bad_Good", "point": 1}, {"character": storyworld.characters[0], "pValue": "False_Honest", "point": 1}, 0)
#		current_option.reactions.append(new_reaction)
#		current_encounter.options.append(current_option)
#		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.add_item(current_option.text)
#		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.select($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_item_count() - 1)
#		load_Option(current_option)
#		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(0)
#		update_wordcount(current_encounter)
#		log_update(current_encounter)
#
#func _on_ConfirmOptionDeletion_confirmed():
#	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
#		var option_to_delete = current_encounter.options[selection[0]]
#		print("Deleting option: " + option_to_delete.text.left(10))
#		for encounter in storyworld.encounters:
#			for prereq in encounter.prerequisites:
#				if (prereq.option == option_to_delete):
#					prereq.option = null
#					log_update(encounter)
#		current_encounter.options.erase(option_to_delete)
#		option_to_delete.call_deferred("free")
#		refresh_option_list()
#		if (0 < current_encounter.options.size()):
#			current_option = current_encounter.options[0]
#			$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.select(0)
#			load_Option(current_option)
#		update_wordcount(current_encounter)
#		log_update(current_encounter)
#		refresh_graphview()
#
#func _on_DeleteOption_pressed():
#	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
#		var dialog_text = "Are you sure you wish to delete the option: \""
#		dialog_text += current_encounter.options[selection[0]].text + "\"?"
#		$ConfirmOptionDeletion.dialog_text = dialog_text
#		$ConfirmOptionDeletion.popup()
#
#func _on_MoveOptionUpButton_pressed():
#	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
#		if (0 == selection[0]):
#			#Cannot move option up any farther.
#			print("Cannot move option up any farther: " + current_encounter.options[selection[0]].text)
#		else:
#			print("Moving option up: " + current_encounter.options[selection[0]].text)
#			var swap = current_encounter.options[selection[0]]
#			current_encounter.options[selection[0]] = current_encounter.options[selection[0]-1]
#			current_encounter.options[selection[0]-1] = swap
#			refresh_option_list()
#			if (0 < current_encounter.options.size()):
#				current_option = current_encounter.options[selection[0]-1]
#				$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.select(selection[0]-1)
#				load_Option(current_option)
#				$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(0)
#				load_Reaction(current_option.reactions[0])
#			log_update(current_encounter)
#
#func _on_MoveOptionDownButton_pressed():
#	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
#		if ((current_encounter.options.size()-1) == selection[0]):
#			#Cannot move option down any farther.
#			print("Cannot move option down any farther: " + current_encounter.options[selection[0]].text)
#		else:
#			print("Moving option down: " + current_encounter.options[selection[0]].text)
#			var swap = current_encounter.options[selection[0]]
#			current_encounter.options[selection[0]] = current_encounter.options[selection[0]+1]
#			current_encounter.options[selection[0]+1] = swap
#			refresh_option_list()
#			if (0 < current_encounter.options.size()):
#				current_option = current_encounter.options[selection[0]+1]
#				$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.select(selection[0]+1)
#				load_Option(current_option)
#				$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(0)
#				load_Reaction(current_option.reactions[0])
#			log_update(current_encounter)
#
#func trait_index(trait_text):
#	match trait_text:
#		"Bad_Good":
#			return 0
#		"-Bad_Good":
#			return 1
#		"False_Honest":
#			return 2
#		"-False_Honest":
#			return 3
#		"Timid_Dominant":
#			return 4
#		"-Timid_Dominant":
#			return 5
#		"pBad_Good":
#			return 6
#		"-pBad_Good":
#			return 7
#		"pFalse_Honest":
#			return 8
#		"-pFalse_Honest":
#			return 9
#		"pTimid_Dominant":
#			return 10
#		"-pTimid_Dominant":
#			return 11
#		_:
#			return 0
#
#func _on_OptionsList_item_selected(index):
#	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
#		current_option = current_encounter.options[selection[0]]
#		load_Option(current_option)
#		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(0)
#		load_Reaction(current_option.reactions[0])
#
#func _on_OptionText_text_changed(new_text):
#	if (null != current_option):
#		current_option.text = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionText.text
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
#		var which = 0
#		if (0 < selection.size()):
#			which = selection[0]
#		refresh_option_list()
#		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/OptionsScroll/OptionsList.select(which)
#		update_wordcount(current_encounter)
#		log_update(current_encounter)
#
#func _on_AddReaction_pressed():
#	if (null != current_option):
#		current_reaction = Reaction.new(current_option, "How does the antagonist respond?", {"character": storyworld.characters[0], "pValue": "Bad_Good", "point": 1}, {"character": storyworld.characters[0], "pValue": "False_Honest", "point": 1}, 0)
#		current_option.reactions.append(current_reaction)
#		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.add_item(current_reaction.text.left(30) + "...")
#		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_item_count() - 1)
#		load_Reaction(current_reaction)
#		update_wordcount(current_encounter)
#		log_update(current_encounter)
#
#func _on_ConfirmReactionDeletion_confirmed():
#	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
#		current_reaction = current_option.reactions[selection[0]]
#		print("Deleting reaction: " + current_reaction.text.left(25))
#		for encounter in storyworld.encounters:
#			for prereq in encounter.prerequisites:
#				if (prereq.reaction == current_reaction):
#					prereq.reaction = null
#					log_update(encounter)
#		current_option.reactions.erase(current_reaction)
#		current_reaction.call_deferred("free")
#		load_Option(current_option)
#		current_reaction = current_option.reactions[0]
#		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(0)
#		load_Reaction(current_reaction)
#		update_wordcount(current_encounter)
#		log_update(current_encounter)
#		refresh_graphview()
#
#func _on_DeleteReaction_pressed():
#	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
#		if (1 < current_option.reactions.size()):
#			var dialog_text = "Are you sure you wish to delete the reaction: \""
#			dialog_text += current_option.reactions[selection[0]].text + "\"?"
#			$ConfirmReactionDeletion.dialog_text = dialog_text
#			$ConfirmReactionDeletion.popup()
#			log_update(current_encounter)
#		else:
#			print("Each option must have at least one reaction.")
#
#func _on_MoveReactionUpButton_pressed():
#	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
#		if (0 == selection[0]):
#			#Cannot move reaction up any farther.
#			print("Cannot move reaction up any farther: " + current_option.reactions[selection[0]].text)
#		else:
#			print("Moving reaction up: " + current_option.reactions[selection[0]].text)
#			var swap = current_option.reactions[selection[0]]
#			current_option.reactions[selection[0]] = current_option.reactions[selection[0]-1]
#			current_option.reactions[selection[0]-1] = swap
#			refresh_reaction_list()
#			if (0 < current_option.reactions.size()):
#				current_reaction = current_option.reactions[selection[0]-1]
#				$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(selection[0]-1)
#				load_Reaction(current_reaction)
#			log_update(current_encounter)
#
#func _on_MoveReactionDownButton_pressed():
#	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
#		if ((current_option.reactions.size()-1) == selection[0]):
#			#Cannot move reaction down any farther.
#			print("Cannot move reaction down any farther: " + current_option.reactions[selection[0]].text)
#		else:
#			print("Moving reaction down: " + current_option.reactions[selection[0]].text)
#			var swap = current_option.reactions[selection[0]]
#			current_option.reactions[selection[0]] = current_option.reactions[selection[0]+1]
#			current_option.reactions[selection[0]+1] = swap
#			refresh_reaction_list()
#			if (0 < current_option.reactions.size()):
#				current_reaction = current_option.reactions[selection[0]+1]
#				$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(selection[0]+1)
#				load_Reaction(current_reaction)
#			log_update(current_encounter)
#
#func _on_ReactionList_item_selected(index):
#	if ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
#		current_reaction = current_option.reactions[selection[0]]
#		load_Reaction(current_reaction)
#
#func _on_ReactionText_text_changed():
#	if (null != current_reaction):
#		current_reaction.text = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionText.text
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
#		var which = 0
#		if (0 < selection.size()):
#			which = selection[0]
#		refresh_reaction_list()
#		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/ReactionsScroll/ReactionList.select(which)
#		update_wordcount(current_encounter)
#		log_update(current_encounter)
#
#func _on_InclinationHSlider_value_changed(value):
#	if (null != current_reaction):
#		current_reaction.blend_weight = ($VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCLSL/InclinationHSlider.value / 100)
#		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/IncBlendWeightLabel.text = "Inclination blend weight: " + str(current_reaction.blend_weight)
#		log_update(current_encounter)
#
#func _on_Trait1_item_selected(index):
#	if (null != current_reaction):
#		var traits = ["Bad_Good", "-Bad_Good", "False_Honest", "-False_Honest", "Timid_Dominant", "-Timid_Dominant", "pBad_Good", "-pBad_Good", "pFalse_Honest", "-pFalse_Honest", "pTimid_Dominant", "-pTimid_Dominant"]
#		current_reaction.set_blend_x(traits[$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCTT/Trait1.get_selected_id()])
#		log_update(current_encounter)
#
#func _on_Trait2_item_selected(index):
#	if (null != current_reaction):
#		var traits = ["Bad_Good", "-Bad_Good", "False_Honest", "-False_Honest", "Timid_Dominant", "-Timid_Dominant", "pBad_Good", "-pBad_Good", "pFalse_Honest", "-pFalse_Honest", "pTimid_Dominant", "-pTimid_Dominant"]
#		current_reaction.set_blend_y(traits[$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCTT/Trait2.get_selected_id()])
#		log_update(current_encounter)
#
#func _on_ChangeConsequence_pressed():
#	if (null != current_reaction):
#		var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/VScroll/EncountersList.get_selected_items()
#		if (storyworld.encounters[selection[0]] == current_encounter):
#			print("An encounter cannot serve as a consequence for itself.")
#		else:
#			current_reaction.consequence = storyworld.encounters[selection[0]]
#			$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCConsequence/CurrentConsequence.text = current_reaction.consequence.title
#			log_update(current_encounter)
#			refresh_graphview()
#
#func _on_RemoveConsequenceButton_pressed():
#	if (null != current_reaction):
#		current_reaction.consequence = null
#		$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/HBCConsequence/CurrentConsequence.text = current_reaction.consequence.title
#		log_update(current_encounter)
#		refresh_graphview()
#
#func _on_pValueChangeAdd_pressed():
#	if (null != current_reaction):
#		$pValueChangeSelection.popup()
#	else:
#		print("No reaction currently selected.")
#
#func _on_pValueChangeSelection_confirmed():
#	if (null != current_reaction):
#		var des_character_id = $pValueChangeSelection/VBC/HBC/CharacterSelect.get_selected_id()
#		var des_character = storyworld.characters[des_character_id]
#		var des_pValue_id = $pValueChangeSelection/VBC/HBC/pValueSelect.get_selected_id()
#		var des_pValue = $pValueChangeSelection/VBC/HBC/pValueSelect.get_item_text(des_pValue_id)
#		var des_point = $pValueChangeSelection/VBC/HBC/PointSet.value
#		var new_pValueChange = Desideratum.new(des_character, des_pValue, des_point)
#		current_reaction.pValue_changes.append(new_pValueChange)
#		refresh_pValue_Change_List()
#		log_update(current_encounter)
#	else:
#		print("No reaction currently selected.")
#
#func _on_pValueChangeDelete_pressed():
#	var selection = $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/pValueChangeList.get_selected_items()
#	if (0 < selection.size()):
#		var change_to_delete = current_reaction.pValue_changes[selection[0]]
#		current_reaction.pValue_changes.erase(change_to_delete)
#		refresh_pValue_Change_List()
#
#func refresh_pValue_Change_List():
#	$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/pValueChangeList.clear()
#	if (null != current_reaction):
#		for change in current_reaction.pValue_changes:
#			$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/pValueChangeList.add_item(change.explain_pValue_change())
#		if (0 != $VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/pValueChangeList.get_item_count()):
#			$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column3/pValueChangeList.select(0)

#Settings tab interface elements:
func _on_TitleEdit_text_changed(new_text):
	storyworld.storyworld_title = $VBC/Bookspine/EditorTabs/Settings/VBC/TitleEdit.text
	log_update(null)

func _on_AuthorEdit_text_changed(new_text):
	storyworld.storyworld_author = $VBC/Bookspine/EditorTabs/Settings/VBC/AuthorEdit.text
	log_update(null)

func _on_DBMSwitch_toggled(button_pressed):
	if (button_pressed):
		storyworld.storyworld_debug_mode_on = true
	else:
		storyworld.storyworld_debug_mode_on = false
	log_update(null)

func _on_DisplayModeSwitch_toggled(button_pressed):
	if (button_pressed):
		storyworld.storyworld_display_mode = 1
	else:
		storyworld.storyworld_display_mode = 0
	log_update(null)


#Statistical Overview interface elements.
func refresh_statistical_overview():
	var sum_options = 0
	var sum_reactions = 0
	var sum_words = 0
	var earliest_turn = 0
	var latest_turn = 0
	var regex = RegEx.new()
	regex.compile("\\S+") # Negated whitespace character class.
	for x in storyworld.encounters:
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
	for x in storyworld.characters:
		sum_words += regex.search_all(x.char_name).size()
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatEncounters.text = "Total number of encounters: " + str(storyworld.encounters.size())
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatOptions.text = "Total number of options: " + str(sum_options)
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatReactions.text = "Total number of reactions: " + str(sum_reactions)
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatCharacters.text = "Total number of characters: " + str(storyworld.characters.size())
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatWords.text = "Total number of words: " + str(sum_words)
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatEarliestTurn.text = "Earliest Turn: " + str(earliest_turn)
	$VBC/Bookspine/InterpreterTabs/Statistics/VBC/StatLatestTurn.text = "Latest Turn: " + str(latest_turn)

func _on_RefreshStats_pressed():
	refresh_statistical_overview()

#func update_wordcount(encounter):
#	#In order to try to avoid sluggishness, we only do this if sort_by is set to word count or rev. word count.
#	var sort_method_id = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/SortMenu.get_selected_id()
#	var sort_method = $VBC/Bookspine/EditorTabs/Encounters/Main/Column1/SortMenu.get_popup().get_item_text(sort_method_id)
#	if ("Word Count" == sort_method || "Rev. Word Count" == sort_method):
##		encounter.word_count = wordcount(encounter)
#		var word_count = encounter.wordcount()
#		print("check. " + str(word_count))
#		log_update(encounter)
#		refresh_encounter_list()

#Graphview Functionality

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
			if (!(reaction.consequence == null)):
				$VBC/Bookspine/InterpreterTabs/GraphView/VBC/GraphEdit.connect_node(encounter_graph_node.get_name(), 1, reaction.consequence.graphview_node.get_name(), 1)

func clear_graphview():
	$VBC/Bookspine/InterpreterTabs/GraphView/VBC/GraphEdit.clear_connections()
	get_tree().call_group("graphview_nodes", "delete")

func refresh_graphview():
	clear_graphview()
	for each in storyworld.encounters:
		load_encounter_in_graphview(each, 0)
	for each in storyworld.encounters:
		#Two passes are required to ensure that all nodes are loaded before attempting to load connections.
		load_connections_in_graphview(each, 0)

func _on_GraphEdit__end_node_move():
	get_tree().call_group("graphview_nodes", "save_position")

# Encounter settings interface elements.
#onready var event_selection_tree = get_node("EditEncounterSettings/EventSelection/VScrollBar/EventTree")
#onready var event_selection_tree = get_node("EditEncounterSettings/EventSelection/VBC/EventTree")
#
#func refresh_event_selection():
#	event_selection_tree.clear()
#	var root = event_selection_tree.create_item()
#	root.set_text(0, "Encounters: ")
#	for encounter in storyworld.encounters:
#		if (encounter != current_encounter):
#			var entry_e = event_selection_tree.create_item(root)
#			if ("" == encounter.title):
#				entry_e.set_text(0, "[Untitled]")
#			else:
#				entry_e.set_text(0, encounter.title)
#			entry_e.set_metadata(0, {"encounter": encounter, "option": null, "reaction": null})
#			for option in encounter.options:
#				var entry_o = event_selection_tree.create_item(entry_e)
#				entry_o.set_text(0, option.text)
#				entry_o.set_metadata(0, {"encounter": encounter, "option": option, "reaction": null})
#				for reaction in option.reactions:
#					var entry_r = event_selection_tree.create_item(entry_o)
#					entry_r.set_text(0, reaction.text)
#					entry_r.set_metadata(0, {"encounter": encounter, "option": option, "reaction": reaction})
#
#func _on_Edit_Encounter_Settings_Button_pressed():
#	if (null != current_encounter):
#		refresh_encounter_settings_screen()
#		refresh_event_selection()
#		$EditEncounterSettings.popup()
#	else:
#		print("You must open an encounter before you can edit its settings.")
#
#func _on_EventSelection_confirmed():
#	var event = event_selection_tree.get_selected()
#	if(null != event && null != event.get_metadata(0)):
#		var metadata = event.get_metadata(0)
#		var encounter = metadata["encounter"]
#		var option = metadata["option"]
#		var reaction = metadata["reaction"]
#		var option_index = ""
#		if (null != option):
#			option_index = " / " + str(option.get_index())
#		var reaction_index = ""
#		if (null != reaction):
#			reaction_index = " / " + str(reaction.get_index())
#		print ("Adding prerequisite for encounter: " + current_encounter.title)
#		print ("Prerequisite: " + encounter.title + option_index + reaction_index)
#		#Add an event prerequisite to the current encounter.
#		var new_prereq_negated = $EditEncounterSettings/EventSelection/VBC/NegatedCheckBox.is_pressed()
#		var new_prerequisite = Prerequisite.new(0, new_prereq_negated)
#		new_prerequisite.encounter = encounter
#		new_prerequisite.option = option
#		new_prerequisite.reaction = reaction
#		current_encounter.prerequisites.append(new_prerequisite)
#		log_update(current_encounter)
#		refresh_encounter_settings_screen()
#
#func refresh_encounter_settings_screen():
#	$EditEncounterSettings.window_title = current_encounter.title + " Settings"
#	$EditEncounterSettings/VBC/HBC/VBC/Scroll/PrerequisiteList.clear()
#	$EditEncounterSettings/VBC/HBC/VBC2/Scroll/DesiderataList.clear()
#	for each in current_encounter.prerequisites:
#		$EditEncounterSettings/VBC/HBC/VBC/Scroll/PrerequisiteList.add_item(each.summarize())
#	for each in current_encounter.desiderata:
#		$EditEncounterSettings/VBC/HBC/VBC2/Scroll/DesiderataList.add_item(each.summarize())
#
#func _on_AddDesideratum_pressed():
#	refresh_character_list()
#	$EditEncounterSettings/DesideratumSelection.popup()
#
#func _on_DesideratumSelection_confirmed():
#	var des_character_id = $EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.get_selected_id()
#	var des_character = storyworld.characters[des_character_id]
#	var des_pValue_id = $EditEncounterSettings/DesideratumSelection/HBC/pValueSelect.get_selected_id()
#	var des_pValue = $EditEncounterSettings/DesideratumSelection/HBC/pValueSelect.get_item_text(des_pValue_id)
#	var des_point = $EditEncounterSettings/DesideratumSelection/HBC/PointSet.value
#	var new_desideratum = Desideratum.new(des_character, des_pValue, des_point)
#	current_encounter.desiderata.append(new_desideratum)
#	log_update(current_encounter)
#	refresh_encounter_settings_screen()
#
#func _on_DeleteDesideratum_pressed():
#	if ($EditEncounterSettings/VBC/HBC/VBC2/Scroll/DesiderataList.is_anything_selected()):
#		var selection = $EditEncounterSettings/VBC/HBC/VBC2/Scroll/DesiderataList.get_selected_items()
#		var selected_desiderata = []
#		for each in selection:
#			selected_desiderata.append(current_encounter.desiderata[each])
#		for each in selected_desiderata:
#			current_encounter.desiderata.erase(each)
#		$EditEncounterSettings/VBC/HBC/VBC2/Scroll/DesiderataList.clear()
#		for entry in current_encounter.desiderata:
#			$EditEncounterSettings/VBC/HBC/VBC2/Scroll/DesiderataList.add_item(entry.summarize())
#		log_update(current_encounter)


#Option Settings Interface Elements
#onready var option_event_select = get_node("EditOptionSettings/EventSelection/VBC/EventTree")
#
#func refresh_option_event_selection(list):
#	option_event_select.clear()
#	var root = option_event_select.create_item()
#	root.set_text(0, "Encounters: ")
#	root.set_metadata(0, list)
#	for encounter in storyworld.encounters:
#		if (encounter != current_encounter):
#			var entry_e = option_event_select.create_item(root)
#			if ("" == encounter.title):
#				entry_e.set_text(0, "[Untitled]")
#			else:
#				entry_e.set_text(0, encounter.title)
#			entry_e.set_metadata(0, {"encounter": encounter, "option": null, "reaction": null})
#			for option in encounter.options:
#				var entry_o = option_event_select.create_item(entry_e)
#				entry_o.set_text(0, option.text)
#				entry_o.set_metadata(0, {"encounter": encounter, "option": option, "reaction": null})
#				for reaction in option.reactions:
#					var entry_r = option_event_select.create_item(entry_o)
#					entry_r.set_text(0, reaction.text)
#					entry_r.set_metadata(0, {"encounter": encounter, "option": option, "reaction": reaction})
#
#func refresh_option_settings_screen():
#	$EditOptionSettings.window_title = current_option.text + " Settings"
#	$EditOptionSettings/VBC/HBC/VBC/Scroll/VisibilityPrerequisiteList.clear()
#	$EditOptionSettings/VBC/HBC/VBC2/Scroll/PerformabilityPrerequisiteList.clear()
#	for each in current_option.visibility_prerequisites:
#		$EditOptionSettings/VBC/HBC/VBC/Scroll/VisibilityPrerequisiteList.add_item(each.summarize())
#	for each in current_option.performability_prerequisites:
#		$EditOptionSettings/VBC/HBC/VBC2/Scroll/PerformabilityPrerequisiteList.add_item(each.summarize())
#
#func _on_OptionSettingsButton_pressed():
#	if (null != current_option):
#		refresh_option_settings_screen()
#		$EditOptionSettings.popup()
#
#func _on_VisibilityPrereqAdd_pressed():
#	if (null != current_option):
#		refresh_option_event_selection("visibility")
#		$EditOptionSettings/EventSelection.popup()
#
#func _on_PerformabilityPrereqAdd_pressed():
#	if (null != current_option):
#		refresh_option_event_selection("performability")
#		$EditOptionSettings/EventSelection.popup()
#
#func _on_OptionEventSelection_confirmed():
#	var event = option_event_select.get_selected()
#	if(null != event && null != event.get_metadata(0) && null != current_option):
#		var metadata = event.get_metadata(0)
#		var encounter = metadata["encounter"]
#		var option = metadata["option"]
#		var reaction = metadata["reaction"]
#		var option_index = ""
#		if (null != option):
#			option_index = " / " + str(option.get_index())
#		var reaction_index = ""
#		if (null != reaction):
#			reaction_index = " / " + str(reaction.get_index())
#		print ("Adding prerequisite for option: " + current_encounter.title + " / " + current_option.text)
#		print ("Prerequisite: " + encounter.title + option_index + reaction_index)
#		#Add an event prerequisite to the current option.
#		var new_prereq_negated = $EditOptionSettings/EventSelection/VBC/NegatedCheckBox.is_pressed()
#		var new_prerequisite = Prerequisite.new(0, new_prereq_negated)
#		new_prerequisite.encounter = encounter
#		new_prerequisite.option = option
#		new_prerequisite.reaction = reaction
#		var list = option_event_select.get_root().get_metadata(0)
#		if ("visibility" == list):
#			current_option.visibility_prerequisites.append(new_prerequisite)
#		else:
#			current_option.performability_prerequisites.append(new_prerequisite)
#		log_update(current_encounter)
#		refresh_option_settings_screen()
#
#func _on_VisibilityPrereqDelete_pressed():
#	if ($EditOptionSettings/VBC/HBC/VBC/Scroll/VisibilityPrerequisiteList.is_anything_selected()):
#		var selection = $EditOptionSettings/VBC/HBC/VBC/Scroll/VisibilityPrerequisiteList.get_selected_items()
#		var selected_prerequisites = []
#		for each in selection:
#			selected_prerequisites.append(current_option.visibility_prerequisites[each])
#		for each in selected_prerequisites:
#			current_option.visibility_prerequisites.erase(each)
#		$EditOptionSettings/VBC/HBC/VBC/Scroll/VisibilityPrerequisiteList.clear()
#		for entry in current_option.visibility_prerequisites:
#			$EditOptionSettings/VBC/HBC/VBC/Scroll/VisibilityPrerequisiteList.add_item(entry.summarize())
#		log_update(current_encounter)
#
#func _on_PerformabilityPrereqDelete_pressed():
#	if ($EditOptionSettings/VBC/HBC/VBC2/Scroll/PerformabilityPrerequisiteList.is_anything_selected()):
#		var selection = $EditOptionSettings/VBC/HBC/VBC2/Scroll/PerformabilityPrerequisiteList.get_selected_items()
#		var selected_prerequisites = []
#		for each in selection:
#			selected_prerequisites.append(current_option.performability_prerequisites[each])
#		for each in selected_prerequisites:
#			current_option.performability_prerequisites.erase(each)
#		$EditOptionSettings/VBC/HBC/VBC2/Scroll/PerformabilityPrerequisiteList.clear()
#		for entry in current_option.performability_prerequisites:
#			$EditOptionSettings/VBC/HBC/VBC2/Scroll/PerformabilityPrerequisiteList.add_item(entry.summarize())
#		log_update(current_encounter)










var rehearsal_test = null
var rehearsal_time_start = 0
#var rehearsal_time_end = 0

func rehearse():
	if (true == $VBC/Bookspine/InterpreterTabs/Statistics/VBC/Test_Rehearsal_Button.pressed):
		if (null == rehearsal_test):
			rehearsal_time_start = OS.get_unix_time()
			rehearsal_test = Rehearsal.new(storyworld)
			$VBC/Bookspine/InterpreterTabs/Statistics/VBC.add_child(rehearsal_test.history)
			rehearsal_test.history.rect_min_size.x = 256
			rehearsal_test.history.rect_min_size.y = 256
		var rehearsal_complete = rehearsal_test.rehearse_depth_first()
		if (rehearsal_complete):
			$VBC/Bookspine/InterpreterTabs/Statistics/VBC/Test_Rehearsal_Button.pressed = false
			var rehearsal_time_end = OS.get_unix_time()
			var elapsed = rehearsal_time_end - rehearsal_time_start
			var minutes = elapsed / 60
			var seconds = elapsed % 60
			var str_elapsed = "%02d : %02d" % [minutes, seconds]
			print("Time elapsed : ", str_elapsed)
			$VBC/Bookspine/InterpreterTabs/Statistics/VBC/Occurrences.clear()
			var root = $VBC/Bookspine/InterpreterTabs/Statistics/VBC/Occurrences.create_item()
			for encounter in rehearsal_test.storyworld.encounters:
				var encounter_branch = $VBC/Bookspine/InterpreterTabs/Statistics/VBC/Occurrences.create_item(root)
				var text = encounter.title + " (" + str(encounter.occurrences) + ")"
				encounter_branch.set_text(0, text)
				for option in encounter.options:
					var option_branch = $VBC/Bookspine/InterpreterTabs/Statistics/VBC/Occurrences.create_item(encounter_branch)
					text = option.text.left(10) + " (" + str(option.occurrences) + ")"
					option_branch.set_text(0, text)
					for reaction in option.reactions:
						var reaction_branch = $VBC/Bookspine/InterpreterTabs/Statistics/VBC/Occurrences.create_item(option_branch)
						text = reaction.text.left(10) + " (" + str(reaction.occurrences) + ")"
						reaction_branch.set_text(0, text)

func _on_Test_Rehearsal_Button_pressed():
	pass

func _process(delta):
	rehearse()


func _on_ImportFromStoryworldFileDialog_file_selected(path):
	$ConfirmImport/Margin/StoryworldMergingScreen.file_paths = [path]
	$ConfirmImport/Margin/StoryworldMergingScreen.clear_data()
	$ConfirmImport/Margin/StoryworldMergingScreen.load_content_from_files()
	$ConfirmImport.popup()

func _on_ImportFromStoryworldFileDialog_files_selected(paths):
	$ConfirmImport/Margin/StoryworldMergingScreen.file_paths = paths
	$ConfirmImport/Margin/StoryworldMergingScreen.clear_data()
	$ConfirmImport/Margin/StoryworldMergingScreen.load_content_from_files()
	$ConfirmImport.popup()

func _on_ConfirmImport_confirmed():
	storyworld.import_characters($ConfirmImport/Margin/StoryworldMergingScreen.get_selected_characters())
	$VBC/Bookspine/EditorTabs/Characters/CharacterEditScreen.refresh_character_list()
	storyworld.import_encounters($ConfirmImport/Margin/StoryworldMergingScreen.get_selected_encounters())
	$VBC/Bookspine/EditorTabs/Encounters/EncounterEditScreen.refresh_encounter_list()
