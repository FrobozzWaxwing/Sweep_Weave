extends ColorRect

#Character Edit Interface Elements:
var storyworld = null
var current_character = null
var trait_editing_node_scene = load("res://CharacterTraitEditingInterface.tscn")
var character_to_delete = null #We want to set this up as a gloabal variable for this script in case a user

signal new_character_created(character)
signal character_name_changed(character)
signal character_deleted(deleted_character, replacement)

func _ready():
	pass

func log_update(character = null):
	if (null != character):
		character.log_update()
	storyworld.log_update()
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false

func refresh_character_list():
	$HBC/VBC/Scroll/CharacterList.clear()
	var index = 0
	for character in storyworld.characters:
		$HBC/VBC/Scroll/CharacterList.add_item(character.char_name)
		$HBC/VBC/Scroll/CharacterList.set_item_metadata(index, character)
		index += 1
	if (0 < storyworld.characters.size()):
		$HBC/VBC/Scroll/CharacterList.select(0)

func refresh_property_list():
	for each in $HBC/VBC2/Scroll_Properties/VBC.get_children():
		each.queue_free()
	if (0 == storyworld.characters.size()):
		return
	for key in current_character.bnumber_properties.keys():
		var new_node = trait_editing_node_scene.instance()
		new_node.storyworld = storyworld
		new_node.character = current_character
		new_node.keyring = [key]
		for index in range(storyworld.authored_property_directory[key].depth):
			new_node.keyring.append(storyworld.characters[0].id)
		new_node.refresh()
		$HBC/VBC2/Scroll_Properties/VBC.add_child(new_node)

func _on_AddCharacter_pressed():
	var new_character = storyworld.create_default_character()
	for character in storyworld.characters:
		for property in storyworld.authored_properties:
			if (property.attribution_target == property.possible_attribution_targets.CAST_MEMBERS and property.affected_characters.has(character)):
				character.add_character_to_bnumber_property(new_character, property.id, property.depth, property.default_value, storyworld.characters)
			if (property.attribution_target == property.possible_attribution_targets.ENTIRE_CAST):
				character.add_character_to_bnumber_property(new_character, property.id, property.depth, property.default_value, storyworld.characters)
	storyworld.add_character(new_character)
	new_character.initialize_bnumber_properties(storyworld.characters, storyworld.authored_properties)
	log_update(new_character)
	$HBC/VBC/Scroll/CharacterList.add_item(new_character.char_name)
	var index = $HBC/VBC/Scroll/CharacterList.get_item_count() - 1
	$HBC/VBC/Scroll/CharacterList.set_item_metadata(index, new_character)
	emit_signal("new_character_created", new_character)
	load_character(new_character)

func load_character(who):
	current_character = who
	$HBC/VBC2/CharNameEdit.text = current_character.char_name
	$HBC/VBC2/CharPronounEdit.text = current_character.pronoun
	refresh_property_list()
	$HBC/VBC/Scroll/CharacterList.select(storyworld.characters.find(who))

func _on_CharNameEdit_text_changed(new_text):
	current_character.char_name = new_text
	if ($HBC/VBC/Scroll/CharacterList.is_anything_selected()):
		var selection = $HBC/VBC/Scroll/CharacterList.get_selected_items()
		$HBC/VBC/Scroll/CharacterList.set_item_text(selection[0], current_character.char_name)
	for each in $HBC/VBC2/Scroll_Properties/VBC.get_children():
		each.refresh_character_name(current_character)
	log_update(current_character)
	emit_signal("character_name_changed", current_character)

func _on_CharPronounEdit_text_changed(new_text):
	current_character.pronoun = new_text
	log_update(null)

func _on_DeleteCharacter_pressed():
	if ($HBC/VBC/Scroll/CharacterList.is_anything_selected()):
		if (1 < storyworld.characters.size()):
			var selection = $HBC/VBC/Scroll/CharacterList.get_selected_items()
			var dialog_text = 'Are you sure you wish to delete the character: "'
			character_to_delete = storyworld.characters[selection[0]]
			dialog_text += character_to_delete.char_name + '"? If so, please select a new character to serve as the antagonist for every encounter currently employing "' + character_to_delete.char_name + '" as antagonist.'
			$ConfirmCharacterDeletion.dialog_text = dialog_text
			$ConfirmCharacterDeletion/Center/AntagonistReplacementPicker.clear()
			var option_index = 0
			for each in storyworld.characters:
				if (each != character_to_delete):
					$ConfirmCharacterDeletion/Center/AntagonistReplacementPicker.add_item(each.char_name)
					$ConfirmCharacterDeletion/Center/AntagonistReplacementPicker.set_item_metadata(option_index, each)
					option_index += 1
			$ConfirmCharacterDeletion/Center/AntagonistReplacementPicker.select(0)
			$ConfirmCharacterDeletion.popup()
		else:
			print("The storyworld must have at least one character.")

func _on_ConfirmCharacterDeletion_confirmed():
	if ($HBC/VBC/Scroll/CharacterList.is_anything_selected()):
		var replacement = $ConfirmCharacterDeletion/Center/AntagonistReplacementPicker.get_selected_metadata()
		print("Replacing: \"" + character_to_delete.char_name + "\" with \"" + replacement.char_name + "\" in all scripts.")
		for encounter in storyworld.encounters:
			if (encounter.antagonist == character_to_delete):
				encounter.antagonist = replacement
				log_update(encounter)
			print(encounter.title + " Desirability Script")
			encounter.desirability_script.replace_character_with_character(character_to_delete, replacement) #ScriptManager
			for option in encounter.options:
				for reaction in option.reactions:
					print(reaction.text.left(25) + " Desirability Script")
					reaction.desirability_script.replace_character_with_character(character_to_delete, replacement) #ScriptManager
					for effect in reaction.after_effects:
						if (effect is BNumberEffect):
							effect.operand_0.replace_character_with_character(character_to_delete, replacement) #BNumberPointer
							effect.operand_1.replace_character_with_character(character_to_delete, replacement) #ScriptManager
		for authored_property in storyworld.authored_properties:
			authored_property.affected_characters.erase(character_to_delete)
		storyworld.characters.erase(character_to_delete)
		character_to_delete.call_deferred("free")
		log_update(null)
		refresh_character_list()
		if (0 < storyworld.characters.size()):
			$HBC/VBC/Scroll/CharacterList.select(0)
			load_character(storyworld.characters[0])
		emit_signal("character_deleted", character_to_delete, replacement)

func _on_CharacterList_item_selected(index):
	if (0 < storyworld.characters.size()):
		var selection = $HBC/VBC/Scroll/CharacterList.get_selected_items()
		var who = storyworld.characters[selection[0]]
		load_character(who)
