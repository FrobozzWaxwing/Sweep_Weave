extends ColorRect

#Character Edit Interface Elements:
var storyworld = null
var current_character = null
var trait_editing_node_scene = load("res://interface/CharacterTraitEditingInterface.tscn")
var character_to_delete = null #We want to set this up as a gloabal variable for this script in case a user

signal new_character_created(character)
signal character_name_changed(character)
signal character_deleted()
signal refresh_authored_property_lists()

func _ready():
	pass

func log_update(character = null):
	if (null != character):
		character.log_update()
	storyworld.log_update()
	get_window().set_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false

func refresh_character_list():
	$HBC/VBC/CharacterList.clear()
	var index = 0
	for character in storyworld.characters:
		$HBC/VBC/CharacterList.add_item(character.get_listable_text())
		$HBC/VBC/CharacterList.set_item_metadata(index, character)
		index += 1
	if (0 < storyworld.characters.size()):
		$HBC/VBC/CharacterList.select(0)

func refresh_property_list():
	for each in $HBC/VBC2/Scroll_Properties/VBC.get_children():
		each.queue_free()
	if (0 == storyworld.characters.size()):
		return
	for key in current_character.bnumber_properties.keys():
		var onion = current_character.bnumber_properties[key]
		if (TYPE_DICTIONARY == typeof(onion) and onion.is_empty()):
			continue
		var new_node = trait_editing_node_scene.instantiate()
		new_node.storyworld = storyworld
		new_node.character_to_edit = current_character
		new_node.keyring = [key]
		var depth = storyworld.authored_property_directory[key].depth
		if (0 < depth):
			for index in range(1, depth + 1):
				for character in storyworld.characters:
					if (character.id in onion):
						new_node.keyring.append(character.id)
						onion = onion[character.id]
						break
		new_node.refresh()
		$HBC/VBC2/Scroll_Properties/VBC.add_child(new_node)

func _on_AddCharacter_pressed():
	var new_character = storyworld.create_default_character()
	for character in storyworld.characters:
		for property in storyworld.authored_properties:
			if (property.attribution_target == property.possible_attribution_targets.CAST_MEMBERS and property.affected_characters.has(character)):
				character.add_character_to_bnumber_property(new_character, property, storyworld.characters)
			if (property.attribution_target == property.possible_attribution_targets.ENTIRE_CAST):
				character.add_character_to_bnumber_property(new_character, property, storyworld.characters)
	storyworld.add_character(new_character)
	new_character.initialize_bnumber_properties(storyworld.characters, storyworld.authored_properties)
	log_update(new_character)
	$HBC/VBC/CharacterList.add_item(new_character.get_listable_text())
	var index = $HBC/VBC/CharacterList.get_item_count() - 1
	$HBC/VBC/CharacterList.set_item_metadata(index, new_character)
	new_character_created.emit(new_character)
	load_character(new_character)

func load_character(who:Actor):
	current_character = who
	$HBC/VBC2/CharNameEdit.text = current_character.char_name
	$HBC/VBC2/CharPronounEdit.text = current_character.pronoun
	refresh_property_list()
	$HBC/VBC/CharacterList.select(storyworld.characters.find(who))

func _on_CharNameEdit_text_changed(new_text:String):
	current_character.char_name = new_text
	if ($HBC/VBC/CharacterList.is_anything_selected()):
		var selection = $HBC/VBC/CharacterList.get_selected_items()
		$HBC/VBC/CharacterList.set_item_text(selection[0], current_character.get_listable_text())
	for each in $HBC/VBC2/Scroll_Properties/VBC.get_children():
		each.refresh_character_name(current_character)
	log_update(current_character)
	character_name_changed.emit(current_character)

func _on_CharPronounEdit_text_changed(new_text):
	current_character.pronoun = new_text
	log_update(null)

func _on_DeleteCharacter_pressed():
	if ($HBC/VBC/CharacterList.is_anything_selected()):
		if (1 < storyworld.characters.size()):
			var selection = $HBC/VBC/CharacterList.get_selected_items()
			var dialog_text = 'Are you sure you wish to delete the character: "'
			character_to_delete = storyworld.characters[selection[0]]
			dialog_text += character_to_delete.char_name + '"?'
			$ConfirmCharacterDeletion.dialog_text = dialog_text
			$ConfirmCharacterDeletion.popup_centered()
		else:
			print("The storyworld must have at least one character.")

func _on_ConfirmCharacterDeletion_confirmed():
	if ($HBC/VBC/CharacterList.is_anything_selected()):
		#Delete character from scripts:
		for encounter in storyworld.encounters:
			encounter.acceptability_script.delete_character(character_to_delete) #ScriptManager
			encounter.desirability_script.delete_character(character_to_delete) #ScriptManager
			for option in encounter.options:
				option.visibility_script.delete_character(character_to_delete) #ScriptManager
				option.performability_script.delete_character(character_to_delete) #ScriptManager
				for reaction in option.reactions:
					reaction.desirability_script.delete_character(character_to_delete) #ScriptManager
					for effect in reaction.after_effects:
						if (effect is BNumberEffect):
							effect.assignee.delete_character(character_to_delete) #BNumberPointer
							effect.assignment_script.delete_character(character_to_delete) #ScriptManager
						elif (effect is SpoolEffect):
							effect.assignment_script.delete_character(character_to_delete) #ScriptManager
		storyworld.delete_character(character_to_delete)
		log_update(null)
		refresh_character_list()
		if (!storyworld.characters.is_empty()):
			load_character(storyworld.characters.front())
		character_deleted.emit()
		refresh_authored_property_lists.emit()

func _on_CharacterList_item_selected(index):
	if (0 < storyworld.characters.size()):
		var who = $HBC/VBC/CharacterList.get_item_metadata(index)
		load_character(who)

#GUI Themes:

@onready var add_icon_light = preload("res://icons/add.svg")
@onready var add_icon_dark = preload("res://icons/add_dark.svg")
@onready var delete_icon_light = preload("res://icons/delete.svg")
@onready var delete_icon_dark = preload("res://icons/delete_dark.svg")

func set_gui_theme(theme_name, background_color):
	color = background_color
	match theme_name:
		"Clarity":
			$HBC/VBC/Header/AddCharacter.icon = add_icon_dark
			$HBC/VBC/Header/DeleteCharacter.icon = delete_icon_dark
		"Lapis Lazuli":
			$HBC/VBC/Header/AddCharacter.icon = add_icon_light
			$HBC/VBC/Header/DeleteCharacter.icon = delete_icon_light
