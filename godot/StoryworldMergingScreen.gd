extends Panel

var file_paths = null
var storyworlds = []
var encounters = []
var characters = []
var MainLabel = null
var EncounterList = null
var CharacterList = null

func _ready():
	MainLabel = $Margin/VBC/HBC1/Label
	EncounterList = $Margin/VBC/HBC2/VBC1/EncounterList
	CharacterList = $Margin/VBC/HBC2/VBC2/CharacterList

func clear_data():
	for storyworld in storyworlds:
		storyworld.clear()
		storyworld.call_deferred("free")
	storyworlds = []
	encounters = []
	characters = []

func load_content_from_files():
	EncounterList.clear()
	CharacterList.clear()
	if (0 == file_paths.size()):
		MainLabel.text = "No files selected for importation."
	elif (1 == file_paths.size()):
		MainLabel.text = "Importing content from file:"
	else:
		MainLabel.text = "Importing content from files:"
	for path in file_paths:
		print("Opening: " + path)
		MainLabel.text += " (" + path + ")"
		var file = File.new()
		file.open(path, 1)
		var json_string = file.get_as_text().replacen("var storyworld_data = ", "")
		var storyworld = Storyworld.new()
		storyworld.load_from_json(json_string)
		file.close()
		storyworlds.append(storyworld)
		for encounter in storyworld.encounters:
			if ("" == encounter.title):
				EncounterList.add_item("[Encounter with blank title]")
			else:
				EncounterList.add_item(encounter.title)
			var index = EncounterList.get_item_count() - 1
			EncounterList.set_item_metadata(index, encounter)
		for character in storyworld.characters:
			if ("" == character.char_name):
				CharacterList.add_item("[Character with blank name]")
			else:
				CharacterList.add_item(character.char_name)
			var index = CharacterList.get_item_count() - 1
			CharacterList.set_item_metadata(index, character)

func get_selected_encounters():
	var selected_encounters = []
	for index in EncounterList.get_selected_items():
		var encounter = EncounterList.get_item_metadata(index)
		selected_encounters.append(encounter)
	return selected_encounters

func get_selected_characters():
	var selected_characters = []
	for index in CharacterList.get_selected_items():
		var character = CharacterList.get_item_metadata(index)
		selected_characters.append(character)
	return selected_characters
