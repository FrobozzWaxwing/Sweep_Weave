extends Object
class_name ScriptManager

enum sw_script_data_types {BOOLEAN, BNUMBER, STRING, VARIANT}
var contents = null
var input_type = sw_script_data_types.VARIANT
var output_type = sw_script_data_types.VARIANT
var sw_script_changed = false #Used by find and replace functions to track whether or not a change has been made to the script.

func _init(in_contents = null):
	set_contents(in_contents)

func set_contents(new_script):
	clear()
	if (new_script is SWScriptElement):
		contents = new_script
		contents.parent_operator = self
		contents.script_index = 0
		output_type = contents.output_type
	elif (TYPE_BOOL == typeof(new_script)):
		contents = BooleanConstant.new(new_script)
		contents.parent_operator = self
		contents.script_index = 0
		output_type = sw_script_data_types.BOOLEAN
	elif (TYPE_INT == typeof(new_script) or TYPE_FLOAT == typeof(new_script)):
		contents = BNumberConstant.new(new_script)
		contents.parent_operator = self
		contents.script_index = 0
		output_type = sw_script_data_types.BNUMBER
	elif (TYPE_STRING == typeof(new_script)):
		contents = StringConstant.new(new_script)
		contents.parent_operator = self
		contents.script_index = 0
		output_type = sw_script_data_types.STRING
	else:
		contents = null
		output_type = sw_script_data_types.VARIANT

func deeply_copy(original):
	var copy_of_element = null
	var copy_of_operands = []
	if (original is SWOperator):
		#Copy the operands here so that we can use the pop_front() function below to safely create new script elements.
		for each in original.operands:
			copy_of_operands.append(deeply_copy(each))
	if (null == original):
		copy_of_element = null
	elif (TYPE_BOOL == typeof(original)):
		copy_of_element = original
	elif (TYPE_INT == typeof(original) or TYPE_FLOAT == typeof(original)):
		copy_of_element = original
	elif (TYPE_ARRAY == typeof(original)):
		copy_of_element = []
		for each in original:
			copy_of_element.append(deeply_copy(each))
	elif (original is AbsoluteValueOperator):
		copy_of_element = AbsoluteValueOperator.new(copy_of_operands.pop_front())
	elif (original is ArithmeticComparator):
		copy_of_element = ArithmeticComparator.new(original.operator_subtype_to_string(), copy_of_operands.pop_front(), copy_of_operands.pop_front())
	elif (original is ArithmeticMeanOperator):
		copy_of_element = ArithmeticMeanOperator.new(copy_of_operands)
	elif (original is ArithmeticNegationOperator):
		copy_of_element = ArithmeticNegationOperator.new(copy_of_operands.pop_front())
	elif (original is BlendOperator):
		copy_of_element = BlendOperator.new(copy_of_operands.pop_front(), copy_of_operands.pop_front(), copy_of_operands.pop_front())
	elif (original is BNumberConstant):
		copy_of_element = BNumberConstant.new(original.get_value())
	elif (original is BNumberPointer):
		copy_of_element = BNumberPointer.new(original.character)
		copy_of_element.set_as_copy_of(original)
	elif (original is BooleanConstant):
		copy_of_element = BooleanConstant.new(original.get_value())
	elif (original is BooleanComparator):
		copy_of_element = BooleanComparator.new(original.operator_subtype_to_string(), copy_of_operands)
	elif (original is BSumOperator):
		copy_of_element = BSumOperator.new(copy_of_operands)
	elif (original is Desideratum):
		copy_of_element = Desideratum.new(copy_of_operands.pop_front(), copy_of_operands.pop_front())
	elif (original is EventPointer):
		copy_of_element = EventPointer.new(original.encounter, original.option, original.reaction)
	elif (original is NudgeOperator):
		copy_of_element = NudgeOperator.new(copy_of_operands.pop_front(), copy_of_operands.pop_front())
	elif (original is SpoolStatusPointer):
		copy_of_element = SpoolStatusPointer.new()
		copy_of_element.set_as_copy_of(original)
	elif (original is StringConcatenationOperator):
		copy_of_element = StringConcatenationOperator.new()
		for operand in copy_of_operands:
			copy_of_element.add_operand(operand)
	elif(original is StringConstant):
		copy_of_element = StringConstant.new(original.get_value())
	elif (original is SWEqualsOperator):
		copy_of_element = SWEqualsOperator.new(copy_of_operands)
		copy_of_element.input_type = original.input_type
	elif (original is SWIfOperator):
		copy_of_element = SWIfOperator.new()
		for operand in copy_of_operands:
			copy_of_element.add_operand(operand)
		copy_of_element.output_type = original.output_type
	elif (original is SWMaxOperator):
		copy_of_element = SWMaxOperator.new(copy_of_operands)
	elif (original is SWMinOperator):
		copy_of_element = SWMinOperator.new(copy_of_operands)
	elif (original is SWNotOperator):
		copy_of_element = SWNotOperator.new(copy_of_operands.pop_front())
	return copy_of_element

func set_as_copy_of(original):
	set_contents(deeply_copy(original.contents))

func remap(to_storyworld):
	var succeeded = true
	if (null == contents):
		return true
	elif (contents is SWScriptElement):
		succeeded = contents.remap(to_storyworld)
	if (!succeeded):
		print ("Error when remapping script to new storyworld.")
	return succeeded

func replace_element(old_element, new_element):
	if (old_element is SWScriptElement and new_element is SWScriptElement):
		var parent = old_element.parent_operator
		var index = old_element.script_index
		if (parent is SWOperator):
			parent.operands[index] = new_element
			new_element.parent_operator = parent
			new_element.script_index = index
		elif (self == parent):
			set_contents(new_element)
		old_element.clear()
		old_element.call_deferred("free")

func recursive_replace_character_with_character(onion, search_term, replacement):
	if (onion is BNumberPointer):
		onion.replace_character_with_character(search_term, replacement)
	elif (onion is SWOperator):
		for operand in onion.operands:
			recursive_replace_character_with_character(operand, search_term, replacement)

func replace_character_with_character(search_term, replacement):
	if (search_term is Actor and replacement is Actor):
		recursive_replace_character_with_character(contents, search_term, replacement)

func recursive_replace_property_with_pointer(onion, search_term, replacement):
	if (onion is BNumberPointer):
		if (!onion.keyring.is_empty() and onion.keyring.front() == search_term.id):
			onion.set_as_copy_of(replacement)
	elif (onion is SWOperator):
		for operand in onion.operands:
			recursive_replace_property_with_pointer(operand, search_term, replacement)

func replace_property_with_pointer(search_term, replacement):
	if (search_term is BNumberBlueprint and replacement is BNumberPointer):
		recursive_replace_property_with_pointer(contents, search_term, replacement)

func recursive_replace_character_and_property_with_pointer(onion, search_character, search_property, replacement):
	if (onion is BNumberPointer):
		if (!onion.keyring.is_empty() and onion.character == search_character and onion.keyring.front() == search_property.id):
			onion.set_as_copy_of(replacement)
	elif (onion is SWOperator):
		for operand in onion.operands:
			recursive_replace_character_and_property_with_pointer(operand, search_character, search_property, replacement)

func replace_character_and_property_with_pointer(search_character, search_property, replacement):
	if (search_character is Actor and search_property is BNumberBlueprint and replacement is BNumberPointer):
		recursive_replace_character_and_property_with_pointer(contents, search_character, search_property, replacement)

func recursive_quicken_bnumberpointers(rehearsal, onion):
	if (onion is BNumberPointer):
		var constant = true
		for index in range(rehearsal.cast_traits_legend.size()):
			var pointer = rehearsal.cast_traits_legend[index]
			if (onion.is_parallel_to(pointer)):
				replace_element(onion, QuickBNPointer.new(rehearsal, index))
				sw_script_changed = true
				constant = false
				break
		if (constant):
			for pointer in rehearsal.cast_trait_constants:
				if (onion.is_parallel_to(pointer)):
					replace_element(onion, BNumberConstant.new(onion.get_value()))
					sw_script_changed = true
					break
	elif (onion is SWOperator):
		for operand in onion.operands:
			recursive_quicken_bnumberpointers(rehearsal, operand)

func quicken_bnumberpointers(rehearsal):
	sw_script_changed = false
	recursive_quicken_bnumberpointers(rehearsal, contents)
	return sw_script_changed

func recursive_delete_character(character, onion):
	if (onion is BNumberPointer):
		if (onion.character == character):
			replace_element(onion, BNumberConstant.new(0))
			sw_script_changed = true
		else:
			for key in onion.keyring:
				if (key == character.id):
					replace_element(onion, BNumberConstant.new(0))
					sw_script_changed = true
					break
	elif (onion is SWOperator):
		for operand in onion.operands:
			recursive_delete_character(character, operand)

func delete_character(character):
	sw_script_changed = false
	recursive_delete_character(character, contents)
	return sw_script_changed

func recursive_delete_property(property, onion):
	if (onion is BNumberPointer):
		if (onion.keyring.front() == property.id):
			replace_element(onion, BNumberConstant.new(0))
			sw_script_changed = true
	elif (onion is SWOperator):
		for operand in onion.operands:
			recursive_delete_property(property, operand)

func delete_property(property):
	sw_script_changed = false
	recursive_delete_property(property, contents)
	return sw_script_changed

func recursive_delete_reaction(reaction, onion):
	if (onion is EventPointer):
		if (onion.reaction == reaction):
			onion.reaction = null
			sw_script_changed = true
	elif (onion is SWOperator):
		for operand in onion.operands:
			recursive_delete_reaction(reaction, operand)

func delete_reaction(reaction):
	sw_script_changed = false
	recursive_delete_reaction(reaction, contents)
	return sw_script_changed

func recursive_delete_option(option, onion):
	if (onion is EventPointer):
		if (onion.option == option):
			onion.option = null
			onion.reaction = null
			sw_script_changed = true
	elif (onion is SWOperator):
		for operand in onion.operands:
			recursive_delete_option(option, operand)

func delete_option(option):
	sw_script_changed = false
	recursive_delete_option(option, contents)
	return sw_script_changed

func recursive_delete_encounter(encounter, onion):
	if (onion is EventPointer):
		if (onion.encounter == encounter):
			replace_element(onion, BooleanConstant.new(true))
			sw_script_changed = true
	elif (onion is SWOperator):
		for operand in onion.operands:
			recursive_delete_encounter(encounter, operand)

func delete_encounter(encounter):
	sw_script_changed = false
	recursive_delete_encounter(encounter, contents)
	return sw_script_changed

func recursive_delete_spool(spool, onion):
	if (onion is SpoolStatusPointer):
		if (onion.spool == spool):
			replace_element(onion, BooleanConstant.new(true))
			sw_script_changed = true
	elif (onion is SWOperator):
		for operand in onion.operands:
			recursive_delete_spool(spool, operand)

func delete_spool(spool):
	sw_script_changed = false
	recursive_delete_spool(spool, contents)
	return sw_script_changed

func recursive_has_search_text(onion, searchterm):
	if (onion is StringConstant):
		var text = onion.get_value()
		if (TYPE_STRING == typeof(text) and searchterm in text):
			return true
	elif (onion is SWOperator):
		for operand in onion.operands:
			if (recursive_has_search_text(operand, searchterm)):
				return true
	return false

func has_search_text(searchterm):
	if (TYPE_STRING == typeof(searchterm) and sw_script_data_types.STRING == output_type):
		return recursive_has_search_text(contents, searchterm)
	return false

func recursive_find_occurrences_of_string(onion, searchterm, results):
	if (onion is StringConstant):
		var match_indices = onion.find_occurrences(searchterm)
		if (TYPE_ARRAY == match_indices and !match_indices.is_empty()):
			for match_index in match_indices:
				results["element"].append(onion)
				results["match_index"].append(match_index)
	elif (onion is SWOperator):
		for operand in onion.operands:
			recursive_find_occurrences_of_string(operand, searchterm, results)

func find_occurrences_of_string(searchterm):
	var results = {}
	results["element"] = []
	results["match_index"] = []
	if (TYPE_STRING == typeof(searchterm) and sw_script_data_types.STRING == output_type):
		return recursive_find_occurrences_of_string(contents, searchterm, results)
	return results

func count_eventpointers(element = contents):
	if (element is EventPointer):
		return 1
	elif (element is SWOperator):
		var number_of_pointers = 0
		for operand in element.operands:
			number_of_pointers += count_eventpointers(operand)
		return number_of_pointers
	else:
		return 0

func count_bnumberpointers(element = contents):
	if (element is BNumberPointer):
		return 1
	elif (element is SWOperator):
		var number_of_pointers = 0
		for operand in element.operands:
			number_of_pointers += count_bnumberpointers(operand)
		return number_of_pointers
	else:
		return 0

func recursive_wordcount(onion):
	if (onion is StringConstant):
		var text = onion.get_value()
		if (TYPE_STRING == typeof(text)):
			var regex = RegEx.new()
			regex.compile("\\S+") # Negated whitespace character class.
			return regex.search_all(text).size()
	elif (onion is SWOperator):
		var sum = 0
		for operand in onion.operands:
			sum += recursive_wordcount(onion)
		return sum
	return 0

func wordcount():
	if (sw_script_data_types.STRING == output_type):
		return recursive_wordcount(contents)
	return 0

func recursive_find_all_eventpointers(element, results):
	if (element is EventPointer):
		results.append(element)
	elif (element is SWOperator):
		for operand in element.operands:
			recursive_find_all_eventpointers(operand, results)

func find_all_eventpointers():
	var results = []
	recursive_find_all_eventpointers(contents, results)
	return results

func recursive_find_all_bnumberpointers(element, results):
	if (element is BNumberPointer):
		results.append(element)
	elif (element is SWOperator):
		for operand in element.operands:
			recursive_find_all_bnumberpointers(operand, results)

func find_all_bnumberpointers():
	var results = []
	recursive_find_all_bnumberpointers(contents, results)
	return results

func recursive_find_all_characters_involved(element, results):
	if (element is BNumberPointer and element.character is Actor):
		results[element.character.id] = element.character
	elif (element is SWOperator):
		for operand in element.operands:
			recursive_find_all_characters_involved(operand, results)

func find_all_characters_involved():
	#Use a dictionary for the results list so that we can avoid duplicate entries.
	#Key will be character id, value will be the character themselves.
	var results = {}
	recursive_find_all_characters_involved(contents, results)
	return results

func recursive_trace_referenced_events(element):
	if (element is EventPointer):
		if (null != element.encounter):
			element.encounter.linked_scripts.append(self)
		if (null != element.option):
			element.option.linked_scripts.append(self)
		if (null != element.reaction):
			element.reaction.linked_scripts.append(self)
	elif (element is SWOperator):
		for operand in element.operands:
			recursive_trace_referenced_events(operand)

func trace_referenced_events():
	#Finds events referenced by the present script and adds the present script to the linked_scripts property of each event.
	recursive_trace_referenced_events(contents)

func get_value():
	var result = null
	if (contents is SWScriptElement):
		result = contents.get_value()
	return result

func get_and_report_value():
	var result = null
	if (contents is SWScriptElement):
		result = contents.get_and_report_value()
	return result

func clear():
	if (contents is SWScriptElement):
		contents.clear()
		contents.call_deferred("free")
	contents = null
	output_type = sw_script_data_types.VARIANT

func compile(_parent_storyworld, _include_editor_only_variables = false):
	var result = null
	if (null == contents):
		result = null
	elif (TYPE_BOOL == typeof(contents) or TYPE_INT == typeof(contents) or TYPE_FLOAT == typeof(contents)):
		result = contents
	elif (contents is SWScriptElement):
		result = contents.compile(_parent_storyworld, _include_editor_only_variables)
	return result

func stringify_datatype(datatype):
	#This is used for script validation, not storyworld compilation, so unlike the similar functions in script elements and operators, the strings that this function outputs need not be javascript datatype names.
	if (sw_script_data_types.BOOLEAN == datatype):
		return "boolean"
	elif (sw_script_data_types.BNUMBER == datatype):
		return "bounded number"
	elif (sw_script_data_types.STRING == datatype):
		return "string"
	elif (sw_script_data_types.VARIANT == datatype):
		return "variant"
	else:
		return ""

func data_to_string():
	var result = "[invalid script]"
	if (null == contents):
		result = "null"
	elif (TYPE_BOOL == typeof(contents) or TYPE_INT == typeof(contents) or TYPE_FLOAT == typeof(contents)):
		result = str(contents)
	elif (contents is SWScriptElement):
		result = contents.data_to_string()
	return result

func proofread(element):
	if (element is SWOperator):
		if (element.operands.size() < element.minimum_number_of_operands):
			if (sw_script_data_types.BNUMBER == element.input_type):
				for _i in range(element.operands.size(), element.minimum_number_of_operands):
					element.add_operand(BNumberConstant.new(0))
			elif (sw_script_data_types.BOOLEAN == element.input_type):
				for _i in range(element.operands.size(), element.minimum_number_of_operands):
					element.add_operand(BooleanConstant.new(true))
			elif (sw_script_data_types.STRING == element.input_type):
				for _i in range(element.operands.size(), element.minimum_number_of_operands):
					element.add_operand(StringConstant.new(""))
	return element

func recursive_load_from_json_v0_0_21_through_v0_0_29(storyworld, data_to_load):
	var element = null
	if (TYPE_BOOL == typeof(data_to_load)):
		#Data should be either a boolean value, (true or false,) or a dictionary.
		element = BooleanConstant.new(data_to_load)
	elif (TYPE_DICTIONARY != typeof(data_to_load) or !data_to_load.has("script_element_type")):
		element = null
	elif ("Pointer" == data_to_load["script_element_type"] and data_to_load.has("pointer_type")):
		if ("Bounded Number Constant" == data_to_load["pointer_type"] and data_to_load.has("value")):
			element = BNumberConstant.new(data_to_load["value"])
		elif ("Bounded Number Pointer" == data_to_load["pointer_type"] and data_to_load.has_all(["character", "coefficient", "keyring"]) and storyworld.character_directory.has(data_to_load["character"])):
			var character = storyworld.character_directory[data_to_load["character"]]
			element = BNumberPointer.new(character, data_to_load["keyring"])
			element.coefficient = data_to_load["coefficient"]
		elif ("Event Pointer" == data_to_load["pointer_type"] and data_to_load.has_all(["encounter", "option", "reaction"])):
			element = EventPointer.new()
			if (TYPE_STRING == typeof(data_to_load["encounter"]) and storyworld.encounter_directory.has(data_to_load["encounter"])):
				element.encounter = storyworld.encounter_directory[data_to_load["encounter"]]
				if (TYPE_INT == typeof(data_to_load["option"]) or TYPE_FLOAT == typeof(data_to_load["option"])):
					var option_index = data_to_load["option"]
					var maximum = element.encounter.options.size()
					if (0 <= option_index and option_index < maximum):
						element.option = element.encounter.options[option_index]
						if (TYPE_INT == typeof(data_to_load["reaction"]) or TYPE_FLOAT == typeof(data_to_load["reaction"])):
							var reaction_index = data_to_load["reaction"]
							maximum = element.option.reactions.size()
							if (0 <= reaction_index and reaction_index < maximum):
								element.reaction = element.option.reactions[data_to_load["reaction"]]
						else:
							print ("Reaction index is not a number.")
				else:
					print ("Option index is not a number.")
			if (data_to_load.has("negated") and true == data_to_load["negated"]):
				element = SWNotOperator.new(element)
	elif ("Operator" == data_to_load["script_element_type"] and data_to_load.has_all(["operator_type", "operands"])):
		#Parse operands:
		var operands = []
		for operand in data_to_load["operands"]:
			var parsed_operand = recursive_load_from_json_v0_0_21_through_v0_0_29(storyworld, operand)
			if (parsed_operand is SWScriptElement):
				operands.append(parsed_operand)
		#Create operator:
		if ("Arithmetic Mean" == data_to_load["operator_type"]):
			element = ArithmeticMeanOperator.new(operands)
		elif ("Blend" == data_to_load["operator_type"] and 3 == operands.size()):
			element = BlendOperator.new(operands.pop_front(), operands.pop_front(), operands.pop_front())
		elif ("Boolean Comparator" == data_to_load["operator_type"] and data_to_load.has("operator_subtype")):
			if ("NOT" == data_to_load["operator_subtype"]):
				element = SWNotOperator.new(operands.pop_front())
			else:
				element = BooleanComparator.new(data_to_load["operator_subtype"], operands)
		elif ("Desideratum" == data_to_load["operator_type"] and 2 == operands.size()):
			element = Desideratum.new(operands.pop_front(), operands.pop_front())
		elif ("Nudge" == data_to_load["operator_type"] and 2 == operands.size()):
			element = NudgeOperator.new(operands.pop_front(), operands.pop_front())
	return proofread(element)

func load_from_json_v0_0_21_through_v0_0_29(storyworld, data_to_load, expected_output_datatype):
	var parsed_script = recursive_load_from_json_v0_0_21_through_v0_0_29(storyworld, data_to_load)
	if (null == parsed_script):
		if (sw_script_data_types.BNUMBER == expected_output_datatype):
#			print ("Warning, script has null or invalid contents. Setting script contents to bounded number constant to match expected output datatype.")
			set_contents(BNumberConstant.new(0))
		elif (sw_script_data_types.BOOLEAN == expected_output_datatype):
#			print ("Warning, script has null or invalid contents. Setting script contents to boolean constant to match expected output datatype.")
			set_contents(BooleanConstant.new(false))
		else:
			print ("Warning, script has null or invalid contents. Please try running storyworld validation lizard to find broken scripts.")
			set_contents(null)
	else:
		set_contents(parsed_script)

func recursive_load_from_json_v0_0_34_through_v0_1_9(storyworld, data_to_load):
	var element = null
	if (TYPE_BOOL == typeof(data_to_load)):
		#Data should be either a boolean value, (true or false,) or a dictionary.
		element = BooleanConstant.new(data_to_load)
	elif (TYPE_DICTIONARY != typeof(data_to_load) or !data_to_load.has("script_element_type")):
		element = null
	elif ("Pointer" == data_to_load["script_element_type"] and data_to_load.has("pointer_type")):
		if ("Bounded Number Constant" == data_to_load["pointer_type"] and data_to_load.has("value")):
			element = BNumberConstant.new(data_to_load["value"])
		elif ("Bounded Number Pointer" == data_to_load["pointer_type"] and data_to_load.has_all(["character", "coefficient", "keyring"]) and storyworld.character_directory.has(data_to_load["character"])):
			var character = storyworld.character_directory[data_to_load["character"]]
			element = BNumberPointer.new(character, data_to_load["keyring"])
			element.coefficient = data_to_load["coefficient"]
		elif ("Event Pointer" == data_to_load["pointer_type"] and data_to_load.has_all(["encounter", "option", "reaction"])):
			element = EventPointer.new()
			if (TYPE_STRING == typeof(data_to_load["encounter"]) and storyworld.encounter_directory.has(data_to_load["encounter"])):
				element.encounter = storyworld.encounter_directory[data_to_load["encounter"]]
				if (TYPE_STRING == typeof(data_to_load["option"]) and storyworld.option_directory.has(data_to_load["option"])):
					element.option = storyworld.option_directory[data_to_load["option"]]
					if (TYPE_STRING == typeof(data_to_load["reaction"]) and storyworld.reaction_directory.has(data_to_load["reaction"])):
						element.reaction = storyworld.reaction_directory[data_to_load["reaction"]]
			if (data_to_load.has("negated") and true == data_to_load["negated"]):
				element = SWNotOperator.new(element)
		elif ("Spool Status Pointer" == data_to_load["pointer_type"] and data_to_load.has_all(["spool", "negated"]) and storyworld.spool_directory.has(data_to_load["spool"])):
			element = SpoolStatusPointer.new()
			element.spool = storyworld.spool_directory[data_to_load["spool"]]
			element.negated = data_to_load["negated"]
		elif ("Spool Pointer" == data_to_load["pointer_type"] and data_to_load.has_all(["spool"]) and storyworld.spool_directory.has(data_to_load["spool"])):
			element = SpoolPointer.new()
			element.spool = storyworld.spool_directory[data_to_load["spool"]]
		elif ("String Constant" == data_to_load["pointer_type"] and data_to_load.has("value")):
			element = StringConstant.new(data_to_load["value"])
	elif ("Operator" == data_to_load["script_element_type"] and data_to_load.has_all(["operator_type", "operands"])):
		#Parse operands:
		var operands = []
		for operand in data_to_load["operands"]:
			var parsed_operand = recursive_load_from_json_v0_0_34_through_v0_1_9(storyworld, operand)
			if (parsed_operand is SWScriptElement):
				operands.append(parsed_operand)
		#Create operator:
		if ("Absolute Value" == data_to_load["operator_type"]):
			element = AbsoluteValueOperator.new(operands.pop_front())
		elif ("Arithmetic Comparator" == data_to_load["operator_type"] and data_to_load.has("operator_subtype")):
			element = ArithmeticComparator.new(data_to_load["operator_subtype"], operands.pop_front(), operands.pop_front())
		elif ("Arithmetic Mean" == data_to_load["operator_type"]):
			element = ArithmeticMeanOperator.new(operands)
		elif ("Arithmetic Negation" == data_to_load["operator_type"]):
			element = ArithmeticNegationOperator.new(operands.pop_front())
		elif ("Blend" == data_to_load["operator_type"] and 3 == operands.size()):
			element = BlendOperator.new(operands.pop_front(), operands.pop_front(), operands.pop_front())
		elif ("Boolean Comparator" == data_to_load["operator_type"] and data_to_load.has("operator_subtype")):
			element = BooleanComparator.new(data_to_load["operator_subtype"], operands)
		elif ("Concatenate" == data_to_load["operator_type"]):
			element = StringConcatenationOperator.new(operands)
		elif ("Desideratum" == data_to_load["operator_type"] and 2 == operands.size()):
			element = Desideratum.new(operands.pop_front(), operands.pop_front())
		elif ("Equals" == data_to_load["operator_type"]):
			element = SWEqualsOperator.new(operands)
			#SWEqualsOperator.input_type will be set according to first operand.
		elif ("If Then" == data_to_load["operator_type"]):
			element = SWIfOperator.new()
			for operand in operands:
				element.add_operand(operand)
			if (1 < operands.size()):
				var operand = operands[1]
				if (operand is SWScriptElement):
					if (sw_script_data_types.BNUMBER == operand.output_type):
						element.output_type = sw_script_data_types.BNUMBER
					elif (sw_script_data_types.BOOLEAN == operand.output_type):
						element.output_type = sw_script_data_types.BOOLEAN
					elif (sw_script_data_types.STRING == operand.output_type):
						element.output_type = sw_script_data_types.STRING
		elif ("Maximum of" == data_to_load["operator_type"]):
			element = SWMaxOperator.new(operands)
		elif ("Minimum of" == data_to_load["operator_type"]):
			element = SWMinOperator.new(operands)
		elif ("Not" == data_to_load["operator_type"]):
			element = SWNotOperator.new(operands.pop_front())
		elif ("Nudge" == data_to_load["operator_type"] and 2 == operands.size()):
			element = NudgeOperator.new(operands.pop_front(), operands.pop_front())
	return proofread(element)

func load_from_json_v0_0_34_through_v0_1_9(storyworld, data_to_load, expected_output_datatype):
	var parsed_script = recursive_load_from_json_v0_0_34_through_v0_1_9(storyworld, data_to_load)
	if (null == parsed_script):
		if (sw_script_data_types.BNUMBER == expected_output_datatype):
#			print ("Warning, script has null or invalid contents. Setting script contents to bounded number constant to match expected output datatype.")
			set_contents(BNumberConstant.new(0))
		elif (sw_script_data_types.BOOLEAN == expected_output_datatype):
#			print ("Warning, script has null or invalid contents. Setting script contents to boolean constant to match expected output datatype.")
			set_contents(BooleanConstant.new(false))
		elif (sw_script_data_types.STRING == expected_output_datatype):
#			print ("Warning, script has null or invalid contents. Setting script contents to string constant to match expected output datatype.")
			set_contents(StringConstant.new(""))
		else:
			print ("Warning, script has null or invalid contents. Please try running storyworld validation lizard to find broken scripts.")
			set_contents(null)
	else:
		set_contents(parsed_script)

func validate(_intended_script_output_datatype):
	if (null == contents):
		return "Script root is null."
	elif (!(contents is SWScriptElement)):
		return "Script root is not a SweepWeave script element."
	elif (!is_instance_valid(contents)):
		return "Script root has been deleted but not properly nullified or replaced."
	else:
		var validation_report = ""
		if (output_type != _intended_script_output_datatype and sw_script_data_types.VARIANT != _intended_script_output_datatype):
			validation_report += "Script has incorrect output type. The correct output type would be " + stringify_datatype(_intended_script_output_datatype)
			validation_report += ", but the script has an output type of " + stringify_datatype(output_type)
		if (null == contents.parent_operator):
			validation_report += "\n" + "The parent operator of the script root is null."
		elif (!is_instance_valid(contents.parent_operator)):
			validation_report += "\n" + "The parent operator of the script root is an invalid instance."
		elif (contents.parent_operator != self):
			validation_report += "\n" + "Script root has incorrect parent operator."
		if (contents.script_index != 0):
			validation_report += "\n" + "Script root has incorrect script index. The script index should be 0, but is " + str(contents.script_index) + "."
		var contents_report = contents.validate(_intended_script_output_datatype)
		if ("Passed." != contents_report):
			validation_report += "\n" + contents_report
		if ("" == validation_report):
			return "Passed."
		return validation_report

func is_parallel_to(sibling):
	if (contents is SWScriptElement and sibling.contents is SWScriptElement):
		if ((contents is SWOperator and sibling.contents is SWOperator and contents.get_operator_type() == sibling.contents.get_operator_type()) or (contents is SWPointer and sibling.contents is SWPointer and contents.get_pointer_type() == sibling.contents.get_pointer_type())):
			return contents.is_parallel_to(sibling.contents)
	return false
