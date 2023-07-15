extends Control

var current_project_path = ""
var current_html_template_path = "res://custom_resources/encounter_engine.html"
var open_after_compiling = false

var sweepweave_version_number = "0.1.2"
var storyworld = null
var clipboard = Clipboard.new()

#Theme variables:
var theme_background_colors = {}
#Clarity:
onready var clarity_gradient_header = preload("res://custom_resources/gradient_header_texture_clarity.tres")
onready var clarity_theme = preload("res://custom_resources/clarity.tres")
#Lapis Lazuli:
onready var lapis_lazuli_gradient_header = preload("res://custom_resources/gradient_header_texture_lapis_lazuli.tres")
onready var lapis_lazuli_theme = preload("res://custom_resources/lapis_lazuli.tres")

func on_character_name_changed(character):
	$Background/VBC/EditorTabs/Encounters.refresh_character_names()

#File Management

func load_project(file_text):
	clipboard.clear()
	storyworld.load_from_json(file_text)
	storyworld.sweepweave_version_number = sweepweave_version_number
	$Background/VBC/EditorTabs/Encounters.refresh_encounter_list()
	$Background/VBC/EditorTabs/Encounters.Clear_Encounter_Editing_Screen()
	$Background/VBC/EditorTabs/Encounters.refresh_bnumber_property_lists()
	$Background/VBC/EditorTabs/Encounters.load_and_focus_first_encounter()
	$Background/VBC/EditorTabs/Characters.refresh_character_list()
	if (0 < storyworld.characters.size()):
		$Background/VBC/EditorTabs/Characters.load_character(storyworld.characters.front())
	$Background/VBC/EditorTabs/Spools.refresh()
	$Background/VBC/EditorTabs/Settings.refresh()
	$Background/VBC/EditorTabs/GraphView.refresh_graphview()
	$Background/VBC/EditorTabs/PersonalityModel.refresh_property_list()
	if (0 < storyworld.authored_properties.size()):
		$Background/VBC/EditorTabs/PersonalityModel.load_authored_property(storyworld.authored_properties.front())
	$Background/VBC/EditorTabs/Overview.refresh()
	$Background/VBC/EditorTabs/Play.clear()
	$StoryworldTroubleshooting/StoryworldValidationInterface.refresh()
	storyworld.project_saved = true
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title)

func save_project(save_as = false):
	storyworld.save_project(current_project_path, save_as)
	storyworld.project_saved = true
	$Background/VBC/EditorTabs/Settings/VBC/SavePathDisplay.set_text("Current project save path: " + current_project_path)
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title)
	$Background/VBC/EditorTabs/Encounters.refresh_encounter_list()

# On Startup

func new_storyworld():
	if (null == storyworld):
		storyworld = Storyworld.new("New Storyworld", "Anonymous", sweepweave_version_number)
		$Background/VBC/EditorTabs/Overview.storyworld = storyworld
		$Background/VBC/EditorTabs/Encounters.storyworld = storyworld
		$Background/VBC/EditorTabs/Characters.storyworld = storyworld
		$Background/VBC/EditorTabs/Spools.storyworld = storyworld
		$Background/VBC/EditorTabs/Settings.storyworld = storyworld
		$Summary/Statistics.storyworld = storyworld
		$Background/VBC/EditorTabs/GraphView.storyworld = storyworld
		$Background/VBC/EditorTabs/Play.reference_storyworld = storyworld
		$Background/VBC/EditorTabs/PersonalityModel.storyworld = storyworld
		$StoryworldTroubleshooting/StoryworldValidationInterface.storyworld = storyworld
		clipboard.storyworld = storyworld
	else:
		storyworld.clear()
		storyworld.sweepweave_version_number = sweepweave_version_number
	clipboard.clear()
	#Initiate personality / relationship model.
	storyworld.init_classical_personality_model()
	#Add at least one character to the storyworld.
	var first_character = storyworld.create_default_character()
	storyworld.add_character(first_character)
	first_character.initialize_bnumber_properties(storyworld.characters, storyworld.authored_properties)
	$Background/VBC/EditorTabs/Characters.log_update(first_character)
	$Background/VBC/EditorTabs/Characters.refresh_character_list()
	$Background/VBC/EditorTabs/Characters.load_character(first_character)
	$Background/VBC/EditorTabs/Characters.refresh_property_list()
	#Add at least one encounter to the storyworld.
	var first_encounter = storyworld.create_new_generic_encounter()
	storyworld.add_encounter(first_encounter)
	log_update(first_encounter)
	$Background/VBC/EditorTabs/Encounters.refresh_encounter_list()
	$Background/VBC/EditorTabs/Encounters.refresh_bnumber_property_lists()
	$Background/VBC/EditorTabs/Encounters.Clear_Encounter_Editing_Screen()
	$Background/VBC/EditorTabs/Encounters.load_and_focus_first_encounter()
	#Add at least one spool to the storyworld.
	$Background/VBC/EditorTabs/Spools._on_AddButton_pressed()
	#Add encounter to spool.
	storyworld.spools.front().encounters.append(storyworld.encounters.front())
	storyworld.encounters.front().connected_spools.append(storyworld.spools.front())
	$Background/VBC/EditorTabs/Spools.refresh()
	$Background/VBC/EditorTabs/Spools.load_and_focus_first_spool()
	$Background/VBC/EditorTabs/Overview.refresh()
	$Background/VBC/EditorTabs/Settings.refresh()
	$Background/VBC/EditorTabs/GraphView.refresh_graphview()
	$Background/VBC/EditorTabs/PersonalityModel.refresh_property_list()
	if (0 < storyworld.authored_properties.size()):
		$Background/VBC/EditorTabs/PersonalityModel.load_authored_property(storyworld.authored_properties[0])
	$Background/VBC/EditorTabs/Play.clear()
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
	$About.get_ok().set_text("Read MIT License")
	$About.get_cancel().set_text("Close")
	new_storyworld()
	$Background/VBC/MenuBar/FileMenu.get_popup().connect("id_pressed", self, "_on_filemenu_item_pressed")
	$Background/VBC/MenuBar/ViewMenu.get_popup().connect("id_pressed", self, "_on_viewmenu_item_pressed")
	$Background/VBC/MenuBar/ViewMenu.connect("menu_input", self, "_on_viewmenu_item_toggled")
	$Background/VBC/MenuBar/HelpMenu.get_popup().connect("id_pressed", self, "_on_helpmenu_item_pressed")
	$Background/VBC/EditorTabs/Play.connect("encounter_edit_button_pressed", self, "display_encounter_by_id")
	$Background/VBC/EditorTabs/Characters.connect("new_character_created", $Background/VBC/EditorTabs/Encounters, "add_character_to_lists")
	$Background/VBC/EditorTabs/Characters.connect("character_deleted", $Background/VBC/EditorTabs/Encounters, "replace_character")
	$Background/VBC/EditorTabs/Characters.connect("character_name_changed", self, "on_character_name_changed")
	$Background/VBC/EditorTabs/Characters.connect("refresh_authored_property_lists", $Background/VBC/EditorTabs/PersonalityModel, "refresh_property_list")
	$Background/VBC/EditorTabs/Characters.connect("refresh_authored_property_lists", $Background/VBC/EditorTabs/Encounters, "refresh_bnumber_property_lists")
	$Background/VBC/EditorTabs/Encounters.connect("refresh_graphview", $Background/VBC/EditorTabs/GraphView, "refresh_graphview")
	$Background/VBC/EditorTabs/Encounters.connect("refresh_encounter_list", $Background/VBC/EditorTabs/Spools, "refresh")
	$Background/VBC/EditorTabs/Encounters.connect("refresh_encounter_list", $Background/VBC/EditorTabs/Overview, "refresh")
	$Background/VBC/EditorTabs/Spools.connect("request_overview_change", $Background/VBC/EditorTabs/Overview, "refresh")
	$Background/VBC/EditorTabs/Spools.connect("request_overview_change", $Background/VBC/EditorTabs/Encounters, "refresh_spool_lists")
	$Background/VBC/EditorTabs/Overview.connect("encounter_load_requested", self, "display_encounter")
	$Background/VBC/EditorTabs/Overview.connect("refresh_graphview", $Background/VBC/EditorTabs/GraphView, "refresh_graphview")
	$Background/VBC/EditorTabs/Overview.connect("refresh_encounter_list", $Background/VBC/EditorTabs/Spools, "refresh")
	$Background/VBC/EditorTabs/Overview.connect("refresh_encounter_list", $Background/VBC/EditorTabs/Encounters, "refresh_encounter_list")
	$Background/VBC/EditorTabs/GraphView.connect("load_encounter_from_graphview", self, "display_encounter")
	$Background/VBC/EditorTabs/PersonalityModel.connect("refresh_authored_property_lists", $Background/VBC/EditorTabs/Characters, "refresh_property_list")
	$Background/VBC/EditorTabs/PersonalityModel.connect("refresh_authored_property_lists", $Background/VBC/EditorTabs/Encounters, "refresh_bnumber_property_lists")
	$About/VBC/VersionMessage.text = "SweepWeave v." + sweepweave_version_number
	$CheckForUpdates/UpdateScreen/VBC/VersionMessage.text = "Current SweepWeave version: " + sweepweave_version_number
	$CheckForUpdates/UpdateScreen.sweepweave_version_number = sweepweave_version_number
	$Background/VBC/EditorTabs.set_tab_title(4, "Personality Model")
	$Background/VBC/EditorTabs.set_tab_title(7, "Graph View")
	$Background/VBC/EditorTabs.set_current_tab(1)
	#Initialize clipboard:
	$Background/VBC/EditorTabs/Encounters.set_clipboard(clipboard)
	#Set GUI theme variables:
	theme_background_colors["Clarity"] = Color(0.882353, 0.882353, 0.882353)
	theme_background_colors["Lapis Lazuli"] = Color(0, 0.062745, 0.12549)
	set_gui_theme("Clarity")

#GUI Functions

func _notification(what):
	if (what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		if(false == storyworld.project_saved):
			$ConfirmQuit.popup_centered()
		else:
			get_tree().quit()

func _on_ConfirmQuit_confirmed():
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("project_save_as"):
		#This check must come before the Control + S check, otherwise Control + S will take precedence.
		print("Control + Alt + S pressed")
		$SaveAsFileDialog.invalidate()
		$SaveAsFileDialog.popup_centered()
	elif event.is_action_pressed("project_save_overwrite"):
		print("Control + S pressed")
		if ("" != current_project_path):
			save_project()
		else:
			$SaveAsFileDialog.invalidate()
			$SaveAsFileDialog.popup_centered()
	elif event.is_action_pressed("project_new"):
		print("Control + N pressed")
		if(false == storyworld.project_saved):
			$ConfirmNewStoryworld.popup_centered()
		else:
			new_storyworld()
	elif event.is_action_pressed("project_load"):
		print("Control + O pressed")
		if(false == storyworld.project_saved):
			$ConfirmOpenWhenUnsaved.popup_centered()
		else:
			$LoadFileDialog.invalidate()
			$LoadFileDialog.popup_centered()

func log_update(encounter = null):
	#If encounter == wild_encounter, then the project as a whole is being updated, rather than a specific encounter, or an encounter has been added, deleted, or duplicated.
	if (null != encounter):
		encounter.log_update()
	storyworld.log_update()
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false

func _on_filemenu_item_pressed(id):
	var item_name = $Background/VBC/MenuBar/FileMenu.get_popup().get_item_text(id)
	if ("New Storyworld" == item_name):
		if(false == storyworld.project_saved):
			$ConfirmNewStoryworld.popup_centered()
		else:
			new_storyworld()
	elif ("Open" == item_name):
		if(false == storyworld.project_saved):
			$ConfirmOpenWhenUnsaved.popup_centered()
		else:
			$LoadFileDialog.invalidate()
			$LoadFileDialog.popup_centered()
	elif ("Import from Storyworld" == item_name):
		$ImportFromStoryworldFileDialog.invalidate()
		$ImportFromStoryworldFileDialog.popup_centered()
	elif ("Save" == item_name):
		if ("" != current_project_path):
			save_project()
		else:
			$SaveAsFileDialog.invalidate()
			$SaveAsFileDialog.popup_centered()
	elif ("Save As" == item_name):
		$SaveAsFileDialog.invalidate()
		$SaveAsFileDialog.popup_centered()
	elif ("Compile to HTML" == item_name):
		open_after_compiling = false
		$CompileFileDialog.invalidate()
		$CompileFileDialog.popup_centered()
	elif ("Compile and Playtest" == item_name):
		open_after_compiling = true
		$CompileFileDialog.invalidate()
		$CompileFileDialog.popup_centered()
	elif ("Quit" == item_name):
		if(false == storyworld.project_saved):
			$ConfirmQuit.popup_centered()
		else:
			get_tree().quit()

func _on_viewmenu_item_toggled(tab, id, checked):
	match tab:
		"Encounters":
			match id:
				0:
					$Background/VBC/EditorTabs/Encounters.set_display_encounter_list(checked)
				1:
					$Background/VBC/EditorTabs/Encounters.set_display_encounter_qdse(checked)
				2:
					$Background/VBC/EditorTabs/Encounters.set_display_reaction_qdse(checked)
		"Play":
			match id:
				0:
					$Background/VBC/EditorTabs/Play.set_display_spoolbook(checked)
		"Themes":
			match id:
				0:
					set_gui_theme("Clarity")
				1:
					set_gui_theme("Lapis Lazuli")

func _on_viewmenu_item_pressed(id):
	var item_name = $Background/VBC/MenuBar/ViewMenu.get_popup().get_item_text(id)
	if ("Summary" == item_name):
		$Summary/Statistics.refresh_statistical_overview()
		$Summary.popup_centered()

func _on_helpmenu_item_pressed(id):
	var item_name = $Background/VBC/MenuBar/HelpMenu.get_popup().get_item_text(id)
	if ("About" == item_name):
		$About.popup_centered()
	elif ("Validate and Troubleshoot" == item_name):
		$StoryworldTroubleshooting.popup_centered()
	elif ("Check for Updates" == item_name):
		$CheckForUpdates/UpdateScreen.refresh()
		$CheckForUpdates.popup_centered()

func _on_OpenSweepWeaveHomepage_pressed():
	#This button is part of the "About" popup.
	OS.shell_open("https://www.sweepweave.org")

func _on_OpenPatreonButton_pressed():
	#This button is part of the "About" popup.
	OS.shell_open("https://www.patreon.com/sasha_fenn")

func _on_ConfirmNewStoryworld_confirmed():
	new_storyworld()

func _on_ConfirmOpenWhenUnsaved_confirmed():
	$LoadFileDialog.invalidate()
	$LoadFileDialog.popup_centered()

func _on_LoadFileDialog_file_selected(path):
	current_project_path = path
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
		OS.shell_open("file:///" + path)




#var rehearsal_test = null
#var rehearsal_time_start = 0
##var rehearsal_time_end = 0
#
#func rehearse():
#	if (true == $Background/VBC/EditorTabs/Statistics/VBC/Test_Rehearsal_Button.pressed):
#		if (null == rehearsal_test):
#			rehearsal_time_start = OS.get_unix_time()
#			rehearsal_test = Rehearsal.new(storyworld)
#			$Background/VBC/EditorTabs/Statistics/VBC.add_child(rehearsal_test.history)
#			rehearsal_test.history.rect_min_size.x = 256
#			rehearsal_test.history.rect_min_size.y = 256
#		var rehearsal_complete = rehearsal_test.rehearse_depth_first()
#		if (rehearsal_complete):
#			$Background/VBC/EditorTabs/Statistics/VBC/Test_Rehearsal_Button.pressed = false
#			var rehearsal_time_end = OS.get_unix_time()
#			var elapsed = rehearsal_time_end - rehearsal_time_start
#			var minutes = elapsed / 60
#			var seconds = elapsed % 60
#			var str_elapsed = "%02d : %02d" % [minutes, seconds]
#			print("Time elapsed : ", str_elapsed)
#			$Background/VBC/EditorTabs/Statistics/VBC/Occurrences.clear()
#			var root = $Background/VBC/EditorTabs/Statistics/VBC/Occurrences.create_item()
#			for encounter in rehearsal_test.storyworld.encounters:
#				var encounter_branch = $Background/VBC/EditorTabs/Statistics/VBC/Occurrences.create_item(root)
#				var text = encounter.title + " (" + str(encounter.occurrences) + ")"
#				encounter_branch.set_text(0, text)
#				for option in encounter.options:
#					var option_branch = $Background/VBC/EditorTabs/Statistics/VBC/Occurrences.create_item(encounter_branch)
#					text = option.get_text().left(10) + " (" + str(option.occurrences) + ")"
#					option_branch.set_text(0, text)
#					for reaction in option.reactions:
#						var reaction_branch = $Background/VBC/EditorTabs/Statistics/VBC/Occurrences.create_item(option_branch)
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
	$ConfirmImport.popup_centered()

func _on_ImportFromStoryworldFileDialog_files_selected(paths):
	$ConfirmImport/Margin/StoryworldMergingScreen.file_paths = paths
	$ConfirmImport/Margin/StoryworldMergingScreen.clear_data()
	$ConfirmImport/Margin/StoryworldMergingScreen.load_content_from_files()
	$ConfirmImport.popup_centered()

func _on_ConfirmImport_confirmed():
	storyworld.import_characters($ConfirmImport/Margin/StoryworldMergingScreen.get_selected_characters())
	$Background/VBC/EditorTabs/Characters.refresh_character_list()
	storyworld.import_encounters($ConfirmImport/Margin/StoryworldMergingScreen.get_selected_encounters())
	$Background/VBC/EditorTabs/Encounters.refresh_encounter_list()

func display_encounter(encounter):
	if (null != encounter):
		$Background/VBC/EditorTabs/Encounters.load_Encounter(encounter)
		$Background/VBC/EditorTabs.set_current_tab(1)

func display_encounter_by_id(id):
	$Background/VBC/EditorTabs/Encounters.load_Encounter_by_id(id)
	$Background/VBC/EditorTabs.set_current_tab(1)

func _on_About_confirmed():
	#Used to bring up MIT License message.
	$MITLicenseDialog.popup_centered()

func set_gui_theme(theme_name):
	match theme_name:
		"Clarity":
			$Background.set_texture(clarity_gradient_header)
			set_theme(clarity_theme)
		"Lapis Lazuli":
			$Background.set_texture(lapis_lazuli_gradient_header)
			set_theme(lapis_lazuli_theme)
	$Background/VBC/EditorTabs/Overview.set_gui_theme(theme_name, theme_background_colors[theme_name])
	$Background/VBC/EditorTabs/Encounters.set_gui_theme(theme_name, theme_background_colors[theme_name])
	$Background/VBC/EditorTabs/Spools.set_gui_theme(theme_name, theme_background_colors[theme_name])
	$Background/VBC/EditorTabs/Characters.set_gui_theme(theme_name, theme_background_colors[theme_name])
	$Background/VBC/EditorTabs/PersonalityModel.set_gui_theme(theme_name, theme_background_colors[theme_name])
	$Background/VBC/EditorTabs/Settings.set_gui_theme(theme_name, theme_background_colors[theme_name])
	$Background/VBC/EditorTabs/Documentation.set_gui_theme(theme_name, theme_background_colors[theme_name])
	$Background/VBC/EditorTabs/GraphView.set_gui_theme(theme_name, theme_background_colors[theme_name])
	$Background/VBC/EditorTabs/Play.set_gui_theme(theme_name, theme_background_colors[theme_name])
