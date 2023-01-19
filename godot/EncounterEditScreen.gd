extends HSplitContainer

var current_encounter = null
var current_option = null
var current_reaction = null
var storyworld = null
var node_scene = preload("res://graphview_node.tscn")
#Track objects to delete.
var encounters_to_delete = []
var options_to_delete = null
var reactions_to_delete = null
var effect_to_delete = null
#Clipboard system variables:
var clipboard = [] #Copies of the clipped data.
var clipped_originals = [] #References to the original objects that were clipped.
enum clipboard_task_types {NONE, CUT, COPY}
var clipboard_task = clipboard_task_types.NONE

signal refresh_graphview()
signal refresh_encounter_list()

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
	emit_signal("refresh_encounter_list")

func list_option(option, cutoff = 50):
	var optionslist = $HSC/Column2/OptionsScroll/OptionsList
	var index = optionslist.get_item_count()
	var text = option.get_text()
	if ("" == text):
		optionslist.add_item("[Blank Option]")
	elif (text.left(cutoff) == text):
		optionslist.add_item(text)
	else:
		optionslist.add_item(text.left(cutoff) + "...")
		optionslist.set_item_tooltip(index, text)
	optionslist.set_item_metadata(index, option)

func refresh_option_list(cutoff = 100):
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
	var text = reaction.get_text()
	if ("" == text):
		reactionslist.add_item("[Blank Reaction]")
	elif (text.left(cutoff) == text):
		reactionslist.add_item(text)
	else:
		reactionslist.add_item(text.left(cutoff) + "...")
		reactionslist.set_item_tooltip(index, text)
	reactionslist.set_item_metadata(index, reaction)

func refresh_reaction_list(cutoff = 100):
	$HSC/Column3/ReactionsScroll/ReactionList.clear()
	if (null != current_option):
		for reaction in current_option.reactions:
			list_reaction(reaction, cutoff)

func replace_character(deleted_character, replacement):
	print("Replacing " + deleted_character.char_name + " with " + replacement.char_name)
	log_update(null)
	refresh_bnumber_property_lists()

func add_character_to_lists(character):
	refresh_bnumber_property_lists()

func refresh_character_names():
	refresh_bnumber_property_lists()

func refresh_reaction_after_effects_list():
	$HSC/Column3/AfterReactionEffectsDisplay.clear()
	$HSC/Column3/AfterReactionEffectsDisplay.list_to_display.clear()
	if (null != current_reaction):
		for change in current_reaction.after_effects:
			var entry = {"text": change.data_to_string(), "metadata": change}
			$HSC/Column3/AfterReactionEffectsDisplay.list_to_display.append(entry)
	$HSC/Column3/AfterReactionEffectsDisplay.refresh()
	$EffectEditor/EffectEditorScreen.reset()
	$EffectEditor/EffectEditorScreen.refresh()

func refresh_bnumber_property_lists():
	$HSC/Column3/HBCTT/Trait1Selector.reset()
	$HSC/Column3/HBCTT/Trait2Selector.reset()
	if (null != current_reaction):
		if (current_reaction.desirability_script is ScriptManager):
			if (current_reaction.desirability_script.contents is BlendOperator and 3 == current_reaction.desirability_script.contents.operands.size()):
				if (current_reaction.desirability_script.contents.operands[0] is BNumberPointer):
					$HSC/Column3/HBCTT/Trait1Selector.selected_property.set_as_copy_of(current_reaction.desirability_script.contents.operands[0])
				if (current_reaction.desirability_script.contents.operands[1] is BNumberPointer):
					$HSC/Column3/HBCTT/Trait2Selector.selected_property.set_as_copy_of(current_reaction.desirability_script.contents.operands[1])
			elif (current_reaction.desirability_script.contents is BNumberPointer):
				$HSC/Column3/HBCTT/Trait1Selector.selected_property.set_as_copy_of(current_reaction.desirability_script.contents)
	$HSC/Column3/HBCTT/Trait1Selector.allow_coefficient_editing = true
	$HSC/Column3/HBCTT/Trait1Selector.refresh()
	$HSC/Column3/HBCTT/Trait2Selector.allow_coefficient_editing = true
	$HSC/Column3/HBCTT/Trait2Selector.refresh()
	refresh_reaction_after_effects_list()

func refresh_spool_lists():
	refresh_reaction_after_effects_list()

func refresh_quick_reaction_scripting_interface():
	$HSC/Column3/HBCLSL/BlendWeightSelector.set_layout("", 1)
	$HSC/Column3/HBCLSL/BlendWeightSelector.storyworld = storyworld
	$HSC/Column3/HBCLSL/BlendWeightSelector.reset()
	$HSC/Column3/HBCTT/Trait1Selector.allow_coefficient_editing = true
	$HSC/Column3/HBCTT/Trait1Selector.storyworld = storyworld
	$HSC/Column3/HBCTT/Trait1Selector.reset()
	$HSC/Column3/HBCTT/Trait2Selector.allow_coefficient_editing = true
	$HSC/Column3/HBCTT/Trait2Selector.storyworld = storyworld
	$HSC/Column3/HBCTT/Trait2Selector.reset()
	if (null == current_reaction):
		$HSC/Column3/HBCLSL/BlendWeightSelector.refresh()
		$HSC/Column3/HBCTT/Trait1Selector.refresh()
		$HSC/Column3/HBCTT/Trait2Selector.refresh()
	else:
		if (current_reaction.desirability_script is ScriptManager):
			if (current_reaction.desirability_script.contents is BlendOperator
				and 3 == current_reaction.desirability_script.contents.operands.size()
				and current_reaction.desirability_script.contents.operands[0] is BNumberPointer
				and current_reaction.desirability_script.contents.operands[1] is BNumberPointer
				and current_reaction.desirability_script.contents.operands[2] is BNumberConstant):
				$HSC/Column3/HBCLSL/BlendWeightSelector.operator.set_value(current_reaction.desirability_script.contents.operands[2].get_value())
				$HSC/Column3/HBCLSL/BlendWeightSelector.refresh()
				$HSC/Column3/HBCTT/Trait1Selector.selected_property.set_as_copy_of(current_reaction.desirability_script.contents.operands[0])
				$HSC/Column3/HBCTT/Trait1Selector.refresh()
				$HSC/Column3/HBCTT/Trait2Selector.selected_property.set_as_copy_of(current_reaction.desirability_script.contents.operands[1])
				$HSC/Column3/HBCTT/Trait2Selector.refresh()
				$HSC/Column3/HBCTT/Trait2Selector.visible = true
				$HSC/Column3/HBCLSL/Label.visible = true
				$HSC/Column3/HBCLSL/Label2.visible = true
				$HSC/Column3/HBCLSL.visible = true
				$HSC/Column3/HBCTT.visible = true
			elif (current_reaction.desirability_script.contents is BNumberPointer):
				$HSC/Column3/HBCTT/Trait1Selector.selected_property.set_as_copy_of(current_reaction.desirability_script.contents)
				$HSC/Column3/HBCTT/Trait1Selector.refresh()
				$HSC/Column3/HBCTT/Trait2Selector.visible = false
				$HSC/Column3/HBCLSL.visible = false
				$HSC/Column3/HBCTT.visible = true
			elif (current_reaction.desirability_script.contents is BNumberConstant):
				$HSC/Column3/HBCLSL/BlendWeightSelector.operator.set_value(current_reaction.desirability_script.contents.get_value())
				$HSC/Column3/HBCLSL/BlendWeightSelector.refresh()
				$HSC/Column3/HBCLSL/Label.visible = false
				$HSC/Column3/HBCLSL/Label2.visible = false
				$HSC/Column3/HBCLSL.visible = true
				$HSC/Column3/HBCTT.visible = false
			else:
				$HSC/Column3/HBCLSL.visible = false
				$HSC/Column3/HBCTT.visible = false
		else:
			$HSC/Column3/HBCLSL.visible = false
			$HSC/Column3/HBCTT.visible = false

func load_Reaction(reaction):
	current_reaction = reaction
	if (null == reaction):
		$HSC/Column3/ReactionText.text = ""
		$HSC/Column3/HBCConsequence/CurrentConsequence.text = "No consequence."
		for each in $HSC/Column3.get_children():
			if ($HSC/Column3/Null_Reaction_Label == each):
				each.visible = true
			else:
				each.visible = false
	else:
		$HSC/Column3/ReactionText.text = reaction.get_text()
		if (null == reaction.consequence):
			$HSC/Column3/HBCConsequence/CurrentConsequence.text = "No consequence."
		else:
			$HSC/Column3/HBCConsequence/CurrentConsequence.text = reaction.consequence.title
		for each in $HSC/Column3.get_children():
			if ($HSC/Column3/Null_Reaction_Label == each):
				each.visible = false
			else:
				each.visible = true
	refresh_quick_reaction_scripting_interface()
	refresh_reaction_after_effects_list()

func load_Option(option):
	current_option = option
	refresh_reaction_list()
	if (null == option):
		$HSC/Column2/OptionText.text = ""
		load_Reaction(null)
	else:
		$HSC/Column2/OptionText.text = option.get_text()
		if (0 < option.reactions.size()):
			load_Reaction(option.reactions[0])
			$HSC/Column3/ReactionsScroll/ReactionList.select(0)

func load_Encounter(encounter):
	if (null == encounter):
		Clear_Encounter_Editing_Screen()
		return
	current_encounter = encounter
	$HSC/Column2/HBCTitle/EncounterTitleEdit.text = encounter.title
	$HSC/Column2/EncounterMainTextEdit.text = encounter.get_text()
	$HSC/Column2/HBCTurn/VBC/EarliestTurn.value = encounter.earliest_turn
	$HSC/Column2/HBCTurn/VBC2/LatestTurn.value = encounter.latest_turn
	refresh_bnumber_property_lists()
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
	$HSC/Column2/HBCTitle/EncounterTitleEdit.text = ""
	$HSC/Column2/EncounterMainTextEdit.text = ""
	$HSC/Column2/HBCTurn/VBC/EarliestTurn.value = 0
	$HSC/Column2/HBCTurn/VBC2/LatestTurn.value = 0
	$HSC/Column2/OptionsScroll/OptionsList.clear()
	$HSC/Column3/ReactionsScroll/ReactionList.clear()
	$HSC/Column2/OptionText.text = ""
	$HSC/Column3/ReactionText.text = ""
	$HSC/Column3/IncBlendWeightLabel.text = "Reaction desirability"
	$HSC/Column3/HBCConsequence/CurrentConsequence.text = ""
	refresh_bnumber_property_lists()
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
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false

func _on_AddButton_pressed():
	var new_encounter = storyworld.create_new_generic_encounter()
	storyworld.add_encounter(new_encounter)
	log_update(new_encounter)
	refresh_encounter_list()
	emit_signal("refresh_graphview")
	emit_signal("refresh_encounter_list")
	current_encounter = null
	current_option = null
	current_reaction = null
	load_Encounter(new_encounter)
	$Column1/VScroll/EncountersList.select(storyworld.encounters.find(new_encounter))

func _on_Edit_pressed():
	if ($Column1/VScroll/EncountersList.is_anything_selected()):
		var selection = $Column1/VScroll/EncountersList.get_selected_items()
		var encounter_index = selection[0]
		var encounter_to_edit = storyworld.encounters[encounter_index]
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
		emit_signal("refresh_encounter_list")
		if (encounter_to_edit != null):
			load_Encounter(encounter_to_edit)
			$Column1/VScroll/EncountersList.select(storyworld.encounters.find(encounter_to_edit))

func _on_EncounterTitleEdit_text_changed(new_text):
	#Change encounter title
	if (null != current_encounter):
		current_encounter.title = new_text
		update_wordcount(current_encounter)
		log_update(current_encounter)
		refresh_encounter_list()
		emit_signal("refresh_graphview")
		emit_signal("refresh_encounter_list")

func _on_EncounterMainTextEdit_text_changed():
	#Change encounter main text
	if (null != current_encounter):
		current_encounter.set_text($HSC/Column2/EncounterMainTextEdit.text)
		update_wordcount(current_encounter)
		log_update(current_encounter)
		emit_signal("refresh_graphview")

func _on_ConfirmEncounterDeletion_confirmed():
	var encounter_to_select = null
	var selection_index = storyworld.encounters.find(current_encounter) - 1
	if (null != current_encounter and encounters_to_delete.has(current_encounter) and encounters_to_delete.size() < storyworld.encounters.size()):
		while (-1 < selection_index):
			if (encounters_to_delete.has(storyworld.encounters[selection_index])):
				selection_index -= 1
			else:
				encounter_to_select = storyworld.encounters[selection_index]
				break
		if (null == encounter_to_select):
			selection_index = storyworld.encounters.find(current_encounter) + 1
			while (selection_index < storyworld.encounters.size()):
				if (encounters_to_delete.has(storyworld.encounters[selection_index])):
					selection_index += 1
				else:
					encounter_to_select = storyworld.encounters[selection_index]
					break
		load_Encounter(encounter_to_select)
	for each in encounters_to_delete:
		storyworld.delete_encounter(each)
	log_update(null)
	refresh_encounter_list()
	if (null != encounter_to_select):
		$Column1/VScroll/EncountersList.select(selection_index)
	emit_signal("refresh_graphview")
	emit_signal("refresh_encounter_list")

func _on_DeleteButton_pressed():
	if ($Column1/VScroll/EncountersList.is_anything_selected()):
		var selection = $Column1/VScroll/EncountersList.get_selected_items()
		encounters_to_delete.clear()
		for each in selection:
			encounters_to_delete.append(storyworld.encounters[each])
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

func _on_EarliestTurn_value_changed(value):
	if (null != current_encounter):
		current_encounter.earliest_turn = value
		log_update(current_encounter)

func _on_LatestTurn_value_changed(value):
	if (null != current_encounter):
		current_encounter.latest_turn = value
		log_update(current_encounter)

#Options and Reactions interface elements:
#Option editing interface:

func _on_AddOption_pressed():
	if (null != current_encounter):
		var new_option = storyworld.create_new_generic_option(current_encounter)
		current_encounter.options.append(new_option)
		list_option(new_option)
		load_Option(new_option)
		$HSC/Column2/OptionsScroll/OptionsList.select(new_option.get_index())
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_ConfirmOptionDeletion_confirmed():
	for option in options_to_delete:
		print("Deleting option: " + option.get_truncated_text(20))
		for encounter in storyworld.encounters:
			if (encounter.acceptability_script.search_and_replace(option, null)):
				log_update(encounter)
			for each in encounter.options:
				if (each.visibility_script.search_and_replace(option, null)):
					log_update(encounter)
				if (each.performability_script.search_and_replace(option, null)):
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
			dialog_text += " (" + option.get_text() + ")"
		$ConfirmOptionDeletion.dialog_text = dialog_text
		$ConfirmOptionDeletion.popup()

func _on_MoveOptionUpButton_pressed():
	if ($HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var selection = $HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		if (0 != selection[0]):
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
		if ((current_encounter.options.size()-1) != selection[0]):
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
		current_option.set_text($HSC/Column2/OptionText.text)
		var optionslist = $HSC/Column2/OptionsScroll/OptionsList
		var text = current_option.get_text()
		if ("" == text):
			optionslist.set_item_text(current_option.get_index(), "[Blank Option]")
		elif (text.left(50) == text):
			optionslist.set_item_text(current_option.get_index(), text)
		else:
			var index = current_option.get_index()
			optionslist.set_item_text(index, text.left(50) + "...")
			optionslist.set_item_tooltip(index, text)
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_OptionsList_item_rmb_selected(index, at_position):
	# Bring up context menu.
	var mouse_position = get_global_mouse_position()
	var context_menu = $HSC/Column2/OptionsScroll/OptionsList/OptionsContextMenu
	if ($HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
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
	if (0 == options_to_add.size()):
		return
	var copies_to_add = []
	for object in options_to_add:
		var copy = storyworld.create_new_generic_option(current_encounter)
		copy.set_as_copy_of(object, false)
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
		if (0 < copies_to_add.size()):
			load_Option(copies_to_add[0])
			$HSC/Column2/OptionsScroll/OptionsList.select(copies_to_add[0].get_index())
		else:
			load_Option(current_encounter.options[0])
			$HSC/Column2/OptionsScroll/OptionsList.select(current_encounter.options[0].get_index())
	else:
		load_Option(null)
	update_wordcount(current_encounter)
	log_update(current_encounter)
	emit_signal("refresh_graphview")

func duplicate_selected_options():
	if ($HSC/Column2/OptionsScroll/OptionsList.is_anything_selected()):
		var last_option_added = null
		var selection = $HSC/Column2/OptionsScroll/OptionsList.get_selected_items()
		for each in selection:
			var option = $HSC/Column2/OptionsScroll/OptionsList.get_item_metadata(each)
			var new_option = storyworld.create_new_generic_option(current_encounter)
			new_option.set_as_copy_of(option, false)
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
			var new_option = storyworld.create_new_generic_option(current_encounter)
			new_option.set_as_copy_of(option, false)
			clipboard.append(new_option)
			clipped_originals.append(option)

func delete_clipped_originals():
	if (0 >= clipped_originals.size()):
		return
	if (clipped_originals[0] is Option):
		for object in clipped_originals:
			if (object is Option):
				print("Deleting option: " + object.get_truncated_text(20))
				for encounter in storyworld.encounters:
					if (encounter.acceptability_script.search_and_replace(object, null)):
						log_update(encounter)
					for option in encounter.options:
						if (option.visibility_script.search_and_replace(object, null)):
							log_update(encounter)
						if (option.performability_script.search_and_replace(object, null)):
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
				print("Deleting reaction: " + object.get_truncated_text(20))
				for encounter in storyworld.encounters:
					if (encounter.acceptability_script.search_and_replace(object, null)):
						log_update(encounter)
					for option in encounter.options:
						if (option.visibility_script.search_and_replace(object, null)):
							log_update(encounter)
						if (option.performability_script.search_and_replace(object, null)):
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
			var new_option = storyworld.create_new_generic_option(current_encounter)
			add_options_at_position([new_option], item_index)
			print ("Adding new option before the selected one.")
		1:
			#Add new option after
			var new_option = storyworld.create_new_generic_option(current_encounter)
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

func _on_AddReaction_pressed():
	if (null != current_option):
		current_reaction = storyworld.create_new_generic_reaction(current_option)
		current_option.reactions.append(current_reaction)
		list_reaction(current_reaction)
		load_Reaction(current_reaction)
		$HSC/Column3/ReactionsScroll/ReactionList.select(current_reaction.get_index())
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_ConfirmReactionDeletion_confirmed():
	for reaction in reactions_to_delete:
		print("Deleting reaction: " + reaction.get_truncated_text(25))
		for encounter in storyworld.encounters:
			if (encounter.acceptability_script.search_and_replace(reaction, null)):
				log_update(encounter)
			for option in encounter.options:
				if (option.visibility_script.search_and_replace(reaction, null)):
					log_update(encounter)
				if (option.performability_script.search_and_replace(reaction, null)):
					log_update(encounter)
		current_option.reactions.erase(reaction)
		reaction.call_deferred("free")
	load_Option(current_option)
	if (null != current_option and 0 < current_option.reactions.size()):
		current_reaction = current_option.reactions[0]
		load_Reaction(current_reaction)
		$HSC/Column3/ReactionsScroll/ReactionList.select(0)
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
				dialog_text += " (" + reaction.get_text() + ")"
			$ConfirmReactionDeletion.dialog_text = dialog_text
			$ConfirmReactionDeletion.popup()

func _on_MoveReactionUpButton_pressed():
	if ($HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var selection = $HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		if (0 != selection[0]):
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
		if ((current_option.reactions.size()-1) != selection[0]):
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
		current_reaction.set_text($HSC/Column3/ReactionText.text)
		var index = current_reaction.get_index()
		var text = current_reaction.get_text()
		if ("" == text):
			reactionslist.set_item_text(index, "[Blank Reaction]")
		elif (text.left(50) == text):
			reactionslist.set_item_text(index, text)
		else:
			reactionslist.set_item_text(index, text.left(50) + "...")
			reactionslist.set_item_tooltip(index, text)
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_BlendWeightSelector_bnumber_value_changed(operator):
	if (null != current_reaction and null != operator and operator is BNumberConstant):
		if (current_reaction.desirability_script is ScriptManager):
			if (current_reaction.desirability_script.contents is BlendOperator
				and 3 == current_reaction.desirability_script.contents.operands.size()
				and current_reaction.desirability_script.contents.operands[2] is BNumberConstant
				and current_reaction.desirability_script.contents.operands[0] is BNumberPointer
				and current_reaction.desirability_script.contents.operands[1] is BNumberPointer):
				current_reaction.desirability_script.contents.operands[2].set_value(operator.get_value())
				$HSC/Column3/IncBlendWeightLabel.text = "Reaction desirability:"
				log_update(current_encounter)
			elif (current_reaction.desirability_script.contents is BNumberConstant):
				current_reaction.desirability_script.contents.set_value(operator.get_value())
				$HSC/Column3/IncBlendWeightLabel.text = "Reaction desirability:"
				log_update(current_encounter)

func _on_Trait1Selector_bnumber_property_selected(selected_property):
	if (null != current_reaction and null != selected_property):
		if (selected_property is BNumberPointer):
			if (current_reaction.desirability_script is ScriptManager):
				if (current_reaction.desirability_script.contents is BlendOperator and 3 == current_reaction.desirability_script.contents.operands.size()):
					current_reaction.desirability_script.contents.operands[0].set_as_copy_of(selected_property)
					log_update(current_encounter)
				elif (current_reaction.desirability_script.contents is BNumberPointer):
					current_reaction.desirability_script.contents.set_as_copy_of(selected_property)
					log_update(current_encounter)

func _on_Trait2Selector_bnumber_property_selected(selected_property):
	if (null != current_reaction and null != selected_property):
		if (selected_property is BNumberPointer):
			if (current_reaction.desirability_script is ScriptManager):
				if (current_reaction.desirability_script.contents is BlendOperator and 3 == current_reaction.desirability_script.contents.operands.size()):
					current_reaction.desirability_script.contents.operands[1].set_as_copy_of(selected_property)
					log_update(current_encounter)

func _on_ChangeConsequence_pressed():
	if (null != current_reaction):
		if ($Column1/VScroll/EncountersList.is_anything_selected()):
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

func _on_AddEffect_pressed():
	if (null != current_reaction):
		if (null != storyworld and 0 < storyworld.characters.size() and 0 < storyworld.authored_properties.size()):
			$EffectEditor/EffectEditorScreen.storyworld = storyworld
			$EffectEditor/EffectEditorScreen.reset()
		$EffectEditor.popup()
	else:
		print("No reaction currently selected.")

func _on_EffectEditor_confirmed():
	if (null != current_reaction):
		var new_change = $EffectEditor/EffectEditorScreen.get_effect()
		if (null != new_change):
			current_reaction.after_effects.append(new_change)
		refresh_reaction_after_effects_list()
		log_update(current_encounter)
	else:
		print("No reaction currently selected.")

func _on_DeleteEffect_pressed():
	var selected_change = $HSC/Column3/AfterReactionEffectsDisplay.get_selected_metadata()
	if (null != selected_change and selected_change is SWEffect):
		effect_to_delete = selected_change
		var dialog_text = ""
		dialog_text = "Are you sure you wish to delete the following reaction effect?"
		dialog_text += " \"" + selected_change.data_to_string() + "\""
		$ConfirmReactionEffectDeletion.dialog_text = dialog_text
		$ConfirmReactionEffectDeletion.popup()

func _on_ConfirmReactionEffectDeletion_confirmed():
	if (current_reaction.after_effects.has(effect_to_delete)):
		current_reaction.after_effects.erase(effect_to_delete)
		if (effect_to_delete is SWEffect):
			effect_to_delete.clear()
			effect_to_delete.call_deferred("free")
		log_update(current_encounter)
	refresh_reaction_after_effects_list()

func _on_ReactionList_item_rmb_selected(index, at_position):
	# Bring up context menu.
	var mouse_position = get_global_mouse_position()
	var context_menu = $HSC/Column3/ReactionsScroll/ReactionList/ReactionsContextMenu
	if ($HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
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
	if (0 == reactions_to_add.size()):
		return
	var copies_to_add = []
	for object in reactions_to_add:
		var copy = storyworld.create_new_generic_reaction(current_option)
		copy.set_as_copy_of(object, false)
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
		if (0 < copies_to_add.size()):
			load_Reaction(copies_to_add[0])
			$HSC/Column3/ReactionsScroll/ReactionList.select(copies_to_add[0].get_index())
		else:
			load_Reaction(current_option.reactions[0])
			$HSC/Column3/ReactionsScroll/ReactionList.select(current_option.reactions[0].get_index())
	else:
		load_Reaction(null)
	update_wordcount(current_encounter)
	log_update(current_encounter)
	emit_signal("refresh_graphview")

func duplicate_selected_reactions():
	if ($HSC/Column3/ReactionsScroll/ReactionList.is_anything_selected()):
		var last_reaction_added = null
		var selection = $HSC/Column3/ReactionsScroll/ReactionList.get_selected_items()
		for each in selection:
			var reaction = $HSC/Column3/ReactionsScroll/ReactionList.get_item_metadata(each)
			var new_reaction = storyworld.create_new_generic_reaction(current_option)
			new_reaction.set_as_copy_of(reaction, false)
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
			var new_reaction = storyworld.create_new_generic_reaction(current_option)
			new_reaction.set_as_copy_of(reaction, false)
			clipboard.append(new_reaction)
			clipped_originals.append(reaction)

func _on_ReactionsContextMenu_id_pressed(id):
	var item_index = $HSC/Column3/ReactionsScroll/ReactionList/ReactionsContextMenu.get_item_metadata(id)
	match id:
		0:
			#Add new reaction before
			var new_reaction = storyworld.create_new_generic_reaction(current_option)
			add_reactions_at_position([new_reaction], item_index)
			print ("Adding new reaction before the selected one.")
		1:
			#Add new reaction after
			var new_reaction = storyworld.create_new_generic_reaction(current_option)
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
		var word_count = encounter.wordcount()
		log_update(encounter)
		refresh_encounter_list()

func _ready():
	if (0 < $Column1/SortMenu.get_item_count()):
		$Column1/SortMenu.select(0)

#Script Editing:

func _on_EditEncounterAcceptabilityScriptButton_pressed():
	if (null != current_encounter and current_encounter is Encounter):
		$ScriptEditWindow/ScriptEditScreen/Background/VBC/Label.text = current_encounter.title + " Acceptability Script"
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = current_encounter.acceptability_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup()
	else:
		print("You must open an encounter before you can edit its settings.")

func _on_EditEncounterDesirabilityScriptButton_pressed():
	if (null != current_encounter and current_encounter is Encounter):
		$ScriptEditWindow/ScriptEditScreen/Background/VBC/Label.text = current_encounter.title + " Desirability Script"
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = current_encounter.desirability_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup()
	else:
		print("You must open an encounter before you can edit its settings.")

func _on_ARDSEButton_pressed():
	var title = current_reaction.get_truncated_text(40)
	title += "Reaction Desirability Script"
	$ScriptEditWindow/ScriptEditScreen/Background/VBC/Label.text = title
	$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
	$ScriptEditWindow/ScriptEditScreen.script_to_edit = current_reaction.desirability_script
	$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
	$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
	$ScriptEditWindow.popup()

func _on_ScriptEditScreen_sw_script_changed(sw_script):
	if (current_encounter.acceptability_script == sw_script):
		emit_signal("refresh_graphview")
		log_update(current_encounter)
	if (current_encounter.desirability_script == sw_script):
		log_update(current_encounter)
	if (current_reaction.desirability_script == sw_script):
		load_Reaction(current_reaction)
		log_update(current_encounter)

func _on_AfterReactionEffectsDisplay_moved_item(item, from_index, to_index):
	if (null == current_reaction):
		refresh_reaction_after_effects_list()
		return
	var effect = current_reaction.after_effects.pop_at(from_index)
	print(effect.data_to_string())
	print(str(current_reaction.after_effects.size()))
	if (to_index > from_index):
		to_index = to_index - 1
	if (to_index < current_reaction.after_effects.size()):
		current_reaction.after_effects.insert(to_index, effect)
	else:
		current_reaction.after_effects.append(effect)

func _on_AfterReactionEffectsDisplay_item_activated():
	pass

func _on_EditOptionVisibilityScriptButton_pressed():
	if (null != current_option and current_option is Option):
		var title = current_option.get_truncated_text(40)
		title += "Option Visibility Script"
		$ScriptEditWindow/ScriptEditScreen/Background/VBC/Label.text = title
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = current_option.visibility_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup()

func _on_EditOptionPerformabilityScriptButton_pressed():
	if (null != current_option and current_option is Option):
		var title = current_option.get_truncated_text(40)
		title += "Option Performability Script"
		$ScriptEditWindow/ScriptEditScreen/Background/VBC/Label.text = title
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = current_option.performability_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup()

