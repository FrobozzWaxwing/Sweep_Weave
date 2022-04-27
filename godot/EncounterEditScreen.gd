extends HSplitContainer

var current_encounter = null
var current_option = null
var current_reaction = null
var storyworld = null
var node_scene = preload("res://graphview_node.tscn")
#Track objects to delete.
var encounters_to_delete = null
var options_to_delete = null
var reactions_to_delete = null
#Clipboard system variables:
var clipboard = [] #Copies of the clipped data.
var clipped_originals = [] #References to the original objects that were clipped.
enum clipboard_task_types {NONE, CUT, COPY}
var clipboard_task = clipboard_task_types.NONE

signal refresh_graphview()

func refresh_encounter_list():
	$Column1/VScroll/EncountersList.clear()
	var sort_method_id = $Column1/SortMenu.get_selected_id()
	var sort_method = $Column1/SortMenu.get_popup().get_item_text(sort_method_id)
	storyworld.sort_encounters(sort_method)
	for entry in storyworld.encounters:
		if ("" == entry.title):
			$Column1/VScroll/EncountersList.add_item("[Untitled]")
		else:
			$Column1/VScroll/EncountersList.add_item(entry.title)
	if (0 == storyworld.encounters.size()):
		Clear_Encounter_Editing_Screen()

func _on_SortMenu_item_selected(index):
	var sort_method = $Column1/SortMenu.get_popup().get_item_text(index)
	if ("Word Count" == sort_method || "Rev. Word Count" == sort_method):
		for each in storyworld.encounters:
			update_wordcount(each)
	refresh_encounter_list()

func list_option(option, cutoff = 50):
	var optionslist = $HSC/Column2/OptionsScroll/OptionsList
	var index = optionslist.get_item_count()
	if ("" == option.text):
		optionslist.add_item("[Blank Option]")
	else:
		if (option.text.left(cutoff) == option.text):
			optionslist.add_item(option.text)
		else:
			optionslist.add_item(option.text.left(cutoff) + "...")
			optionslist.set_item_tooltip(index, option.text)
	optionslist.set_item_metadata(index, option)

func refresh_option_list(cutoff = 50):
	$HSC/Column2/OptionsScroll/OptionsList.clear()
	if (null != current_encounter):
		for option in current_encounter.options:
			list_option(option, cutoff)
		if (0 < current_encounter.options.size()):
			load_Option(current_encounter.options[0])
			$HSC/Column2/OptionsScroll/OptionsList.select(0)

func list_reaction(reaction, cutoff = 50):
	var reactionslist = $HSC/Column3/ReactionsScroll/ReactionList
	var index = reactionslist.get_item_count()
	if ("" == reaction.text):
		reactionslist.add_item("[Blank Reaction]")
	else:
		if (reaction.text.left(cutoff) == reaction.text):
			reactionslist.add_item(reaction.text)
		else:
			reactionslist.add_item(reaction.text.left(cutoff) + "...")
			reactionslist.set_item_tooltip(index, reaction.text)
	reactionslist.set_item_metadata(index, reaction)

func refresh_reaction_list(cutoff = 50):
	$HSC/Column3/ReactionsScroll/ReactionList.clear()
	if (null != current_option):
		for reaction in current_option.reactions:
			list_reaction(reaction, cutoff)

func refresh_character_lists():
	$HSC/Column2/HBCTurn/VBC3/AntagonistPicker.clear()
	$EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.clear()
	$pValueChangeSelection/VBC/HBC/CharacterSelect.clear()
	var index = 0
	for entry in storyworld.characters:
		$HSC/Column2/HBCTurn/VBC3/AntagonistPicker.add_item(entry.char_name)
		$HSC/Column2/HBCTurn/VBC3/AntagonistPicker.set_item_metadata(index, entry)
		$EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.add_item(entry.char_name)
		$EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.set_item_metadata(index, entry)
		$pValueChangeSelection/VBC/HBC/CharacterSelect.add_item(entry.char_name)
		$pValueChangeSelection/VBC/HBC/CharacterSelect.set_item_metadata(index, entry)
		index += 1
	if (null != current_encounter):
		$HSC/Column2/HBCTurn/VBC3/AntagonistPicker.select(storyworld.characters.find(current_encounter.antagonist))
	else:
		$HSC/Column2/HBCTurn/VBC3/AntagonistPicker.select(0)
	$EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.select(0)
	$pValueChangeSelection/VBC/HBC/CharacterSelect.select(0)

func replace_character(deleted_character, replacement):
	print("Replacing " + deleted_character.char_name + " with " + replacement.char_name)
	for encounter in storyworld.encounters:
		for desid in encounter.desiderata:
			if (desid.character == deleted_character):
				desid.character = replacement
				log_update(encounter)
		if (encounter.antagonist == deleted_character):
			encounter.antagonist = replacement
			log_update(encounter)
	storyworld.characters.erase(deleted_character)
	deleted_character.call_deferred("free")
	log_update(null)
	refresh_character_lists()

func add_character_to_lists(character):
	$HSC/Column2/HBCTurn/VBC3/AntagonistPicker.add_item(character.char_name)
	$pValueChangeSelection/VBC/HBC/CharacterSelect.add_item(character.char_name)

func refresh_character_names():
	for index in range($HSC/Column2/HBCTurn/VBC3/AntagonistPicker.get_item_count()):
		var character = $HSC/Column2/HBCTurn/VBC3/AntagonistPicker.get_item_metadata(index)
		$HSC/Column2/HBCTurn/VBC3/AntagonistPicker.set_item_text(index, character.char_name)
	for index in range($EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.get_item_count()):
		var character = $EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.get_item_metadata(index)
		$EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.set_item_text(index, character.char_name)
	for index in range($pValueChangeSelection/VBC/HBC/CharacterSelect.get_item_count()):
		var character = $pValueChangeSelection/VBC/HBC/CharacterSelect.get_item_metadata(index)
		$pValueChangeSelection/VBC/HBC/CharacterSelect.set_item_text(index, character.char_name)

func refresh_pValue_Change_List():
	$HSC/Column3/pValueChangeList.clear()
	if (null != current_reaction):
		for change in current_reaction.pValue_changes:
			$HSC/Column3/pValueChangeList.add_item(change.explain_pValue_change())
		if (0 != $HSC/Column3/pValueChangeList.get_item_count()):
			$HSC/Column3/pValueChangeList.select(0)

func refresh_bnumber_property_lists():
	$HSC/Column3/HBCTT/Trait1.clear()
	$HSC/Column3/HBCTT/Trait2.clear()
	$EditEncounterSettings/DesideratumSelection/HBC/pValueSelect.clear()
	$pValueChangeSelection/VBC/HBC/pValueSelect.clear()
	for bnumber_property in storyworld.personality_model.keys():
		$HSC/Column3/HBCTT/Trait1.add_item(bnumber_property)
		$HSC/Column3/HBCTT/Trait1.add_item("-" + bnumber_property)
		$HSC/Column3/HBCTT/Trait2.add_item(bnumber_property)
		$HSC/Column3/HBCTT/Trait2.add_item("-" + bnumber_property)
		$EditEncounterSettings/DesideratumSelection/HBC/pValueSelect.add_item(bnumber_property)
		$pValueChangeSelection/VBC/HBC/pValueSelect.add_item(bnumber_property)

func load_Reaction(reaction):
	current_reaction = reaction
	if (null == reaction):
		$HSC/Column3/ReactionText.text = ""
		$HSC/Column3/IncBlendWeightLabel.text = "Inclination blend weight: " + str(0)
		$HSC/Column3/HBCLSL/InclinationHSlider.value = 0
		$HSC/Column3/HBCTT/Trait1.select(0)
		$HSC/Column3/HBCTT/Trait2.select(0)
		$HSC/Column3/HBCConsequence/CurrentConsequence.text = "No consequence."
		for each in $HSC/Column3.get_children():
			if ($HSC/Column3/Null_Reaction_Label == each):
				each.visible = true
			else:
				each.visible = false
	else:
		$HSC/Column3/ReactionText.text = reaction.text
		$HSC/Column3/IncBlendWeightLabel.text = "Inclination blend weight: " + str(reaction.blend_weight)
		$HSC/Column3/HBCLSL/InclinationHSlider.value = (reaction.blend_weight)
		$HSC/Column3/HBCTT/Trait1.select(trait_index(reaction.blend_x.sign_and_pValue()))
		$HSC/Column3/HBCTT/Trait2.select(trait_index(reaction.blend_y.sign_and_pValue()))
		if (null == reaction.consequence):
			$HSC/Column3/HBCConsequence/CurrentConsequence.text = "No consequence."
		else:
			$HSC/Column3/HBCConsequence/CurrentConsequence.text = reaction.consequence.title
		for each in $HSC/Column3.get_children():
			if ($HSC/Column3/Null_Reaction_Label == each):
				each.visible = false
			else:
				each.visible = true
#		$HSC/Column3/ReactionsScroll/ReactionList.select(reaction.get_index())
	refresh_pValue_Change_List()

func load_Option(option):
	current_option = option
	refresh_reaction_list()
	if (null == option):
		$HSC/Column2/OptionText.text = ""
		load_Reaction(null)
	else:
		$HSC/Column2/OptionText.text = option.text
		if (0 < option.reactions.size()):
			load_Reaction(option.reactions[0])
			$HSC/Column3/ReactionsScroll/ReactionList.select(0)
#		$HSC/Column2/OptionsScroll/OptionsList.select(option.get_index())

func load_Encounter(encounter):
	current_encounter = encounter
	print("Loading Encounter: " + encounter.title)
	$HSC/Column2/HBCTitle/EncounterTitleEdit.text = encounter.title
	$HSC/Column2/EncounterMainTextEdit.text = encounter.main_text
	$HSC/Column2/HBCTurn/VBC/EarliestTurn.value = encounter.earliest_turn
	$HSC/Column2/HBCTurn/VBC2/LatestTurn.value = encounter.latest_turn
	$HSC/Column2/HBCTurn/VBC3/AntagonistPicker.select(storyworld.characters.find(encounter.antagonist))
	refresh_option_list()
	if (0 < encounter.options.size()):
		load_Option(encounter.options[0])
		$HSC/Column2/OptionsScroll/OptionsList.select(0)
	else:
		load_Option(null)

func load_Encounter_by_id(id):
	if (null != id and storyworld.encounter_directory.has(id)):
		var encounter = storyworld.encounter_directory[id]
		load_Encounter(encounter)

func Clear_Encounter_Editing_Screen():
	current_encounter = null
	current_option = null
	current_reaction = null
	print("Clearing Encounter Editing Screen.")
	$HSC/Column2/HBCTitle/EncounterTitleEdit.text = ""
	$HSC/Column2/EncounterMainTextEdit.text = ""
	$HSC/Column2/HBCTurn/VBC/EarliestTurn.value = 0
	$HSC/Column2/HBCTurn/VBC2/LatestTurn.value = 0
	$HSC/Column2/HBCTurn/VBC3/AntagonistPicker.select(0)
	$HSC/Column2/OptionsScroll/OptionsList.clear()
	$HSC/Column3/ReactionsScroll/ReactionList.clear()
	$HSC/Column2/OptionText.text = ""
	$HSC/Column3/ReactionText.text = ""
	$HSC/Column3/IncBlendWeightLabel.text = "Inclination blend weight: 0"
	$HSC/Column3/HBCLSL/InclinationHSlider.value = 0
	$HSC/Column3/HBCTT/Trait1.select(0)
	$HSC/Column3/HBCTT/Trait2.select(0)
	$HSC/Column3/HBCConsequence/CurrentConsequence.text = ""
	load_Option(null)

func load_and_focus_first_encounter():
	if (0 < storyworld.encounters.size()):
		load_Encounter(storyworld.encounters[0])
		$Column1/VScroll/EncountersList.select(0)

func log_update(encounter = null):
	#If encounter == null, then the project as a whole is being updated, rather than a specific encounter, or an encounter has been added, deleted, or duplicated.
	if (null != encounter):
		encounter.log_update()
	storyworld.log_update()
	OS.set_window_title("Encounter Editor - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false

func _on_AddButton_pressed():
	var new_encounter = Encounter.new(storyworld, "encounter_" + storyworld.unique_id(), "Encounter " + str(storyworld.unique_id_seed-1), "", 0, 1000, storyworld.characters[0], [], storyworld.unique_id_seed-1)
	var new_option = Option.new(new_encounter, "What does the user do?")
	var blend_x = null
	var blend_y = null
	if (0 < storyworld.personality_model.size()):
		var properties = storyworld.personality_model.keys()
		blend_x = properties[0]
		if (1 < storyworld.personality_model.size()):
			blend_y = properties[1]
	var new_reaction = Reaction.new(new_option, "How does the antagonist respond?", {"character": storyworld.characters[0], "pValue": blend_x, "point": 1}, {"character": storyworld.characters[0], "pValue": blend_y, "point": 1}, 0)
	new_encounter.options.append(new_option)
	new_option.reactions.append(new_reaction)
	storyworld.add_encounter(new_encounter)
	log_update(new_encounter)
	refresh_encounter_list()
	emit_signal("refresh_graphview")
	load_Encounter(new_encounter)

func _on_Edit_pressed():
	if ($Column1/VScroll/EncountersList.is_anything_selected()):
		var selection = $Column1/VScroll/EncountersList.get_selected_items()
		var encounter_id = selection[0]
		var encounter_to_edit = storyworld.encounters[encounter_id]
		load_Encounter(encounter_to_edit)

func _on_EncountersList_item_activated(index):
	var encounter_to_edit = storyworld.encounters[index]
	print("Loading Encounter: " + encounter_to_edit.title)
	load_Encounter(encounter_to_edit)

func _on_Duplicate_pressed():
	if ($Column1/VScroll/EncountersList.is_anything_selected()):
		var selection = $Column1/VScroll/EncountersList.get_selected_items()
		var encounters_to_duplicate = []
		for entry in selection:
			encounters_to_duplicate.append(storyworld.encounters[entry])
		var encounter_to_edit = null
		for entry in encounters_to_duplicate:
			print("Duplicating Encounter: " + entry.title)
			var new_encounter = storyworld.duplicate_encounter(entry)
			if (encounter_to_edit == null):
				encounter_to_edit = new_encounter
		log_update(null)
		refresh_encounter_list()
		emit_signal("refresh_graphview")
		if (encounter_to_edit != null):
			load_Encounter(encounter_to_edit)

func _on_EncounterTitleEdit_text_changed(new_text):
	#Change encounter title
	if (null != current_encounter):
		current_encounter.title = new_text
		update_wordcount(current_encounter)
		log_update(current_encounter)
		refresh_encounter_list()
		emit_signal("refresh_graphview")

func _on_EncounterMainTextEdit_text_changed():
	#Change encounter main text
	if (null != current_encounter):
		current_encounter.main_text = $HSC/Column2/EncounterMainTextEdit.text
		update_wordcount(current_encounter)
		log_update(current_encounter)
		emit_signal("refresh_graphview")

func _on_ConfirmEncounterDeletion_confirmed():
	for each in encounters_to_delete:
		storyworld.delete_encounter(each)
	log_update(null)
	refresh_encounter_list()
	emit_signal("refresh_graphview")

func _on_DeleteButton_pressed():
	if ($Column1/VScroll/EncountersList.is_anything_selected()):
		var selection = $Column1/VScroll/EncountersList.get_selected_items()
		encounters_to_delete = []
		for each in selection:
			encounters_to_delete.append(storyworld.encounters[each])
		if (0 == encounters_to_delete.size()):
			$CannotDelete.dialog_text = 'No encounters can be deleted.'
			$CannotDelete.popup()
		else:
			var dialog_text = 'Are you sure you wish to delete the following encounter(s)?'
			for each in encounters_to_delete:
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
#		current_encounter.earliest_turn = $HSC/Column2/HBCTurn/VBC/EarliestTurn.value
		current_encounter.earliest_turn = value
		log_update(current_encounter)

func _on_LatestTurn_value_changed(value):
	if (null != current_encounter):
#		current_encounter.latest_turn = $HSC/Column2/HBCTurn/VBC2/LatestTurn.value
		current_encounter.latest_turn = value
		log_update(current_encounter)

func _on_AntagonistPicker_item_selected(index):
	if (null != current_encounter):
		current_encounter.antagonist = storyworld.characters[index]
		log_update(current_encounter)

#Options and Reactions interface elements:
#Option editing interface:

func create_new_generic_option(encounter = current_encounter):
	var new_option = Option.new(encounter, "What does the user do?")
	var new_reaction = create_new_generic_reaction(new_option)
	new_option.reactions.append(new_reaction)
	return new_option

func _on_AddOption_pressed():
	if (null != current_encounter):
		var new_option = create_new_generic_option()
		current_encounter.options.append(new_option)
		list_option(new_option)
		load_Option(new_option)
		$HSC/Column2/OptionsScroll/OptionsList.select(new_option.get_index())
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_ConfirmOptionDeletion_confirmed():
	for option in options_to_delete:
		print("Deleting option: " + option.text.left(20))
		for encounter in storyworld.encounters:
			for prereq in encounter.prerequisites:
				if (prereq.option == option):
					prereq.option = null
					log_update(encounter)
		current_encounter.options.erase(option)
		option.call_deferred("free")
	refresh_option_list()
	if (0 < current_encounter.options.size()):
		load_Option(current_encounter.options[0])
		$HSC/Column2/OptionsScroll/OptionsList.select(0)
	else:
		load_Option(null)
	update_wordcount(current_encounter)
	log_update(current_encounter)
	emit_signal("refresh_graphview")

func _on_DeleteOption_pressed():
	if ($HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var selection = $HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		options_to_delete = []
		for each in selection:
			options_to_delete.append(current_encounter.options[each])
		var dialog_text = ""
		if (1 == options_to_delete.size()):
			dialog_text = "Are you sure you wish to delete the following option?"
		else:
			dialog_text = "Are you sure you wish to delete the following options?"
		for option in options_to_delete:
			dialog_text += " (" + option.text + ")"
		$ConfirmOptionDeletion.dialog_text = dialog_text
		$ConfirmOptionDeletion.popup()

func _on_MoveOptionUpButton_pressed():
	if ($HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var selection = $HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
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
				$HSC/Column2/OptionsScroll/OptionsList.select(selection[0]-1)
				load_Option(current_option)
				$HSC/Column3/ReactionsScroll/ReactionList.select(0)
				load_Reaction(current_option.reactions[0])
			log_update(current_encounter)

func _on_MoveOptionDownButton_pressed():
	if ($HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var selection = $HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
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
				$HSC/Column2/OptionsScroll/OptionsList.select(selection[0]+1)
				load_Option(current_option)
				$HSC/Column3/ReactionsScroll/ReactionList.select(0)
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
		_:
			return 0

func _on_OptionsList_item_selected(index):
	if ($HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var selection = $HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		current_option = current_encounter.options[selection[0]]
		load_Option(current_option)
		$HSC/Column3/ReactionsScroll/ReactionList.select(0)
		load_Reaction(current_option.reactions[0])

func _on_OptionsList_multi_selected(index, selected):
	if ($HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var selection = $HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		current_option = current_encounter.options[selection[0]]
		load_Option(current_option)
		$HSC/Column3/ReactionsScroll/ReactionList.select(0)
		load_Reaction(current_option.reactions[0])

func _on_OptionText_text_changed(new_text):
	if (null != current_option):
		current_option.text = $HSC/Column2/OptionText.text
		var optionslist = $HSC/Column2/OptionsScroll/OptionsList
		if ("" == current_option.text):
			optionslist.set_item_text(current_option.get_index(), "[Blank Option]")
		else:
			if (current_option.text.left(50) == current_option.text):
				optionslist.set_item_text(current_option.get_index(), current_option.text)
			else:
				var index = current_option.get_index()
				optionslist.set_item_text(index, current_option.text.left(50) + "...")
				optionslist.set_item_tooltip(index, current_option.text)
#		var selection = $HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
#		var which = 0
#		if (0 < selection.size()):
#			which = selection[0]
#		refresh_option_list()
#		$HSC/Column2/OptionsScroll/OptionsList.select(which)
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_OptionsList_item_rmb_selected(index, at_position):
	# Bring up context menu.
	var mouse_position = get_global_mouse_position()
	var context_menu = $HSC/Column2/OptionsScroll/OptionsList/OptionsContextMenu
	if ($HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
#		var text_of_selection = "\"" + $HSC/Column2/OptionsScroll/OptionsList.get_item_metadata(index).text
#		if (text_of_selection != text_of_selection.left(14)):
#			text_of_selection = text_of_selection.left(10) + "..."
#		else:
#			text_of_selection += "\""
		var text_of_selection = "this."
		context_menu.clear()
		context_menu.add_item("Add option before " + text_of_selection, 0)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Add option after " + text_of_selection, 1)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Cut", 2)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Copy", 3)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Paste before " + text_of_selection, 4)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Paste after " + text_of_selection, 5)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Delete", 6)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Duplicate", 7)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
#		context_menu.add_item("Select all", 8)
#		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.popup(Rect2(mouse_position.x, mouse_position.y, context_menu.rect_size.x, context_menu.rect_size.y))

func add_options_at_position(options_to_add, position):
	var copies_to_add = []
	for object in options_to_add:
		var copy = create_new_generic_option()
		copy.set_as_copy_of(object)
		copy.encounter = current_encounter
		copies_to_add.append(copy)
	if (1 == copies_to_add.size()):
		current_encounter.options.insert(position, copies_to_add[0])
	elif (0 >= position):
		copies_to_add.append_array(current_encounter.options)
		current_encounter.options = copies_to_add
	elif (position < current_encounter.options.size()):
		var new_array = current_encounter.options.slice(0, (position - 1))
		new_array.append_array(copies_to_add)
		new_array.append_array(current_encounter.options.slice(position, (current_encounter.options.size() - 1)))
		current_encounter.options = new_array
	elif (position >= current_encounter.options.size()):
		current_encounter.options.append_array(copies_to_add)
	refresh_option_list()
	if (0 < current_encounter.options.size()):
		load_Option(copies_to_add[0])
		$HSC/Column2/OptionsScroll/OptionsList.select(copies_to_add[0].get_index())
	update_wordcount(current_encounter)
	log_update(current_encounter)
	emit_signal("refresh_graphview")

func duplicate_selected_options():
	if ($HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var last_option_added = null
		var selection = $HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		for each in selection:
			var option = $HSC/Column2/OptionsScroll/OptionsList.get_item_metadata(each)
			var new_option = create_new_generic_option()
			new_option.set_as_copy_of(option)
			new_option.encounter = current_encounter
			current_encounter.options.append(new_option)
			list_option(new_option)
			last_option_added = new_option
		load_Option(last_option_added)
		update_wordcount(current_encounter)
		log_update(current_encounter)
		emit_signal("refresh_graphview")

func add_selected_options_to_clipboard():
	if ($HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var selection = $HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		for each in selection:
			var option = $HSC/Column2/OptionsScroll/OptionsList.get_item_metadata(each)
			var new_option = create_new_generic_option()
			new_option.set_as_copy_of(option)
			clipboard.append(new_option)
			clipped_originals.append(option)

func delete_clipped_originals():
	if (0 >= clipped_originals.size()):
		return
	if (clipped_originals[0] is Option):
		for object in clipped_originals:
			if (object is Option):
				print("Deleting option: " + object.text.left(20))
				for encounter in storyworld.encounters:
					for prereq in encounter.prerequisites:
						if (prereq.option == object):
							prereq.option = null
							log_update(encounter)
				object.encounter.options.erase(object)
				update_wordcount(object.encounter)
				log_update(object.encounter)
				object.call_deferred("free")
		refresh_option_list()
		if (0 < current_encounter.options.size()):
			load_Option(current_encounter.options[0])
			$HSC/Column2/OptionsScroll/OptionsList.select(0)
		else:
			load_Option(null)
	elif (clipped_originals[0] is Reaction):
		for object in clipped_originals:
			if (object is Reaction):
				print("Deleting reaction: " + object.text.left(20))
				for encounter in storyworld.encounters:
					for prereq in encounter.prerequisites:
						if (prereq.reaction == object):
							prereq.reaction = null
							log_update(encounter)
				object.option.reactions.erase(object)
				update_wordcount(object.option.encounter)
				log_update(object.option.encounter)
				object.call_deferred("free")
		refresh_reaction_list()
		if (0 < current_option.reactions.size()):
			load_Reaction(current_option.reactions[0])
			$HSC/Column3/ReactionsScroll/ReactionList.select(0)
		else:
			load_Reaction(null)
	emit_signal("refresh_graphview")

func _on_OptionsContextMenu_id_pressed(id):
	var item_index = $HSC/Column2/OptionsScroll/OptionsList/OptionsContextMenu.get_item_metadata(id)
	match id:
		0:
			#Add new option before
			var new_option = create_new_generic_option()
			add_options_at_position([new_option], item_index)
			print ("Adding new option before the selected one.")
		1:
			#Add new option after
			var new_option = create_new_generic_option()
			add_options_at_position([new_option], item_index + 1)
			print ("Adding new option after the selected one.")
		2:
			#Cut
			clipboard = []
			clipped_originals = []
			add_selected_options_to_clipboard()
			clipboard_task = clipboard_task_types.CUT
			print ("Cutting selected option for pasting.")
		3:
			#Copy
			clipboard = []
			clipped_originals = []
			add_selected_options_to_clipboard()
			clipboard_task = clipboard_task_types.COPY
			print ("Copying selected option.")
		4:
			#Paste before
			add_options_at_position(clipboard, item_index)
			if (clipboard_task_types.CUT == clipboard_task):
				delete_clipped_originals()
			print ("Pasting before selected option.")
		5:
			#Paste after
			add_options_at_position(clipboard, item_index + 1)
			if (clipboard_task_types.CUT == clipboard_task):
				delete_clipped_originals()
			print ("Pasting after selected option.")
		6:
			#Delete
			_on_DeleteOption_pressed()
			print ("Asking for confirmation for possible deletion of options.")
		7:
			#Duplicate
			duplicate_selected_options()
			print ("Duplicating selected option.")
#		8:
#			#Select all
#			for each in range($HSC/Column2/OptionsScroll/OptionsList.get_item_count()):
#				$HSC/Column2/OptionsScroll/OptionsList.select(each)
#			print ("Selecting all options.")

#Reaction editing interface:

func create_new_generic_reaction(option = current_option):
	return Reaction.new(option, "How does the antagonist respond?", {"character": storyworld.characters[0], "pValue": "Bad_Good", "point": 1}, {"character": storyworld.characters[0], "pValue": "False_Honest", "point": 1}, 0)

func _on_AddReaction_pressed():
	if (null != current_option):
		current_reaction = create_new_generic_reaction(current_option)
		current_option.reactions.append(current_reaction)
		list_reaction(current_reaction)
		load_Reaction(current_reaction)
		$HSC/Column3/ReactionsScroll/ReactionList.select(current_reaction.get_index())
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_ConfirmReactionDeletion_confirmed():
	for reaction in reactions_to_delete:
		print("Deleting reaction: " + reaction.text.left(25))
		for encounter in storyworld.encounters:
			for prereq in encounter.prerequisites:
				if (prereq.reaction == reaction):
					prereq.reaction = null
					log_update(encounter)
		current_option.reactions.erase(reaction)
		reaction.call_deferred("free")
	load_Option(current_option)
	current_reaction = current_option.reactions[0]
	$HSC/Column3/ReactionsScroll/ReactionList.select(0)
	load_Reaction(current_reaction)
	update_wordcount(current_encounter)
	log_update(current_encounter)
	emit_signal("refresh_graphview")

func _on_DeleteReaction_pressed():
	if ($HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var selection = $HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		reactions_to_delete = []
		for each in selection:
			reactions_to_delete.append(current_option.reactions[each])
		if (1 == current_option.reactions.size()):
			$CannotDelete.dialog_text = 'Cannot delete reaction. Each option must have at least one reaction.'
			$CannotDelete.popup()
			print("Cannot delete reaction. Each option must have at least one reaction.")
		elif(reactions_to_delete.size() == current_option.reactions.size()):
			#Print "reactions" instead of "reaction."
			$CannotDelete.dialog_text = 'Cannot delete reactions. Each option must have at least one reaction.'
			$CannotDelete.popup()
			print("Cannot delete reactions. Each option must have at least one reaction.")
		else:
			var dialog_text = ""
			if (1 == reactions_to_delete.size()):
				dialog_text = "Are you sure you wish to delete the following reaction?"
			else:
				dialog_text = "Are you sure you wish to delete the following reactions?"
			for reaction in reactions_to_delete:
				dialog_text += " (" + reaction.text + ")"
			$ConfirmReactionDeletion.dialog_text = dialog_text
			$ConfirmReactionDeletion.popup()

func _on_MoveReactionUpButton_pressed():
	if ($HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var selection = $HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
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
				$HSC/Column3/ReactionsScroll/ReactionList.select(selection[0]-1)
				load_Reaction(current_reaction)
			log_update(current_encounter)

func _on_MoveReactionDownButton_pressed():
	if ($HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var selection = $HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
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
				$HSC/Column3/ReactionsScroll/ReactionList.select(selection[0]+1)
				load_Reaction(current_reaction)
			log_update(current_encounter)

func _on_ReactionList_item_selected(index):
	if ($HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var selection = $HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		current_reaction = current_option.reactions[selection[0]]
		load_Reaction(current_reaction)

func _on_ReactionList_multi_selected(index, selected):
	if ($HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var selection = $HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		current_reaction = current_option.reactions[selection[0]]
		load_Reaction(current_reaction)

func _on_ReactionText_text_changed():
	if (null != current_reaction):
		var reactionslist = $HSC/Column3/ReactionsScroll/ReactionList
		current_reaction.text = $HSC/Column3/ReactionText.text
		var index = current_reaction.get_index()
		if ("" == current_reaction.text):
			reactionslist.set_item_text(index, "[Blank Reaction]")
		else:
			if (current_reaction.text.left(50) == current_reaction.text):
				reactionslist.set_item_text(index, current_reaction.text)
			else:
				reactionslist.set_item_text(index, current_reaction.text.left(50) + "...")
				reactionslist.set_item_tooltip(index, current_reaction.text)
#		var selection = $HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
#		var which = 0
#		if (0 < selection.size()):
#			which = selection[0]
#		refresh_reaction_list()
#		$HSC/Column3/ReactionsScroll/ReactionList.select(which)
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_InclinationHSlider_value_changed(value):
	if (null != current_reaction):
		current_reaction.blend_weight = ($HSC/Column3/HBCLSL/InclinationHSlider.value)
		$HSC/Column3/IncBlendWeightLabel.text = "Inclination blend weight: " + str(current_reaction.blend_weight)
		log_update(current_encounter)

func _on_Trait1_item_selected(index):
	if (null != current_reaction):
		var traits = ["Bad_Good", "-Bad_Good", "False_Honest", "-False_Honest", "Timid_Dominant", "-Timid_Dominant", "pBad_Good", "-pBad_Good", "pFalse_Honest", "-pFalse_Honest", "pTimid_Dominant", "-pTimid_Dominant"]
		current_reaction.set_blend_x(traits[$HSC/Column3/HBCTT/Trait1.get_selected_id()])
		log_update(current_encounter)

func _on_Trait2_item_selected(index):
	if (null != current_reaction):
		var traits = ["Bad_Good", "-Bad_Good", "False_Honest", "-False_Honest", "Timid_Dominant", "-Timid_Dominant", "pBad_Good", "-pBad_Good", "pFalse_Honest", "-pFalse_Honest", "pTimid_Dominant", "-pTimid_Dominant"]
		current_reaction.set_blend_y(traits[$HSC/Column3/HBCTT/Trait2.get_selected_id()])
		log_update(current_encounter)

func _on_ChangeConsequence_pressed():
	if (null != current_reaction):
		var selection = $Column1/VScroll/EncountersList.get_selected_items()
		if (storyworld.encounters[selection[0]] == current_encounter):
			print("An encounter cannot serve as a consequence for itself.")
		else:
			current_reaction.consequence = storyworld.encounters[selection[0]]
			$HSC/Column3/HBCConsequence/CurrentConsequence.text = current_reaction.consequence.title
			log_update(current_encounter)
			emit_signal("refresh_graphview")

func _on_RemoveConsequenceButton_pressed():
	if (null != current_reaction):
		current_reaction.consequence = null
		$HSC/Column3/HBCConsequence/CurrentConsequence.text = "No consequence."
		log_update(current_encounter)
		emit_signal("refresh_graphview")

func _on_pValueChangeAdd_pressed():
	if (null != current_reaction):
		$pValueChangeSelection.popup()
	else:
		print("No reaction currently selected.")

func _on_pValueChangeSelection_confirmed():
	if (null != current_reaction):
		var des_character_id = $pValueChangeSelection/VBC/HBC/CharacterSelect.get_selected_id()
		var des_character = storyworld.characters[des_character_id]
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
	var selection = $HSC/Column3/pValueChangeList.get_selected_items()
	if (0 < selection.size()):
		var change_to_delete = current_reaction.pValue_changes[selection[0]]
		current_reaction.pValue_changes.erase(change_to_delete)
		refresh_pValue_Change_List()

func _on_ReactionList_item_rmb_selected(index, at_position):
	# Bring up context menu.
	var mouse_position = get_global_mouse_position()
	var context_menu = $HSC/Column3/ReactionsScroll/ReactionList/ReactionsContextMenu
	if ($HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
#		var text_of_selection = "\"" + $HSC/Column2/OptionsScroll/OptionsList.get_item_metadata(index).text
#		if (text_of_selection != text_of_selection.left(14)):
#			text_of_selection = text_of_selection.left(10) + "..."
#		else:
#			text_of_selection += "\""
		var text_of_selection = "this."
		context_menu.clear()
		context_menu.add_item("Add reaction before " + text_of_selection, 0)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Add reaction after " + text_of_selection, 1)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Cut", 2)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Copy", 3)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Paste before " + text_of_selection, 4)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Paste after " + text_of_selection, 5)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Delete", 6)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.add_item("Duplicate", 7)
		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
#		context_menu.add_item("Select all", 8)
#		context_menu.set_item_metadata((context_menu.get_item_count() - 1), index)
		context_menu.popup(Rect2(mouse_position.x, mouse_position.y, context_menu.rect_size.x, context_menu.rect_size.y))

func add_reactions_at_position(reactions_to_add, position):
	var copies_to_add = []
	for object in reactions_to_add:
		var copy = create_new_generic_reaction()
		copy.set_as_copy_of(object)
		copy.option = current_option
		copies_to_add.append(copy)
	if (1 == copies_to_add.size()):
		current_option.reactions.insert(position, copies_to_add[0])
	elif (0 >= position):
		copies_to_add.append_array(current_option.reactions)
		current_option.reactions = copies_to_add
	elif (position < current_option.reactions.size()):
		var new_array = current_option.reactions.slice(0, (position - 1))
		new_array.append_array(copies_to_add)
		new_array.append_array(current_option.reactions.slice(position, (current_option.reactions.size() - 1)))
		current_option.reactions = new_array
	elif (position >= current_option.reactions.size()):
		current_option.reactions.append_array(copies_to_add)
	refresh_reaction_list()
	if (0 < current_option.reactions.size()):
		load_Reaction(copies_to_add[0])
		$HSC/Column3/ReactionsScroll/ReactionList.select(copies_to_add[0].get_index())
	update_wordcount(current_encounter)
	log_update(current_encounter)
	emit_signal("refresh_graphview")

func duplicate_selected_reactions():
	if ($HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var last_reaction_added = null
		var selection = $HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		for each in selection:
			var reaction = $HSC/Column3/ReactionsScroll/ReactionList.get_item_metadata(each)
			var new_reaction = create_new_generic_reaction()
			new_reaction.set_as_copy_of(reaction)
			new_reaction.option = current_option
			current_option.reactions.append(new_reaction)
			list_reaction(new_reaction)
			last_reaction_added = new_reaction
		load_Reaction(last_reaction_added)
		update_wordcount(current_encounter)
		log_update(current_encounter)
		emit_signal("refresh_graphview")

func add_selected_reactions_to_clipboard():
	if ($HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var selection = $HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		for each in selection:
			var reaction = $HSC/Column3/ReactionsScroll/ReactionList.get_item_metadata(each)
			var new_reaction = create_new_generic_reaction()
			new_reaction.set_as_copy_of(reaction)
			clipboard.append(new_reaction)
			clipped_originals.append(reaction)

func _on_ReactionsContextMenu_id_pressed(id):
	var item_index = $HSC/Column3/ReactionsScroll/ReactionList/ReactionsContextMenu.get_item_metadata(id)
	match id:
		0:
			#Add new reaction before
			var new_reaction = create_new_generic_reaction(current_option)
			add_reactions_at_position([new_reaction], item_index)
			print ("Adding new reaction before the selected one.")
		1:
			#Add new reaction after
			var new_reaction = create_new_generic_reaction(current_option)
			add_reactions_at_position([new_reaction], item_index + 1)
			print ("Adding new reaction after the selected one.")
		2:
			#Cut
			clipboard = []
			clipped_originals = []
			add_selected_reactions_to_clipboard()
			clipboard_task = clipboard_task_types.CUT
			print ("Cutting selected reactions for pasting.")
		3:
			#Copy
			clipboard = []
			clipped_originals = []
			add_selected_reactions_to_clipboard()
			clipboard_task = clipboard_task_types.COPY
			print ("Copying selected reactions.")
		4:
			#Paste before
			add_reactions_at_position(clipboard, item_index)
			if (clipboard_task_types.CUT == clipboard_task):
				delete_clipped_originals()
			print ("Pasting before selected reactions.")
		5:
			#Paste after
			add_reactions_at_position(clipboard, item_index + 1)
			if (clipboard_task_types.CUT == clipboard_task):
				delete_clipped_originals()
			print ("Pasting after selected reactions.")
		6:
			#Delete
			_on_DeleteReaction_pressed()
			print ("Asking for confirmation for possible deletion of reactions.")
		7:
			#Duplicate
			duplicate_selected_reactions()
			print ("Duplicating selected reactions.")

func update_wordcount(encounter):
	#In order to try to avoid sluggishness, we only do this if sort_by is set to word count or rev. word count.
	var sort_method_id = $Column1/SortMenu.get_selected_id()
	var sort_method = $Column1/SortMenu.get_popup().get_item_text(sort_method_id)
	if ("Word Count" == sort_method || "Rev. Word Count" == sort_method):
#		encounter.word_count = wordcount(encounter)
		var word_count = encounter.wordcount()
#		print("check. " + str(word_count))
		log_update(encounter)
		refresh_encounter_list()

# Encounter settings interface elements.
onready var event_selection_tree = get_node("EditEncounterSettings/EventSelection/VBC/EventTree")

func refresh_event_selection():
	event_selection_tree.clear()
	var root = event_selection_tree.create_item()
	root.set_text(0, "Encounters: ")
	for encounter in storyworld.encounters:
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
	refresh_character_lists()
	$EditEncounterSettings/DesideratumSelection.popup()

func _on_DesideratumSelection_confirmed():
	var des_character_id = $EditEncounterSettings/DesideratumSelection/HBC/CharacterSelect.get_selected_id()
	var des_character = storyworld.characters[des_character_id]
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
	for encounter in storyworld.encounters:
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

func _ready():
	$Column1/SortMenu.select(0)






