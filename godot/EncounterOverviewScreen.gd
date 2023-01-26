extends Control

var storyworld = null
var searchterm = ""
var encounters_to_delete = []

signal encounter_load_requested(encounter)
signal refresh_graphview()
signal refresh_encounter_list()

#Utility functions:

func log_update(encounter = null):
	#If encounter == null, then the project as a whole is being updated, rather than a specific encounter, or an encounter has been added, deleted, or duplicated.
	if (null != encounter):
		encounter.log_update()
	storyworld.log_update()
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false

func get_selected_encounters():
	var selected_encounters = []
	var row = $ColorRect/VBC/EncounterList.get_next_selected(null)
	while (null != row):
		var encounter = row.get_metadata(0)
		if (encounter is Encounter):
			selected_encounters.append(encounter)
		row = $ColorRect/VBC/EncounterList.get_next_selected(row)
	return selected_encounters

# Encounter Title | Number of Options | Number of Reactions | Number of Effects | Characters Involved | Associated Spools | Word Count | Creation Time | Modified Time

func _ready():
	if (0 < $ColorRect/VBC/HFlowContainer/SortBar/SortMenu.get_item_count()):
		$ColorRect/VBC/HFlowContainer/SortBar/SortMenu.select(0)
	$ColorRect/VBC/EncounterList.set_column_title(0, "Title")
	$ColorRect/VBC/EncounterList.set_column_expand(0, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(0, 3)
	$ColorRect/VBC/EncounterList.set_column_title(1, "Options")
	$ColorRect/VBC/EncounterList.set_column_expand(1, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(1, 1)
	$ColorRect/VBC/EncounterList.set_column_title(2, "Reactions")
	$ColorRect/VBC/EncounterList.set_column_expand(2, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(2, 1)
	$ColorRect/VBC/EncounterList.set_column_title(3, "Effects")
	$ColorRect/VBC/EncounterList.set_column_expand(3, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(3, 1)
	$ColorRect/VBC/EncounterList.set_column_title(4, "Characters")
	$ColorRect/VBC/EncounterList.set_column_expand(4, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(4, 3)
	$ColorRect/VBC/EncounterList.set_column_title(5, "Spools")
	$ColorRect/VBC/EncounterList.set_column_expand(5, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(5, 3)
	$ColorRect/VBC/EncounterList.set_column_title(6, "Word Count")
	$ColorRect/VBC/EncounterList.set_column_expand(6, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(6, 1)
	#$ColorRect/VBC/EncounterList.set_column_title(6, "Creation Time")
	#$ColorRect/VBC/EncounterList.set_column_title(7, "Modified Time")
	$ConfirmEncounterDeletion.get_ok().set_text("Yes")
	$ConfirmEncounterDeletion.get_cancel().set_text("No")

onready var table_of_encounters = get_node("ColorRect/VBC/EncounterList")

func refresh():
	if (null == storyworld):
		return
	table_of_encounters.clear()
	var root = table_of_encounters.create_item()
	root.set_text(0, "Encounters: ")
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
			var involved_characters = encounter.connected_characters().values()
			var character_names = ""
			if (involved_characters.empty()):
				character_names = "None."
			else:
				involved_characters.sort_custom(CharacterSorter, "sort_a_z")
				var delimiter = ""
				for character in involved_characters:
					character_names += delimiter + character.char_name
					delimiter = ", "
				character_names += "."
			entry.set_text(4, character_names)
			#Associated Spools:
			var connected_spools = encounter.connected_spools.duplicate()
			var spool_names = ""
			if (connected_spools.empty()):
				spool_names = "None."
			else:
				connected_spools.sort_custom(SpoolSorter, "sort_a_z")
				var delimiter = ""
				for spool in connected_spools:
					spool_names += delimiter + spool.spool_name
					delimiter = ", "
				spool_names += "."
			entry.set_text(5, spool_names)
			#Word Count:
			entry.set_text(6, str(encounter.wordcount()))

func _on_SortMenu_item_selected(index):
	var sort_method = $ColorRect/VBC/HFlowContainer/SortBar/SortMenu.get_popup().get_item_text(index)
	storyworld.sort_encounters(sort_method)
	refresh()
	#if ("Word Count" == sort_method || "Rev. Word Count" == sort_method):
		#for each in storyworld.encounters:
			#update_wordcount(each)
	#refresh_encounter_list()

func _on_LineEdit_text_entered(new_text):
	searchterm = new_text
	print("Searching events for \"" + new_text + "\"")
	refresh()

func _on_EncounterList_item_activated():
	var encounter = table_of_encounters.get_selected().get_metadata(0)
	if (encounter is Encounter):
		emit_signal("encounter_load_requested", encounter)

func _on_AddEncounterButton_pressed():
	var new_encounter = storyworld.create_new_generic_encounter()
	storyworld.add_encounter(new_encounter)
	log_update(new_encounter)
	refresh()
	emit_signal("refresh_graphview")
	emit_signal("refresh_encounter_list")
	emit_signal("encounter_load_requested", new_encounter)

func _on_DeleteEncounterButton_pressed():
	encounters_to_delete.clear()
	encounters_to_delete = get_selected_encounters()
	if (!encounters_to_delete.empty()):
		var dialog_text = ""
		if (1 == encounters_to_delete.size()):
			dialog_text = "Are you sure you wish to delete the following encounter?"
		else:
			dialog_text = "Are you sure you wish to delete the following encounters?"
		$ConfirmEncounterDeletion/EncountersToDelete.clear()
		for each in encounters_to_delete:
			$ConfirmEncounterDeletion/EncountersToDelete.add_item(each.title)
		$ConfirmEncounterDeletion.dialog_text = dialog_text
		$ConfirmEncounterDeletion.popup()

func _on_ConfirmEncounterDeletion_confirmed():
	for each in encounters_to_delete:
		storyworld.delete_encounter(each)
	log_update(null)
	refresh()
	emit_signal("refresh_graphview")
	emit_signal("refresh_encounter_list")
	emit_signal("encounter_load_requested", null) #Clear encounter editing screen.

func _on_EditEncounterButton_pressed():
	var selected_encounters = get_selected_encounters()
	if (!selected_encounters.empty()):
		emit_signal("encounter_load_requested", selected_encounters.front())

func _on_DuplicateEncounterButton_pressed():
	var selected_encounters = get_selected_encounters()
	if (!selected_encounters.empty()):
		var encounter_to_load = null
		for encounter in selected_encounters:
			encounter_to_load = storyworld.duplicate_encounter(encounter)
		log_update(null)
		refresh()
		emit_signal("refresh_graphview")
		emit_signal("refresh_encounter_list")
		emit_signal("encounter_load_requested", encounter_to_load)
