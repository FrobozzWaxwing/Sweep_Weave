extends Control

var storyworld = null
var searchterm = ""
var encounters_to_delete = []
var light_mode = true
#Clarity is a light mode theme, while Lapis Lazuli is a dark mode theme.

signal encounter_load_requested(encounter)
signal refresh_graphview()
signal refresh_encounter_list()

#Utility functions:

func log_update(encounter = null):
	#If encounter == null, then the project as a whole is being updated, rather than a specific encounter, or an encounter has been added, deleted, or duplicated.
	if (null != encounter):
		encounter.log_update()
	storyworld.log_update()
	get_window().set_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false

func get_selected_encounters():
	var selected_encounters = []
	var row = $Background/VBC/EncounterList.get_next_selected(null)
	while (null != row):
		var encounter = row.get_metadata(0)
		if (encounter is Encounter):
			selected_encounters.append(encounter)
		row = $Background/VBC/EncounterList.get_next_selected(row)
	return selected_encounters

# Encounter Title | Number of Options | Number of Reactions | Number of Effects | Characters Involved | Associated Spools | Word Count | Creation Time | Modified Time

func _ready():
	$Background/VBC/EncounterList.set_column_title(0, "Title")
	$Background/VBC/EncounterList.set_column_expand(0, true)
	$Background/VBC/EncounterList.set_column_custom_minimum_width(0, 3)
	$Background/VBC/EncounterList.set_column_title(1, "Options")
	$Background/VBC/EncounterList.set_column_expand(1, true)
	$Background/VBC/EncounterList.set_column_custom_minimum_width(1, 1)
	$Background/VBC/EncounterList.set_column_title(2, "Reactions")
	$Background/VBC/EncounterList.set_column_expand(2, true)
	$Background/VBC/EncounterList.set_column_custom_minimum_width(2, 1)
	$Background/VBC/EncounterList.set_column_title(3, "Effects")
	$Background/VBC/EncounterList.set_column_expand(3, true)
	$Background/VBC/EncounterList.set_column_custom_minimum_width(3, 1)
	$Background/VBC/EncounterList.set_column_title(4, "Characters")
	$Background/VBC/EncounterList.set_column_expand(4, true)
	$Background/VBC/EncounterList.set_column_custom_minimum_width(4, 3)
	$Background/VBC/EncounterList.set_column_title(5, "Spools")
	$Background/VBC/EncounterList.set_column_expand(5, true)
	$Background/VBC/EncounterList.set_column_custom_minimum_width(5, 3)
	$Background/VBC/EncounterList.set_column_title(6, "Word Count")
	$Background/VBC/EncounterList.set_column_expand(6, true)
	$Background/VBC/EncounterList.set_column_custom_minimum_width(6, 1)
	#$Background/VBC/EncounterList.set_column_title(6, "Creation Time")
	#$Background/VBC/EncounterList.set_column_title(7, "Modified Time")
	$ConfirmEncounterDeletion.get_ok_button().set_text("Yes")
	$ConfirmEncounterDeletion.get_cancel_button().set_text("No")

@onready var table_of_encounters = get_node("Background/VBC/EncounterList")

func refresh():
	if (null == storyworld):
		return
	var sort_index = $Background/VBC/HFlowContainer/SortBar/SortMenu.get_selected()
	var sort_method = $Background/VBC/HFlowContainer/SortBar/SortMenu.get_popup().get_item_text(sort_index)
	var reversed = $Background/VBC/HFlowContainer/SortBar/ToggleReverseButton.is_pressed()
	storyworld.sort_encounters(sort_method, reversed)
	table_of_encounters.clear()
	var root = table_of_encounters.create_item()
	root.set_text(0, "Encounters: ")
	var even = false
	for encounter in storyworld.encounters:
		if ("" == searchterm or encounter.has_search_text(searchterm)):
			var entry = table_of_encounters.create_item(root)
			#Encounter Title:
			if ("" == encounter.title):
				entry.set_text(0, "[Untitled]")
			else:
				entry.set_text(0, encounter.title)
			entry.set_metadata(0, encounter)
			#Number of Options:
			entry.set_text(1, str(encounter.options.size()))
			#Number of Reactions and Effects:
			var number_of_reactions = 0
			var number_of_effects = 0
			for option in encounter.options:
				number_of_reactions += option.reactions.size()
				for reaction in option.reactions:
					number_of_effects += reaction.after_effects.size()
			entry.set_text(2, str(number_of_reactions))
			entry.set_text(3, str(number_of_effects))
			#Characters Involved:
			var involved_characters = encounter.get_connected_characters().values()
			var character_names = ""
			if (involved_characters.is_empty()):
				character_names = "None."
			else:
				involved_characters.sort_custom(Callable(CharacterSorter, "sort_a_z"))
				var delimiter = ""
				for character in involved_characters:
					character_names += delimiter + character.char_name
					delimiter = ", "
				character_names += "."
			entry.set_text(4, character_names)
			#Associated Spools:
			var connected_spools = encounter.connected_spools.duplicate()
			var spool_names = ""
			if (connected_spools.is_empty()):
				spool_names = "None."
			else:
				connected_spools.sort_custom(Callable(SpoolSorter, "sort_a_z"))
				var delimiter = ""
				for spool in connected_spools:
					spool_names += delimiter + spool.spool_name
					delimiter = ", "
				spool_names += "."
			entry.set_text(5, spool_names)
			#Word Count:
			entry.set_text(6, str(encounter.wordcount()))
			#Set even rows to have different color:
			if (even):
				entry.set_custom_bg_color(0, Color(0.235294, 0.470588, 0.941176, 0.392157))
				entry.set_custom_bg_color(1, Color(0.235294, 0.470588, 0.941176, 0.392157))
				entry.set_custom_bg_color(2, Color(0.235294, 0.470588, 0.941176, 0.392157))
				entry.set_custom_bg_color(3, Color(0.235294, 0.470588, 0.941176, 0.392157))
				entry.set_custom_bg_color(4, Color(0.235294, 0.470588, 0.941176, 0.392157))
				entry.set_custom_bg_color(5, Color(0.235294, 0.470588, 0.941176, 0.392157))
				entry.set_custom_bg_color(6, Color(0.235294, 0.470588, 0.941176, 0.392157))
			even = !even

@onready var sort_alpha_icon_light = preload("res://icons/sort-alpha-down.svg")
@onready var sort_alpha_icon_dark = preload("res://icons/sort-alpha-down_dark.svg")
@onready var sort_rev_alpha_icon_light = preload("res://icons/sort-alpha-down-alt.svg")
@onready var sort_rev_alpha_icon_dark = preload("res://icons/sort-alpha-down-alt_dark.svg")
@onready var sort_numeric_icon_light = preload("res://icons/sort-numeric-down.svg")
@onready var sort_numeric_icon_dark = preload("res://icons/sort-numeric-down_dark.svg")
@onready var sort_rev_numeric_icon_light = preload("res://icons/sort-numeric-down-alt.svg")
@onready var sort_rev_numeric_icon_dark = preload("res://icons/sort-numeric-down-alt_dark.svg")

func refresh_sort_icon():
	var sort_index = $Background/VBC/HFlowContainer/SortBar/SortMenu.get_selected()
	var sort_method = $Background/VBC/HFlowContainer/SortBar/SortMenu.get_popup().get_item_text(sort_index)
	var reversed = $Background/VBC/HFlowContainer/SortBar/ToggleReverseButton.is_pressed()
	if (light_mode):
		if ("Alphabetical" == sort_method or "Characters" == sort_method or "Spools" == sort_method):
			if (reversed):
				$Background/VBC/HFlowContainer/SortBar/ToggleReverseButton.icon = sort_rev_alpha_icon_dark
			else:
				$Background/VBC/HFlowContainer/SortBar/ToggleReverseButton.icon = sort_alpha_icon_dark
		else:
			if (reversed):
				$Background/VBC/HFlowContainer/SortBar/ToggleReverseButton.icon = sort_rev_numeric_icon_dark
			else:
				$Background/VBC/HFlowContainer/SortBar/ToggleReverseButton.icon = sort_numeric_icon_dark
	else:
		if ("Alphabetical" == sort_method or "Characters" == sort_method or "Spools" == sort_method):
			if (reversed):
				$Background/VBC/HFlowContainer/SortBar/ToggleReverseButton.icon = sort_rev_alpha_icon_light
			else:
				$Background/VBC/HFlowContainer/SortBar/ToggleReverseButton.icon = sort_alpha_icon_light
		else:
			if (reversed):
				$Background/VBC/HFlowContainer/SortBar/ToggleReverseButton.icon = sort_rev_numeric_icon_light
			else:
				$Background/VBC/HFlowContainer/SortBar/ToggleReverseButton.icon = sort_numeric_icon_light

func _on_SortMenu_item_selected(index):
	refresh()
	refresh_sort_icon()

func _on_ToggleReverseButton_toggled(button_pressed):
	refresh()
	refresh_sort_icon()

func _on_EncounterList_column_title_clicked(column, mouse_button_index):
	var current_sort_index = $Background/VBC/HFlowContainer/SortBar/SortMenu.get_selected()
	var current_pressed = $Background/VBC/HFlowContainer/SortBar/ToggleReverseButton.is_pressed()
	if ((0 == current_sort_index and 0 == column) or (column + 2 == current_sort_index)):
		#If the user clicked the title of the column currently being used to sort the encounters, reverse the sorting algorithm.
		$Background/VBC/HFlowContainer/SortBar/ToggleReverseButton.set_pressed_no_signal(!current_pressed)
	else:
		if (0 == column):
			$Background/VBC/HFlowContainer/SortBar/SortMenu.select(0)
		else:
			$Background/VBC/HFlowContainer/SortBar/SortMenu.select(column+2)
	refresh()
	refresh_sort_icon()

func _on_LineEdit_text_entered(new_text):
	searchterm = new_text
	refresh()

func _on_EncounterList_item_activated():
	var encounter = table_of_encounters.get_selected().get_metadata(0)
	if (encounter is Encounter):
		encounter_load_requested.emit(encounter)

func _on_AddEncounterButton_pressed():
	var new_encounter = storyworld.create_new_generic_encounter()
	storyworld.add_encounter(new_encounter)
	log_update(new_encounter)
	refresh()
	refresh_graphview.emit()
	refresh_encounter_list.emit()
	encounter_load_requested.emit(new_encounter)

func _on_DeleteEncounterButton_pressed():
	encounters_to_delete.clear()
	encounters_to_delete = get_selected_encounters()
	if (!encounters_to_delete.is_empty()):
		var dialog_text = ""
		if (1 == encounters_to_delete.size()):
			dialog_text = "Are you sure you wish to delete the following encounter?"
		else:
			dialog_text = "Are you sure you wish to delete the following encounters?"
		$ConfirmEncounterDeletion/EncountersToDelete.clear()
		for each in encounters_to_delete:
			$ConfirmEncounterDeletion/EncountersToDelete.add_item(each.title)
		$ConfirmEncounterDeletion.dialog_text = dialog_text
		$ConfirmEncounterDeletion.popup_centered()

func _on_ConfirmEncounterDeletion_confirmed():
	for each in encounters_to_delete:
		storyworld.delete_encounter(each)
	log_update(null)
	refresh()
	refresh_graphview.emit()
	refresh_encounter_list.emit()
	encounter_load_requested.emit(null) #Clear encounter editing screen.

func _on_EditEncounterButton_pressed():
	var selected_encounters = get_selected_encounters()
	if (!selected_encounters.is_empty()):
		encounter_load_requested.emit(selected_encounters.front())

func _on_DuplicateEncounterButton_pressed():
	var selected_encounters = get_selected_encounters()
	if (!selected_encounters.is_empty()):
		var encounter_to_load = null
		for encounter in selected_encounters:
			encounter_to_load = storyworld.duplicate_encounter(encounter)
		log_update(null)
		refresh()
		refresh_graphview.emit()
		refresh_encounter_list.emit()
		encounter_load_requested.emit(encounter_to_load)

@onready var add_icon_light = preload("res://icons/add.svg")
@onready var add_icon_dark = preload("res://icons/add_dark.svg")
@onready var delete_icon_light = preload("res://icons/delete.svg")
@onready var delete_icon_dark = preload("res://icons/delete_dark.svg")

func set_gui_theme(theme_name, background_color):
	$Background.color = background_color
	match theme_name:
		"Clarity":
			$Background/VBC/HFlowContainer/AddEncounterButton.set_button_icon(add_icon_dark)
			$Background/VBC/HFlowContainer/DeleteEncounterButton.set_button_icon(delete_icon_dark)
			light_mode = true
		"Lapis Lazuli":
			$Background/VBC/HFlowContainer/AddEncounterButton.set_button_icon(add_icon_light)
			$Background/VBC/HFlowContainer/DeleteEncounterButton.set_button_icon(delete_icon_light)
			light_mode = false
	refresh_sort_icon()

