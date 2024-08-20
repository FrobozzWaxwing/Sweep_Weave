extends Panel

var file_path = ""
var storyworld_to_merge = null

func _ready():
	pass

func load_content_from_files():
	if ("" == file_path):
		return
	if not FileAccess.file_exists(file_path):
		return # Error: File not found.
	var file = FileAccess.open(file_path, FileAccess.READ)
	if (null == file):
		return # Error: Could not open file.
	var json_string = file.get_as_text().replacen("var storyworld_data = ", "")
	var storyworld = Storyworld.new()
	storyworld.load_from_json(json_string)
	file.close()
	#storyworlds.append(storyworld)
	#for encounter in storyworld.encounters:
		#if ("" == encounter.title):
			#EncounterList.add_item("[Encounter with blank title]")
		#else:
			#EncounterList.add_item(encounter.title)
		#var index = EncounterList.get_item_count() - 1
		#EncounterList.set_item_metadata(index, encounter)
	#for character in storyworld.characters:
		#if ("" == character.char_name):
			#CharacterList.add_item("[Character with blank name]")
		#else:
			#CharacterList.add_item(character.char_name)
		#var index = CharacterList.get_item_count() - 1
		#CharacterList.set_item_metadata(index, character)
