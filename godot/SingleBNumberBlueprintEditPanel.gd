extends Control

var storyworld = null
var current_authored_property = null
var creating_new_property = false # If true, the property is only a rough draft until the author confirms creation of the property.
var characters_to_remove_from_those_affected = []

signal bnumber_property_name_changed(property_blueprint)
signal affected_character_added(property_blueprint, character)
signal affected_character_removed(property_blueprint, character)

func _ready():
	pass

func log_update(property = null):
	if (null != property):
		property.log_update()
	storyworld.log_update()
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false

func add_character_to_affected_characters(character):
	if (current_authored_property.affected_characters.has(character)):
		print ("A property's list of affected characters should not contain duplicate entries.")
	else:
		current_authored_property.affected_characters.append(character)
		if (!creating_new_property):
			character.add_property_to_bnumber_properties(current_authored_property, storyworld.characters)
		emit_signal("affected_character_added", current_authored_property, character)

func remove_character_from_affected_characters(character):
	current_authored_property.affected_characters.erase(character)
	character.delete_property_from_bnumber_properties(current_authored_property)
	if (null != storyworld):
		#Search scripts and replace any bnumber pointers that include the character and property in question.
		for encounter in storyworld.encounters:
			var replacement = storyworld.create_default_bnumber_pointer()
			encounter.acceptability_script.replace_character_and_property_with_pointer(character, current_authored_property, replacement)
			encounter.desirability_script.replace_character_and_property_with_pointer(character, current_authored_property, replacement)
			for option in encounter.options:
				option.visibility_script.replace_character_and_property_with_pointer(character, current_authored_property, replacement)
				option.performability_script.replace_character_and_property_with_pointer(character, current_authored_property, replacement)
				for reaction in option.reactions:
					reaction.desirability_script.replace_character_and_property_with_pointer(character, current_authored_property, replacement)
					var effects = reaction.after_effects.duplicate()
					for effect in effects:
						if (effect is BNumberEffect):
							if (effect.assignee.keyring.front() == current_authored_property.id and effect.assignee.character == character):
								effect.clear()
								reaction.after_effects.erase(effect)
								effect.call_deferred("free")
							else:
								effect.assignment_script.replace_character_and_property_with_pointer(character, current_authored_property, replacement)
						elif (effect is SpoolEffect):
							effect.assignment_script.replace_character_and_property_with_pointer(character, current_authored_property, replacement)
	emit_signal("affected_character_removed", current_authored_property, character)

func _on_NameEdit_text_changed(new_text):
	current_authored_property.property_name = new_text
	if (!creating_new_property):
		log_update(current_authored_property)
	emit_signal("bnumber_property_name_changed", current_authored_property)

func _on_DefaultValueEdit_value_changed(value):
	current_authored_property.default_value = value
	if (!creating_new_property):
		log_update(current_authored_property)

func _on_DepthEdit_value_changed(value):
	current_authored_property.depth = value

func _on_AttributionTargetEdit_item_selected(index):
	current_authored_property.attribution_target = $ColorRect/VBC/AttributionTargetEdit.get_selected_metadata()
	refresh()

func refresh():
	if (creating_new_property):
		$ColorRect/VBC/HBC/DepthLabel.text = "Depth:"
		$ColorRect/VBC/HBC/DepthEdit.visible = true
		$ColorRect/VBC/AttributionTargetEdit.visible = true
		if (current_authored_property.possible_attribution_targets.CAST_MEMBERS == current_authored_property.attribution_target):
			$ColorRect/VBC/AffectedCharactersLabel.visible = true
			$ColorRect/VBC/AddCharacterButton.visible = true
			$ColorRect/VBC/DeleteCharacterButton.visible = true
			$ColorRect/VBC/AffectedCharactersList.visible = true
		else:
			$ColorRect/VBC/AffectedCharactersLabel.visible = false
			$ColorRect/VBC/AddCharacterButton.visible = false
			$ColorRect/VBC/DeleteCharacterButton.visible = false
			$ColorRect/VBC/AffectedCharactersList.visible = false
	else:
		$ColorRect/VBC/HBC/DepthLabel.text = "Depth: " + str(current_authored_property.depth)
		$ColorRect/VBC/HBC/DepthEdit.visible = false
		$ColorRect/VBC/AttributionTargetEdit.visible = false
		if (current_authored_property.possible_attribution_targets.CAST_MEMBERS == current_authored_property.attribution_target):
			$ColorRect/VBC/AffectedCharactersLabel.visible = true
			$ColorRect/VBC/AddCharacterButton.visible = true
			$ColorRect/VBC/DeleteCharacterButton.visible = true
			$ColorRect/VBC/AffectedCharactersList.visible = true
		else:
			$ColorRect/VBC/AffectedCharactersLabel.visible = false
			$ColorRect/VBC/AddCharacterButton.visible = false
			$ColorRect/VBC/DeleteCharacterButton.visible = false
			$ColorRect/VBC/AffectedCharactersList.visible = false
	$ColorRect/VBC/NameEdit.text = current_authored_property.property_name
	$ColorRect/VBC/HBC/DepthEdit.value = current_authored_property.depth
	$ColorRect/VBC/DefaultValueEdit.value = current_authored_property.default_value
	$ColorRect/VBC/AttributionTargetEdit.clear()
	$ColorRect/VBC/AttributionTargetEdit.add_item("Apply to all cast members.")
	$ColorRect/VBC/AttributionTargetEdit.set_item_metadata(0, current_authored_property.possible_attribution_targets.ENTIRE_CAST)
	$ColorRect/VBC/AttributionTargetEdit.add_item("Apply to specific cast members.")
	$ColorRect/VBC/AttributionTargetEdit.set_item_metadata(1, current_authored_property.possible_attribution_targets.CAST_MEMBERS)
	match current_authored_property.attribution_target:
		current_authored_property.possible_attribution_targets.ENTIRE_CAST:
			$ColorRect/VBC/AttributionTargetEdit.select(0)
		current_authored_property.possible_attribution_targets.CAST_MEMBERS:
			$ColorRect/VBC/AttributionTargetEdit.select(1)
	$ColorRect/VBC/AffectedCharactersList.clear()
	var item_index = 0
	for character in current_authored_property.affected_characters:
		$ColorRect/VBC/AffectedCharactersList.add_item(character.char_name)
		$ColorRect/VBC/AffectedCharactersList.set_item_metadata(item_index, character)
		item_index += 1

func _on_AddCharacterButton_pressed():
	$SelectNewAffectedCharacterWindow/PossibleNewAffectedCharactersList.clear()
	if (current_authored_property.affected_characters.size() == storyworld.characters.size()):
		$SelectNewAffectedCharacterWindow/NoCharactersAvailableMessage.visible = true
		$SelectNewAffectedCharacterWindow/PossibleNewAffectedCharactersList.visible = false
	else:
		$SelectNewAffectedCharacterWindow/NoCharactersAvailableMessage.visible = false
		$SelectNewAffectedCharacterWindow/PossibleNewAffectedCharactersList.visible = true
		var item_index = 0
		for character in storyworld.characters:
			if (!current_authored_property.affected_characters.has(character)):
				$SelectNewAffectedCharacterWindow/PossibleNewAffectedCharactersList.add_item(character.char_name)
				$SelectNewAffectedCharacterWindow/PossibleNewAffectedCharactersList.set_item_metadata(item_index, character)
				item_index += 1
	$SelectNewAffectedCharacterWindow.popup()

func _on_SelectNewAffectedCharacterWindow_confirmed():
	var selected_indices = $SelectNewAffectedCharacterWindow/PossibleNewAffectedCharactersList.get_selected_items()
	for index in selected_indices:
		var character = $SelectNewAffectedCharacterWindow/PossibleNewAffectedCharactersList.get_item_metadata(index)
		add_character_to_affected_characters(character)
	refresh()

func _on_DeleteCharacterButton_pressed():
	var nodes_to_delete = $ConfirmRemoveAffectedCharactersWindow/VBC.get_children()
	for each in nodes_to_delete:
		each.call_deferred('free')
	var new_label = Label.new()
	var selected_indices = $ColorRect/VBC/AffectedCharactersList.get_selected_items()
	characters_to_remove_from_those_affected.clear()
	if (0 == selected_indices.size()):
		#No characters are currently selected.
		new_label.text = "No characters are currently selected."
		$ConfirmRemoveAffectedCharactersWindow/VBC.add_child(new_label)
	elif (current_authored_property.affected_characters.size() == selected_indices.size()):
		#Cannot delete all characters from list.
		new_label.text = "A property has to apply to at least one character."
		$ConfirmRemoveAffectedCharactersWindow/VBC.add_child(new_label)
	elif (1 == selected_indices.size()):
		var character = $ColorRect/VBC/AffectedCharactersList.get_item_metadata(selected_indices[0])
		characters_to_remove_from_those_affected.append(character)
		new_label.text = "Are you sure that you want to remove \"" + character.char_name + "\" from the list of characters affected by the \""
		new_label.text += current_authored_property.get_property_name() + "\" property?"
		$ConfirmRemoveAffectedCharactersWindow/VBC.add_child(new_label)
	else:
		new_label.text = "Are you sure that you want to remove the following characters from the list of characters affected by the \""
		new_label.text += current_authored_property.get_property_name() + "\" property?"
		$ConfirmRemoveAffectedCharactersWindow/VBC.add_child(new_label)
		for index in selected_indices:
			var character = $ColorRect/VBC/AffectedCharactersList.get_item_metadata(index)
			characters_to_remove_from_those_affected.append(character)
			new_label = Label.new()
			new_label.text = character.char_name
			$ConfirmRemoveAffectedCharactersWindow/VBC.add_child(new_label)
	$ConfirmRemoveAffectedCharactersWindow.popup()

func _on_ConfirmRemoveAffectedCharactersWindow_confirmed():
	for character in characters_to_remove_from_those_affected:
		print("Removing character: " + character.char_name.left(25) + " from the list of characters affected by " + current_authored_property.get_property_name() + ".")
		remove_character_from_affected_characters(character)
	refresh()

#GUI Themes:

func set_gui_theme(theme_name, background_color):
	$ColorRect.color = background_color
