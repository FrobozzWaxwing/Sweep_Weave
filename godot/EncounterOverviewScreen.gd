extends Control

var storyworld = null
var searchterm = ""

# Encounter Title | Number of Options | Number of Reactions | Characters Involved | Associated Spools | Word Count | Creation Time | Modified Time

func _ready():
	if (0 < $ColorRect/VBC/SortBar/SortMenu.get_item_count()):
		$ColorRect/VBC/SortBar/SortMenu.select(0)
	$ColorRect/VBC/EncounterList.set_column_title(0, "Title")
	$ColorRect/VBC/EncounterList.set_column_expand(0, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(0, 3)
	$ColorRect/VBC/EncounterList.set_column_title(1, "Options")
	$ColorRect/VBC/EncounterList.set_column_expand(1, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(1, 1)
	$ColorRect/VBC/EncounterList.set_column_title(2, "Reactions")
	$ColorRect/VBC/EncounterList.set_column_expand(2, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(2, 1)
	$ColorRect/VBC/EncounterList.set_column_title(3, "Characters Involved")
	$ColorRect/VBC/EncounterList.set_column_expand(3, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(3, 3)
	$ColorRect/VBC/EncounterList.set_column_title(4, "Associated Spools")
	$ColorRect/VBC/EncounterList.set_column_expand(4, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(4, 3)
	$ColorRect/VBC/EncounterList.set_column_title(5, "Word Count")
	$ColorRect/VBC/EncounterList.set_column_expand(5, true)
	$ColorRect/VBC/EncounterList.set_column_min_width(5, 1)
	#$ColorRect/VBC/EncounterList.set_column_title(6, "Creation Time")
	#$ColorRect/VBC/EncounterList.set_column_title(7, "Modified Time")

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
			#Number of Reactions:
			var number_of_reactions = 0
			for option in encounter.options:
				number_of_reactions += option.reactions.size()
			entry.set_text(2, str(number_of_reactions))
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
			entry.set_text(3, character_names)
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
			entry.set_text(4, spool_names)
			#Word Count:
			entry.set_text(5, str(encounter.wordcount()))

func _on_SortMenu_item_selected(index):
	var sort_method = $ColorRect/VBC/SortBar/SortMenu.get_popup().get_item_text(index)
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
