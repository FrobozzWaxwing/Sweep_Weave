extends ColorRect

var rehearsal = null
var reference_storyworld = null
var page_to_display = null
#Display options:
var display_spoolbook = true

signal encounter_edit_button_pressed(id)

func reset_rehearsal():
	if (null == rehearsal):
		rehearsal = Rehearsal.new(reference_storyworld)
	else:
		rehearsal.clear_all_data()
		rehearsal.storyworld.set_as_copy_of(reference_storyworld)
		rehearsal.initial_pValues.record_character_states(rehearsal.storyworld)
	page_to_display = null

func refresh_spoolbook(next_page = null):
	$Layout/VBC/Spoolbook.clear()
	var root = $Layout/VBC/Spoolbook.create_item()
	$Layout/VBC/Spoolbook.set_hide_root(true)
	if (display_spoolbook):
		$Layout/VBC/Spoolbook_Label.visible = true
		$Layout/VBC/Spoolbook.visible = true
		if (null != rehearsal and null != rehearsal.current_page):
			for spool in rehearsal.storyworld.spools:
				var spool_entry = $Layout/VBC/Spoolbook.create_item(root)
				spool_entry.set_text(0, spool.spool_name)
				var text = ""
				if (spool.is_active):
					text += "active"
				else:
					text += "inactive"
				if (null != next_page and next_page.spool_statuses.has(spool.id)):
					if (spool.is_active != next_page.spool_statuses[spool.id]):
						text += " -> "
						if (next_page.spool_statuses[spool.id]):
							text += "active"
						else:
							text += "inactive"
				spool_entry.set_text(1, text)
	else:
		$Layout/VBC/Spoolbook_Label.visible = false
		$Layout/VBC/Spoolbook.visible = false

func set_display_spoolbook(checked:bool):
	display_spoolbook = checked
	refresh_spoolbook()

func refresh_historybook():
	$Layout/VBC/Historybook.clear()
	var current_page = rehearsal.current_page
	var page_list = []
	while (null != current_page):
		page_list.append(current_page)
		current_page = current_page.get_parent()
	page_list.reverse()
	var index = 0
	for page in page_list:
		$Layout/VBC/Historybook.add_item(page.stringify_encounter())
		$Layout/VBC/Historybook.set_item_metadata(index, page)
		index += 1

func recursive_refresh_castbook(root_display_branch:TreeItem, onion, next_page:HB_Record, method_actor:Actor, keyring:Array):
	var cast = rehearsal.storyworld.characters
	for perceived_character in cast:
		if (onion.has(perceived_character.id)):
			var value = onion[perceived_character.id]
			keyring.append(perceived_character.id)
			if (TYPE_DICTIONARY == typeof(value)):
				var leaf = $Layout/L2/VBC/Castbook.create_item(root_display_branch)
				leaf.set_text(0, perceived_character.char_name)
				recursive_refresh_castbook(leaf, value, next_page, method_actor, keyring)
			elif (TYPE_INT == typeof(value) or TYPE_FLOAT == typeof(value)):
				var leaf = $Layout/L2/VBC/Castbook.create_item(root_display_branch)
				var text = perceived_character.char_name + ": " + str(value)
				if (null != next_page):
					var new_value = method_actor.get_bnumber_property(keyring)
					if (value != new_value):
						text += " -> " + str(new_value)
				leaf.set_text(0, text)
			keyring.pop_back()

func refresh_castbook(next_page = null):
	$Layout/L2/VBC/Castbook.clear()
	var root = $Layout/L2/VBC/Castbook.create_item()
	$Layout/L2/VBC/Castbook.set_hide_root(true)
	var cast = rehearsal.storyworld.characters
	for character in cast:
		if (character.is_queued_for_deletion()):
			continue
		var listing = $Layout/L2/VBC/Castbook.create_item(root)
		listing.set_text(0, character.char_name)
		#The method_actor character is used to look up bounded number properties in historybook entries.
		var method_actor = Actor.new(rehearsal.storyworld, "Placeholder", "they / them")
		if (null != next_page):
			method_actor.bnumber_properties = next_page.relationship_values[character.id].duplicate(true)
		for bnumber_property in character.authored_properties:
			var onion = character.bnumber_properties[bnumber_property.id]
			if (TYPE_DICTIONARY == typeof(onion) and onion.is_empty()):
				continue
			var entry = $Layout/L2/VBC/Castbook.create_item(listing)
			var keyring = []
			keyring.append(bnumber_property.id)
			entry.set_metadata(0, keyring)
			if (0 == bnumber_property.depth):
				var text = bnumber_property.get_property_name() + ": " + str(character.get_bnumber_property(keyring))
				if (null != next_page):
					if (character.get_bnumber_property(keyring) != method_actor.get_bnumber_property(keyring)):
						text += " -> " + str(method_actor.get_bnumber_property(keyring))
				entry.set_text(0, text)
			elif (0 < bnumber_property.depth):
				var entry_text = bnumber_property.get_property_name() + ": "
				entry.set_text(0, entry_text)
				recursive_refresh_castbook(entry, onion, next_page, method_actor, keyring)
		method_actor.call_deferred("free")

func refresh_encountertitle():
	var display_turn = " (Turn: Null)"
	if (null != page_to_display.turn):
		display_turn = " (Turn: " + str(page_to_display.turn) + ")"
	if (null == page_to_display.encounter):
		$Layout/L2/ColorRect/VBC/TitleBar/Edit_Button.visible = false
		$Layout/L2/ColorRect/VBC/TitleBar/EncounterTitle.text = "(The End.)" + display_turn
	else:
		$Layout/L2/ColorRect/VBC/TitleBar/Edit_Button.visible = true
		$Layout/L2/ColorRect/VBC/TitleBar/EncounterTitle.text = page_to_display.encounter.title + display_turn
	return $Layout/L2/ColorRect/VBC/TitleBar/EncounterTitle.text

func refresh_maintext():
	var text = ""
	if (null != page_to_display.player_choice):
		text += "> " + page_to_display.player_choice.get_text() + "\n"
	if (null != page_to_display.antagonist_choice):
		text += page_to_display.antagonist_choice.get_text() + "\n"
	if (null != page_to_display.encounter):
		text += page_to_display.encounter.get_text()
	else:
		text += "The End."
	$Layout/L2/ColorRect/VBC/MainText.set_text(text)
	return text

func refresh_optionslist():
	$Layout/L2/ColorRect/VBC/OptionsList.clear()
	if (null == page_to_display.encounter):
		return
	var all_options_index = 0
	var open_options_index = 0
	for option in page_to_display.encounter.options:
		var option_visible = option.visibility_script.get_value()
		var option_open = option.performability_script.get_value()
		if (option_visible and option_open):
			$Layout/L2/ColorRect/VBC/OptionsList.add_item(option.get_text())
			$Layout/L2/ColorRect/VBC/OptionsList.set_item_metadata(all_options_index, page_to_display.unexplored_branches[open_options_index])
			open_options_index += 1
		elif (option_visible):
			$Layout/L2/ColorRect/VBC/OptionsList.add_item(option.get_text() + " (Visible but closed off.)")
			$Layout/L2/ColorRect/VBC/OptionsList.set_item_metadata(all_options_index, "(Visible but closed off.)")
		else:
			$Layout/L2/ColorRect/VBC/OptionsList.add_item(option.get_text() + " (Invisible.)")
			$Layout/L2/ColorRect/VBC/OptionsList.set_item_metadata(all_options_index, "(Invisible.)")
		all_options_index += 1

func load_options_script_report():
	$OptionScriptReportWindow/ScriptDisplay.clear()
	if (null == page_to_display or null == page_to_display.encounter):
		return
	var root = $OptionScriptReportWindow/ScriptDisplay.create_item()
	$OptionScriptReportWindow/ScriptDisplay.set_hide_root(true)
	for option in page_to_display.encounter.options:
		var option_entry = $OptionScriptReportWindow/ScriptDisplay.create_item(root)
		var visible_entry = $OptionScriptReportWindow/ScriptDisplay.create_item(option_entry)
		$OptionScriptReportWindow/ScriptDisplay.recursively_add_to_script_display(visible_entry, option.visibility_script.contents)
		var open_entry = $OptionScriptReportWindow/ScriptDisplay.create_item(option_entry)
		$OptionScriptReportWindow/ScriptDisplay.recursively_add_to_script_display(open_entry, option.performability_script.contents)
		var option_visible = option.visibility_script.get_and_report_value()
		var option_open = option.performability_script.get_and_report_value()
		var text = option.get_text().left(40)
		if (option_visible):
			if (!option_open):
				text += " (Visible but closed off.)"
		else:
			text += " (Invisible.)"
		option_entry.set_text(0, text)
		visible_entry.set_text(0, "Visibility")
		visible_entry.set_text(1, str(option_visible))
		open_entry.set_text(0, "Performability")
		open_entry.set_text(1, str(option_open))
	$OptionScriptReportWindow.popup_centered()

func report_encounter_scripts(entry):
	#Used by load_encounter_selection_report() to fill table.
	if (5 == entry.size()):
		var encounter = entry[0]
		var spool_entry = entry[3]
		var encounter_entry = $EncounterScriptReportWindow/VBC/ScriptDisplay.create_item(spool_entry)
		encounter_entry.set_text(0, encounter.title)
		var occurred = entry[4]
		var occurred_entry = $EncounterScriptReportWindow/VBC/ScriptDisplay.create_item(encounter_entry)
		occurred_entry.set_text(0, "Has occurred before")
		occurred_entry.set_text(1, str(occurred))
		var acceptability_entry = $EncounterScriptReportWindow/VBC/ScriptDisplay.create_item(encounter_entry)
		$EncounterScriptReportWindow/VBC/ScriptDisplay.recursively_add_to_script_display(acceptability_entry, encounter.acceptability_script.contents)
		#Recalculate the encounter's acceptability in order to fill the display with the value produced by each operator.
		var acceptable = encounter.acceptability_script.get_and_report_value()
		acceptability_entry.set_text(0, "Acceptability")
		acceptability_entry.set_text(1, str(acceptable))
		var desirability_entry = $EncounterScriptReportWindow/VBC/ScriptDisplay.create_item(encounter_entry)
		$EncounterScriptReportWindow/VBC/ScriptDisplay.recursively_add_to_script_display(desirability_entry, encounter.desirability_script.contents)
		#Recalculate the encounter's desirability in order to fill the display with the value produced by each operator.
		var desirability = encounter.calculate_and_report_desirability()
		desirability_entry.set_text(0, "Desirability")
		desirability_entry.set_text(1, str(desirability))

func load_encounter_selection_report():
	$EncounterScriptReportWindow/VBC/Background/ConsequenceReport.set_text("")
	$EncounterScriptReportWindow/VBC/ScriptDisplay.clear()
	if (null == page_to_display):
		return
	#List results:
	var text = ""
	if (null == page_to_display.player_choice):
		text += "Start of play\n"
	else:
		var previous_page = page_to_display.get_parent()
		if (null != previous_page):
			text += "Previous encounter: " + previous_page.encounter.title.left(100) + "\n"
		text += "Option chosen: " + page_to_display.stringify_option(50) + "\n"
		text += "Reaction chosen: " + page_to_display.stringify_reaction(50) + "\n"
	var selected_encounter = null
	if (null != page_to_display.antagonist_choice and null != page_to_display.antagonist_choice.consequence):
		#If the reaction of the last encounter led to a consequence encounter, that consequence occurs next.
		selected_encounter = page_to_display.antagonist_choice.consequence
		text += "Reaction consequence: " + selected_encounter.title.left(100) + "\n"
	#List scripts:
	var root = $EncounterScriptReportWindow/VBC/ScriptDisplay.create_item()
	$EncounterScriptReportWindow/VBC/ScriptDisplay.set_hide_root(true)
	var acceptable_encounters = []
	var unacceptable_encounters = []
	var checked = {}
	var active_spool_count = 0
	var index = 0
	for spool in rehearsal.storyworld.spools:
		if (spool.is_active):
			var spool_entry = null
			active_spool_count += 1
			for encounter in spool.encounters:
				if (!checked.has(encounter.id)):
					checked[encounter.id] = true
					var entry = []
					entry.append(encounter)
					entry.append(encounter.calculate_desirability())
					entry.append(index)
					if (null == spool_entry):
						spool_entry = $EncounterScriptReportWindow/VBC/ScriptDisplay.create_item(root)
						spool_entry.set_text(0, spool.spool_name)
					entry.append(spool_entry)
					var occurred
					if (encounter == page_to_display.encounter):
						occurred = (1 < encounter.occurrences)
					else:
						occurred = (0 < encounter.occurrences)
					entry.append(occurred)
					if (!occurred and encounter.acceptability_script.get_value()):
						acceptable_encounters.append(entry)
					else:
						unacceptable_encounters.append(entry)
					index += 1
	text += "Active spools: " + str(active_spool_count) + "\n"
	text += "Acceptable encounters: " + str(acceptable_encounters.size()) + "\n"
	acceptable_encounters.sort_custom(Callable(InclinationSorter, "sort_descending"))
	for entry in acceptable_encounters:
		report_encounter_scripts(entry)
	unacceptable_encounters.sort_custom(Callable(InclinationSorter, "sort_descending"))
	for entry in unacceptable_encounters:
		report_encounter_scripts(entry)
	if (null != page_to_display.encounter):
		text += "Encounter chosen: " + page_to_display.stringify_encounter(100)
	else:
		text += "The End."
	$EncounterScriptReportWindow/VBC/Background/ConsequenceReport.append_text(text)
	$EncounterScriptReportWindow.popup_centered()

func refresh_reaction_inclinations(option = null):
	$Layout/L2/VBC/Reaction_Inclinations.clear()
	if (null == option):
		$Layout/L2/VBC/Reaction_Inclinations.visible = false
		return
	else:
		$Layout/L2/VBC/Reaction_Inclinations.visible = true
	var table = []
	var index = 0
	for reaction in option.reactions:
		var entry = []
		entry.append(reaction)
		entry.append(reaction.calculate_desirability())
		entry.append(index)
		table.append(entry)
		index += 1
	table.sort_custom(Callable(InclinationSorter, "sort_descending"))
	var root = $Layout/L2/VBC/Reaction_Inclinations.create_item()
	$Layout/L2/VBC/Reaction_Inclinations.set_hide_root(true)
	for entry in table:
		if (3 == entry.size()):
			var reaction = entry[0]
			var text = reaction.get_text().left(30)
			var reaction_entry = $Layout/L2/VBC/Reaction_Inclinations.create_item(root)
			$Layout/L2/VBC/Reaction_Inclinations.recursively_add_to_script_display(reaction_entry, reaction.desirability_script.contents)
			reaction_entry.set_text(0, text)
			reaction_entry.set_metadata(0, reaction)
			#Recalculate the reaction's desirability in order to fill the display with the value produced by each operator.
			var inclination = reaction.calculate_and_report_desirability()
			reaction_entry.set_text(1, str(inclination))

func load_Page(page:HB_Record):
	page_to_display = page
	rehearsal.turn_to_page(page)
	refresh_encountertitle()
	refresh_maintext()
	refresh_optionslist()
	refresh_spoolbook()
	refresh_historybook()
	refresh_castbook()
	refresh_reaction_inclinations()
	$Layout/L2/ColorRect/VBC/ScriptReportButtonsHBC.visible = true
	$Layout/L2/VBC/Resulting_Reaction.visible = false
	$Layout/L2/VBC/Resulting_Reaction.text = ""
	$Layout/L2/VBC/Resulting_Encounter.visible = false
	$Layout/L2/VBC/Resulting_Encounter.text = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	$Layout/VBC/Spoolbook.set_column_expand(0, true)
	$Layout/VBC/Spoolbook.set_column_custom_minimum_width(0, 1)
	$Layout/VBC/Spoolbook.set_column_expand(1, true)
	$Layout/VBC/Spoolbook.set_column_custom_minimum_width(1, 1)
	$Layout/L2/VBC/Reaction_Inclinations.set_column_expand(0, true)
	$Layout/L2/VBC/Reaction_Inclinations.set_column_custom_minimum_width(0, 9)
	$Layout/L2/VBC/Reaction_Inclinations.set_column_expand(1, true)
	$Layout/L2/VBC/Reaction_Inclinations.set_column_custom_minimum_width(1, 1)
	$OptionScriptReportWindow/ScriptDisplay.set_column_expand(0, true)
	$OptionScriptReportWindow/ScriptDisplay.set_column_custom_minimum_width(0, 4)
	$OptionScriptReportWindow/ScriptDisplay.set_column_expand(1, true)
	$OptionScriptReportWindow/ScriptDisplay.set_column_custom_minimum_width(1, 1)
	$EncounterScriptReportWindow/VBC/ScriptDisplay.set_column_expand(0, true)
	$EncounterScriptReportWindow/VBC/ScriptDisplay.set_column_custom_minimum_width(0, 4)
	$EncounterScriptReportWindow/VBC/ScriptDisplay.set_column_expand(1, true)
	$EncounterScriptReportWindow/VBC/ScriptDisplay.set_column_custom_minimum_width(1, 1)

func clear():
	$Layout/L2/ColorRect/VBC/TitleBar/Play_Button.text = "Start"
	$Layout/VBC/Spoolbook.clear()
	$Layout/VBC/Historybook.clear()
	$Layout/L2/ColorRect/VBC/TitleBar/Edit_Button.visible = false
	$Layout/L2/ColorRect/VBC/TitleBar/EncounterTitle.text = ""
	$Layout/L2/ColorRect/VBC/MainText.set_text("")
	$Layout/L2/VBC/Castbook.clear()
	$Layout/L2/ColorRect/VBC/OptionsList.clear()
	$Layout/L2/VBC/Reaction_Inclinations.clear()
	$EncounterScriptReportWindow/VBC/ScriptDisplay.clear()
	$OptionScriptReportWindow/ScriptDisplay.clear()
	$Layout/L2/ColorRect/VBC/ScriptReportButtonsHBC.visible = false
	$Layout/L2/VBC/Resulting_Reaction.visible = false
	$Layout/L2/VBC/Resulting_Reaction.text = ""
	$Layout/L2/VBC/Resulting_Encounter.visible = false
	$Layout/L2/VBC/Resulting_Encounter.text = ""

func _on_Play_Button_pressed():
	$Layout/L2/ColorRect/VBC/TitleBar/Play_Button.text = "Restart"
	reset_rehearsal()
	rehearsal.begin_playthrough()
	load_Page(rehearsal.current_page)

func _on_Edit_Button_pressed():
	if (null != page_to_display and null != page_to_display.encounter and page_to_display.encounter is Encounter):
		encounter_edit_button_pressed.emit(page_to_display.encounter.id)

func _on_OptionsList_item_selected(index:int):
	var option_page = $Layout/L2/ColorRect/VBC/OptionsList.get_item_metadata(index)
	if (TYPE_STRING == typeof(option_page)):
		$Layout/L2/VBC/Resulting_Reaction.visible = false
		$Layout/L2/VBC/Resulting_Reaction.text = ""
		$Layout/L2/VBC/Resulting_Encounter.visible = true
		$Layout/L2/VBC/Resulting_Encounter.text = "Option cannot be chosen by the player."
		refresh_spoolbook()
		refresh_castbook()
		refresh_reaction_inclinations()
		return
	refresh_spoolbook(option_page)
	refresh_castbook(option_page)
	refresh_reaction_inclinations(option_page.player_choice)
	$Layout/L2/VBC/Resulting_Reaction.visible = true
	$Layout/L2/VBC/Resulting_Reaction.text = "Reaction: " + option_page.stringify_reaction()
	$Layout/L2/VBC/Resulting_Encounter.visible = true
	$Layout/L2/VBC/Resulting_Encounter.text = "Encounter: " + option_page.stringify_encounter()

func _on_OptionsList_item_activated(index:int):
	var option_page = $Layout/L2/ColorRect/VBC/OptionsList.get_item_metadata(index)
	if (TYPE_STRING == typeof(option_page)):
		$Layout/L2/VBC/Resulting_Reaction.visible = false
		$Layout/L2/VBC/Resulting_Reaction.text = ""
		$Layout/L2/VBC/Resulting_Encounter.visible = true
		$Layout/L2/VBC/Resulting_Encounter.text = "Option cannot be chosen by the player."
		refresh_spoolbook()
		refresh_castbook()
		refresh_reaction_inclinations()
		return
	load_Page(option_page)

func _on_Historybook_item_activated(index:int):
	var historybook_page = $Layout/VBC/Historybook.get_item_metadata(index)
	load_Page(historybook_page)

func _on_OptionScriptReportButton_pressed():
	load_options_script_report()

func _on_EncounterSelectionReportButton_pressed():
	load_encounter_selection_report()

#GUI Themes:

@onready var edit_icon_light = preload("res://icons/edit.svg")
@onready var edit_icon_dark = preload("res://icons/edit_dark.svg")

func set_gui_theme(theme_name:String, background_color:Color):
	color = background_color
	$Layout/L2/ColorRect.color = background_color
	$EncounterScriptReportWindow/VBC/Background.color = background_color
	match theme_name:
		"Clarity":
			$Layout/L2/ColorRect/VBC/TitleBar/Edit_Button.icon = edit_icon_dark
		"Lapis Lazuli":
			$Layout/L2/ColorRect/VBC/TitleBar/Edit_Button.icon = edit_icon_light
