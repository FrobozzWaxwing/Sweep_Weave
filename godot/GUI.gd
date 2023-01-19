extends Control

var current_project_path = ""
var current_html_template_path = "res://custom_resources/encounter_engine.html"
var open_after_compiling = false
var sweepweave_version_number = "0.0.34"
var storyworld = null

func on_character_name_changed(character):
	$VBC/EditorTabs/Encounters/EncounterEditScreen.refresh_character_names()

#File Management

func load_project(file_text):
	storyworld.load_from_json(file_text)
	storyworld.sweepweave_version_number = sweepweave_version_number
	$VBC/EditorTabs/Encounters/EncounterEditScreen.refresh_encounter_list()
	$VBC/EditorTabs/Encounters/EncounterEditScreen.Clear_Encounter_Editing_Screen()
	$VBC/EditorTabs/Encounters/EncounterEditScreen.refresh_bnumber_property_lists()
	$VBC/EditorTabs/Encounters/EncounterEditScreen.load_and_focus_first_encounter()
	$VBC/EditorTabs/Characters/CharacterEditScreen.refresh_character_list()
	if (0 < storyworld.characters.size()):
		$VBC/EditorTabs/Characters/CharacterEditScreen.load_character(storyworld.characters[0])
	$VBC/EditorTabs/Spools/SpoolEditScreen.refresh()
	$VBC/EditorTabs/Settings/SettingsEditScreen.refresh()
	$VBC/EditorTabs/GraphView/GraphViewScreen.refresh_graphview()
	$VBC/EditorTabs/PersonalityModel/AuthoredPropertyCreationScreen.refresh_property_list()
	if (0 < storyworld.authored_properties.size()):
		$VBC/EditorTabs/PersonalityModel/AuthoredPropertyCreationScreen.load_authored_property(storyworld.authored_properties[0])
	$VBC/EditorTabs/Overview/EncounterOverviewScreen.refresh()
	$VBC/EditorTabs/Play/PlayScreen.clear()
	$StoryworldTroubleshooting/StoryworldValidationInterface.refresh()
	storyworld.project_saved = true
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title)

func save_project(save_as = false):
	storyworld.save_project(current_project_path, save_as)
	storyworld.project_saved = true
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title)
	$VBC/EditorTabs/Encounters/EncounterEditScreen.refresh_encounter_list()

# Functions to import from Chris Crawford's XML format

#func _on_ImportXMLFileDialog_file_selected(path):
#	pass # 

# On Startup

func new_storyworld():
	if (null == storyworld):
		storyworld = Storyworld.new("New Storyworld", "Anonymous", sweepweave_version_number)
		$VBC/EditorTabs/Overview/EncounterOverviewScreen.storyworld = storyworld
		$VBC/EditorTabs/Encounters/EncounterEditScreen.storyworld = storyworld
		$VBC/EditorTabs/Characters/CharacterEditScreen.storyworld = storyworld
		$VBC/EditorTabs/Spools/SpoolEditScreen.storyworld = storyworld
		$VBC/EditorTabs/Settings/SettingsEditScreen.storyworld = storyworld
		$Summary/Statistics.storyworld = storyworld
		$VBC/EditorTabs/GraphView/GraphViewScreen.storyworld = storyworld
		$VBC/EditorTabs/Play/PlayScreen.reference_storyworld = storyworld
		$VBC/EditorTabs/PersonalityModel/AuthoredPropertyCreationScreen.storyworld = storyworld
		$StoryworldTroubleshooting/StoryworldValidationInterface.storyworld = storyworld
	else:
		storyworld.clear()
		storyworld.sweepweave_version_number = sweepweave_version_number
	#Initiate personality / relationship model.
	storyworld.init_classical_personality_model()
	#Add at least one character to the storyworld.
	var new_character = storyworld.create_default_character()
	storyworld.add_character(new_character)
	new_character.initialize_bnumber_properties(storyworld.characters, storyworld.authored_properties)
	$VBC/EditorTabs/Characters/CharacterEditScreen.log_update(new_character)
	$VBC/EditorTabs/Characters/CharacterEditScreen.refresh_character_list()
	$VBC/EditorTabs/Characters/CharacterEditScreen.load_character(new_character)
	$VBC/EditorTabs/Characters/CharacterEditScreen.refresh_property_list()
	$VBC/EditorTabs/Encounters/EncounterEditScreen._on_AddButton_pressed() #Add at least one encounter to the storyworld.
	$VBC/EditorTabs/Encounters/EncounterEditScreen.refresh_encounter_list()
	$VBC/EditorTabs/Encounters/EncounterEditScreen.refresh_bnumber_property_lists()
	$VBC/EditorTabs/Encounters/EncounterEditScreen.Clear_Encounter_Editing_Screen()
	$VBC/EditorTabs/Encounters/EncounterEditScreen.load_and_focus_first_encounter()
	$VBC/EditorTabs/Spools/SpoolEditScreen._on_AddButton_pressed() #Add at least one spool to the storyworld.
	#Add encounter to spool.
	storyworld.spools.front().encounters.append(storyworld.encounters.front())
	storyworld.encounters.front().connected_spools.append(storyworld.spools.front())
	$VBC/EditorTabs/Spools/SpoolEditScreen.refresh()
	$VBC/EditorTabs/Overview/EncounterOverviewScreen.refresh()
	$VBC/EditorTabs/Settings/SettingsEditScreen.refresh()
	$VBC/EditorTabs/GraphView/GraphViewScreen.refresh_graphview()
	$VBC/EditorTabs/PersonalityModel/AuthoredPropertyCreationScreen.refresh_property_list()
	if (0 < storyworld.authored_properties.size()):
		$VBC/EditorTabs/PersonalityModel/AuthoredPropertyCreationScreen.load_authored_property(storyworld.authored_properties[0])
	$VBC/EditorTabs/Play/PlayScreen.clear()
	$StoryworldTroubleshooting/StoryworldValidationInterface.refresh()
	current_project_path = ""
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title)
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
#	$VBC/EditorTabs/Play/PlayScreen.connect("encounter_loaded", self, "load_Encounter_by_id")
	$VBC/EditorTabs/Characters/CharacterEditScreen.connect("new_character_created", $VBC/EditorTabs/Encounters/EncounterEditScreen, "add_character_to_lists")
	$VBC/EditorTabs/Characters/CharacterEditScreen.connect("character_deleted", $VBC/EditorTabs/Encounters/EncounterEditScreen, "replace_character")
	$VBC/EditorTabs/Characters/CharacterEditScreen.connect("character_name_changed", self, "on_character_name_changed")
	$VBC/EditorTabs/Characters/CharacterEditScreen.connect("character_name_changed", self, "on_character_name_changed")
	$VBC/EditorTabs/Characters/CharacterEditScreen.connect("refresh_authored_property_lists", $VBC/EditorTabs/PersonalityModel/AuthoredPropertyCreationScreen, "refresh_property_list")
	$VBC/EditorTabs/Characters/CharacterEditScreen.connect("refresh_authored_property_lists", $VBC/EditorTabs/Encounters/EncounterEditScreen, "refresh_bnumber_property_lists")
	$VBC/EditorTabs/Encounters/EncounterEditScreen.connect("refresh_graphview", $VBC/EditorTabs/GraphView/GraphViewScreen, "refresh_graphview")
	$VBC/EditorTabs/Encounters/EncounterEditScreen.connect("refresh_encounter_list", $VBC/EditorTabs/Spools/SpoolEditScreen, "refresh")
	$VBC/EditorTabs/Encounters/EncounterEditScreen.connect("refresh_encounter_list", $VBC/EditorTabs/Overview/EncounterOverviewScreen, "refresh")
	$VBC/EditorTabs/Spools/SpoolEditScreen.connect("request_overview_change", $VBC/EditorTabs/Overview/EncounterOverviewScreen, "refresh")
	$VBC/EditorTabs/Spools/SpoolEditScreen.connect("request_overview_change", $VBC/EditorTabs/Encounters/EncounterEditScreen, "refresh_spool_lists")
	$VBC/EditorTabs/Overview/EncounterOverviewScreen.connect("encounter_load_requested", self, "display_encounter")
	$VBC/EditorTabs/Overview/EncounterOverviewScreen.connect("refresh_graphview", $VBC/EditorTabs/GraphView/GraphViewScreen, "refresh_graphview")
	$VBC/EditorTabs/Overview/EncounterOverviewScreen.connect("refresh_encounter_list", $VBC/EditorTabs/Spools/SpoolEditScreen, "refresh")
	$VBC/EditorTabs/Overview/EncounterOverviewScreen.connect("refresh_encounter_list", $VBC/EditorTabs/Encounters/EncounterEditScreen, "refresh_encounter_list")
	$VBC/EditorTabs/GraphView/GraphViewScreen.connect("load_encounter_from_graphview", self, "display_encounter")
	$VBC/EditorTabs/PersonalityModel/AuthoredPropertyCreationScreen.connect("refresh_authored_property_lists", $VBC/EditorTabs/Characters/CharacterEditScreen, "refresh_property_list")
	$VBC/EditorTabs/PersonalityModel/AuthoredPropertyCreationScreen.connect("refresh_authored_property_lists", $VBC/EditorTabs/Encounters/EncounterEditScreen, "refresh_bnumber_property_lists")

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
		$SaveAsFileDialog.invalidate()
		$SaveAsFileDialog.popup()
	elif event.is_action_pressed("project_save_overwrite"):
		print("Control + S pressed")
		if ("" != current_project_path):
			save_project()
		else:
			$SaveAsFileDialog.invalidate()
			$SaveAsFileDialog.popup()
	elif event.is_action_pressed("project_new"):
		print("Control + N pressed")
		if(false == storyworld.project_saved):
			$ConfirmNewStoryworld.popup()
		else:
			new_storyworld()
	elif event.is_action_pressed("project_load"):
		print("Control + O pressed")
		if(false == storyworld.project_saved):
			$ConfirmOpenWhenUnsaved.popup()
		else:
			$LoadFileDialog.invalidate()
			$LoadFileDialog.popup()

func log_update(encounter = null):
	#If encounter == wild_encounter, then the project as a whole is being updated, rather than a specific encounter, or an encounter has been added, deleted, or duplicated.
	if (null != encounter):
		encounter.log_update()
	storyworld.log_update()
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
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
			$LoadFileDialog.invalidate()
			$LoadFileDialog.popup()
	elif ("Import from Storyworld" == item_name):
		$ImportFromStoryworldFileDialog.invalidate()
		$ImportFromStoryworldFileDialog.popup()
	elif ("Import from XML" == item_name):
		$ImportXMLFileDialog.popup()
	elif ("Save" == item_name):
		if ("" != current_project_path):
			save_project()
		else:
			$SaveAsFileDialog.invalidate()
			$SaveAsFileDialog.popup()
	elif ("Save As" == item_name):
		$SaveAsFileDialog.invalidate()
		$SaveAsFileDialog.popup()
	elif ("Compile to HTML" == item_name):
		open_after_compiling = false
		$CompileFileDialog.invalidate()
		$CompileFileDialog.popup()
	elif ("Compile and Playtest" == item_name):
		open_after_compiling = true
		$CompileFileDialog.invalidate()
		$CompileFileDialog.popup()
	elif ("Summary" == item_name):
		$Summary/Statistics.refresh_statistical_overview()
		$Summary.popup()
	elif ("Validate and Troubleshoot" == item_name):
		$StoryworldTroubleshooting.popup()
	elif ("Quit" == item_name):
		if(false == storyworld.project_saved):
			$ConfirmQuit.popup()
		else:
			get_tree().quit()
#	print(item_name + " pressed")

func _on_OpenPatreonButton_pressed():
	#This button is in the "About" popup.
	OS.shell_open("https://www.patreon.com/sasha_fenn")

func _on_ConfirmNewStoryworld_confirmed():
	new_storyworld()

func _on_ConfirmOpenWhenUnsaved_confirmed():
	$LoadFileDialog.invalidate()
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




#var rehearsal_test = null
#var rehearsal_time_start = 0
##var rehearsal_time_end = 0
#
#func rehearse():
#	if (true == $VBC/EditorTabs/Statistics/VBC/Test_Rehearsal_Button.pressed):
#		if (null == rehearsal_test):
#			rehearsal_time_start = OS.get_unix_time()
#			rehearsal_test = Rehearsal.new(storyworld)
#			$VBC/EditorTabs/Statistics/VBC.add_child(rehearsal_test.history)
#			rehearsal_test.history.rect_min_size.x = 256
#			rehearsal_test.history.rect_min_size.y = 256
#		var rehearsal_complete = rehearsal_test.rehearse_depth_first()
#		if (rehearsal_complete):
#			$VBC/EditorTabs/Statistics/VBC/Test_Rehearsal_Button.pressed = false
#			var rehearsal_time_end = OS.get_unix_time()
#			var elapsed = rehearsal_time_end - rehearsal_time_start
#			var minutes = elapsed / 60
#			var seconds = elapsed % 60
#			var str_elapsed = "%02d : %02d" % [minutes, seconds]
#			print("Time elapsed : ", str_elapsed)
#			$VBC/EditorTabs/Statistics/VBC/Occurrences.clear()
#			var root = $VBC/EditorTabs/Statistics/VBC/Occurrences.create_item()
#			for encounter in rehearsal_test.storyworld.encounters:
#				var encounter_branch = $VBC/EditorTabs/Statistics/VBC/Occurrences.create_item(root)
#				var text = encounter.title + " (" + str(encounter.occurrences) + ")"
#				encounter_branch.set_text(0, text)
#				for option in encounter.options:
#					var option_branch = $VBC/EditorTabs/Statistics/VBC/Occurrences.create_item(encounter_branch)
#					text = option.get_text().left(10) + " (" + str(option.occurrences) + ")"
#					option_branch.set_text(0, text)
#					for reaction in option.reactions:
#						var reaction_branch = $VBC/EditorTabs/Statistics/VBC/Occurrences.create_item(option_branch)
#						text = reaction.get_text().left(10) + " (" + str(reaction.occurrences) + ")"
#						reaction_branch.set_text(0, text)
#
#func _on_Test_Rehearsal_Button_pressed():
#	pass
#
#func _process(delta):
#	rehearse()


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
	$VBC/EditorTabs/Characters/CharacterEditScreen.refresh_character_list()
	storyworld.import_encounters($ConfirmImport/Margin/StoryworldMergingScreen.get_selected_encounters())
	$VBC/EditorTabs/Encounters/EncounterEditScreen.refresh_encounter_list()

func display_encounter(encounter):
	$VBC/EditorTabs/Encounters/EncounterEditScreen.load_Encounter(encounter)
	if (null != encounter):
		$VBC/EditorTabs.set_current_tab(1)
