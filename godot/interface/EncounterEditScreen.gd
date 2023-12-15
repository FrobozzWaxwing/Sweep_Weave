extends HSplitContainer

var current_encounter = null
var current_option = null
var current_reaction = null
var storyworld = null
#Track items to delete.
var items_to_delete = []
#Clipboard system variables:
var clipboard = null
#Display options:
#Track whether or not to display the quick desirability script editors.
var display_encounter_qdse = false
var display_reaction_qdse = true
#Clarity is a light mode theme, while Lapis Lazuli is a dark mode theme.
var light_mode = true

signal refresh_graphview()
signal refresh_encounter_list()

func refresh_encounter_list():
	$Column1/VScroll/EncountersList.clear()
	var sort_method_id = $Column1/SortBar/SortMenu.get_selected_id()
	var sort_method = $Column1/SortBar/SortMenu.get_popup().get_item_text(sort_method_id)
	var reversed = $Column1/SortBar/ToggleReverseButton.pressed
	storyworld.sort_encounters(sort_method, reversed)
	var index = 0
	for entry in storyworld.encounters:
		if ("" == entry.title):
			$Column1/VScroll/EncountersList.add_item("[Untitled]")
		else:
			$Column1/VScroll/EncountersList.add_item(entry.title)
		$Column1/VScroll/EncountersList.set_item_metadata(index, entry)
		index += 1
	if (0 == storyworld.encounters.size()):
		Clear_Encounter_Editing_Screen()

onready var sort_alpha_icon_light = preload("res://icons/sort-alpha-down.svg")
onready var sort_alpha_icon_dark = preload("res://icons/sort-alpha-down_dark.svg")
onready var sort_rev_alpha_icon_light = preload("res://icons/sort-alpha-down-alt.svg")
onready var sort_rev_alpha_icon_dark = preload("res://icons/sort-alpha-down-alt_dark.svg")
onready var sort_numeric_icon_light = preload("res://icons/sort-numeric-down.svg")
onready var sort_numeric_icon_dark = preload("res://icons/sort-numeric-down_dark.svg")
onready var sort_rev_numeric_icon_light = preload("res://icons/sort-numeric-down-alt.svg")
onready var sort_rev_numeric_icon_dark = preload("res://icons/sort-numeric-down-alt_dark.svg")

func refresh_sort_icon():
	var sort_index = $Column1/SortBar/SortMenu.get_selected()
	var sort_method = $Column1/SortBar/SortMenu.get_popup().get_item_text(sort_index)
	var reversed = $Column1/SortBar/ToggleReverseButton.pressed
	if (light_mode):
		if ("Alphabetical" == sort_method or "Characters" == sort_method or "Spools" == sort_method):
			if (reversed):
				$Column1/SortBar/ToggleReverseButton.icon = sort_rev_alpha_icon_dark
			else:
				$Column1/SortBar/ToggleReverseButton.icon = sort_alpha_icon_dark
		else:
			if (reversed):
				$Column1/SortBar/ToggleReverseButton.icon = sort_rev_numeric_icon_dark
			else:
				$Column1/SortBar/ToggleReverseButton.icon = sort_numeric_icon_dark
	else:
		if ("Alphabetical" == sort_method or "Characters" == sort_method or "Spools" == sort_method):
			if (reversed):
				$Column1/SortBar/ToggleReverseButton.icon = sort_rev_alpha_icon_light
			else:
				$Column1/SortBar/ToggleReverseButton.icon = sort_alpha_icon_light
		else:
			if (reversed):
				$Column1/SortBar/ToggleReverseButton.icon = sort_rev_numeric_icon_light
			else:
				$Column1/SortBar/ToggleReverseButton.icon = sort_numeric_icon_light

func _on_SortMenu_item_selected(index):
	var sort_method = $Column1/SortBar/SortMenu.get_popup().get_item_text(index)
	if ("Word Count" == sort_method):
		for each in storyworld.encounters:
			update_wordcount(each)
	refresh_encounter_list()
	refresh_sort_icon()
	emit_signal("refresh_encounter_list")

func _on_ToggleReverseButton_toggled(button_pressed):
	refresh_encounter_list()
	refresh_sort_icon()

func set_display_encounter_list(display):
	$Column1.visible = display

func set_display_encounter_qdse(display):
	display_encounter_qdse = display
	refresh_quick_encounter_scripting_interface()

func set_display_reaction_qdse(display):
	display_reaction_qdse = display
	refresh_quick_reaction_scripting_interface()

func set_clipboard(new_clipboard):
	clipboard = new_clipboard
	$HSC/Column2/OptionsList.clipboard = new_clipboard
	$HSC/Column3/ReactionsList.clipboard = new_clipboard
	$HSC/Column3/AfterReactionEffectsDisplay.clipboard = new_clipboard

func refresh_option_list():
	$HSC/Column2/OptionsList.clear()
	if (null != current_encounter):
		$HSC/Column2/OptionsList.items_to_list = current_encounter.options.duplicate()
		$HSC/Column2/OptionsList.refresh()
		if (0 < current_encounter.options.size()):
			load_Option(current_encounter.options.front())
			$HSC/Column2/OptionsList.select_first_item()
	else:
		$HSC/Column2/OptionsList.items_to_list.clear()
		$HSC/Column2/OptionsList.refresh()

func refresh_reaction_list():
	$HSC/Column3/ReactionsList.clear()
	if (null != current_option):
		$HSC/Column3/ReactionsList.items_to_list = current_option.reactions.duplicate()
		$HSC/Column3/ReactionsList.refresh()
		if (0 < current_option.reactions.size()):
			load_Reaction(current_option.reactions.front())
			$HSC/Column3/ReactionsList.select_first_item()
	else:
		$HSC/Column3/ReactionsList.items_to_list.clear()
		$HSC/Column3/ReactionsList.refresh()

func replace_character(deleted_character, replacement):
	log_update(null)
	refresh_bnumber_property_lists()

func add_character_to_lists(character):
	refresh_bnumber_property_lists()

func refresh_character_names():
	refresh_bnumber_property_lists()

func refresh_reaction_after_effects_list():
	$HSC/Column3/AfterReactionEffectsDisplay.clear()
	if (null != current_reaction):
		$HSC/Column3/AfterReactionEffectsDisplay.items_to_list = current_reaction.after_effects.duplicate()
	else:
		$HSC/Column3/AfterReactionEffectsDisplay.items_to_list.clear()
	$HSC/Column3/AfterReactionEffectsDisplay.refresh()
	$EffectEditor/EffectEditorScreen.reset()
	$EffectEditor/EffectEditorScreen.refresh()

func refresh_bnumber_property_lists():
	$HSC/Column2/SimplifiedEncounterDesirabilityScriptingInterface.storyworld = storyworld
	$HSC/Column2/SimplifiedEncounterDesirabilityScriptingInterface.refresh_bnumber_property_lists()
	$HSC/Column3/SimplifiedReactionDesirabilityScriptingInterface.storyworld = storyworld
	$HSC/Column3/SimplifiedReactionDesirabilityScriptingInterface.refresh_bnumber_property_lists()
	refresh_reaction_after_effects_list()

func refresh_spool_lists():
	refresh_reaction_after_effects_list()

func refresh_quick_encounter_scripting_interface():
	$HSC/Column2/SimplifiedEncounterDesirabilityScriptingInterface.storyworld = storyworld
	if (current_encounter is Encounter and current_encounter.desirability_script is ScriptManager):
		$HSC/Column2/SimplifiedEncounterDesirabilityScriptingInterface.script_to_edit = current_encounter.desirability_script
		$HSC/Column2/SimplifiedEncounterDesirabilityScriptingInterface.refresh()
		if (display_encounter_qdse):
			$HSC/Column2/SimplifiedEncounterDesirabilityScriptingInterface.set_visible(true)
		else:
			$HSC/Column2/SimplifiedEncounterDesirabilityScriptingInterface.set_visible(false)
	else:
		$HSC/Column2/SimplifiedEncounterDesirabilityScriptingInterface.script_to_edit = null
		$HSC/Column2/SimplifiedEncounterDesirabilityScriptingInterface.set_visible(false)

func refresh_quick_reaction_scripting_interface():
	$HSC/Column3/SimplifiedReactionDesirabilityScriptingInterface.storyworld = storyworld
	if (current_reaction is Reaction and current_reaction.desirability_script is ScriptManager):
		$HSC/Column3/SimplifiedReactionDesirabilityScriptingInterface.script_to_edit = current_reaction.desirability_script
		$HSC/Column3/SimplifiedReactionDesirabilityScriptingInterface.refresh()
		if (display_reaction_qdse):
			$HSC/Column3/SimplifiedReactionDesirabilityScriptingInterface.set_visible(true)
		else:
			$HSC/Column3/SimplifiedReactionDesirabilityScriptingInterface.set_visible(false)
	else:
		$HSC/Column3/SimplifiedReactionDesirabilityScriptingInterface.script_to_edit = null
		$HSC/Column3/SimplifiedReactionDesirabilityScriptingInterface.set_visible(false)

func refresh_reaction_consequence_display():
	if (current_reaction is Reaction):
		if (null == current_reaction.consequence):
			$HSC/Column3/HBCConsequence/ChangeConsequence.visible = false
			$HSC/Column3/HBCConsequence/ChangeConsequence.set_text("")
		elif (current_reaction.consequence is Encounter):
			$HSC/Column3/HBCConsequence/ChangeConsequence.set_text("Next page set to: " + current_reaction.consequence.title)
			$HSC/Column3/HBCConsequence/ChangeConsequence.visible = true
		else:
			#Error:
			$HSC/Column3/HBCConsequence/ChangeConsequence.visible = false
			$HSC/Column3/HBCConsequence/ChangeConsequence.set_text("")

func load_Reaction(reaction):
	current_reaction = reaction
	if (null == reaction):
		$HSC/Column3/ReactionText.set_text("")
		for each in $HSC/Column3.get_children():
			if ($HSC/Column3/Null_Reaction_Label == each):
				each.set_visible(true)
			else:
				each.set_visible(false)
	else:
		$HSC/Column3/ReactionText.set_text(reaction.get_text())
		for each in $HSC/Column3.get_children():
			if ($HSC/Column3/Null_Reaction_Label == each):
				each.set_visible(false)
			else:
				each.set_visible(true)
	refresh_reaction_consequence_display()
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
			$HSC/Column3/ReactionsList.select_first_item()

func load_Encounter(encounter):
	if (null == encounter):
		Clear_Encounter_Editing_Screen()
		return
	current_encounter = encounter
	$HSC/Column2/HBCTitle/EncounterTitleEdit.text = encounter.title
	$HSC/Column2/EncounterMainTextEdit.text = encounter.get_text()
	refresh_bnumber_property_lists()
	refresh_quick_encounter_scripting_interface()
	refresh_option_list()
	if (0 < encounter.options.size()):
		load_Option(encounter.options[0])
		$HSC/Column2/OptionsList.select_first_item()
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
	$HSC/Column2/OptionsList.items_to_list.clear()
	$HSC/Column2/OptionsList.refresh()
	$HSC/Column2/OptionText.text = ""
	$HSC/Column3/ReactionsList.items_to_list.clear()
	$HSC/Column3/ReactionsList.refresh()
	$HSC/Column3/ReactionText.text = ""
	$HSC/Column3/AfterReactionEffectsDisplay.items_to_list.clear()
	$HSC/Column3/AfterReactionEffectsDisplay.refresh()
	refresh_bnumber_property_lists()
	refresh_quick_encounter_scripting_interface()
	load_Option(null)

func load_and_focus_first_encounter():
	if (0 < storyworld.encounters.size()):
		load_Encounter(storyworld.encounters.front())
		$Column1/VScroll/EncountersList.select(0)

func log_update(encounter = null):
	#If encounter == null, then the project as a whole is being updated, rather than a specific encounter, or an encounter has been added, deleted, or duplicated.
	if (null != encounter):
		encounter.log_update()
	storyworld.log_update()
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false
	emit_signal("refresh_encounter_list")

#Encounter editing interface:

func _on_AddButton_pressed():
	var new_encounter = storyworld.create_new_generic_encounter()
	storyworld.add_encounter(new_encounter)
	log_update(new_encounter)
	refresh_encounter_list()
	emit_signal("refresh_graphview")
	load_Encounter(new_encounter)
	$Column1/VScroll/EncountersList.select(storyworld.encounters.find(new_encounter))

func _on_EncountersList_multi_selected(index, selected):
	var encounter_to_edit = $Column1/VScroll/EncountersList.get_item_metadata(index)
	load_Encounter(encounter_to_edit)

func _on_Duplicate_pressed():
	if ($Column1/VScroll/EncountersList.is_anything_selected()):
		var selected_indices = $Column1/VScroll/EncountersList.get_selected_items()
		var encounters_to_duplicate = []
		for index in selected_indices:
			var encounter = $Column1/VScroll/EncountersList.get_item_metadata(index)
			encounters_to_duplicate.append(encounter)
		var encounter_to_edit = null
		for entry in encounters_to_duplicate:
			var new_encounter = storyworld.duplicate_encounter(entry)
			if (encounter_to_edit == null):
				encounter_to_edit = new_encounter
		log_update(null)
		refresh_encounter_list()
		emit_signal("refresh_graphview")
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

func _on_EncounterMainTextEdit_text_changed():
	#Change encounter main text
	if (null != current_encounter):
		current_encounter.set_text($HSC/Column2/EncounterMainTextEdit.text)
		update_wordcount(current_encounter)
		log_update(current_encounter)
		emit_signal("refresh_graphview")

func _on_ConfirmDeletion_confirmed():
	if (items_to_delete.front() is Encounter):
		var encounter_to_select = current_encounter
		var starting_index = storyworld.encounters.find(current_encounter)
		if (null != current_encounter and items_to_delete.has(current_encounter) and items_to_delete.size() < storyworld.encounters.size()):
			for index in range(starting_index, storyworld.encounters.size()):
				if (!items_to_delete.has(storyworld.encounters[index])):
					encounter_to_select = storyworld.encounters[index]
					break
			if (encounter_to_select == current_encounter):
				for index in range(starting_index, -1, -1):
					if (!items_to_delete.has(storyworld.encounters[index])):
						encounter_to_select = storyworld.encounters[index]
						break
			if (encounter_to_select == current_encounter):
				encounter_to_select = null
			load_Encounter(encounter_to_select)
		for each in items_to_delete:
			storyworld.delete_encounter(each)
		refresh_encounter_list()
		if (null != encounter_to_select):
			$Column1/VScroll/EncountersList.select(storyworld.encounters.find(encounter_to_select))
		log_update(null)
	elif (items_to_delete.front() is Option):
		for option in items_to_delete:
			storyworld.delete_option_from_scripts(option)
			option.encounter.options.erase(option)
			option.clear()
			option.call_deferred("free")
		refresh_option_list()
		if (!current_encounter.options.empty()):
			load_Option(current_encounter.options.front())
			$HSC/Column2/OptionsList.select_first_item()
		else:
			load_Option(null)
		update_wordcount(current_encounter)
		log_update(current_encounter)
	elif (items_to_delete.front() is Reaction):
		for reaction in items_to_delete:
			storyworld.delete_reaction_from_scripts(reaction)
			reaction.option.reactions.erase(reaction)
			reaction.clear()
			reaction.call_deferred("free")
		load_Option(current_option)
		if (null != current_option and 0 < current_option.reactions.size()):
			current_reaction = current_option.reactions[0]
			load_Reaction(current_reaction)
			$HSC/Column3/ReactionsList.select_first_item()
		update_wordcount(current_encounter)
		log_update(current_encounter)
	elif (items_to_delete.front() is SWEffect):
		for effect in items_to_delete:
			current_reaction.after_effects.erase(effect)
			effect.clear()
			effect.call_deferred("free")
		log_update(current_encounter)
		refresh_reaction_after_effects_list()
	emit_signal("refresh_graphview")

func _on_DeleteButton_pressed():
	if ($Column1/VScroll/EncountersList.is_anything_selected()):
		var selected_indices = $Column1/VScroll/EncountersList.get_selected_items()
		items_to_delete.clear()
		$ConfirmDeletion/ItemsToDelete.clear()
		for index in selected_indices:
			var encounter = $Column1/VScroll/EncountersList.get_item_metadata(index)
			items_to_delete.append(encounter)
			$ConfirmDeletion/ItemsToDelete.add_item(encounter.title)
		if (!items_to_delete.empty()):
			if (1 == items_to_delete.size()):
				$ConfirmDeletion.dialog_text = "Are you sure you wish to delete the following encounter?"
			else:
				$ConfirmDeletion.dialog_text = "Are you sure you wish to delete the following encounters?"
			$ConfirmDeletion.popup_centered()

#Option editing interface:

func _on_AddOption_pressed():
	if (null != current_encounter):
		var new_option = storyworld.create_new_generic_option(current_encounter)
		current_encounter.options.append(new_option)
		$HSC/Column2/OptionsList.items_to_list.append(new_option)
		$HSC/Column2/OptionsList.list_item(new_option)
		load_Option(new_option)
		$HSC/Column2/OptionsList.deselect_all()
		$HSC/Column2/OptionsList.select_last_item()
		update_wordcount(current_encounter)
		log_update(current_encounter)

func confirm_option_deletion(options):
	items_to_delete = options
	if (!items_to_delete.empty()):
		$ConfirmDeletion/ItemsToDelete.clear()
		for each in items_to_delete:
			$ConfirmDeletion/ItemsToDelete.add_item(each.get_listable_text(30))
		if (1 == items_to_delete.size()):
			$ConfirmDeletion.dialog_text = "Are you sure you wish to delete the following option?"
		else:
			$ConfirmDeletion.dialog_text = "Are you sure you wish to delete the following options?"
		$ConfirmDeletion.popup_centered()

func _on_DeleteOption_pressed():
	confirm_option_deletion($HSC/Column2/OptionsList.get_all_selected_metadata())

func _on_OptionsList_moved_item(item, from_index, to_index):
	if (null == current_encounter):
		refresh_option_list()
		return
	var option = current_encounter.options.pop_at(from_index)
	if (to_index > from_index):
		to_index = to_index - 1
	if (to_index < current_encounter.options.size()):
		current_encounter.options.insert(to_index, option)
	else:
		current_encounter.options.append(option)

func _on_MoveOptionUpButton_pressed():
	$HSC/Column2/OptionsList.raise_selected_item()

func _on_MoveOptionDownButton_pressed():
	$HSC/Column2/OptionsList.lower_selected_item()

func _on_OptionsList_multi_selected(item, column, selected):
	var selected_option = $HSC/Column2/OptionsList.get_first_selected_metadata()
	if (null != selected_option):
		current_option = selected_option
		load_Option(current_option)
		load_Reaction(current_option.reactions.front())
		$HSC/Column3/ReactionsList.select_first_item()

func _on_OptionText_text_changed(new_text):
	if (null != current_option):
		current_option.set_text($HSC/Column2/OptionText.text)
		$HSC/Column2/OptionsList.refresh()
		$HSC/Column2/OptionsList.select_linked_item(current_option)
		update_wordcount(current_encounter)
		log_update(current_encounter)

#Option list context menu:

func add_options_at_position(options_to_add, position):
	if (1 == options_to_add.size()):
		current_encounter.options.insert(position, options_to_add.front())
	elif (0 >= position):
		options_to_add.append_array(current_encounter.options)
		current_encounter.options = options_to_add
	elif (position < current_encounter.options.size()):
		var new_array = current_encounter.options.slice(0, (position - 1))
		new_array.append_array(options_to_add)
		new_array.append_array(current_encounter.options.slice(position, (current_encounter.options.size() - 1)))
		current_encounter.options = new_array
	elif (position >= current_encounter.options.size()):
		current_encounter.options.append_array(options_to_add)

func duplicate_selected_options(selected_items):
	if (!selected_items.empty()):
		var last_option_added = null
		for option in selected_items:
			var new_option = storyworld.create_new_generic_option(current_encounter)
			new_option.set_as_copy_of(option, false)
			new_option.encounter = current_encounter
			current_encounter.options.append(new_option)
			$HSC/Column2/OptionsList.items_to_list.append(new_option)
			$HSC/Column2/OptionsList.list_item(new_option)
			last_option_added = new_option
		load_Option(last_option_added)
		$HSC/Column2/OptionsList.select_only_linked_item(last_option_added)
		update_wordcount(current_encounter)
		log_update(current_encounter)
		emit_signal("refresh_graphview")

func _on_OptionsList_add_at(index):
	if (null != current_encounter):
		var new_option = storyworld.create_new_generic_option(current_encounter)
		current_encounter.options.insert(index, new_option)
		refresh_option_list()
		load_Option(new_option)
		$HSC/Column2/OptionsList.select_only_linked_item(new_option)
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_OptionsList_cut(items):
	clipboard.cut(items)

func _on_OptionsList_copy(items):
	clipboard.copy(items)

func _on_OptionsList_paste_at(index):
	var items_to_add = clipboard.paste()
	if (!items_to_add.empty()):
		add_options_at_position(items_to_add, index)
		if (clipboard.clipboard_task_types.CUT == clipboard.clipboard_task):
			clipboard.delete_clipped_originals()
		refresh_option_list()
		load_Option(items_to_add.front())
		$HSC/Column2/OptionsList.select_only_linked_item(items_to_add.front())
		update_wordcount(current_encounter)
		log_update(current_encounter)
		emit_signal("refresh_graphview")

#Reaction editing interface:

func _on_AddReaction_pressed():
	if (null != current_option):
		current_reaction = storyworld.create_new_generic_reaction(current_option)
		current_option.reactions.append(current_reaction)
		$HSC/Column3/ReactionsList.items_to_list.append(current_reaction)
		$HSC/Column3/ReactionsList.list_item(current_reaction)
		load_Reaction(current_reaction)
		$HSC/Column3/ReactionsList.deselect_all()
		$HSC/Column3/ReactionsList.select_last_item()
		update_wordcount(current_encounter)
		log_update(current_encounter)

func confirm_reaction_deletion(reactions):
	items_to_delete = reactions
	if (!items_to_delete.empty()):
		$ConfirmDeletion/ItemsToDelete.clear()
		for each in items_to_delete:
			$ConfirmDeletion/ItemsToDelete.add_item(each.get_listable_text(30))
		if (1 == current_option.reactions.size()):
			$CannotDelete.dialog_text = 'Cannot delete reaction. Each option must have at least one reaction.'
			$CannotDelete.popup_centered()
		elif(items_to_delete.size() == current_option.reactions.size()):
			#Print "reactions" instead of "reaction."
			$CannotDelete.dialog_text = 'Cannot delete reactions. Each option must have at least one reaction.'
			$CannotDelete.popup_centered()
		else:
			if (1 == items_to_delete.size()):
				$ConfirmDeletion.dialog_text = "Are you sure you wish to delete the following reaction?"
			else:
				$ConfirmDeletion.dialog_text = "Are you sure you wish to delete the following reactions?"
			$ConfirmDeletion.popup_centered()

func _on_DeleteReaction_pressed():
	confirm_reaction_deletion($HSC/Column3/ReactionsList.get_all_selected_metadata())

func _on_ReactionsList_moved_item(item, from_index, to_index):
	if (null == current_option):
		refresh_reaction_list()
		return
	var reaction = current_option.reactions.pop_at(from_index)
	if (to_index > from_index):
		to_index = to_index - 1
	if (to_index < current_option.reactions.size()):
		current_option.reactions.insert(to_index, reaction)
	else:
		current_option.reactions.append(reaction)

func _on_MoveReactionUpButton_pressed():
	$HSC/Column3/ReactionsList.raise_selected_item()

func _on_MoveReactionDownButton_pressed():
	$HSC/Column3/ReactionsList.lower_selected_item()

func _on_ReactionsList_multi_selected(item, column, selected):
	var selected_reaction = $HSC/Column3/ReactionsList.get_first_selected_metadata()
	if (null != selected_reaction):
		current_reaction = selected_reaction
		load_Reaction(current_reaction)

func _on_ReactionText_text_changed():
	if (null != current_reaction):
		current_reaction.set_text($HSC/Column3/ReactionText.text)
		$HSC/Column3/ReactionsList.refresh()
		$HSC/Column3/ReactionsList.select_linked_item(current_reaction)
		update_wordcount(current_encounter)
		log_update(current_encounter)

func _on_SimplifiedReactionDesirabilityScriptingInterface_sw_script_changed(sw_script):
	log_update(current_encounter)

#Reaction list context menu:

func add_reactions_at_position(reactions_to_add, position):
	if (1 == reactions_to_add.size()):
		current_option.reactions.insert(position, reactions_to_add.front())
	elif (0 >= position):
		reactions_to_add.append_array(current_option.reactions)
		current_option.reactions = reactions_to_add
	elif (position < current_option.reactions.size()):
		var new_array = current_option.reactions.slice(0, (position - 1))
		new_array.append_array(reactions_to_add)
		new_array.append_array(current_option.reactions.slice(position, (current_option.reactions.size() - 1)))
		current_option.reactions = new_array
	elif (position >= current_option.reactions.size()):
		current_option.reactions.append_array(reactions_to_add)

func duplicate_selected_reactions(selected_items):
	if (!selected_items.empty()):
		var last_reaction_added = null
		for reaction in selected_items:
			var new_reaction = storyworld.create_new_generic_reaction(current_option)
			new_reaction.set_as_copy_of(reaction, false)
			new_reaction.option = current_option
			current_option.reactions.append(new_reaction)
			$HSC/Column3/ReactionsList.items_to_list.append(new_reaction)
			$HSC/Column3/ReactionsList.list_item(new_reaction)
			last_reaction_added = new_reaction
		load_Reaction(last_reaction_added)
		$HSC/Column3/ReactionsList.select_only_linked_item(last_reaction_added)
		update_wordcount(current_encounter)
		log_update(current_encounter)
		emit_signal("refresh_graphview")

func _on_ReactionsList_add_at(index):
	var new_reaction = storyworld.create_new_generic_reaction(current_option)
	current_option.reactions.insert(index, new_reaction)
	refresh_reaction_list()
	load_Reaction(new_reaction)
	$HSC/Column3/ReactionsList.select_only_linked_item(new_reaction)
	update_wordcount(current_encounter)
	log_update(current_encounter)

func _on_ReactionsList_cut(items):
	clipboard.cut(items)

func _on_ReactionsList_copy(items):
	clipboard.copy(items)

func _on_ReactionsList_paste_at(index):
	var items_to_add = clipboard.paste()
	if (!items_to_add.empty()):
		add_reactions_at_position(items_to_add, index)
		if (clipboard.clipboard_task_types.CUT == clipboard.clipboard_task):
			clipboard.delete_clipped_originals()
		refresh_reaction_list()
		load_Reaction(items_to_add.front())
		$HSC/Column3/ReactionsList.select_only_linked_item(items_to_add.front())
		update_wordcount(current_encounter)
		log_update(current_encounter)
		emit_signal("refresh_graphview")

#Effect editing interface:

func _on_ChangeConsequence_pressed():
	if (current_reaction is Reaction):
		$EffectEditor/EffectEditorScreen.storyworld = storyworld
		$EffectEditor/EffectEditorScreen.reset()
		$EffectEditor/EffectEditorScreen.load_effect(current_reaction.consequence)
		$EffectEditor.popup_centered()

func _on_AddEffect_pressed():
	if (null != current_reaction):
		if (null != storyworld and 0 < storyworld.characters.size() and 0 < storyworld.authored_properties.size()):
			$EffectEditor/EffectEditorScreen.storyworld = storyworld
			$EffectEditor/EffectEditorScreen.reset()
		items_to_delete.clear()
		$EffectEditor.popup_centered()

func _on_EffectEditor_confirmed():
	if (null != current_reaction):
		var new_change = $EffectEditor/EffectEditorScreen.get_effect()
		if (null != new_change):
			if (new_change is SWEffect):
				new_change.cause = current_reaction
				var index = -1
				if (!items_to_delete.empty()):
					index = current_reaction.after_effects.find(items_to_delete.front())
				if (-1 == index):
					current_reaction.after_effects.append(new_change)
					refresh_reaction_after_effects_list()
					log_update(current_encounter)
				else:
					current_reaction.after_effects[index] = new_change
					refresh_reaction_after_effects_list()
					log_update(current_encounter)
				items_to_delete.clear()
			elif (new_change is EventPointer):
				if (null == new_change.encounter or new_change.encounter is Encounter):
					current_reaction.consequence = new_change.encounter
					refresh_reaction_consequence_display()
					log_update(current_encounter)
					emit_signal("refresh_graphview")

func confirm_effect_deletion(effects):
	items_to_delete = effects.duplicate()
	if (!items_to_delete.empty()):
		$ConfirmDeletion/ItemsToDelete.clear()
		for each in items_to_delete:
			$ConfirmDeletion/ItemsToDelete.add_item(each.data_to_string())
		if (!items_to_delete.empty()):
			if (1 == items_to_delete.size()):
				$ConfirmDeletion.dialog_text = "Are you sure you wish to delete the following effect?"
			else:
				$ConfirmDeletion.dialog_text = "Are you sure you wish to delete the following effects?"
			$ConfirmDeletion.popup_centered()

func _on_DeleteEffect_pressed():
	confirm_effect_deletion($HSC/Column3/AfterReactionEffectsDisplay.get_all_selected_metadata())

func _on_AfterReactionEffectsDisplay_moved_item(item, from_index, to_index):
	if (null == current_reaction):
		refresh_reaction_after_effects_list()
		return
	var effect = current_reaction.after_effects.pop_at(from_index)
	if (to_index > from_index):
		to_index = to_index - 1
	if (to_index < current_reaction.after_effects.size()):
		current_reaction.after_effects.insert(to_index, effect)
	else:
		current_reaction.after_effects.append(effect)

func _on_MoveEffectUpButton_pressed():
	$HSC/Column3/AfterReactionEffectsDisplay.raise_selected_item()

func _on_MoveEffectDownButton_pressed():
	$HSC/Column3/AfterReactionEffectsDisplay.lower_selected_item()

func _on_AfterReactionEffectsDisplay_item_activated():
	if (null != current_reaction):
		if (null != storyworld):
			$EffectEditor/EffectEditorScreen.storyworld = storyworld
			$EffectEditor/EffectEditorScreen.reset()
			var effect = $HSC/Column3/AfterReactionEffectsDisplay.get_first_selected_metadata()
			$EffectEditor/EffectEditorScreen.load_effect(effect)
			items_to_delete.clear()
			items_to_delete.append(effect)
			$EffectEditor.popup_centered()

func _on_AfterReactionEffectsDisplay_edit_effect_script(effect):
	if (effect is SWEffect):
		if (null != storyworld):
			$EffectEditor/EffectEditorScreen.storyworld = storyworld
			$EffectEditor/EffectEditorScreen.reset()
			$EffectEditor/EffectEditorScreen.load_effect(effect)
			items_to_delete.clear()
			items_to_delete.append(effect)
			$EffectEditor.popup_centered()

#Effect list context menu:

func add_effects_at_position(effects_to_add, position):
	if (1 == effects_to_add.size()):
		current_reaction.after_effects.insert(position, effects_to_add.front())
	elif (0 >= position):
		effects_to_add.append_array(current_reaction.after_effects)
		current_reaction.after_effects = effects_to_add
	elif (position < current_reaction.after_effects.size()):
		var new_array = current_reaction.after_effects.slice(0, (position - 1))
		new_array.append_array(effects_to_add)
		new_array.append_array(current_reaction.after_effects.slice(position, (current_reaction.after_effects.size() - 1)))
		current_reaction.after_effects = new_array
	elif (position >= current_reaction.after_effects.size()):
		current_reaction.after_effects.append_array(effects_to_add)

func duplicate_selected_effects(selected_items):
	if (!selected_items.empty()):
		for item in selected_items:
			var change_made = false
			if (item is BNumberEffect):
				var copy = BNumberEffect.new()
				copy.set_as_copy_of(item)
				copy.cause = current_reaction
				current_reaction.after_effects.append(copy)
				$HSC/Column3/AfterReactionEffectsDisplay.items_to_list.append(copy)
				$HSC/Column3/AfterReactionEffectsDisplay.list_item(copy)
				change_made = true
			elif (item is SpoolEffect):
				var copy = SpoolEffect.new()
				copy.set_as_copy_of(item)
				copy.cause = current_reaction
				current_reaction.after_effects.append(copy)
				$HSC/Column3/AfterReactionEffectsDisplay.items_to_list.append(copy)
				$HSC/Column3/AfterReactionEffectsDisplay.list_item(copy)
				change_made = true
			if (change_made):
				log_update(current_encounter)

func _on_AfterReactionEffectsDisplay_add_at(index):
	pass # To do: let authors create new effects that are inserted into the effects list in a specified location upon being created.

func _on_AfterReactionEffectsDisplay_cut(items):
	clipboard.cut(items)

func _on_AfterReactionEffectsDisplay_copy(items):
	clipboard.copy(items)

func _on_AfterReactionEffectsDisplay_paste_at(index):
	var items_to_paste = clipboard.paste()
	if (!items_to_paste.empty()):
		add_effects_at_position(items_to_paste, index)
		if (clipboard.clipboard_task_types.CUT == clipboard.clipboard_task):
			clipboard.delete_clipped_originals()
		refresh_reaction_after_effects_list()
		update_wordcount(current_encounter)
		log_update(current_encounter)

#General:

func update_wordcount(encounter):
	#In order to try to avoid sluggishness, we only do this if sort_by is set to word count or rev. word count.
	var sort_method_id = $Column1/SortBar/SortMenu.get_selected_id()
	var sort_method = $Column1/SortBar/SortMenu.get_popup().get_item_text(sort_method_id)
	if ("Word Count" == sort_method):
		encounter.wordcount()
		log_update(encounter)
		refresh_encounter_list()

func _ready():
	if (0 < $Column1/SortBar/SortMenu.get_item_count()):
		$Column1/SortBar/SortMenu.select(0)
	$HSC/Column2/OptionsList.context_menu_enabled = true
	$HSC/Column2/OptionsList.item_type = "option"
	$HSC/Column3/ReactionsList.context_menu_enabled = true
	$HSC/Column3/ReactionsList.item_type = "reaction"
	$HSC/Column3/AfterReactionEffectsDisplay.context_menu_enabled = true
	$HSC/Column3/AfterReactionEffectsDisplay.item_type = "effect"

#Script Editing:

func _on_EditEncounterAcceptabilityScriptButton_pressed():
	if (current_encounter is Encounter):
		$ScriptEditWindow.window_title = current_encounter.title + " Acceptability Script"
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = current_encounter.acceptability_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup_centered()

func _on_EditEncounterDesirabilityScriptButton_pressed():
	if (current_encounter is Encounter):
		$ScriptEditWindow.window_title = current_encounter.title + " Desirability Script"
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = current_encounter.desirability_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup_centered()

func _on_ReactionDesirabilityScriptEditButton_pressed():
	if (current_reaction is Reaction):
		var title = '"' + current_reaction.get_listable_text(40) + '"'
		title += " Desirability Script"
		$ScriptEditWindow.window_title = title
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = current_reaction.desirability_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup_centered()

func _on_ReactionsList_edit_desirability_script(reaction):
	if (reaction is Reaction):
		var title = '"' + reaction.get_listable_text(40) + '"'
		title += " Desirability Script"
		$ScriptEditWindow.window_title = title
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = reaction.desirability_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup_centered()

func _on_ScriptEditScreen_sw_script_changed(sw_script):
	if (current_encounter.desirability_script == sw_script):
		refresh_quick_encounter_scripting_interface()
	elif (current_reaction.desirability_script == sw_script):
		refresh_quick_reaction_scripting_interface()
	emit_signal("refresh_graphview")
	log_update(current_encounter)

func _on_EditOptionVisibilityScriptButton_pressed():
	if (current_option is Option):
		var title = '"' + current_option.get_listable_text(40) + '"'
		title += " Visibility Script"
		$ScriptEditWindow.window_title = title
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = current_option.visibility_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup_centered()

func _on_OptionsList_edit_visibility_script(option):
	if (option is Option):
		var title = '"' + option.get_listable_text(40) + '"'
		title += " Visibility Script"
		$ScriptEditWindow.window_title = title
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = option.visibility_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup_centered()

func _on_EditOptionPerformabilityScriptButton_pressed():
	if (current_option is Option):
		var title = '"' + current_option.get_listable_text(40) + '"'
		title += " Performability Script"
		$ScriptEditWindow.window_title = title
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = current_option.performability_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup_centered()

func _on_OptionsList_edit_performability_script(option):
	if (option is Option):
		var title = '"' + option.get_listable_text(40) + '"'
		title += " Performability Script"
		$ScriptEditWindow.window_title = title
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = option.performability_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup_centered()


#GUI Themes:

onready var add_icon_light = preload("res://icons/add.svg")
onready var add_icon_dark = preload("res://icons/add_dark.svg")
onready var delete_icon_light = preload("res://icons/delete.svg")
onready var delete_icon_dark = preload("res://icons/delete_dark.svg")
onready var move_up_icon_light = preload("res://icons/arrow-up.svg")
onready var move_up_icon_dark = preload("res://icons/arrow-up_dark.svg")
onready var move_down_icon_light = preload("res://icons/arrow-down.svg")
onready var move_down_icon_dark = preload("res://icons/arrow-down_dark.svg")
onready var acceptability_icon = preload("res://icons/check.svg")
onready var acceptability_icon_dark = preload("res://icons/check_dark.svg")
onready var desirability_icon = preload("res://icons/bullseye.svg")
onready var desirability_icon_dark = preload("res://icons/bullseye_dark.svg")
onready var visibility_icon = preload("res://icons/eye.svg")
onready var visibility_icon_dark = preload("res://icons/eye_dark.svg")
onready var performability_icon = preload("res://icons/hand.svg")
onready var performability_icon_dark = preload("res://icons/hand_dark.svg")

func set_gui_theme(theme_name, background_color):
	match theme_name:
		"Clarity":
			$Column1/HBC/AddButton.icon = add_icon_dark
			$Column1/HBC/DeleteButton.icon = delete_icon_dark
			$HSC/Column2/HBCTitle/EditEncounterAcceptabilityScriptButton.icon = acceptability_icon_dark
			$HSC/Column2/HBCTitle/EditEncounterDesirabilityScriptButton.icon = desirability_icon_dark
			$HSC/Column2/HBCOptionButtons/AddOption.icon = add_icon_dark
			$HSC/Column2/HBCOptionButtons/DeleteOption.icon = delete_icon_dark
			$HSC/Column2/HBCOptionButtons/MoveOptionUpButton.icon = move_up_icon_dark
			$HSC/Column2/HBCOptionButtons/MoveOptionDownButton.icon = move_down_icon_dark
			$HSC/Column2/HBCOptionButtons/EditOptionVisibilityScriptButton.icon = visibility_icon_dark
			$HSC/Column2/HBCOptionButtons/EditOptionPerformabilityScriptButton.icon = performability_icon_dark
			$HSC/Column3/HBC/AddReaction.icon = add_icon_dark
			$HSC/Column3/HBC/DeleteReaction.icon = delete_icon_dark
			$HSC/Column3/HBC/MoveReactionUpButton.icon = move_up_icon_dark
			$HSC/Column3/HBC/MoveReactionDownButton.icon = move_down_icon_dark
			$HSC/Column3/HBC/ReactionDesirabilityScriptEditButton.icon = desirability_icon_dark
			$HSC/Column3/HBCEffectButtons/AddEffect.icon = add_icon_dark
			$HSC/Column3/HBCEffectButtons/DeleteEffect.icon = delete_icon_dark
			$HSC/Column3/HBCEffectButtons/MoveEffectUpButton.icon = move_up_icon_dark
			$HSC/Column3/HBCEffectButtons/MoveEffectDownButton.icon = move_down_icon_dark
			light_mode = true
		"Lapis Lazuli":
			$Column1/HBC/AddButton.icon = add_icon_light
			$Column1/HBC/DeleteButton.icon = delete_icon_light
			$HSC/Column2/HBCTitle/EditEncounterAcceptabilityScriptButton.icon = acceptability_icon
			$HSC/Column2/HBCTitle/EditEncounterDesirabilityScriptButton.icon = desirability_icon
			$HSC/Column2/HBCOptionButtons/AddOption.icon = add_icon_light
			$HSC/Column2/HBCOptionButtons/DeleteOption.icon = delete_icon_light
			$HSC/Column2/HBCOptionButtons/MoveOptionUpButton.icon = move_up_icon_light
			$HSC/Column2/HBCOptionButtons/MoveOptionDownButton.icon = move_down_icon_light
			$HSC/Column2/HBCOptionButtons/EditOptionVisibilityScriptButton.icon = visibility_icon
			$HSC/Column2/HBCOptionButtons/EditOptionPerformabilityScriptButton.icon = performability_icon
			$HSC/Column3/HBC/AddReaction.icon = add_icon_light
			$HSC/Column3/HBC/DeleteReaction.icon = delete_icon_light
			$HSC/Column3/HBC/MoveReactionUpButton.icon = move_up_icon_light
			$HSC/Column3/HBC/MoveReactionDownButton.icon = move_down_icon_light
			$HSC/Column3/HBC/ReactionDesirabilityScriptEditButton.icon = desirability_icon
			$HSC/Column3/HBCEffectButtons/AddEffect.icon = add_icon_light
			$HSC/Column3/HBCEffectButtons/DeleteEffect.icon = delete_icon_light
			$HSC/Column3/HBCEffectButtons/MoveEffectUpButton.icon = move_up_icon_light
			$HSC/Column3/HBCEffectButtons/MoveEffectDownButton.icon = move_down_icon_light
			light_mode = false
	$EffectEditor/EffectEditorScreen.set_gui_theme(theme_name, background_color)
	$ScriptEditWindow/ScriptEditScreen.set_gui_theme(theme_name, background_color)
	refresh_sort_icon()






