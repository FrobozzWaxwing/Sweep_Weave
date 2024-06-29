extends Object
class_name QuickStoryworld

var characters = []
var character_directory = {}
var encounters = []
var encounter_directory = {}
var option_directory = {} #Used to load projects from json.
var reaction_directory = {} #Used to load projects from json.
var spools = []
var spool_directory = {}
var authored_properties = []
var authored_property_directory = {}
var unique_id_seeds = {"character": 0, "encounter": 0, "option": 0, "reaction": 0, "spool": 0, "authored_property": 0}
var storyworld_debug_mode_on = false
var sweepweave_version_number = ""
var creation_time = null
var modified_time = null
#Metadata:
var storyworld_title = ""
var storyworld_author = ""
var ifid = ""
var about_text = null
var meta_description = "An interactive storyworld made in SweepWeave."
var language = "en" #An ISO 639-1 language code.
var rating = "general"
#Graphics Options:
var storyworld_display_mode = 1 #0 is old display mode, (maintext, choice, reaction, next-button, clear screen, maintext...), 1 is new display mode, (maintext, choice, clear screen, reaction, maintext...)
var css_theme = "lilac"
var font_size = "16"
#Variables for editor:
var project_saved = true

enum sw_script_data_types {BOOLEAN, BNUMBER, STRING, VARIANT}

#Basic Functions:

func _init(in_title = "New Storyworld", in_author = "Anonymous", in_sw_version = "?"):
	storyworld_title = in_title
	storyworld_author = in_author
	about_text = ScriptManager.new(StringConstant.new(""))
	sweepweave_version_number = in_sw_version
	creation_time = Time.get_unix_time_from_system()
	modified_time = Time.get_unix_time_from_system()
	ifid = IFIDGenerator.IFID_from_creation_time(creation_time)

func unique_id(element_type = "encounter", length = 32):
	var result = "%x" % unique_id_seeds[element_type]
	result += "_" + str(Time.get_unix_time_from_system())
	result = result.sha1_text()
	result = result.left(length)
	unique_id_seeds[element_type] += 1
	return result

func clear():
	unique_id_seeds = {"character": 0, "encounter": 0, "option": 0, "reaction": 0, "spool": 0, "authored_property": 0}
	storyworld_title = "New Storyworld"
	storyworld_author = "Anonymous"
	meta_description = "An interactive storyworld made in SweepWeave."
	sweepweave_version_number = "?"
	storyworld_debug_mode_on = false
	storyworld_display_mode = 1
	creation_time = Time.get_unix_time_from_system()
	modified_time = Time.get_unix_time_from_system()
	ifid = IFIDGenerator.IFID_from_creation_time(creation_time)
	language = "en"
	rating = "general"
	css_theme = "lilac"
	font_size = "16"
	var copy_authored_properties = authored_properties.duplicate()
	authored_properties = []
	authored_property_directory = {}
	var copy_characters = characters.duplicate()
	characters = []
	character_directory = {}
	var copy_encounters = encounters.duplicate()
	encounters = []
	encounter_directory = {}
	var copy_spools = spools.duplicate()
	spools = []
	spool_directory = {}
	for each in copy_authored_properties:
		delete_authored_property(each)
	for each in copy_characters:
		delete_character(each)
	for each in copy_encounters:
		each.clear()
		each.call_deferred("free")
	for each in copy_spools:
		each.call_deferred("free")

#Personality / relationship model:

func index_authored_property(property):
	authored_properties.append(property)
	authored_property_directory[property.id] = property

func add_authored_property(property):
	index_authored_property(property)
	if (property.attribution_target == property.possible_attribution_targets.CAST_MEMBERS):
		for character in property.affected_characters:
			character.add_property_to_bnumber_properties(property, characters)
	if (property.attribution_target == property.possible_attribution_targets.ENTIRE_CAST):
		for character in characters:
			character.add_property_to_bnumber_properties(property, characters)

func delete_authored_property(property):
	if (null == property):
		return
	authored_properties.erase(property)
	authored_property_directory.erase(property.id)
	for character in characters:
		character.delete_property_from_bnumber_properties(property)
	property.call_deferred("free")

func init_classical_personality_model():
	#Three personality traits: goodness, honesty, and dominance.
	var ap_names = ["Bad_Good", "False_Honest", "Timid_Dominant"]
	for ap_name in ap_names:
		var new_index = unique_id_seeds["authored_property"]
		unique_id_seeds["authored_property"] += 1
		var new_id = ap_name
		add_authored_property(BNumberBlueprint.new(self, new_index, new_id, ap_name, 0, 0))
	#Three relationship types: affection, trust, and fear.
	ap_names = ["pBad_Good", "pFalse_Honest", "pTimid_Dominant"]
	for ap_name in ap_names:
		var new_index = unique_id_seeds["authored_property"]
		unique_id_seeds["authored_property"] += 1
		var new_id = ap_name
		add_authored_property(BNumberBlueprint.new(self, new_index, new_id, ap_name, 1, 0))

func add_all_authored_properties_from(original):
	for property in original.authored_properties:
		var new_index = unique_id_seeds["authored_property"]
		unique_id_seeds["authored_property"] += 1
		var copy = BNumberBlueprint.new(self, new_index, "", "", 0, 0)
		copy.set_as_copy_of(property, false) #create_mutual_links == false
		index_authored_property(copy)

#Characters:

func add_character(character):
	characters.append(character)
	character_directory[character.id] = character

func delete_character(character):
	characters.erase(character)
	character_directory.erase(character)
	#Delete character from authored properties:
	for property in authored_properties:
		property.affected_characters.erase(character)
	#Delete character from relationships:
	for observer in characters:
		observer.delete_character_from_bnumber_properties(character)
	character.call_deferred("free")

func add_all_characters_from(original):
	for character in original.characters:
		var newbie = Actor.new(self, character.char_name, character.pronoun, character.bnumber_properties)
		newbie.set_as_copy_of(character, false) #create_mutual_links == false
		newbie.creation_index = character.creation_index
		newbie.creation_time = character.creation_time
		newbie.modified_time = Time.get_unix_time_from_system()
		newbie.remap(self)
		add_character(newbie)

func import_characters(original_characters):
	for character in original_characters:
		var newbie = Actor.new(self, character.char_name, character.pronoun, character.bnumber_properties)
		newbie.set_as_copy_of(character, false) #create_mutual_links == false
		newbie.creation_index = character.creation_index
		newbie.creation_time = character.creation_time
		newbie.modified_time = Time.get_unix_time_from_system()
		newbie.remap(self)
		add_character(newbie)

func erase_self_perceptions():
	for character in characters:
		for key in character.bnumber_properties.keys():
			var onion = character.bnumber_properties[key]
			if (TYPE_DICTIONARY == typeof(onion)):
				onion.erase(character.id)
				for key2 in onion.keys():
					var onion2 = onion[key2]
					if (TYPE_DICTIONARY == typeof(onion2)):
						onion2.erase(key2)
					else:
						break

#Encounters:

func add_encounter(encounter):
	encounters.append(encounter)
	encounter_directory[encounter.id] = encounter

func add_all_encounters_from(original):
	for encounter in original.encounters:
		var copy = Encounter.new(self, "", "", "", 0)
		copy.set_as_copy_of(encounter, true, false) #copy_id = true, create_mutual_links == false
		add_encounter(copy)

#Spools:

func add_spool(spool):
	spools.append(spool)
	spool_directory[spool.id] = spool

func add_all_spools_from(original):
	for spool in original.spools:
		var copy = Spool.new()
		copy.set_as_copy_of(spool, false) #create_mutual_links == false
		add_spool(copy)

#Advanced Functions:

func set_as_quickened_copy_of(original):
	unique_id_seeds = original.unique_id_seeds.duplicate(true)
	storyworld_title = original.storyworld_title
	storyworld_author = original.storyworld_author
	storyworld_debug_mode_on = original.storyworld_debug_mode_on
	storyworld_display_mode = original.storyworld_display_mode
	sweepweave_version_number = original.sweepweave_version_number
	clear()
	add_all_authored_properties_from(original)
	add_all_characters_from(original)
	for property_blueprint in authored_properties:
		property_blueprint.remap(self)
	for encounter in original.encounters:
		var encounter_copy = QuickEncounter.new(self, encounter)
		add_encounter(encounter_copy)
	var checklist_index = 0
	for spool in original.spools:
		var spool_copy = QuickSpool.new(self, spool)
		for encounter in spool.encounters:
			if (encounter.acceptability_script.contents is BooleanConstant and !encounter.acceptability_script.contents.value):
				#Leave out encounters that are never acceptable.
				continue
			if (encounter_directory.has(encounter.id)):
				var quick_encounter = encounter_directory[encounter.id]
				if (quick_encounter.desirability_script.contents is BNumberConstant):
					spool_copy.sorted_encounters.append(quick_encounter)
				else:
					spool_copy.unsorted_encounters.append(quick_encounter)
				quick_encounter.connected_spools.append(spool_copy)
				quick_encounter.checklist_id = checklist_index
				checklist_index += 1
		spool_copy.sorted_encounters.sort_custom(Callable(EncounterSorter, "sort_desirability"))
		add_spool(spool_copy)
	for encounter in encounters:
		encounter.remap(self)

func sort_encounters(sort_method, reverse):
	if (reverse):
		match sort_method:
			"Alphabetical":
				encounters.sort_custom(Callable(EncounterSorter, "sort_z_a"))
			"Creation Time":
				encounters.sort_custom(Callable(EncounterSorter, "sort_r_created"))
			"Modified Time":
				encounters.sort_custom(Callable(EncounterSorter, "sort_r_modified"))
			"Option Count":
				encounters.sort_custom(Callable(EncounterSorter, "sort_r_options"))
			"Reaction Count":
				encounters.sort_custom(Callable(EncounterSorter, "sort_r_reactions"))
			"Effect Count":
				encounters.sort_custom(Callable(EncounterSorter, "sort_r_effects"))
			"Characters":
				for encounter in encounters:
					encounter.connected_characters = encounter.get_connected_characters().values()
					encounter.connected_characters.sort_custom(Callable(CharacterSorter, "sort_a_z"))
				encounters.sort_custom(Callable(EncounterSorter, "sort_r_characters"))
			"Spools":
				for encounter in encounters:
					encounter.connected_spools.sort_custom(Callable(SpoolSorter, "sort_a_z"))
				encounters.sort_custom(Callable(EncounterSorter, "sort_r_spools"))
			"Word Count":
				encounters.sort_custom(Callable(EncounterSorter, "sort_r_word_count"))
	else:
		match sort_method:
			"Alphabetical":
				encounters.sort_custom(Callable(EncounterSorter, "sort_a_z"))
			"Creation Time":
				encounters.sort_custom(Callable(EncounterSorter, "sort_created"))
			"Modified Time":
				encounters.sort_custom(Callable(EncounterSorter, "sort_modified"))
			"Option Count":
				encounters.sort_custom(Callable(EncounterSorter, "sort_options"))
			"Reaction Count":
				encounters.sort_custom(Callable(EncounterSorter, "sort_reactions"))
			"Effect Count":
				encounters.sort_custom(Callable(EncounterSorter, "sort_effects"))
			"Characters":
				for encounter in encounters:
					encounter.connected_characters = encounter.get_connected_characters().values()
					encounter.connected_characters.sort_custom(Callable(CharacterSorter, "sort_a_z"))
				encounters.sort_custom(Callable(EncounterSorter, "sort_characters"))
			"Spools":
				for encounter in encounters:
					encounter.connected_spools.sort_custom(Callable(SpoolSorter, "sort_a_z"))
				encounters.sort_custom(Callable(EncounterSorter, "sort_spools"))
			"Word Count":
				encounters.sort_custom(Callable(EncounterSorter, "sort_word_count"))

func trace_referenced_events():
	#Run through the storyworld and connect events to the scripts that reference them.
	for encounter in encounters:
		encounter.linked_scripts.clear()
		for option in encounter.get_options():
			option.linked_scripts.clear()
			for reaction in option.reactions:
				reaction.linked_scripts.clear()
	for encounter in encounters:
		encounter.acceptability_script.trace_referenced_events()
		encounter.desirability_script.trace_referenced_events()
		for option in encounter.get_options():
			option.visibility_script.trace_referenced_events()
			option.performability_script.trace_referenced_events()
			for reaction in option.reactions:
				reaction.desirability_script.trace_referenced_events()
				for effect in reaction.after_effects:
					effect.assignment_script.trace_referenced_events()

func check_for_parallels():
	for encounter in encounters:
		encounter.check_for_parallels()

func cast_has_properties():
	for character in characters:
		if (character.has_properties()):
			return true
	return false
