extends Object
class_name ScriptManager

enum sw_script_data_types {BOOLEAN, BNUMBER, VARIANT}
var contents = null
var output_type = sw_script_data_types.VARIANT
var script_changed = false #Used by find and replace functions to track whether or not a change has been made to the script.

func _init(in_contents = null):
	set_contents(in_contents)

func set_contents(new_script):
	clear()
	if (new_script is SWScriptElement):
		contents = new_script
		contents.parent_operator = self
		output_type = contents.output_type
	elif (TYPE_ARRAY == typeof(new_script)):
		contents = []
		for operand in new_script:
			contents.append(operand)
			if (operand is SWScriptElement):
				operand.parent_operator = self
		output_type = sw_script_data_types.VARIANT
	elif (TYPE_BOOL == typeof(new_script)):
		contents = new_script
		output_type = sw_script_data_types.BOOLEAN
	elif (TYPE_INT == typeof(new_script) or TYPE_REAL == typeof(new_script)):
		contents = new_script
		output_type = sw_script_data_types.BNUMBER
	else:
		contents = new_script
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
	elif (TYPE_INT == typeof(original) or TYPE_REAL == typeof(original)):
		copy_of_element = original
	elif (TYPE_ARRAY == typeof(original)):
		copy_of_element = []
		for each in original:
			copy_of_element.append(deeply_copy(each))
	elif (original is ArithmeticAbsoluteValueOperator):
		copy_of_element = ArithmeticAbsoluteValueOperator.new(copy_of_operands.pop_front())
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
	elif (original is BooleanOperator):
		copy_of_element = BooleanOperator.new(original.operator_subtype_to_string(), copy_of_operands)
	elif (original is BSumOperator):
		copy_of_element = BSumOperator.new(copy_of_operands)
	elif (original is Desideratum):
		copy_of_element = Desideratum.new(copy_of_operands.pop_front(), copy_of_operands.pop_front())
	elif (original is EventPointer):
		copy_of_element = EventPointer.new(original.encounter, original.option, original.reaction)
		copy_of_element.negated = original.negated
	elif (original is NudgeOperator):
		copy_of_element = NudgeOperator.new(copy_of_operands.pop_front(), copy_of_operands.pop_front())
	elif (original is SpoolStatusPointer):
		copy_of_element = SpoolStatusPointer.new()
		copy_of_element.set_as_copy_of(original)
	return copy_of_element

func set_as_copy_of(original):
	set_contents(deeply_copy(original.contents))

func remap(to_storyworld):
	var succeeded = true
	if (null == contents):
		return
	elif (TYPE_ARRAY == typeof(contents)):
		for each in contents:
			if (each is SWScriptElement):
				succeeded = each.remap(to_storyworld) and succeeded
	elif (contents is SWScriptElement):
		succeeded = contents.remap(to_storyworld)
	if (!succeeded):
		print ("Error when remapping script to new storyworld.")

func compare_to_search_term(operand, search_term):
	if (null == search_term):
		return true
	elif (typeof(operand) == typeof(search_term) and operand == search_term):
		return true
	return false

func search_and_replace_onion(onion, search_term, replacement):
	#print ("Searching and replacing through script element.")
	if (null == onion):
		#print ("Script element was null.")
		return onion
	elif (onion is ArithmeticMeanOperator):
		#print ("Script element was Arithmetic Mean Operator.")
		var copy = []
		for each in onion.operands:
			var new_operand = search_and_replace_onion(each, search_term, replacement)
			if (null != new_operand):
				copy.append(new_operand)
		if (onion.operands != copy):
			script_changed = true
			if (0 == copy.size()):
				onion.operands = [0]
			else:
				onion.operands = copy.duplicate()
	elif (onion is BlendOperator):
		#print ("Script element was Blend Operator.")
		if (3 == onion.operands.size()):
			onion.operands[0] = search_and_replace_onion(onion.operands[0], search_term, replacement)
			onion.operands[1] = search_and_replace_onion(onion.operands[1], search_term, replacement)
			onion.operands[2] = search_and_replace_onion(onion.operands[2], search_term, replacement)
	elif (onion is BNumberConstant):
		#print ("Script element was Bounded Number Constant.")
		var flag = false
		if (search_term is BNumberConstant and onion.get_value() == search_term.get_value()):
			flag = true
		elif ((TYPE_INT == typeof(search_term) or TYPE_REAL == typeof(search_term)) and onion.get_value() == search_term):
			flag = true
		if (flag):
			if (replacement is BNumberConstant and onion.get_value() != replacement.get_value()):
				script_changed = true
				onion.set_value(replacement.get_value())
			elif ((TYPE_INT == typeof(replacement) or TYPE_REAL == typeof(replacement)) and onion.get_value() != replacement):
				script_changed = true
				onion.set_value(replacement)
	elif (onion is BNumberPointer and 0 < onion.keyring.size()):
		print ("Script element was Bounded Number Pointer.")
		if (search_term is BNumberPointer
			and compare_to_search_term(onion.character, search_term.character)
			and compare_to_search_term(onion.coefficient, search_term.coefficient)
			and compare_to_search_term(onion.keyring, search_term.keyring)):
			if (replacement is BNumberPointer):
				if (null != replacement.character):
					script_changed = true
					onion.character = replacement.character
				if (null != replacement.coefficient):
					script_changed = true
					onion.coefficient = replacement.coefficient
				if (null != replacement.keyring):
					script_changed = true
					onion.keyring = []
					for each in replacement.keyring:
						onion.keyring.append(each)
			elif (TYPE_INT == typeof(replacement) or TYPE_REAL == typeof(replacement) or TYPE_NIL == typeof(replacement)):
				script_changed = true
#				onion.call_deferred("free")
				onion = replacement
		elif (search_term is Actor):
			if (replacement is Actor):
				print ("Search term and replacement are both characters.")
				if (onion.character == search_term):
					script_changed = true
					onion.character = replacement
				for key in onion.keyring:
					if (key == search_term.id):
						script_changed = true
						key = replacement.id
			elif (replacement is BNumberPointer or TYPE_INT == typeof(replacement) or TYPE_REAL == typeof(replacement) or TYPE_NIL == typeof(replacement)):
				var flag = false
				if (onion.character == search_term):
					flag = true
				for key in onion.keyring:
					if (key == search_term.id):
						flag = true
						break
				if (flag):
					if (replacement is BNumberPointer):
						if (null != replacement.character):
							script_changed = true
							onion.character = replacement.character
						if (null != replacement.coefficient):
							script_changed = true
							onion.coefficient = replacement.coefficient
						if (null != replacement.keyring):
							script_changed = true
							onion.keyring = []
							for each in replacement.keyring:
								onion.keyring.append(each)
					else:
						script_changed = true
#						onion.call_deferred("free")
						onion = replacement
		elif (search_term is BNumberBlueprint):
			if (onion.keyring[0] == search_term.id):
				if (replacement is BNumberBlueprint and search_term.depth == replacement.depth):
					script_changed = true
					onion.keyring[0] = replacement.id
				if (replacement is BNumberPointer):
					if (null != replacement.character):
						script_changed = true
						onion.character = replacement.character
					if (null != replacement.coefficient):
						script_changed = true
						onion.coefficient = replacement.coefficient
					if (null != replacement.keyring):
						script_changed = true
						onion.keyring = []
						for each in replacement.keyring:
							onion.keyring.append(each)
				elif (TYPE_INT == typeof(replacement) or TYPE_REAL == typeof(replacement) or TYPE_NIL == typeof(replacement)):
					script_changed = true
#					onion.call_deferred("free")
					onion = replacement
		if (!onion.character.authored_property_directory.has(onion.keyring[0])):
			if (0 == onion.character.authored_properties.size()):
				script_changed = true
#				onion.call_deferred("free")
				onion = 0
			else:
				script_changed = true
				var blueprint = onion.character.authored_properties[0]
				onion.keyring.clear()
				onion.keyring.append(blueprint.id)
				for layer in range(blueprint.depth):
					onion.keyring.append(onion.character.id)
	elif (onion is BooleanConstant):
		#print ("Script element was Boolean Constant.")
		if (compare_to_search_term(onion.get_value(), search_term)):
			if (TYPE_BOOL == typeof(replacement) and onion.get_value() != replacement):
				script_changed = true
				onion.set_value(replacement)
			elif (replacement is BooleanConstant and onion.get_value() != replacement.get_value()):
				script_changed = true
				onion.set_value(replacement.get_value())
	elif (onion is BooleanOperator):
		#print ("Script element was Boolean Operator.")
		var copy = []
		for each in onion.operands:
			var new_operand = search_and_replace_onion(each, search_term, replacement)
			if (null != new_operand):
				copy.append(new_operand)
		if (onion.operands != copy):
			script_changed = true
			if (0 == copy.size()):
				onion.operands = [true]
			else:
				onion.operands = copy.duplicate()
	elif (onion is BSumOperator):
		#print ("Script element was Bounded Sum Operator.")
		var copy = []
		for each in onion.operands:
			var new_operand = search_and_replace_onion(each, search_term, replacement)
			if (null != new_operand):
				copy.append(new_operand)
		if (onion.operands != copy):
			script_changed = true
			if (0 == copy.size()):
				onion.operands = [0]
			else:
				onion.operands = copy.duplicate()
	elif (onion is Desideratum):
		#print ("Script element was Proximity To Operator.")
		if (2 == onion.operands.size()):
			onion.operands[0] = search_and_replace_onion(onion.operands[0], search_term, replacement)
			onion.operands[1] = search_and_replace_onion(onion.operands[1], search_term, replacement)
	elif (onion is EventPointer):
		#print ("Script element was Event Pointer.")
		var flag = false
		if (search_term is EventPointer
			and compare_to_search_term(onion.negated, search_term.negated)
			and compare_to_search_term(onion.encounter, search_term.encounter)
			and compare_to_search_term(onion.option, search_term.option)
			and compare_to_search_term(onion.reaction, search_term.reaction)):
			flag = true
		elif (compare_to_search_term(onion.encounter, search_term)):
			flag = true
		elif (compare_to_search_term(onion.option, search_term)):
			flag = true
		elif (compare_to_search_term(onion.reaction, search_term)):
			flag = true
		if (flag):
			if (replacement is EventPointer):
				if (null != replacement.negated):
					script_changed = true
					onion.negated = replacement.negated
				if (null != replacement.encounter):
					script_changed = true
					onion.encounter = replacement.encounter
				if (null != replacement.option):
					script_changed = true
					onion.option = replacement.option
				if (null != replacement.reaction):
					script_changed = true
					onion.reaction = replacement.reaction
			elif (TYPE_BOOL == typeof(replacement) or TYPE_NIL == typeof(replacement)):
				script_changed = true
#				onion.call_deferred("free")
				onion = replacement
	elif (onion is NudgeOperator):
		#print ("Script element was Nudge Operator.")
		if (2 == onion.operands.size()):
			onion.operands[0] = search_and_replace_onion(onion.operands[0], search_term, replacement)
			onion.operands[1] = search_and_replace_onion(onion.operands[1], search_term, replacement)
	if (null == onion):
		print ("Done searching script element. Returning null element.")
	else:
		print ("Done searching script element. Returning non-null element.")
	return onion

func search_and_replace(search_term, replacement):
	script_changed = false
	var editted_script = search_and_replace_onion(contents, search_term, replacement)
	if (script_changed):
		set_contents(editted_script)
	var result = script_changed
	script_changed = false
	return result

func recursive_replace_character_with_character(onion, search_term, replacement):
	if (search_term is Actor and replacement is Actor):
		if (onion is BNumberPointer):
			onion.replace_character_with_character(search_term, replacement)
		elif (onion is SWOperator):
			for operand in onion.operands:
				recursive_replace_character_with_character(operand, search_term, replacement)

func replace_character_with_character(search_term, replacement):
	if (search_term is Actor and replacement is Actor):
		recursive_replace_character_with_character(contents, search_term, replacement)

func recursive_replace_property_with_pointer(onion, search_term, replacement):
	if (search_term is BNumberBlueprint):
		if (replacement is BNumberPointer):
			if (onion is BNumberPointer):
				if (onion.keyring.empty()):
					print ("Found bnumber pointer with empty keyring.")
				else:
					var onion_property_id = onion.keyring[0]
					if (onion_property_id == search_term.id):
						print ("Replacing " + onion.data_to_string() + " with " + replacement.data_to_string() + ".")
						onion.set_as_copy_of(replacement)
			elif (onion is SWOperator):
				for operand in onion.operands:
					recursive_replace_property_with_pointer(operand, search_term, replacement)

func replace_property_with_pointer(search_term, replacement):
	if (search_term is BNumberBlueprint and replacement is BNumberPointer):
		recursive_replace_property_with_pointer(contents, search_term, replacement)

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
	if (element is BNumberPointer and null != element.character):
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

func get_value(leaf = null):
	var result = null
	if (null == contents):
		result = null
	elif (TYPE_BOOL == typeof(contents)):
		result = contents
	elif (TYPE_INT == typeof(contents) or TYPE_REAL == typeof(contents)):
		result = contents
	elif (TYPE_ARRAY == typeof(contents)):
		if (0 < contents.size() and contents[0] is SWScriptElement):
			result = contents[0].get_value(leaf)
	elif (contents is SWScriptElement):
		result = contents.get_value(leaf)
	return result

func clear():
	if (contents is SWScriptElement):
		contents.clear()
		contents.call_deferred("free")
	contents = null
	output_type = sw_script_data_types.VARIANT

func compile(parent_storyworld, include_editor_only_variables = false):
	var result = null
	if (null == contents):
		result = null
	elif (TYPE_BOOL == typeof(contents) or TYPE_INT == typeof(contents) or TYPE_REAL == typeof(contents)):
		result = contents
	elif (contents is SWScriptElement):
		result = contents.compile(parent_storyworld, include_editor_only_variables)
	return result

func stringify_datatype(datatype):
	#This is used for script validation, not storyworld compilation, so unlike the similar functions in script elements and operators, the strings that this function outputs need not be javascript datatype names.
	if (sw_script_data_types.BOOLEAN == datatype):
		return "boolean"
	elif (sw_script_data_types.BNUMBER == datatype):
		return "bounded number"
	elif (sw_script_data_types.VARIANT == datatype):
		return "variant"
	else:
		return ""

func data_to_string():
	var result = "[invalid script]"
	if (null == contents):
		result = "null"
	elif (TYPE_BOOL == typeof(contents) or TYPE_INT == typeof(contents) or TYPE_REAL == typeof(contents)):
		result = str(contents)
	elif (contents is SWScriptElement):
		result = contents.data_to_string()
	return result

func recursive_load_from_json_v0_0_21(storyworld, data_to_load):
	if (TYPE_BOOL == typeof(data_to_load)):
		#Data should be either a boolean value, (true or false,) or a dictionary.
		return BooleanConstant.new(data_to_load)
	if (TYPE_DICTIONARY != typeof(data_to_load) or !data_to_load.has("script_element_type")):
		return null
	if ("Pointer" == data_to_load["script_element_type"] and data_to_load.has("pointer_type")):
		if ("Bounded Number Constant" == data_to_load["pointer_type"] and data_to_load.has("value")):
			return BNumberConstant.new(data_to_load["value"])
		elif ("Bounded Number Pointer" == data_to_load["pointer_type"] and data_to_load.has_all(["character", "coefficient", "keyring"]) and storyworld.character_directory.has(data_to_load["character"])):
			var character = storyworld.character_directory[data_to_load["character"]]
			var script_element = BNumberPointer.new(character, data_to_load["keyring"])
			script_element.coefficient = data_to_load["coefficient"]
			return script_element
		elif ("Event Pointer" == data_to_load["pointer_type"] and data_to_load.has_all(["negated", "spool", "encounter", "option", "reaction"]) and TYPE_BOOL == typeof(data_to_load["negated"])):
			var script_element = EventPointer.new()
			script_element.negated = data_to_load["negated"]
			if (TYPE_STRING == typeof(data_to_load["spool"]) and storyworld.spool_directory.has(data_to_load["spool"])):
				script_element.spool = storyworld.spool_directory[data_to_load["spool"]]
			if (TYPE_STRING == typeof(data_to_load["encounter"]) and storyworld.encounter_directory.has(data_to_load["encounter"])):
				script_element.encounter = storyworld.encounter_directory[data_to_load["encounter"]]
				if (TYPE_INT == typeof(data_to_load["option"]) or TYPE_REAL == typeof(data_to_load["option"])):
					var option_index = data_to_load["option"]
					var maximum = script_element.encounter.options.size()
					if (0 <= option_index and option_index < maximum):
						script_element.option = script_element.encounter.options[option_index]
						if (TYPE_INT == typeof(data_to_load["reaction"]) or TYPE_REAL == typeof(data_to_load["reaction"])):
							var reaction_index = data_to_load["reaction"]
							maximum = script_element.option.reactions.size()
							if (0 <= reaction_index and reaction_index < maximum):
								script_element.reaction = script_element.option.reactions[data_to_load["reaction"]]
#							else:
#								print ("Reaction index (" + str(reaction_index) + ") is out of range (0 to " + str(maximum - 1) + ".)")
						else:
							print ("Reaction index is not a number.")
#					else:
#						print ("Option index (" + str(option_index) + ") is out of range (0 to " + str(maximum - 1) + ".)")
				else:
					print ("Option index is not a number.")
			return script_element
	elif ("Operator" == data_to_load["script_element_type"] and data_to_load.has_all(["operator_type", "operands"])):
		var operands = []
		for operand in data_to_load["operands"]:
			var parsed_operand = recursive_load_from_json_v0_0_21(storyworld, operand)
			if (null != parsed_operand and parsed_operand is SWScriptElement):
				operands.append(parsed_operand)
		if ("Arithmetic Mean" == data_to_load["operator_type"]):
			return ArithmeticMeanOperator.new(operands)
		elif ("Blend" == data_to_load["operator_type"] and 3 == operands.size()):
			return BlendOperator.new(operands.pop_front(), operands.pop_front(), operands.pop_front())
		elif ("Boolean Comparator" == data_to_load["operator_type"] and data_to_load.has("operator_subtype")):
			return BooleanOperator.new(data_to_load["operator_subtype"], operands)
		elif ("Bounded Sum" == data_to_load["operator_type"]):
			return BSumOperator.new(operands)
		elif ("Desideratum" == data_to_load["operator_type"] and 2 == operands.size()):
			return Desideratum.new(operands.pop_front(), operands.pop_front())
		elif ("Nudge" == data_to_load["operator_type"] and 2 == operands.size()):
			return NudgeOperator.new(operands.pop_front(), operands.pop_front())
	return null

func load_from_json_v0_0_21(storyworld, data_to_load, expected_output_datatype):
	var parsed_script = recursive_load_from_json_v0_0_21(storyworld, data_to_load)
	if (null == parsed_script):
		if (sw_script_data_types.BNUMBER == expected_output_datatype):
			print ("Warning, script has null or invalid contents. Setting script contents to bounded number constant to match expected output datatype.")
			set_contents(BNumberConstant.new(0))
		elif (sw_script_data_types.BOOLEAN == expected_output_datatype):
			print ("Warning, script has null or invalid contents. Setting script contents to boolean constant to match expected output datatype.")
			set_contents(BooleanConstant.new(false))
		else:
			print ("Warning, script has null or invalid contents. Please try running storyworld validation lizard to find broken scripts.")
			set_contents(null)
	else:
		set_contents(parsed_script)

func validate(intended_script_output_datatype):
	if (null == contents):
		return "Script contents are null."
	elif (!(contents is SWScriptElement)):
		return "Script contents are not a SweepWeave script element."
	elif (!is_instance_valid(contents)):
		return "Script contents have been deleted but not properly nullified or replaced."
	else:
		var validation_report = ""
		if (output_type != intended_script_output_datatype and sw_script_data_types.VARIANT != intended_script_output_datatype):
			validation_report += "Script has incorrect output type. The correct output type would be " + stringify_datatype(intended_script_output_datatype)
			validation_report += ", but the script has an output type of " + stringify_datatype(output_type)
		var contents_report = contents.validate(intended_script_output_datatype)
		if ("Passed." != contents_report):
			validation_report += "\n" + contents_report
		if ("" == validation_report):
			return "Passed."
		return validation_report
