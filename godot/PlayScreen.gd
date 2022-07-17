extends ColorRect

var rehearsal = null
var reference_storyworld = null
var page_to_display = null

func reset_rehearsal():
	if (null == rehearsal):
		rehearsal = Rehearsal.new(reference_storyworld)
	else:
		rehearsal.clear_all_data()
		rehearsal.storyworld.set_as_copy_of(reference_storyworld)
		rehearsal.initial_pValues.set_pValues(rehearsal.storyworld)
	page_to_display = null

func refresh_historybook():
	$Layout/VBC/Scroll_History/Historybook.clear()
	var current_page = rehearsal.current_page
	var page_list = []
	while (null != current_page):
		page_list.append(current_page)
		current_page = current_page.get_parent()
	page_list.invert()
	var index = 0
	for page in page_list:
		$Layout/VBC/Scroll_History/Historybook.add_item(page.get_metadata(0).data_to_string())
		$Layout/VBC/Scroll_History/Historybook.set_item_metadata(index, page)
		index += 1

func refresh_castbook(next_page = null):
	var current_antagonist = null
	if (null != page_to_display.get_metadata(0).encounter):
		current_antagonist = page_to_display.get_metadata(0).encounter.antagonist
	$Layout/L2/VBC/Scroll_Cast/Castbook.clear()
	var root = $Layout/L2/VBC/Scroll_Cast/Castbook.create_item()
	$Layout/L2/VBC/Scroll_Cast/Castbook.set_hide_root(true)
	var cast = rehearsal.storyworld.characters
	for character in cast:
		if (character.is_queued_for_deletion()):
			continue
		var listing = $Layout/L2/VBC/Scroll_Cast/Castbook.create_item(root)
		if (null != current_antagonist and character == current_antagonist):
			listing.set_text(0, character.char_name + " (Antagonist)")
		else:
			listing.set_text(0, character.char_name)
		#The method_actor character is used to look up bounded number properties in historybook entries.
		var method_actor = Actor.new(rehearsal.storyworld, "Placeholder", "they / them")
		if (null != next_page):
			var record = next_page.get_metadata(0)
			method_actor.bnumber_properties = record.relationship_values[character.id].duplicate(true)
		for bnumber_property in character.authored_properties:
			var entry = $Layout/L2/VBC/Scroll_Cast/Castbook.create_item(listing)
			var keyring = []
			keyring.append(bnumber_property.id)
			entry.set_metadata(0, keyring)
			if (0 == bnumber_property.depth):
				var text = bnumber_property.get_property_name() + ": " + str(character.get_bnumber_property(keyring))
				if (null != next_page):
					if (character.get_bnumber_property(keyring) != method_actor.get_bnumber_property(keyring)):
						text += " -> " + str(method_actor.get_bnumber_property(keyring))
#					for change in next_page.get_metadata(0).relationship_values:
#						if (character == change.character and bnumber_property == change.pValue and character.get_bnumber_property([bnumber_property]) != change.point):
#							text += " -> " + str(change.point)
				entry.set_text(0, text)
			elif (0 < bnumber_property.depth):
				var entry_text = bnumber_property.get_property_name() + ": "
				entry.set_text(0, entry_text)
				var current_layer_items = []
				current_layer_items.append(entry)
				var next_layer_items = []
				for layer in range(bnumber_property.depth):
					next_layer_items.clear()
					if (layer < bnumber_property.depth - 1):
						for branch in current_layer_items:
							for perceived_character in cast:
								var leaf = $Layout/L2/VBC/Scroll_Cast/Castbook.create_item(branch)
								keyring = branch.get_metadata(0).duplicate()
								keyring.append(perceived_character.id)
								leaf.set_metadata(0, keyring)
								var text = perceived_character.char_name
								leaf.set_text(0, text)
								next_layer_items.append(leaf)
					elif (layer == bnumber_property.depth - 1):
						for branch in current_layer_items:
							for perceived_character in cast:
								var leaf = $Layout/L2/VBC/Scroll_Cast/Castbook.create_item(branch)
								keyring = branch.get_metadata(0).duplicate()
								keyring.append(perceived_character.id)
								leaf.set_metadata(0, keyring)
								var text = perceived_character.char_name + ": " + str(character.get_bnumber_property(keyring))
								if (null != next_page):
									if (character.get_bnumber_property(keyring) != method_actor.get_bnumber_property(keyring)):
										text += " -> " + str(method_actor.get_bnumber_property(keyring))
								leaf.set_text(0, text)
					current_layer_items.clear()
					current_layer_items = next_layer_items.duplicate()
		method_actor.call_deferred("free")

func refresh_encountertitle():
	var display_turn = " (Turn: Null)"
	if (null != page_to_display.get_metadata(0).turn):
		display_turn = " (Turn: " + str(page_to_display.get_metadata(0).turn) + ")"
	if (null == page_to_display.get_metadata(0).encounter):
		$Layout/L2/ColorRect/VBC/EncounterTitle.text = "(The End.)" + display_turn
	else:
		$Layout/L2/ColorRect/VBC/EncounterTitle.text = page_to_display.get_metadata(0).encounter.title + display_turn
	return $Layout/L2/ColorRect/VBC/EncounterTitle.text

func refresh_maintext():
	var text = ""
	if (null != page_to_display.get_metadata(0).player_choice):
		text += "> " + page_to_display.get_metadata(0).player_choice.text + "\n"
	if (null != page_to_display.get_metadata(0).antagonist_choice):
		text += page_to_display.get_metadata(0).antagonist_choice.text + "\n"
	if (null != page_to_display.get_metadata(0).encounter):
		text += page_to_display.get_metadata(0).encounter.main_text
	else:
		text += "The End."
	$Layout/L2/ColorRect/VBC/MainText.set_bbcode(text)
	return text

#https://github.com/godotengine/godot/issues/19796
#Trees have a strange system for getting the children of a tree item.
func get_item_children(item:TreeItem)->Array:
	item = item.get_children()
	var children = []
	while item:
		children.append(item)
		item = item.get_next()
	return children

func refresh_optionslist():
	$Layout/L2/ColorRect/VBC/Scroll_Options/OptionsList.clear()
	if (null == page_to_display.get_metadata(0).encounter):
		return
	var all_options_index = 0
	var open_options_index = 0
	var page_children = get_item_children(page_to_display)
	for option in page_to_display.get_metadata(0).encounter.options:
		var option_visible = option.visibility_script.get_value(page_to_display)
		var option_open = option.performability_script.get_value(page_to_display)
#		var option_visible = true
#		var option_open = true
#		for prerequisite in option.visibility_prerequisites:
#			if (!rehearsal.evaluate_prerequisite(prerequisite, page_to_display)):
#				option_visible = false
#				break
#		for prerequisite in option.performability_prerequisites:
#			if (!rehearsal.evaluate_prerequisite(prerequisite, page_to_display)):
#				option_open = false
#				break
		if (option_visible and option_open):
			$Layout/L2/ColorRect/VBC/Scroll_Options/OptionsList.add_item(option.text)
			$Layout/L2/ColorRect/VBC/Scroll_Options/OptionsList.set_item_metadata(all_options_index, page_children[open_options_index])
			open_options_index += 1
		elif (option_visible):
			$Layout/L2/ColorRect/VBC/Scroll_Options/OptionsList.add_item(option.text + " (Visible but closed off.)")
			$Layout/L2/ColorRect/VBC/Scroll_Options/OptionsList.set_item_metadata(all_options_index, "(Visible but closed off.)")
		else:
			$Layout/L2/ColorRect/VBC/Scroll_Options/OptionsList.add_item(option.text + " (Invisible.)")
			$Layout/L2/ColorRect/VBC/Scroll_Options/OptionsList.set_item_metadata(all_options_index, "(Invisible.)")
		all_options_index += 1

func refresh_reaction_inclinations(option):
	$Layout/L2/VBC/Scroll_Reactions/Reaction_Inclinations.clear()
	if (null == option):
		$Layout/L2/VBC/Scroll_Reactions.visible = false
		return
	else:
		$Layout/L2/VBC/Scroll_Reactions.visible = true
	var table = []
	var character = option.encounter.antagonist
	var index = 0
	for reaction in option.reactions:
		var entry = []
		entry.append(reaction)
		entry.append(reaction.calculate_desirability())
		entry.append(index)
		table.append(entry)
		index += 1
	table.sort_custom(InclinationSorter, "sort_descending")
	var root = $Layout/L2/VBC/Scroll_Reactions/Reaction_Inclinations.create_item()
	$Layout/L2/VBC/Scroll_Reactions/Reaction_Inclinations.set_hide_root(true)
	for entry in table:
		if (3 == entry.size()):
			var reaction = entry[0]
			var text = reaction.text.left(30) + " (Inc: " + str(entry[1]) + ")"
			var reaction_entry = $Layout/L2/VBC/Scroll_Reactions/Reaction_Inclinations.create_item(root)
			reaction_entry.set_text(0, text)
			reaction_entry.set_metadata(0, reaction)
			text = reaction.desirability_script.contents.data_to_string()
			var inclination_entry = $Layout/L2/VBC/Scroll_Reactions/Reaction_Inclinations.create_item(reaction_entry)
			inclination_entry.set_text(0, text)

signal encounter_loaded(id)

func load_Page(page):
	page_to_display = page
	rehearsal.step_playthrough(page)
	refresh_encountertitle()
	refresh_maintext()
	refresh_castbook()
	refresh_optionslist()
	refresh_reaction_inclinations(null)
	$Layout/L2/VBC/Result_Label.visible = false
	$Layout/L2/VBC/Result_Display.visible = false
	$Layout/L2/VBC/Result_Display.text = ""
	if (null != page and null != page.get_metadata(0) and null != page.get_metadata(0).encounter and null != page.get_metadata(0).encounter.id):
		emit_signal("encounter_loaded", page.get_metadata(0).encounter.id)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func clear():
	$Layout/L2/ColorRect/VBC/Play_Button.text = "Start"
	$Layout/VBC/Scroll_History/Historybook.clear()
	$Layout/L2/ColorRect/VBC/EncounterTitle.text = ""
	$Layout/L2/ColorRect/VBC/MainText.set_bbcode("")
	$Layout/L2/VBC/Scroll_Cast/Castbook.clear()
	$Layout/L2/ColorRect/VBC/Scroll_Options/OptionsList.clear()
	$Layout/L2/VBC/Scroll_Reactions/Reaction_Inclinations.clear()
	$Layout/L2/VBC/Result_Label.visible = false
	$Layout/L2/VBC/Result_Display.visible = false
	$Layout/L2/VBC/Result_Display.text = ""

func _on_Play_Button_pressed():
	$Layout/L2/ColorRect/VBC/Play_Button.text = "Restart"
	reset_rehearsal()
	rehearsal.begin_playthrough()
	load_Page(rehearsal.current_page)
	refresh_historybook()

func _on_OptionsList_item_selected(index):
	var option_page = $Layout/L2/ColorRect/VBC/Scroll_Options/OptionsList.get_item_metadata(index)
	if (TYPE_STRING == typeof(option_page)):
		$Layout/L2/VBC/Result_Label.visible = false
		$Layout/L2/VBC/Result_Display.visible = true
		$Layout/L2/VBC/Result_Display.text = "Option cannot be chosen by the player."
		refresh_castbook()
		refresh_reaction_inclinations(null)
		return
	refresh_castbook(option_page)
	refresh_reaction_inclinations(option_page.get_metadata(0).player_choice)
	var result_text = ""
	if (null != option_page.get_metadata(0).antagonist_choice):
		result_text += "Reaction: " + option_page.get_metadata(0).antagonist_choice.text.left(30) + " "
	else:
		result_text += "Reaction: Null "
	if (null != option_page.get_metadata(0).encounter):
		result_text += "Encounter: " + option_page.get_metadata(0).encounter.title + "."
	else:
		result_text += "Encounter: Null."
	$Layout/L2/VBC/Result_Label.visible = true
	$Layout/L2/VBC/Result_Display.visible = true
	$Layout/L2/VBC/Result_Display.text = result_text

func _on_OptionsList_item_activated(index):
	var option_page = $Layout/L2/ColorRect/VBC/Scroll_Options/OptionsList.get_item_metadata(index)
	if (TYPE_STRING == typeof(option_page)):
		$Layout/L2/VBC/Result_Label.visible = false
		$Layout/L2/VBC/Result_Display.visible = true
		$Layout/L2/VBC/Result_Display.text = "Option cannot be chosen by the player."
		refresh_castbook()
		refresh_reaction_inclinations(null)
		return
	load_Page(option_page)
	refresh_historybook()

func _on_Historybook_item_activated(index):
	var historybook_page = $Layout/VBC/Scroll_History/Historybook.get_item_metadata(index)
	load_Page(historybook_page)
