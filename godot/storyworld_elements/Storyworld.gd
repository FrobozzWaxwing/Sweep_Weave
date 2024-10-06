extends Object
class_name Storyworld

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

func log_update():
	modified_time = Time.get_unix_time_from_system()

func clear():
	unique_id_seeds = {"character": 0, "encounter": 0, "option": 0, "reaction": 0, "spool": 0, "authored_property": 0}
	storyworld_title = "New Storyworld"
	storyworld_author = "Anonymous"
	set_about_text("")
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
		delete_encounter(each)
	for each in copy_spools:
		delete_spool(each)

#About text:

func get_about_text():
	if (about_text is ScriptManager):
		if (about_text.sw_script_data_types.STRING == about_text.output_type):
			return about_text.get_value()
	return ""

func set_about_text(new_text):
	if (about_text is ScriptManager):
		if (about_text.contents is StringConstant):
			about_text.contents.set_value(new_text)

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

func delete_encounter(encounter):
	encounters.erase(encounter)
	encounter_directory.erase(encounter)
	for each1 in encounters:
		if (each1.acceptability_script.delete_encounter(encounter)):
			each1.log_update()
		if (each1.desirability_script.delete_encounter(encounter)):
			each1.log_update()
		if (each1.text_script.delete_encounter(encounter)):
			each1.log_update()
		for each2 in each1.options:
			if (each2.visibility_script.delete_encounter(encounter)):
				each1.log_update()
			if (each2.performability_script.delete_encounter(encounter)):
				each1.log_update()
			if (each2.text_script.delete_encounter(encounter)):
				each1.log_update()
			for each3 in each2.reactions:
				if (each3.consequence == encounter):
					each3.consequence = null
					each1.log_update()
				if (each3.desirability_script.delete_encounter(encounter)):
					each1.log_update()
				if (each3.text_script.delete_encounter(encounter)):
					each1.log_update()
				for effect in each3.after_effects:
					if (effect is SWEffect and effect.assignment_script is ScriptManager):
						if (effect.assignment_script.delete_encounter(encounter)):
							each1.log_update()
	for spool in encounter.connected_spools:
		spool.encounters.erase(encounter)
	encounter.clear()
	encounter.call_deferred("free")

func add_all_encounters_from(original):
	for encounter in original.encounters:
		var copy = Encounter.new(self, "", "", "", 0)
		copy.set_as_copy_of(encounter, true, false) #copy_id = true, create_mutual_links == false
		add_encounter(copy)

func import_encounters(original_encounters):
	for encounter in original_encounters:
		var copy = Encounter.new(self, "", "", "", 0)
		copy.set_as_copy_of(encounter, true, false) #copy_id = true, create_mutual_links == false
		add_encounter(copy)
	for encounter in encounters:
		encounter.remap(self)

func duplicate_encounter(encounter):
	var new_id_seed = unique_id_seeds["encounter"]
	var new_id = "enc_" + unique_id()
	var new_encounter = Encounter.new(self, new_id, "", "", 0)
	new_encounter.set_as_copy_of(encounter, false, true) #copy_id = false, create_mutual_links == true
	new_encounter.title += " copy"
	new_encounter.creation_index = new_id_seed
	new_encounter.creation_time = Time.get_unix_time_from_system()
	new_encounter.modified_time = Time.get_unix_time_from_system()
	add_encounter(new_encounter)
	return new_encounter

func delete_option_from_scripts(option):
	for each1 in encounters:
		if (each1.acceptability_script.delete_option(option)):
			each1.log_update()
		if (each1.desirability_script.delete_option(option)):
			each1.log_update()
		if (each1.text_script.delete_option(option)):
			each1.log_update()
		for each2 in each1.options:
			if (each2.visibility_script.delete_option(option)):
				each1.log_update()
			if (each2.performability_script.delete_option(option)):
				each1.log_update()
			if (each2.text_script.delete_option(option)):
				each1.log_update()
			for each3 in each2.reactions:
				if (each3.desirability_script.delete_option(option)):
					each1.log_update()
				if (each3.text_script.delete_option(option)):
					each1.log_update()
				for effect in each3.after_effects:
					if (effect is SWEffect and effect.assignment_script is ScriptManager):
						if (effect.assignment_script.delete_option(option)):
							each1.log_update()

func delete_reaction_from_scripts(reaction):
	for each1 in encounters:
		if (each1.acceptability_script.delete_reaction(reaction)):
			each1.log_update()
		if (each1.desirability_script.delete_reaction(reaction)):
			each1.log_update()
		if (each1.text_script.delete_reaction(reaction)):
			each1.log_update()
		for each2 in each1.options:
			if (each2.visibility_script.delete_reaction(reaction)):
				each1.log_update()
			if (each2.performability_script.delete_reaction(reaction)):
				each1.log_update()
			if (each2.text_script.delete_reaction(reaction)):
				each1.log_update()
			for each3 in each2.reactions:
				if (each3.desirability_script.delete_reaction(reaction)):
					each1.log_update()
				if (each3.text_script.delete_reaction(reaction)):
					each1.log_update()
				for effect in each3.after_effects:
					if (effect is SWEffect and effect.assignment_script is ScriptManager):
						if (effect.assignment_script.delete_reaction(reaction)):
							each1.log_update()

#Spools:

func add_spool(spool):
	spools.append(spool)
	spool_directory[spool.id] = spool

func delete_spool(spool):
	for encounter in spool.encounters:
		encounter.connected_spools.erase(spool)
	for each1 in encounters:
		if (each1.acceptability_script.delete_spool(spool)):
			each1.log_update()
		if (each1.desirability_script.delete_spool(spool)):
			each1.log_update()
		if (each1.text_script.delete_spool(spool)):
			each1.log_update()
		for each2 in each1.options:
			if (each2.visibility_script.delete_spool(spool)):
				each1.log_update()
			if (each2.performability_script.delete_spool(spool)):
				each1.log_update()
			if (each2.text_script.delete_spool(spool)):
				each1.log_update()
			for each3 in each2.reactions:
				if (each3.desirability_script.delete_spool(spool)):
					each1.log_update()
				if (each3.text_script.delete_spool(spool)):
					each1.log_update()
				var effects = each3.after_effects.duplicate()
				for effect in effects:
					if (effect is SWEffect):
						if (effect is SpoolEffect and effect.assignee is SpoolPointer and effect.assignee.spool == spool):
							each3.after_effects.erase(effect)
							effect.call_deferred("free")
							each1.log_update()
						elif (effect.assignment_script is ScriptManager):
							if (effect.assignment_script.delete_spool(spool)):
								each1.log_update()
	spools.erase(spool)
	spool_directory.erase(spool)
	spool.call_deferred("free")

func add_all_spools_from(original):
	for spool in original.spools:
		var copy = Spool.new()
		copy.set_as_copy_of(spool, false) #create_mutual_links == false
		add_spool(copy)

#Advanced Functions:

func set_as_copy_of(original):
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
	add_all_encounters_from(original)
	add_all_spools_from(original)
	for encounter in encounters:
		encounter.remap(self)
	for spool in spools:
		spool.remap(self)

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
			"Desirability":
				encounters.sort_custom(Callable(EncounterSorter, "sort_r_desirability"))
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
			"Desirability":
				encounters.sort_custom(Callable(EncounterSorter, "sort_desirability"))
			"Word Count":
				encounters.sort_custom(Callable(EncounterSorter, "sort_word_count"))

func trace_referenced_events():
	#Run through the storyworld and connect events to the scripts that reference them.
	for encounter in encounters:
		encounter.linked_scripts.clear()
		for option in encounter.options:
			option.linked_scripts.clear()
			for reaction in option.reactions:
				reaction.linked_scripts.clear()
	for encounter in encounters:
		encounter.acceptability_script.trace_referenced_events()
		encounter.desirability_script.trace_referenced_events()
		encounter.text_script.trace_referenced_events()
		for option in encounter.options:
			option.visibility_script.trace_referenced_events()
			option.performability_script.trace_referenced_events()
			option.text_script.trace_referenced_events()
			for reaction in option.reactions:
				reaction.desirability_script.trace_referenced_events()
				reaction.text_script.trace_referenced_events()
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

func create_default_bnumber_pointer():
	if (authored_properties.is_empty() or characters.is_empty()):
		#Something has gone terribly wrong.
		return null
	var character = null
	for prospect in characters:
		if (!prospect.bnumber_properties.is_empty() and !prospect.authored_properties.is_empty()):
			character = prospect
			break
	if (null == character):
		return null
	var property = character.authored_properties.front()
	var keyring = []
	keyring.append(property.id)
	var onion = character.bnumber_properties[property.id]
	for key_index in range(1, property.depth + 1):
		if (TYPE_DICTIONARY == typeof(onion)):
			for prospect in characters:
				if (onion.has(prospect.id)):
					keyring.append(prospect.id)
					onion = onion[prospect.id]
					break
		else:
			break
	return BNumberPointer.new(character, keyring)

func create_default_character():
	var new_index = unique_id_seeds["character"]
	var new_name = "So&So " + str(new_index)
	var new_character = Actor.new(self, new_name, "they")
	new_character.creation_index = new_index
	new_character.id = unique_id("character", 16)
	return new_character

func create_new_generic_reaction(option):
	var new_desirability_script = ScriptManager.new(BNumberConstant.new(0))
	return Reaction.new(option, unique_id("reaction", 32), "", new_desirability_script)

func create_new_generic_option(encounter):
	var new_option = Option.new(encounter, unique_id("option", 32), "")
	var new_reaction = create_new_generic_reaction(new_option)
	new_option.reactions.append(new_reaction)
	return new_option

func create_new_generic_encounter():
	var new_index = unique_id_seeds["encounter"]
	var new_encounter = Encounter.new(self, "page_" + unique_id(), "Encounter " + str(new_index), "", new_index)
	var new_option = create_new_generic_option(new_encounter)
	new_encounter.options.append(new_option)
	return new_encounter

# Json parsing system:

#Functions for loading project files made in SweepWeave versions 0.0.07 through 0.0.15:

func parse_reactions_data_v0_0_07_through_v0_0_15(data, incomplete_reactions, option, antagonist):
	var result = []
	for each in data:
		var graph_offset = Vector2(0, 0)
		if (each.has_all(["graph_offset_x", "graph_offset_y"])):
			graph_offset = Vector2(each["graph_offset_x"], each["graph_offset_y"])
		var blend_x = BNumberPointer.new(antagonist)
		var blend_y = BNumberPointer.new(antagonist)
		# Check whether or not each blend operand is negated.
		if ("-" == each["blend_x"].left(1)):
			blend_x.keyring.append(each["blend_x"].substr(1))
			blend_x.coefficient = -1
		else:
			blend_x.keyring.append(each["blend_x"])
		if ("-" == each["blend_y"].left(1)):
			blend_y.keyring.append(each["blend_y"].substr(1))
			blend_y.coefficient = -1
		else:
			blend_y.keyring.append(each["blend_y"])
		var blend_weight = BNumberConstant.new(each["blend_weight"])
		var z = BlendOperator.new(blend_x, blend_y, blend_weight)
		var script = ScriptManager.new(z)
		var reaction = Reaction.new(option, unique_id("reaction", 32), each["text"], script, graph_offset)
		if ("wild" == each["consequence_id"]):
			reaction.consequence = null
		elif (encounter_directory.has(each["consequence_id"])):
			reaction.consequence = encounter_directory[each["consequence_id"]]
		else:
			incomplete_reactions.append([reaction, each["consequence_id"]])
		if (each.has("pValue_changes")):
			for x in each["pValue_changes"]:
				var character:Actor = characters[x["character"]]
				var pointer1 = BNumberPointer.new(character, [x["pValue"]])
				var point = BNumberConstant.new(x["point"])
				var new_nudge_operator = NudgeOperator.new(pointer1, point)
				var new_script = ScriptManager.new(new_nudge_operator)
				var pointer2 = BNumberPointer.new(character, [x["pValue"]])
				var new_effect = BNumberEffect.new(pointer2, new_script)
				reaction.add_effect(new_effect)
		elif (each.has_all(["deltaLove", "deltaTrust", "deltaFear"])):
			#This section is included for backwards compatibility.
			if (0 != each["deltaLove"]):
				var pointer1 = BNumberPointer.new(antagonist, ["pBad_Good"])
				var point = BNumberConstant.new(each["deltaLove"])
				var new_nudge_operator = NudgeOperator.new(pointer1, point)
				var new_script = ScriptManager.new(new_nudge_operator)
				var pointer2 = BNumberPointer.new(antagonist, ["pBad_Good"])
				var new_effect = BNumberEffect.new(pointer2, new_script)
				reaction.add_effect(new_effect)
			if (0 != each["deltaTrust"]):
				var pointer1 = BNumberPointer.new(antagonist, ["pFalse_Honest"])
				var point = BNumberConstant.new(each["deltaTrust"])
				var new_nudge_operator = NudgeOperator.new(pointer1, point)
				var new_script = ScriptManager.new(new_nudge_operator)
				var pointer2 = BNumberPointer.new(antagonist, ["pFalse_Honest"])
				var new_effect = BNumberEffect.new(pointer2, new_script)
				reaction.add_effect(new_effect)
			if (0 != each["deltaFear"]):
				var pointer1 = BNumberPointer.new(antagonist, ["pTimid_Dominant"])
				var point = BNumberConstant.new(each["deltaFear"])
				var new_nudge_operator = NudgeOperator.new(pointer1, point)
				var new_script = ScriptManager.new(new_nudge_operator)
				var pointer2 = BNumberPointer.new(antagonist, ["pTimid_Dominant"])
				var new_effect = BNumberEffect.new(pointer2, new_script)
				reaction.add_effect(new_effect)
		result.append(reaction)
		reaction_directory[reaction.id] = reaction
	return result

func parse_prerequisite_data_v0_0_07_through_v0_0_15(data):
	var new_prerequisite = EventPointer.new()
	new_prerequisite.encounter = encounter_directory[data["encounter"]]
	new_prerequisite.option = new_prerequisite.encounter.options[data["option"]]
	new_prerequisite.reaction = new_prerequisite.option.reactions[data["reaction"]]
	if (data["negated"]):
		new_prerequisite = SWNotOperator.new(new_prerequisite)
	return new_prerequisite

func load_from_json_v0_0_07_through_v0_0_15(data_to_load):
	var incomplete_reactions = []
	var incomplete_encounters = []
	var ap_names = ["Bad_Good", "False_Honest", "Timid_Dominant", "pBad_Good", "pFalse_Honest", "pTimid_Dominant"]
	for ap_name in ap_names:
		var new_index = unique_id_seeds["authored_property"]
		unique_id_seeds["authored_property"] += 1
		var new_id = ap_name
		add_authored_property(BNumberBlueprint.new(self, new_index, new_id, ap_name, 0, 0))
	for entry in data_to_load.characters:
		var newbie = Actor.new(self, entry["name"], entry["pronoun"])
		if (entry.has_all(["Bad_Good", "False_Honest", "Timid_Dominant", "pBad_Good", "pFalse_Honest", "pTimid_Dominant"])):
			newbie.set_classical_personality_model(entry["Bad_Good"], entry["False_Honest"], entry["Timid_Dominant"], entry["pBad_Good"], entry["pFalse_Honest"], entry["pTimid_Dominant"])
		elif (entry.has("bnumber_properties")):
			#In version 0.0.15 of SweepWeave, each character's "bnumber_properties" property should only contain 0-depth properties, specifically the 6 listed just above, so we shouldn't need to worry about character ids. Also, character ids were not yet being saved to json.
			newbie.bnumber_properties = entry["bnumber_properties"].duplicate(true)
		if (entry.has_all(["creation_time", "modified_time"])):
			newbie.creation_time = entry["creation_time"]
			newbie.modified_time = entry["modified_time"]
		else:
			newbie.creation_time = Time.get_unix_time_from_system()
			newbie.modified_time = Time.get_unix_time_from_system()
		if (entry.has_all(["creation_index"])):
			newbie.creation_index = entry["creation_index"]
		else:
			newbie.creation_index = unique_id_seeds["character"]
		newbie.id = unique_id("character", 16)
		add_character(newbie)
	#Begin loading encounters.
	#This must proceed in stages, so that encounters which have other encounters associated with them as prerequisites or consequences can be loaded in correctly.
	for entry in data_to_load.encounters:
		#Create encounter:
		var new_encounter = Encounter.new(self, entry["id"], entry["title"], entry["main_text"], entry["creation_index"], entry["creation_time"], entry["modified_time"], Vector2(entry["graph_position_x"], entry["graph_position_y"]))
		new_encounter.earliest_turn = entry["earliest_turn"]
		new_encounter.latest_turn = entry["latest_turn"]
		#Parse prerequisites:
		if (0 < entry["prerequisites"].size()):
			new_encounter.acceptability_script.set_contents(BooleanComparator.new("And"))
		var incomplete = false
		for each in entry["prerequisites"]:
			if (encounter_directory.has(each["encounter"])):
				new_encounter.acceptability_script.contents.operands.append(parse_prerequisite_data_v0_0_07_through_v0_0_15(each))
			else:
				new_encounter.acceptability_script.contents.operands.append(each)
				incomplete = true
		if (true == incomplete):
			incomplete_encounters.append(new_encounter)
		#Parse desiderata:
		if (0 < entry["desiderata"].size()):
			new_encounter.desirability_script.set_contents(ArithmeticMeanOperator.new())
		for each in entry["desiderata"]:
			var d_char:Actor = characters[each["character"]]
			var d_pValue:String = each["pValue"]
			var d_point = BNumberConstant.new(each["point"])
			var pointer = BNumberPointer.new(d_char, [d_pValue])
			var new_desideratum = Desideratum.new(pointer, d_point)
			new_encounter.desirability_script.contents.operands.append(new_desideratum)
			new_desideratum.parent_operator = new_encounter.desirability_script.contents
		#Parse options:
		var antagonist = null
		if (0 <= entry["antagonist"] and entry["antagonist"] < characters.size()):
			antagonist = characters[entry["antagonist"]]
		else:
			antagonist = characters.front()
		for each in entry["options"]:
			var graph_offset = Vector2(0, 0)
#			if (each.has("graph_offset_x") && each.has("graph_offset_y")):
#				graph_offset = Vector2(each["graph_offset_x"], each["graph_offset_y"])
			var new_option = Option.new(new_encounter, unique_id("option", 32), each["text"], graph_offset)
			new_option.reactions = parse_reactions_data_v0_0_07_through_v0_0_15(each["reactions"], incomplete_reactions, new_option, antagonist)
			if (typeof(each) == TYPE_DICTIONARY && each.has("visibility_prerequisites") && each.has("performability_prerequisites")):
				if (!each["visibility_prerequisites"].is_empty()):
					new_option.visibility_script.set_contents(BooleanComparator.new("And"))
					for prerequisite in each["visibility_prerequisites"]:
						new_option.visibility_script.contents.operands.append(prerequisite)
				if (!each["performability_prerequisites"].is_empty()):
					new_option.performability_script.set_contents(BooleanComparator.new("And"))
					for prerequisite in each["performability_prerequisites"]:
						new_option.performability_script.contents.operands.append(prerequisite)
			new_encounter.options.append(new_option)
			option_directory[new_option.id] = new_option
		#Add encounter to database:
		add_encounter(new_encounter)
	for entry in incomplete_reactions:
		if (2 == entry.size()):
			if (encounter_directory.has(entry[1])):
				entry[0].consequence = encounter_directory[entry[1]]
	for entry in incomplete_encounters:
		if (entry.acceptability_script.contents is BooleanComparator):
			var data = entry.acceptability_script.contents.operands.duplicate(true)
			entry.acceptability_script.contents.operands.clear()
			for prereq in data:
				if (prereq is SWScriptElement):
					entry.acceptability_script.contents.add_operand(prereq)
				elif (typeof(prereq) == TYPE_DICTIONARY):
					if (encounter_directory.has(prereq["encounter"])):
						entry.acceptability_script.contents.add_operand(parse_prerequisite_data_v0_0_07_through_v0_0_15(prereq))
	for each in encounters:
		for option in each.options:
			if (option.visibility_script.contents is BooleanComparator):
				var data = option.visibility_script.contents.operands.duplicate(true)
				option.visibility_script.contents.operands.clear()
				for prereq in data:
					if (typeof(prereq) == TYPE_DICTIONARY):
						if (encounter_directory.has(prereq["encounter"])):
							option.visibility_script.contents.add_operand(parse_prerequisite_data_v0_0_07_through_v0_0_15(prereq))
			if (option.performability_script.contents is BooleanComparator):
				var data = option.performability_script.contents.operands.duplicate(true)
				option.performability_script.contents.operands.clear()
				for prereq in data:
					if (typeof(prereq) == TYPE_DICTIONARY):
						if (encounter_directory.has(prereq["encounter"])):
							option.performability_script.contents.add_operand(parse_prerequisite_data_v0_0_07_through_v0_0_15(prereq))
	if (data_to_load.has("unique_id_seed")):
		unique_id_seeds["encounter"] = data_to_load.unique_id_seed
	if (data_to_load.has("char_unique_id_seed")):
		unique_id_seeds["character"] = data_to_load.char_unique_id_seed
	if (data_to_load.has("storyworld_title")):
		storyworld_title = data_to_load.storyworld_title
	if (data_to_load.has("storyworld_author")):
		storyworld_author = data_to_load.storyworld_author
	if (data_to_load.has("debug_mode")):
		storyworld_debug_mode_on = data_to_load.debug_mode
	if (data_to_load.has("display_mode")):
		storyworld_display_mode = data_to_load.display_mode
	if (data_to_load.has("sweepweave_version")):
		sweepweave_version_number = data_to_load.sweepweave_version
	if (data_to_load.has("creation_time")):
		creation_time = data_to_load.creation_time
	if (data_to_load.has("modified_time")):
		modified_time = data_to_load.modified_time
	ifid = IFIDGenerator.IFID_from_creation_time(creation_time)
	option_directory.clear()
	reaction_directory.clear()
	print("Project Loaded: " + storyworld_title + " by " + storyworld_author + ". (Storyworld SWV# " + sweepweave_version_number + ")")

#Functions for loading project files made in SweepWeave versions 0.0.21 through 0.0.29:

func parse_reactions_data_v0_0_21_through_v0_0_29(reactions_data, option):
	var result = []
	for reaction_data in reactions_data:
		var graph_offset = Vector2(0, 0)
		#Currently options and reactions are not visible in the graphview. This may be changed later on.
		var reaction = Reaction.new(option, unique_id("reaction", 32), reaction_data["text"], reaction_data["desirability_script"], graph_offset)
		reaction.consequence = reaction_data["consequence_id"]
		if (reaction_data.has("after_effects")):
			for effect_data in reaction_data["after_effects"]:
				if (effect_data.has_all(["Set", "to"]) and effect_data["Set"].has_all(["pointer_type", "character", "coefficient", "keyring"]) and "Bounded Number Pointer" == effect_data["Set"]["pointer_type"] and TYPE_STRING == typeof(effect_data["Set"]["character"]) and effect_data["to"].has("script_element_type")):
					reaction.after_effects.append(effect_data)
		result.append(reaction)
		reaction_directory[reaction.id] = reaction
	return result

func load_from_json_v0_0_21_through_v0_0_29(data_to_load):
	#Load characters.
	for entry in data_to_load.characters:
		if (entry.has_all(["name", "pronoun", "bnumber_properties", "id", "creation_index", "creation_time", "modified_time"])):
			var newbie = Actor.new(self, entry["name"], entry["pronoun"], entry["bnumber_properties"])
			newbie.id = entry["id"]
			newbie.creation_index = entry["creation_index"]
			newbie.creation_time = entry["creation_time"]
			newbie.modified_time = entry["modified_time"]
			add_character(newbie)
	#Begin loading encounters.
	#This must proceed in stages, so that encounters which have other encounters associated with them as prerequisites or consequences can be loaded in correctly.
	for entry in data_to_load.encounters:
		#Create encounter:
		var new_encounter = Encounter.new(self, entry["id"], entry["title"], entry["main_text"], entry["creation_index"], entry["creation_time"], entry["modified_time"], Vector2(entry["graph_position_x"], entry["graph_position_y"]))
		new_encounter.earliest_turn = entry["earliest_turn"]
		new_encounter.latest_turn = entry["latest_turn"]
		#Temporarily set each script to the dictionary version of it. Each dictionary can be parsed and used to create a ScriptManager object later on, after all encounters, options, reactions and spools have been created and references to these objects can be created.
		new_encounter.acceptability_script = entry["acceptability_script"]
		new_encounter.desirability_script = entry["desirability_script"]
		#Parse options:
		for option_data in entry["options"]:
			if (option_data.has_all(["text", "reactions", "visibility_script", "performability_script"])):
				var graph_offset = Vector2(0, 0)
				#Currently options and reactions are not visible in the graphview. This may be changed later on.
				#if (option_data.has("graph_offset_x") && option_data.has("graph_offset_y")):
				#	graph_offset = Vector2(option_data["graph_offset_x"], option_data["graph_offset_y"])
				var new_option = Option.new(new_encounter, unique_id("option", 32), option_data["text"], graph_offset)
				new_option.reactions = parse_reactions_data_v0_0_21_through_v0_0_29(option_data["reactions"], new_option)
				new_option.visibility_script = option_data["visibility_script"]
				new_option.performability_script = option_data["performability_script"]
				new_encounter.options.append(new_option)
				option_directory[new_option.id] = new_option
		#Add encounter to database:
		add_encounter(new_encounter)
	#Parse scripts:
	for encounter in encounters:
		var new_script = ScriptManager.new(true)
		new_script.load_from_json_v0_0_21_through_v0_0_29(self, encounter.acceptability_script, sw_script_data_types.BOOLEAN)
		encounter.acceptability_script = new_script
		new_script = ScriptManager.new(0)
		new_script.load_from_json_v0_0_21_through_v0_0_29(self, encounter.desirability_script, sw_script_data_types.BNUMBER)
		encounter.desirability_script = new_script
		for option in encounter.options:
			new_script = ScriptManager.new(true)
			new_script.load_from_json_v0_0_21_through_v0_0_29(self, option.visibility_script, sw_script_data_types.BOOLEAN)
			option.visibility_script = new_script
			new_script = ScriptManager.new(true)
			new_script.load_from_json_v0_0_21_through_v0_0_29(self, option.performability_script, sw_script_data_types.BOOLEAN)
			option.performability_script = new_script
			for reaction in option.reactions:
				new_script = ScriptManager.new(0)
				new_script.load_from_json_v0_0_21_through_v0_0_29(self, reaction.desirability_script, sw_script_data_types.BNUMBER)
				reaction.desirability_script = new_script
				var parsed_effects = []
				for effect_data in reaction.after_effects:
					var new_effect = BNumberEffect.new()
					var effect_is_valid = new_effect.load_from_json_v0_0_21_through_v0_0_29(self, effect_data)
					if (effect_is_valid):
						parsed_effects.append(new_effect)
				reaction.after_effects.clear()
				for effect in parsed_effects:
					reaction.add_effect(effect)
				if ("wild" == reaction.consequence):
					reaction.consequence = null
				elif (encounter_directory.has(reaction.consequence)):
					reaction.consequence = encounter_directory[reaction.consequence]
				else:
					reaction.consequence = null
	#Load authored properties:
	for entry in data_to_load["authored_properties"]:
		if (entry.has_all(["property_type", "id", "property_name", "depth", "default_value", "attribution_target", "affected_characters", "creation_index", "creation_time", "modified_time"])):
			if ("bounded number" == entry["property_type"]):
				var new_property = BNumberBlueprint.new(self, entry["creation_index"], entry["id"], entry["property_name"], entry["depth"], entry["default_value"])
				match entry["attribution_target"]:
					"storyworld":
						new_property.attribution_target = new_property.possible_attribution_targets.STORYWORLD
					"some cast members":
						new_property.attribution_target = new_property.possible_attribution_targets.CAST_MEMBERS
						for character_id in entry["affected_characters"]:
							if (character_directory.has(character_id)):
								var character = character_directory[character_id]
								character.authored_properties.append(new_property)
								character.authored_property_directory[new_property.id] = new_property
								new_property.affected_characters.append(character)
					"all cast members":
						new_property.attribution_target = new_property.possible_attribution_targets.ENTIRE_CAST
						for character in characters:
							character.authored_properties.append(new_property)
							character.authored_property_directory[new_property.id] = new_property
				new_property.creation_time = entry["creation_time"]
				new_property.modified_time = entry["modified_time"]
				authored_properties.append(new_property)
				authored_property_directory[new_property.id] = new_property
	#Load spools:
	for entry in data_to_load["spools"]:
		if (entry.has_all(["id", "spool_name", "encounters", "creation_index", "creation_time", "modified_time"])):
			var spool_to_add = Spool.new()
			spool_to_add.id = entry["id"]
			spool_to_add.spool_name = entry["spool_name"]
			for encounter_id in entry["encounters"]:
				if (encounter_directory.has(encounter_id)):
					var encounter = encounter_directory[encounter_id]
					spool_to_add.encounters.append(encounter)
					encounter.connected_spools.append(spool_to_add)
			spool_to_add.id = entry["id"]
			spool_to_add.creation_index = entry["creation_index"]
			spool_to_add.creation_time = entry["creation_time"]
			spool_to_add.modified_time = entry["modified_time"]
			add_spool(spool_to_add)
	#Add all other variables:
	if (data_to_load.has("unique_id_seeds")):
		unique_id_seeds = data_to_load.unique_id_seeds.duplicate()
		unique_id_seeds["option"] = 0
		unique_id_seeds["reaction"] = 0
	if (data_to_load.has("storyworld_title")):
		storyworld_title = data_to_load.storyworld_title
	if (data_to_load.has("storyworld_author")):
		storyworld_author = data_to_load.storyworld_author
	if (data_to_load.has("debug_mode")):
		storyworld_debug_mode_on = data_to_load.debug_mode
	if (data_to_load.has("display_mode")):
		storyworld_display_mode = data_to_load.display_mode
	if (data_to_load.has("sweepweave_version")):
		sweepweave_version_number = data_to_load.sweepweave_version
	if (data_to_load.has("creation_time")):
		creation_time = data_to_load.creation_time
	if (data_to_load.has("modified_time")):
		modified_time = data_to_load.modified_time
	if (data_to_load.has("IFID")):
		ifid = data_to_load.IFID
	else:
		ifid = IFIDGenerator.IFID_from_creation_time(creation_time)
	option_directory.clear()
	reaction_directory.clear()
	print("Project Loaded: " + storyworld_title + " by " + storyworld_author + ". (Storyworld SWV# " + sweepweave_version_number + ")")

#Functions for loading project files made in SweepWeave versions 0.0.34 through 0.0.35:

func parse_reactions_data_v0_0_34_through_v0_1_9(reactions_data, option):
	var result = []
	for reaction_data in reactions_data:
		var graph_offset = Vector2(0, 0)
		#Currently options and reactions are not visible in the graphview. This may be changed later on.
		var reaction = Reaction.new(option, reaction_data["id"], "", reaction_data["desirability_script"], graph_offset)
		reaction.text_script = reaction_data["text_script"]
		reaction.consequence = reaction_data["consequence_id"]
		if (reaction_data.has("after_effects")):
			for effect_data in reaction_data["after_effects"]:
				if (effect_data.has_all(["effect_type", "Set", "to"])):
					reaction.after_effects.append(effect_data)
		result.append(reaction)
		reaction_directory[reaction_data["id"]] = reaction
	return result

func load_from_json_v0_0_34_through_v0_1_2(data_to_load):
	#Load characters.
	for entry in data_to_load.characters:
		if (entry.has_all(["name", "pronoun", "bnumber_properties", "id", "creation_index", "creation_time", "modified_time"])):
			var newbie = Actor.new(self, entry["name"], entry["pronoun"], entry["bnumber_properties"])
			newbie.id = entry["id"]
			newbie.creation_index = entry["creation_index"]
			newbie.creation_time = entry["creation_time"]
			newbie.modified_time = entry["modified_time"]
			add_character(newbie)
	#Load spools:
	for entry in data_to_load["spools"]:
		if (entry.has_all(["id", "spool_name", "encounters", "creation_index", "creation_time", "modified_time"])):
			var spool_to_add = Spool.new()
			spool_to_add.id = entry["id"]
			spool_to_add.spool_name = entry["spool_name"]
			spool_to_add.starts_active = entry["starts_active"]
			spool_to_add.creation_index = entry["creation_index"]
			spool_to_add.creation_time = entry["creation_time"]
			spool_to_add.modified_time = entry["modified_time"]
			add_spool(spool_to_add)
	#Begin loading encounters.
	#This must proceed in stages, so that encounters which have other encounters associated with them as prerequisites or consequences can be loaded in correctly.
	for entry in data_to_load.encounters:
		#Create encounter:
		var new_encounter = Encounter.new(self, entry["id"], entry["title"], "", entry["creation_index"], entry["creation_time"], entry["modified_time"], Vector2(entry["graph_position_x"], entry["graph_position_y"]))
		new_encounter.earliest_turn = entry["earliest_turn"]
		new_encounter.latest_turn = entry["latest_turn"]
		#Temporarily set each script to the dictionary version of it. Each dictionary can be parsed and used to create a ScriptManager object later on, after all encounters, options, reactions and spools have been created and references to these objects can be created.
		new_encounter.text_script = entry["text_script"]
		new_encounter.acceptability_script = entry["acceptability_script"]
		new_encounter.desirability_script = entry["desirability_script"]
		#Parse options:
		for option_data in entry["options"]:
			if (option_data.has_all(["id", "text_script", "reactions", "visibility_script", "performability_script"])):
				var graph_offset = Vector2(0, 0)
				#Currently options and reactions are not visible in the graphview. This may be changed later on.
				#if (option_data.has("graph_offset_x") && option_data.has("graph_offset_y")):
				#	graph_offset = Vector2(option_data["graph_offset_x"], option_data["graph_offset_y"])
				var new_option = Option.new(new_encounter, option_data["id"], "", graph_offset)
				new_option.reactions = parse_reactions_data_v0_0_34_through_v0_1_9(option_data["reactions"], new_option)
				new_option.text_script = option_data["text_script"]
				new_option.visibility_script = option_data["visibility_script"]
				new_option.performability_script = option_data["performability_script"]
				new_encounter.options.append(new_option)
				option_directory[option_data["id"]] = new_option
		#Connect spools:
		for spool_id in entry["connected_spools"]:
			if (spool_directory.has(spool_id)):
				var spool = spool_directory[spool_id]
				spool.encounters.append(new_encounter)
				new_encounter.connected_spools.append(spool)
		#Add encounter to database:
		add_encounter(new_encounter)
	#Parse scripts:
	for encounter in encounters:
		var new_script = ScriptManager.new(null)
		new_script.load_from_json_v0_0_34_through_v0_1_9(self, encounter.text_script, sw_script_data_types.STRING)
		encounter.text_script = new_script
		new_script = ScriptManager.new(null)
		new_script.load_from_json_v0_0_34_through_v0_1_9(self, encounter.acceptability_script, sw_script_data_types.BOOLEAN)
		encounter.acceptability_script = new_script
		new_script = ScriptManager.new(null)
		new_script.load_from_json_v0_0_34_through_v0_1_9(self, encounter.desirability_script, sw_script_data_types.BNUMBER)
		encounter.desirability_script = new_script
		for option in encounter.options:
			new_script = ScriptManager.new(null)
			new_script.load_from_json_v0_0_34_through_v0_1_9(self, option.text_script, sw_script_data_types.STRING)
			option.text_script = new_script
			new_script = ScriptManager.new(null)
			new_script.load_from_json_v0_0_34_through_v0_1_9(self, option.visibility_script, sw_script_data_types.BOOLEAN)
			option.visibility_script = new_script
			new_script = ScriptManager.new(null)
			new_script.load_from_json_v0_0_34_through_v0_1_9(self, option.performability_script, sw_script_data_types.BOOLEAN)
			option.performability_script = new_script
			for reaction in option.reactions:
				new_script = ScriptManager.new(null)
				new_script.load_from_json_v0_0_34_through_v0_1_9(self, reaction.text_script, sw_script_data_types.STRING)
				reaction.text_script = new_script
				new_script = ScriptManager.new(null)
				new_script.load_from_json_v0_0_34_through_v0_1_9(self, reaction.desirability_script, sw_script_data_types.BNUMBER)
				reaction.desirability_script = new_script
				var parsed_effects = []
				for effect_data in reaction.after_effects:
					if ("Bounded Number Effect" == effect_data["effect_type"] and effect_data["Set"].has_all(["pointer_type", "character", "coefficient", "keyring"]) and "Bounded Number Pointer" == effect_data["Set"]["pointer_type"] and TYPE_STRING == typeof(effect_data["Set"]["character"]) and effect_data["to"].has("script_element_type")):
						var new_effect = BNumberEffect.new()
						var effect_is_valid = new_effect.load_from_json_v0_0_34_through_v0_1_9(self, effect_data)
						if (effect_is_valid):
							parsed_effects.append(new_effect)
					elif ("Spool Effect" == effect_data["effect_type"] and TYPE_STRING == typeof(effect_data["Set"])):
						var new_effect = SpoolEffect.new()
						var effect_is_valid = new_effect.load_from_json_v0_0_34_through_v0_1_9(self, effect_data)
						if (effect_is_valid):
							parsed_effects.append(new_effect)
				reaction.after_effects.clear()
				for effect in parsed_effects:
					reaction.add_effect(effect)
				if ("wild" == reaction.consequence):
					reaction.consequence = null
				elif (encounter_directory.has(reaction.consequence)):
					reaction.consequence = encounter_directory[reaction.consequence]
				else:
					reaction.consequence = null
	#Load authored properties:
	for entry in data_to_load["authored_properties"]:
		if (entry.has_all(["property_type", "id", "property_name", "depth", "default_value", "attribution_target", "affected_characters", "creation_index", "creation_time", "modified_time"])):
			if ("bounded number" == entry["property_type"]):
				var new_property = BNumberBlueprint.new(self, entry["creation_index"], entry["id"], entry["property_name"], entry["depth"], entry["default_value"])
				match entry["attribution_target"]:
					"storyworld":
						new_property.attribution_target = new_property.possible_attribution_targets.STORYWORLD
					"some cast members":
						new_property.attribution_target = new_property.possible_attribution_targets.CAST_MEMBERS
						for character_id in entry["affected_characters"]:
							if (character_directory.has(character_id)):
								var character = character_directory[character_id]
								character.authored_properties.append(new_property)
								character.authored_property_directory[new_property.id] = new_property
								new_property.affected_characters.append(character)
					"all cast members":
						new_property.attribution_target = new_property.possible_attribution_targets.ENTIRE_CAST
						for character in characters:
							character.authored_properties.append(new_property)
							character.authored_property_directory[new_property.id] = new_property
				new_property.creation_time = entry["creation_time"]
				new_property.modified_time = entry["modified_time"]
				authored_properties.append(new_property)
				authored_property_directory[new_property.id] = new_property
	#Add all other variables:
	if (data_to_load.has("unique_id_seeds")):
		unique_id_seeds = data_to_load.unique_id_seeds.duplicate()
	if (data_to_load.has("storyworld_title")):
		storyworld_title = data_to_load.storyworld_title
	if (data_to_load.has("storyworld_author")):
		storyworld_author = data_to_load.storyworld_author
	if (data_to_load.has("debug_mode")):
		storyworld_debug_mode_on = data_to_load.debug_mode
	if (data_to_load.has("display_mode")):
		storyworld_display_mode = data_to_load.display_mode
	if (data_to_load.has("sweepweave_version")):
		sweepweave_version_number = data_to_load.sweepweave_version
	if (data_to_load.has("creation_time")):
		creation_time = data_to_load.creation_time
	if (data_to_load.has("modified_time")):
		modified_time = data_to_load.modified_time
	if (data_to_load.has("IFID")):
		ifid = data_to_load.IFID
	else:
		ifid = IFIDGenerator.IFID_from_creation_time(creation_time)
	option_directory.clear()
	reaction_directory.clear()
	print("Project Loaded: " + storyworld_title + " by " + storyworld_author + ". (Storyworld SWV# " + sweepweave_version_number + ")")

func load_from_json_v0_1_3_through_v0_1_9(data_to_load):
	#Load characters.
	for entry in data_to_load.characters:
		if (entry.has_all(["name", "pronoun", "bnumber_properties", "id", "creation_index", "creation_time", "modified_time"])):
			var newbie = Actor.new(self, entry["name"], entry["pronoun"], entry["bnumber_properties"])
			newbie.id = entry["id"]
			newbie.creation_index = entry["creation_index"]
			newbie.creation_time = entry["creation_time"]
			newbie.modified_time = entry["modified_time"]
			add_character(newbie)
	#Load spools:
	for entry in data_to_load["spools"]:
		if (entry.has_all(["id", "spool_name", "encounters", "creation_index", "creation_time", "modified_time"])):
			var spool_to_add = Spool.new()
			spool_to_add.id = entry["id"]
			spool_to_add.spool_name = entry["spool_name"]
			spool_to_add.starts_active = entry["starts_active"]
			spool_to_add.creation_index = entry["creation_index"]
			spool_to_add.creation_time = entry["creation_time"]
			spool_to_add.modified_time = entry["modified_time"]
			add_spool(spool_to_add)
	#Begin loading encounters.
	#This must proceed in stages, so that encounters which have other encounters associated with them as prerequisites or consequences can be loaded in correctly.
	for entry in data_to_load.encounters:
		#Create encounter:
		var new_encounter = Encounter.new(self, entry["id"], entry["title"], "", entry["creation_index"], entry["creation_time"], entry["modified_time"], Vector2(entry["graph_position_x"], entry["graph_position_y"]))
		new_encounter.earliest_turn = entry["earliest_turn"]
		new_encounter.latest_turn = entry["latest_turn"]
		#Temporarily set each script to the dictionary version of it. Each dictionary can be parsed and used to create a ScriptManager object later on, after all encounters, options, reactions and spools have been created and references to these objects can be created.
		new_encounter.text_script = entry["text_script"]
		new_encounter.acceptability_script = entry["acceptability_script"]
		new_encounter.desirability_script = entry["desirability_script"]
		#Parse options:
		for option_data in entry["options"]:
			if (option_data.has_all(["id", "text_script", "reactions", "visibility_script", "performability_script"])):
				var graph_offset = Vector2(0, 0)
				#Currently options and reactions are not visible in the graphview. This may be changed later on.
				#if (option_data.has("graph_offset_x") && option_data.has("graph_offset_y")):
				#	graph_offset = Vector2(option_data["graph_offset_x"], option_data["graph_offset_y"])
				var new_option = Option.new(new_encounter, option_data["id"], "", graph_offset)
				new_option.reactions = parse_reactions_data_v0_0_34_through_v0_1_9(option_data["reactions"], new_option)
				new_option.text_script = option_data["text_script"]
				new_option.visibility_script = option_data["visibility_script"]
				new_option.performability_script = option_data["performability_script"]
				new_encounter.options.append(new_option)
				option_directory[option_data["id"]] = new_option
		#Connect spools:
		for spool_id in entry["connected_spools"]:
			if (spool_directory.has(spool_id)):
				var spool = spool_directory[spool_id]
				spool.encounters.append(new_encounter)
				new_encounter.connected_spools.append(spool)
		#Add encounter to database:
		add_encounter(new_encounter)
	#Parse scripts:
	for encounter in encounters:
		var new_script = ScriptManager.new(null)
		new_script.load_from_json_v0_0_34_through_v0_1_9(self, encounter.text_script, sw_script_data_types.STRING)
		encounter.text_script = new_script
		new_script = ScriptManager.new(null)
		new_script.load_from_json_v0_0_34_through_v0_1_9(self, encounter.acceptability_script, sw_script_data_types.BOOLEAN)
		encounter.acceptability_script = new_script
		new_script = ScriptManager.new(null)
		new_script.load_from_json_v0_0_34_through_v0_1_9(self, encounter.desirability_script, sw_script_data_types.BNUMBER)
		encounter.desirability_script = new_script
		for option in encounter.options:
			new_script = ScriptManager.new(null)
			new_script.load_from_json_v0_0_34_through_v0_1_9(self, option.text_script, sw_script_data_types.STRING)
			option.text_script = new_script
			new_script = ScriptManager.new(null)
			new_script.load_from_json_v0_0_34_through_v0_1_9(self, option.visibility_script, sw_script_data_types.BOOLEAN)
			option.visibility_script = new_script
			new_script = ScriptManager.new(null)
			new_script.load_from_json_v0_0_34_through_v0_1_9(self, option.performability_script, sw_script_data_types.BOOLEAN)
			option.performability_script = new_script
			for reaction in option.reactions:
				new_script = ScriptManager.new(null)
				new_script.load_from_json_v0_0_34_through_v0_1_9(self, reaction.text_script, sw_script_data_types.STRING)
				reaction.text_script = new_script
				new_script = ScriptManager.new(null)
				new_script.load_from_json_v0_0_34_through_v0_1_9(self, reaction.desirability_script, sw_script_data_types.BNUMBER)
				reaction.desirability_script = new_script
				var parsed_effects = []
				for effect_data in reaction.after_effects:
					if ("Bounded Number Effect" == effect_data["effect_type"] and effect_data["Set"].has_all(["pointer_type", "character", "coefficient", "keyring"]) and "Bounded Number Pointer" == effect_data["Set"]["pointer_type"] and TYPE_STRING == typeof(effect_data["Set"]["character"]) and effect_data["to"].has("script_element_type")):
						var new_effect = BNumberEffect.new()
						var effect_is_valid = new_effect.load_from_json_v0_0_34_through_v0_1_9(self, effect_data)
						if (effect_is_valid):
							parsed_effects.append(new_effect)
					elif ("Spool Effect" == effect_data["effect_type"] and TYPE_STRING == typeof(effect_data["Set"])):
						var new_effect = SpoolEffect.new()
						var effect_is_valid = new_effect.load_from_json_v0_0_34_through_v0_1_9(self, effect_data)
						if (effect_is_valid):
							parsed_effects.append(new_effect)
				reaction.after_effects.clear()
				for effect in parsed_effects:
					reaction.add_effect(effect)
				if ("wild" == reaction.consequence):
					reaction.consequence = null
				elif (encounter_directory.has(reaction.consequence)):
					reaction.consequence = encounter_directory[reaction.consequence]
				else:
					reaction.consequence = null
	#Load authored properties:
	for entry in data_to_load["authored_properties"]:
		if (entry.has_all(["property_type", "id", "property_name", "depth", "default_value", "attribution_target", "affected_characters", "creation_index", "creation_time", "modified_time"])):
			if ("bounded number" == entry["property_type"]):
				var new_property = BNumberBlueprint.new(self, entry["creation_index"], entry["id"], entry["property_name"], entry["depth"], entry["default_value"])
				match entry["attribution_target"]:
					"storyworld":
						new_property.attribution_target = new_property.possible_attribution_targets.STORYWORLD
					"some cast members":
						new_property.attribution_target = new_property.possible_attribution_targets.CAST_MEMBERS
						for character_id in entry["affected_characters"]:
							if (character_directory.has(character_id)):
								var character = character_directory[character_id]
								character.authored_properties.append(new_property)
								character.authored_property_directory[new_property.id] = new_property
								new_property.affected_characters.append(character)
					"all cast members":
						new_property.attribution_target = new_property.possible_attribution_targets.ENTIRE_CAST
						for character in characters:
							character.authored_properties.append(new_property)
							character.authored_property_directory[new_property.id] = new_property
				new_property.creation_time = entry["creation_time"]
				new_property.modified_time = entry["modified_time"]
				authored_properties.append(new_property)
				authored_property_directory[new_property.id] = new_property
	#Add all other variables:
	if (data_to_load.has("unique_id_seeds")):
		unique_id_seeds = data_to_load.unique_id_seeds.duplicate()
	if (data_to_load.has("storyworld_title")):
		storyworld_title = data_to_load.storyworld_title
	if (data_to_load.has("storyworld_author")):
		storyworld_author = data_to_load.storyworld_author
	if (data_to_load.has("debug_mode")):
		storyworld_debug_mode_on = data_to_load.debug_mode
	if (data_to_load.has("display_mode")):
		storyworld_display_mode = data_to_load.display_mode
	if (data_to_load.has("sweepweave_version")):
		sweepweave_version_number = data_to_load.sweepweave_version
	if (data_to_load.has("creation_time")):
		creation_time = data_to_load.creation_time
	if (data_to_load.has("modified_time")):
		modified_time = data_to_load.modified_time
	if (data_to_load.has("IFID")):
		ifid = data_to_load.IFID
	else:
		ifid = IFIDGenerator.IFID_from_creation_time(creation_time)
	#about_text, meta_description, language, rating, css_theme and font_size were added in 0.1.3.
	if (data_to_load.has("about_text")):
		about_text.load_from_json_v0_0_34_through_v0_1_9(self, data_to_load.about_text, sw_script_data_types.STRING)
	if (data_to_load.has("meta_description")):
		meta_description = data_to_load.meta_description
	if (data_to_load.has("language")):
		language = data_to_load.language
	if (data_to_load.has("rating")):
		rating = data_to_load.rating
	if (data_to_load.has("css_theme")):
		css_theme = data_to_load.css_theme
	if (data_to_load.has("font_size")):
		font_size = data_to_load.font_size
	option_directory.clear()
	reaction_directory.clear()
	print("Project Loaded: " + storyworld_title + " by " + storyworld_author + ". (Storyworld SWV# " + sweepweave_version_number + ")")

#Function for determining the version of SweepWeave used to make a project file, and then loading the file via the appropriate functions:

func load_from_json(file_text):
	var json_parser = JSON.new()
	var parse_result = json_parser.parse(file_text)
	if not parse_result == OK:
		var error_message = "JSON Parse Error: " + json_parser.get_error_message() + " at line " + str(json_parser.get_error_line())
		print (error_message)
		return error_message
	var data_to_load = json_parser.get_data()
	if (data_to_load.has("sweepweave_version")):
		var version = data_to_load.sweepweave_version.split(".")
		if (3 == version.size()):
			if (0 == int(version[0]) and 0 == int(version[1]) and 7 <= int(version[2]) and 15 >= int(version[2])):
				clear()
				load_from_json_v0_0_07_through_v0_0_15(data_to_load)
				return "Passed."
			elif (0 == int(version[0]) and 0 == int(version[1]) and 21 <= int(version[2]) and 29 >= int(version[2])):
				clear()
				load_from_json_v0_0_21_through_v0_0_29(data_to_load)
				return "Passed."
			elif (0 == int(version[0]) and 0 == int(version[1]) and 34 <= int(version[2]) and 38 >= int(version[2])):
				clear()
				load_from_json_v0_0_34_through_v0_1_2(data_to_load)
				return "Passed."
			elif (0 == int(version[0]) and 1 == int(version[1]) and 0 <= int(version[2]) and 2 >= int(version[2])):
				clear()
				load_from_json_v0_0_34_through_v0_1_2(data_to_load)
				return "Passed."
			elif (0 == int(version[0]) and 1 == int(version[1]) and 3 <= int(version[2]) and 9 >= int(version[2])):
				clear()
				load_from_json_v0_1_3_through_v0_1_9(data_to_load)
				return "Passed."
			else:
				print ("Cannot load project file. The project appears to have been made using an unrecognized version of SweepWeave.")
				return "Cannot load project file. The project appears to have been made using an unrecognized version of SweepWeave."
		else:
			print ("Cannot load project file. Invalid SweepWeave version number.")
			return "Cannot load project file. Invalid SweepWeave version number."
	else:
		print ("Cannot load project file. Could not find SweepWeave version number.")
		return "Cannot load project file. Could not find SweepWeave version number."

func save_project(file_path, save_as = false):
	var file_data = {}
	# Save characters:
	characters.sort_custom(Callable(CharacterSorter, "sort_created"))
	file_data["characters"] = []
	for entry in characters:
		file_data["characters"].append(entry.compile(self, true))
	# Save authored properties:
	authored_properties.sort_custom(Callable(AuthoredPropertySorter, "sort_created"))
	file_data["authored_properties"] = []
	for entry in authored_properties:
		file_data["authored_properties"].append(entry.compile(self, true))
	# Save encounters:
	encounters.sort_custom(Callable(EncounterSorter, "sort_created"))
	file_data["encounters"] = []
	for entry in encounters:
		file_data["encounters"].append(entry.compile(self, true))
	# Save spools:
#	spools.sort_custom(SpoolSorter, "sort_created")
	file_data["spools"] = []
	for entry in spools:
		file_data["spools"].append(entry.compile(self, true))
	# Save storyworld metadata:
	file_data["unique_id_seeds"] = unique_id_seeds.duplicate()
	file_data["storyworld_title"] = storyworld_title
	file_data["storyworld_author"] = storyworld_author
	file_data["debug_mode"] = storyworld_debug_mode_on
	file_data["display_mode"] = storyworld_display_mode
	file_data["sweepweave_version"] = sweepweave_version_number
	file_data["creation_time"] = creation_time
	file_data["modified_time"] = modified_time
	file_data["IFID"] = ifid
	#about_text, meta_description, language, rating, css_theme and font_size were added in 0.1.3.
	if (about_text is ScriptManager):
		file_data["about_text"] = about_text.compile(self, true)
	file_data["meta_description"] = meta_description
	file_data["language"] = language
	file_data["rating"] = rating
	file_data["css_theme"] = css_theme
	file_data["font_size"] = font_size
	# Write contents to json file:
	var file_text = ""
	if (storyworld_debug_mode_on):
		file_text += JSON.stringify(file_data, "\t")
	else:
		file_text += JSON.stringify(file_data, "\t")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(file_text)
	file.close()

func compile_to_html(file_path):
	var file_data = {}
	# Compile characters:
	characters.sort_custom(Callable(CharacterSorter, "sort_created"))
	file_data["characters"] = []
	for entry in characters:
		file_data["characters"].append(entry.compile(self, false))
	# Compile encounters:
	encounters.sort_custom(Callable(EncounterSorter, "sort_created"))
	file_data["encounters"] = []
	for entry in encounters:
		file_data["encounters"].append(entry.compile(self, false))
	# Compile spools:
#	spools.sort_custom(SpoolSorter, "sort_created")
	file_data["spools"] = []
	for entry in spools:
		file_data["spools"].append(entry.compile(self, false))
	# Compile storyworld metadata:
	file_data["storyworld_title"] = storyworld_title
	file_data["debug_mode"] = storyworld_debug_mode_on
	file_data["display_mode"] = storyworld_display_mode
	file_data["IFID"] = ifid
	if (about_text is ScriptManager):
		file_data["about_text"] = about_text.compile(self, true)
	file_data["css_theme"] = css_theme
	file_data["font_size"] = font_size
	# Write data to html file:
	var file_text = "var storyworld_data = "
	if (storyworld_debug_mode_on):
		file_text += JSON.stringify(file_data, "\t")
	else:
		file_text += JSON.stringify(file_data)
	var compiler = Compiler.new(file_text, self)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(compiler.output)
	file.close()

func export_to_txt(file_path):
	var file_data = ""
	# Compile metadata:
	file_data += storyworld_title + "\n"
	file_data += "by " + storyworld_author + "\n"
	file_data += ifid + "\n"
	# Compile characters:
	characters.sort_custom(Callable(CharacterSorter, "sort_created"))
	file_data += "\n*** Cast: ***\n"
	for entry in characters:
		file_data += entry.char_name + "\n"
	# Compile encounters:
	encounters.sort_custom(Callable(EncounterSorter, "sort_created"))
	file_data += "\n*** Encounters: ***\n"
	for entry in encounters:
		file_data += entry.export_to_txt()
	# Save to file:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(file_data)
	file.close()
