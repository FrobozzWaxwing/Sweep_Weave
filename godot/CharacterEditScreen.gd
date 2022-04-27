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
	OS.set_window_title("Encounter Editor - " + storyworld.storyworld_title + "*")
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
	for key in storyworld.personality_model.keys():
		if (0 == storyworld.personality_model[key]):
			var new_node = trait_editing_node_scene.instance()
			new_node.character = current_character
			new_node.keyring = [key]
			new_node.refresh()
			$HBC/VBC2/Scroll_Properties/VBC.add_child(new_node)

func _on_AddCharacter_pressed():
	var new_name = "So&So " + str(storyworld.char_unique_id_seed)
	var new_character = Actor.new(storyworld, new_name, "they")
	new_character.creation_index = storyworld.char_unique_id_seed
	new_character.creation_time = OS.get_unix_time()
	new_character.modified_time = OS.get_unix_time()
	new_character.id = storyworld.char_unique_id()
	print("New character: " + new_character.char_name)
	storyworld.add_character(new_character)
	load_character(new_character)
	log_update(new_character)
	emit_signal("new_character_created", new_character)
	$HBC/VBC/Scroll/CharacterList.add_item(new_character.char_name)
	var index = $HBC/VBC/Scroll/CharacterList.get_item_count() - 1
	$HBC/VBC/Scroll/CharacterList.set_item_metadata(index, new_character)
	$HBC/VBC/Scroll/CharacterList.select(index)

func load_character(who):
	current_character = who
	$HBC/VBC2/CharNameEdit.text = current_character.char_name
	$HBC/VBC2/CharPronounEdit.text = current_character.pronoun
	for each in $HBC/VBC2/Scroll_Properties/VBC.get_children():
		each.character = current_character
		each.refresh()
	$HBC/VBC/Scroll/CharacterList.select(storyworld.characters.find(who))

func _on_CharNameEdit_text_changed(new_text):
	current_character.char_name = new_text
	var selection = $HBC/VBC/Scroll/CharacterList.get_selected_items()
	$HBC/VBC/Scroll/CharacterList.set_item_text(selection[0], current_character.char_name)
	#$VBC/Bookspine/EditorTabs/Encounters/Main/HSC/Column2/HBCTurn/VBC3/AntagonistPicker.set_item_text(selection[0], current_character.char_name)
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
			for each in storyworld.characters:
				if (each != character_to_delete):
					$ConfirmCharacterDeletion/Center/AntagonistReplacementPicker.add_item(each.char_name)
			$ConfirmCharacterDeletion/Center/AntagonistReplacementPicker.select(0)
			$ConfirmCharacterDeletion.popup()
		else:
			print("The storyworld must have at least one character.")

func _on_ConfirmCharacterDeletion_confirmed():
	if ($HBC/VBC/Scroll/CharacterList.is_anything_selected()):
#		var selection = $HBC/VBC/Scroll/CharacterList.get_selected_items()
#		var character_to_delete = storyworld.characters[selection[0]]
		var replacement = storyworld.characters[$ConfirmCharacterDeletion/Center/AntagonistReplacementPicker.get_selected_id()]
		print("Deleting: " + character_to_delete.char_name)
		for encounter in storyworld.encounters:
			for desid in encounter.desiderata:
				if (desid.character == character_to_delete):
					desid.character = replacement
					log_update(encounter)
			if (encounter.antagonist == character_to_delete):
				encounter.antagonist = replacement
				log_update(encounter)
		storyworld.characters.erase(character_to_delete)
		character_to_delete.call_deferred("free")
		log_update(null)
		refresh_character_list()
		$HBC/VBC/Scroll/CharacterList.select(0)
		load_character(storyworld.characters[0])
		emit_signal("character_deleted", character_to_delete, replacement)

func _on_CharacterList_item_selected(index):
	var selection = $HBC/VBC/Scroll/CharacterList.get_selected_items()
	var who = storyworld.characters[selection[0]]
	load_character(who)
