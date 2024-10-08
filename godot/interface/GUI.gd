extends Control

var current_project_path = ""
var current_html_template_path = "res://custom_resources/encounter_engine.html"
var open_after_compiling = false

var sweepweave_version_number = "0.1.9"
var storyworld = null
var clipboard = Clipboard.new()

#Theme variables:
var theme_background_colors = {}
#Clarity:
@onready var clarity_gradient_header = preload("res://custom_resources/gradient_header_texture_clarity.tres")
@onready var clarity_theme = preload("res://custom_resources/clarity.tres")
#Lapis Lazuli:
@onready var lapis_lazuli_gradient_header = preload("res://custom_resources/gradient_header_texture_lapis_lazuli.tres")
@onready var lapis_lazuli_theme = preload("res://custom_resources/lapis_lazuli.tres")

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
	$Background/VBC/EditorTabs/Rehearsal.clear()
	$StoryworldTroubleshooting/StoryworldValidationInterface.refresh()
	storyworld.project_saved = true
	get_window().set_title("SweepWeave - " + storyworld.storyworld_title)

func save_project(save_as = false):
	storyworld.save_project(current_project_path, save_as)
	storyworld.project_saved = true
	$Background/VBC/EditorTabs/Settings/Scroll/VBC/SavePathDisplay.set_text("Current project save path: " + current_project_path)
	get_window().set_title("SweepWeave - " + storyworld.storyworld_title)
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
		$Background/VBC/EditorTabs/Rehearsal.reference_storyworld = storyworld
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
	$Background/VBC/EditorTabs/Rehearsal.clear()
	$StoryworldTroubleshooting/StoryworldValidationInterface.refresh()
	current_project_path = ""
	get_window().set_title("SweepWeave - " + storyworld.storyworld_title)
	storyworld.project_saved = true

func _ready():
	get_tree().set_auto_accept_quit(false)
	$LoadFileDialog.set_current_dir(OS.get_executable_path().get_base_dir())
	$LoadFileDialog.set_current_file("story.json")
	$LoadFileDialog.set_filters(PackedStringArray(["*.json ; JSON Files"]))
	$SaveAsFileDialog.set_current_dir(OS.get_executable_path().get_base_dir())
	$SaveAsFileDialog.set_current_file("story.json")
	$SaveAsFileDialog.set_filters(PackedStringArray(["*.json ; JSON Files"]))
	$CompileFileDialog.set_current_dir(OS.get_executable_path().get_base_dir())
	$CompileFileDialog.set_current_file("story.html")
	$CompileFileDialog.set_filters(PackedStringArray(["*.html ; HTML Files","*.htm ; HTM Files"]))
	$ExportToTxtFileDialog.set_current_dir(OS.get_executable_path().get_base_dir())
	$ExportToTxtFileDialog.set_current_file("story.txt")
	$ExportToTxtFileDialog.set_filters(PackedStringArray(["*.txt ; TXT Files"]))
	$About.get_ok_button().set_text("Read MIT License")
	$About.get_cancel_button().set_text("Close")
	new_storyworld()
	$Background/VBC/MenuBar/FileMenu.get_popup().id_pressed.connect(_on_filemenu_item_pressed)
	$Background/VBC/MenuBar/ViewMenu.get_popup().id_pressed.connect(_on_viewmenu_item_pressed)
	$Background/VBC/MenuBar/ViewMenu.menu_input.connect(_on_viewmenu_item_toggled)
	$Background/VBC/MenuBar/HelpMenu.get_popup().id_pressed.connect(_on_helpmenu_item_pressed)
	$Background/VBC/EditorTabs/Play.encounter_edit_button_pressed.connect(display_encounter_by_id)
	$Background/VBC/EditorTabs/Characters.new_character_created.connect($Background/VBC/EditorTabs/Encounters.add_character_to_lists)
	$Background/VBC/EditorTabs/Characters.character_deleted.connect($Background/VBC/EditorTabs/Encounters.on_character_deleted)
	$Background/VBC/EditorTabs/Characters.character_name_changed.connect(on_character_name_changed)
	$Background/VBC/EditorTabs/Characters.refresh_authored_property_lists.connect($Background/VBC/EditorTabs/PersonalityModel.refresh_property_list)
	$Background/VBC/EditorTabs/Characters.refresh_authored_property_lists.connect($Background/VBC/EditorTabs/Encounters.refresh_bnumber_property_lists)
	$Background/VBC/EditorTabs/Characters.refresh_authored_property_lists.connect($Background/VBC/EditorTabs/GraphView.refresh_quick_scripting_interfaces)
	$Background/VBC/EditorTabs/Encounters.refresh_graphview.connect($Background/VBC/EditorTabs/GraphView.refresh_graphview)
	$Background/VBC/EditorTabs/Encounters.encounter_updated.connect($Background/VBC/EditorTabs/Spools.refresh)
	$Background/VBC/EditorTabs/Encounters.encounter_updated.connect($Background/VBC/EditorTabs/Overview.refresh)
	$Background/VBC/EditorTabs/Spools.request_overview_change.connect($Background/VBC/EditorTabs/Overview.refresh)
	$Background/VBC/EditorTabs/Spools.request_overview_change.connect($Background/VBC/EditorTabs/Encounters.refresh_spool_lists)
	$Background/VBC/EditorTabs/Spools.encounter_load_requested.connect(display_encounter)
	$Background/VBC/EditorTabs/Overview.encounter_load_requested.connect(display_encounter)
	$Background/VBC/EditorTabs/Overview.refresh_graphview.connect($Background/VBC/EditorTabs/GraphView.refresh_graphview)
	$Background/VBC/EditorTabs/Overview.refresh_encounter_list.connect($Background/VBC/EditorTabs/Spools.refresh)
	$Background/VBC/EditorTabs/Overview.refresh_encounter_list.connect($Background/VBC/EditorTabs/Encounters.refresh_encounter_list)
	$Background/VBC/EditorTabs/GraphView.load_encounter_from_graphview.connect(display_encounter)
	$Background/VBC/EditorTabs/GraphView.encounter_modified.connect($Background/VBC/EditorTabs/Encounters._on_encounter_modified_from_graphview)
	$Background/VBC/EditorTabs/GraphView.encounter_modified.connect($Background/VBC/EditorTabs/Spools.refresh)
	$Background/VBC/EditorTabs/PersonalityModel.refresh_authored_property_lists.connect($Background/VBC/EditorTabs/Characters.refresh_property_list)
	$Background/VBC/EditorTabs/PersonalityModel.refresh_authored_property_lists.connect($Background/VBC/EditorTabs/Encounters.refresh_bnumber_property_lists)
	$Background/VBC/EditorTabs/PersonalityModel.refresh_authored_property_lists.connect($Background/VBC/EditorTabs/GraphView.refresh_quick_scripting_interfaces)
	$Background/VBC/EditorTabs/PersonalityModel.property_deleted.connect($Background/VBC/EditorTabs/Characters.refresh_property_list)
	$Background/VBC/EditorTabs/PersonalityModel.property_deleted.connect($Background/VBC/EditorTabs/Encounters.on_property_deleted)
	$Background/VBC/EditorTabs/PersonalityModel.property_deleted.connect($Background/VBC/EditorTabs/GraphView.refresh_quick_scripting_interfaces)
	$About/VBC/VersionMessage.set_text("SweepWeave v." + sweepweave_version_number)
	$CheckForUpdates/UpdateScreen/VBC/VersionMessage.set_text("Current SweepWeave version: " + sweepweave_version_number)
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
	if (what == NOTIFICATION_WM_CLOSE_REQUEST):
		if (false == storyworld.project_saved):
			$ConfirmQuit.popup_centered()
		else:
			get_tree().quit()

func _on_ConfirmQuit_confirmed():
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("project_save_as"):
		#This check must come before the Control + S check, otherwise Control + S will take precedence.
		$SaveAsFileDialog.invalidate()
		$SaveAsFileDialog.popup_centered()
	elif event.is_action_pressed("project_save_overwrite"):
		if ("" != current_project_path):
			save_project()
		else:
			$SaveAsFileDialog.invalidate()
			$SaveAsFileDialog.popup_centered()
	elif event.is_action_pressed("project_new"):
		if(false == storyworld.project_saved):
			$ConfirmNewStoryworld.popup_centered()
		else:
			new_storyworld()
	elif event.is_action_pressed("project_load"):
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
	get_window().set_title("SweepWeave - " + storyworld.storyworld_title + "*")
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
	elif ("Export as txt" == item_name):
		$ExportToTxtFileDialog.invalidate()
		$ExportToTxtFileDialog.popup_centered()
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
		"Graph View":
			match id:
				0:
					$Background/VBC/EditorTabs/GraphView.set_display_encounter_excerpts(checked)
				1:
					$Background/VBC/EditorTabs/GraphView.set_display_encounter_qdse(checked)
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
	if not FileAccess.file_exists(path):
		return # Error: File not found.
	var file = FileAccess.open(path, FileAccess.READ)
	if (null != file):
		current_project_path = path
		var json_string = file.get_as_text()
		load_project(json_string)
		file.close()

func _on_SaveAsFileDialog_file_selected(path):
	current_project_path = path
	save_project(true)

func _on_CompileFileDialog_file_selected(path):
	storyworld.compile_to_html(path)
	if (open_after_compiling):
		OS.shell_open("file:///" + path)

func _on_ExportToTxtFileDialog_file_selected(path):
	storyworld.export_to_txt(path)

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
	$Background/VBC/EditorTabs/Rehearsal.set_gui_theme(theme_name, theme_background_colors[theme_name])
