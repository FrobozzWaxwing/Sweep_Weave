extends Control

var storyworld = null
var errors = []
var current_error_report = null
enum sw_script_data_types {BOOLEAN, BNUMBER, STRING, VARIANT}

signal request_load_event(encounter, option, reaction)

func _ready():
	pass

func list_error(error_report):
	errors.append(error_report)
	$ColorRect/HBC/VBC/ErrorList.add_item(error_report.error_summary)
	$ColorRect/HBC/VBC/ErrorList.set_item_metadata($ColorRect/HBC/VBC/ErrorList.get_item_count() - 1, error_report)

func refresh():
	current_error_report = null
	$ColorRect/HBC/VBC/Label2.visible = false
	$ColorRect/HBC/VBC/ErrorList.visible = false
	$ColorRect/HBC/VBC/ErrorList.clear()
	$ColorRect/HBC/VBC/StoryworldValidationOverview.text = ""
	$ColorRect/HBC/VBC2.visible = false
	$ColorRect/HBC/VBC2/OpenLinkedObjectButton.text = "Open linked object"
	$ColorRect/HBC/VBC2/OpenLinkedScriptButton.text = "Open linked script"
	$ColorRect/HBC/VBC2/ErrorReportDisplay.text = ""
	for error_report in errors:
		if (error_report is ErrorReport):
			error_report.call_deferred("free")
	errors.clear()

func _on_ValidateButton_pressed():
	var number_of_invalid_encounters = 0
	var number_of_invalid_encounter_text_scripts = 0
	var number_of_invalid_encounter_acceptability_scripts = 0
	var number_of_invalid_encounter_desirability_scripts = 0
	var number_of_invalid_options = 0
	var number_of_invalid_option_text_scripts = 0
	var number_of_invalid_option_visibility_scripts = 0
	var number_of_invalid_option_performability_scripts = 0
	var number_of_invalid_reactions = 0
	var number_of_invalid_reaction_text_scripts = 0
	var number_of_invalid_reaction_desirability_scripts = 0
	var number_of_invalid_reaction_effects = 0
	refresh()
	$ColorRect/HBC/VBC/ValidateButton.text = "Checking all scripts for errors..."
	$ColorRect/HBC/VBC/ValidateButton.disabled = true
	var perform_validation = true
	if (null == storyworld):
		$ColorRect/HBC/VBC/StoryworldValidationOverview.text = "Error: Cannot perform validation, storyworld set to null."
		perform_validation = false
	elif (!(storyworld is Storyworld)):
		$ColorRect/HBC/VBC/StoryworldValidationOverview.text = "Error: The storyworld itself is invalid, so it is not possible to check scripts for errors."
		perform_validation = false
	elif (storyworld.encounters.empty()):
		$ColorRect/HBC/VBC/StoryworldValidationOverview.text = "This storyworld has no encounters."
		perform_validation = false
	else:
		$ColorRect/HBC/VBC/StoryworldValidationOverview.text = ""
	if (perform_validation):
		for encounter in storyworld.encounters:
			if (!(encounter is Encounter)):
				number_of_invalid_encounters += 1
				continue
			if (null == encounter.text_script):
				var summary = "Encounter \"" + encounter.title + "\" text script is null."
				var new_error_report = ErrorReport.new(encounter, encounter.text_script, "text", summary, "Error found in " + summary)
				list_error(new_error_report)
				number_of_invalid_encounter_text_scripts += 1
			else:
				var encounter_text_script_validation_report = encounter.text_script.validate(sw_script_data_types.STRING)
				if ("Passed." != encounter_text_script_validation_report):
					var summary = "Encounter \"" + encounter.title + "\" text script."
					var new_error_report = ErrorReport.new(encounter, encounter.text_script, "text", summary, "Error found in " + summary + "\n\n" + encounter_text_script_validation_report)
					list_error(new_error_report)
					number_of_invalid_encounter_text_scripts += 1
			if (null == encounter.acceptability_script):
				var summary = "Encounter \"" + encounter.title + "\" acceptability script is null."
				var new_error_report = ErrorReport.new(encounter, encounter.acceptability_script, "acceptability", summary, "Error found in " + summary)
				list_error(new_error_report)
				number_of_invalid_encounter_acceptability_scripts += 1
			else:
				var encounter_acceptability_script_validation_report = encounter.acceptability_script.validate(sw_script_data_types.BOOLEAN)
				if ("Passed." != encounter_acceptability_script_validation_report):
					var summary = "Encounter \"" + encounter.title + "\" acceptability script."
					var new_error_report = ErrorReport.new(encounter, encounter.acceptability_script, "acceptability", summary, "Error found in " + summary + "\n\n" + encounter_acceptability_script_validation_report)
					list_error(new_error_report)
					number_of_invalid_encounter_acceptability_scripts += 1
			if (null == encounter.desirability_script):
				var summary = "Encounter \"" + encounter.title + "\" desirability script is null."
				var new_error_report = ErrorReport.new(encounter, encounter.desirability_script, "desirability", summary, "Error found in " + summary)
				list_error(new_error_report)
				number_of_invalid_encounter_desirability_scripts += 1
			else:
				var encounter_desirability_script_validation_report = encounter.desirability_script.validate(sw_script_data_types.BNUMBER)
				if ("Passed." != encounter_desirability_script_validation_report):
					var summary = "Encounter \"" + encounter.title + "\" desirability script."
					var new_error_report = ErrorReport.new(encounter, encounter.desirability_script, "desirability", summary, "Error found in " + summary + "\n\n" + encounter_desirability_script_validation_report)
					list_error(new_error_report)
					number_of_invalid_encounter_desirability_scripts += 1
			for option in encounter.options:
				if (!(option is Option)):
					number_of_invalid_options += 1
					continue
				if (null == option.text_script):
					var summary = "Option \"" + option.get_truncated_text(20) + "\" text script is null."
					var details = "Error found in Encounter \"" + encounter.title + "\" / option \"" + option.get_text() + "\" text script is null."
					var new_error_report = ErrorReport.new(option, option.text_script, "text", summary, details)
					list_error(new_error_report)
					number_of_invalid_option_text_scripts += 1
				else:
					var option_text_script_validation_report = option.text_script.validate(sw_script_data_types.STRING)
					if ("Passed." != option_text_script_validation_report):
						var summary = "Option \"" + option.get_truncated_text(20) + "\" text script."
						var new_error_report = ErrorReport.new(option, option.text_script, "text", summary, "Error found in " + summary + "\n\n" + option_text_script_validation_report)
						list_error(new_error_report)
						number_of_invalid_option_text_scripts += 1
				if (null == option.visibility_script):
					var summary = "Option \"" + option.get_truncated_text(20) + "\" visibility script is null."
					var details = "Error found in Encounter \"" + encounter.title + "\" / option \"" + option.get_text() + "\" visibility script is null."
					var new_error_report = ErrorReport.new(option, option.visibility_script, "visibility", summary, details)
					list_error(new_error_report)
					number_of_invalid_option_visibility_scripts += 1
				else:
					var option_visibility_script_validation_report = option.visibility_script.validate(sw_script_data_types.BOOLEAN)
					if ("Passed." != option_visibility_script_validation_report):
						var summary = "Option \"" + option.get_truncated_text(20) + "\" visibility script."
						var new_error_report = ErrorReport.new(option, option.visibility_script, "visibility", summary, "Error found in " + summary + "\n\n" + option_visibility_script_validation_report)
						list_error(new_error_report)
						number_of_invalid_option_visibility_scripts += 1
				if (null == option.performability_script):
					var summary = "Option \"" + option.get_truncated_text(20) + "\" performability script is null."
					var details = "Error found in Encounter \"" + encounter.title + "\" / option \"" + option.get_text() + "\" performability script is null."
					var new_error_report = ErrorReport.new(option, option.performability_script, "performability", summary, details)
					list_error(new_error_report)
					number_of_invalid_option_performability_scripts += 1
				else:
					var option_visibility_script_validation_report = option.performability_script.validate(sw_script_data_types.BOOLEAN)
					if ("Passed." != option_visibility_script_validation_report):
						var summary = "Option \"" + option.get_truncated_text(20) + "\" performability script."
						var new_error_report = ErrorReport.new(option, option.performability_script, "performability", summary, "Error found in " + summary + "\n\n" + option_visibility_script_validation_report)
						list_error(new_error_report)
						number_of_invalid_option_performability_scripts += 1
				for reaction in option.reactions:
					if (!(reaction is Reaction)):
						number_of_invalid_reactions += 1
						continue
					if (null == reaction.text_script):
						var summary = "Reaction \"" + reaction.get_truncated_text(20) + "\" text script is null."
						var details = "Error found in Encounter \"" + encounter.title + "\" / option \"" + option.get_text() + "\" / reaction \"" + reaction.get_text() + "\" performability script is null."
						var new_error_report = ErrorReport.new(reaction, reaction.text_script, "text", summary, details)
						list_error(new_error_report)
						number_of_invalid_reaction_text_scripts += 1
					else:
						var reaction_text_script_validation_report = reaction.text_script.validate(sw_script_data_types.STRING)
						if ("Passed." != reaction_text_script_validation_report):
							var summary = "Reaction \"" + reaction.get_truncated_text(20) + "\" text script."
							var new_error_report = ErrorReport.new(reaction, reaction.text_script, "text", summary, "Error found in " + summary + "\n\n" + reaction_text_script_validation_report)
							list_error(new_error_report)
							number_of_invalid_reaction_text_scripts += 1
					if (null == reaction.desirability_script):
						var summary = "Reaction \"" + reaction.get_truncated_text(20) + "\" desirability script is null."
						var details = "Error found in Encounter \"" + encounter.title + "\" / option \"" + option.get_text() + "\" / reaction \"" + reaction.get_text() + "\" performability script is null."
						var new_error_report = ErrorReport.new(reaction, reaction.desirability_script, "desirability", summary, details)
						list_error(new_error_report)
						number_of_invalid_reaction_desirability_scripts += 1
					else:
						var reaction_desirability_script_validation_report = reaction.desirability_script.validate(sw_script_data_types.BNUMBER)
						if ("Passed." != reaction_desirability_script_validation_report):
							var summary = "Reaction \"" + reaction.get_truncated_text(20) + "\" desirability script."
							var new_error_report = ErrorReport.new(reaction, reaction.desirability_script, "desirability", summary, "Error found in " + summary + "\n\n" + reaction_desirability_script_validation_report)
							list_error(new_error_report)
							number_of_invalid_reaction_desirability_scripts += 1
					for effect in reaction.after_effects:
						if (!(effect is SWEffect)):
							number_of_invalid_reaction_effects += 1
							continue
						var reaction_effect_validation_report = effect.validate(sw_script_data_types.VARIANT)
						if ("Passed." != reaction_effect_validation_report):
							var summary = "Effect (" + effect.data_to_string() + ")"
							var new_error_report = ErrorReport.new(effect, effect.asssignment_script, "effect", summary, "Error found in " + summary + "\n\n" + reaction_effect_validation_report)
							list_error(new_error_report)
							number_of_invalid_reaction_effects += 1
	$ColorRect/HBC/VBC/ValidateButton.text = "Validate storyworld"
	$ColorRect/HBC/VBC/ValidateButton.disabled = false
	if (perform_validation and errors.empty()):
		$ColorRect/HBC/VBC/StoryworldValidationOverview.text = "All scripts checked; no errors found."
	elif(perform_validation):
		$ColorRect/HBC/VBC/Label2.visible = true
		$ColorRect/HBC/VBC/ErrorList.visible = true
		var overview = "Number of script errors: " + str(errors.size())
		if (0 != number_of_invalid_encounters):
			overview += "\n" + "Number of invalid encounters found: " + str(number_of_invalid_encounters)
		overview += "\n" + "Number of broken encounter text scripts: " + str(number_of_invalid_encounter_text_scripts)
		overview += "\n" + "Number of broken encounter acceptability scripts: " + str(number_of_invalid_encounter_acceptability_scripts)
		overview += "\n" + "Number of broken encounter desirability scripts: " + str(number_of_invalid_encounter_desirability_scripts)
		if (0 != number_of_invalid_options):
			overview += "\n" + "Number of invalid options found: " + str(number_of_invalid_options)
		overview += "\n" + "Number of broken option text scripts: " + str(number_of_invalid_option_text_scripts)
		overview += "\n" + "Number of broken option visibility scripts: " + str(number_of_invalid_option_visibility_scripts)
		overview += "\n" + "Number of broken option performability scripts: " + str(number_of_invalid_option_performability_scripts)
		if (0 != number_of_invalid_reactions):
			overview += "\n" + "Number of invalid reactions found: " + str(number_of_invalid_reactions)
		overview += "\n" + "Number of broken reaction text scripts: " + str(number_of_invalid_reaction_text_scripts)
		overview += "\n" + "Number of broken reaction desirability scripts: " + str(number_of_invalid_reaction_desirability_scripts)
		overview += "\n" + "Number of broken reaction effects: " + str(number_of_invalid_reaction_effects)
		$ColorRect/HBC/VBC/StoryworldValidationOverview.text = overview

func _on_ErrorList_item_selected(index):
	var error_report:ErrorReport = $ColorRect/HBC/VBC/ErrorList.get_item_metadata(index)
	if (null == error_report or !(error_report is ErrorReport) or !is_instance_valid(error_report)):
		current_error_report = null
		$ColorRect/HBC/VBC2/OpenLinkedObjectButton.visible = false
		$ColorRect/HBC/VBC2/OpenLinkedScriptButton.visible = false
		$ColorRect/HBC/VBC2/OpenLinkedObjectButton.text = "Open linked object"
		$ColorRect/HBC/VBC2/OpenLinkedScriptButton.text = "Open linked script"
		$ColorRect/HBC/VBC2.visible = true
		$ColorRect/HBC/VBC2/ErrorReportDisplay.visible = true
		$ColorRect/HBC/VBC2/ErrorReportDisplay.text = "Error in validation process. Invalid error report."
	elif ("" == error_report.error_details):
		current_error_report = null
		$ColorRect/HBC/VBC2/OpenLinkedObjectButton.visible = false
		$ColorRect/HBC/VBC2/OpenLinkedScriptButton.visible = false
		$ColorRect/HBC/VBC2/OpenLinkedObjectButton.text = "Open linked object"
		$ColorRect/HBC/VBC2/OpenLinkedScriptButton.text = "Open linked script"
		$ColorRect/HBC/VBC2.visible = true
		$ColorRect/HBC/VBC2/ErrorReportDisplay.visible = true
		$ColorRect/HBC/VBC2/ErrorReportDisplay.text = "No error report available."
	else:
		current_error_report = error_report
		$ColorRect/HBC/VBC2/OpenLinkedObjectButton.visible = false
		$ColorRect/HBC/VBC2/OpenLinkedObjectButton.text = ""
		$ColorRect/HBC/VBC2/OpenLinkedScriptButton.visible = false
		$ColorRect/HBC/VBC2/OpenLinkedScriptButton.text = ""
		if (null != error_report.reported_object):
			if (error_report.reported_object is Encounter):
				$ColorRect/HBC/VBC2/OpenLinkedObjectButton.visible = true
				var event_text = error_report.reported_object.title
				if ("" == event_text):
					event_text = "[Untitled Encounter]"
					$ColorRect/HBC/VBC2/OpenLinkedObjectButton.text = "Open encounter: " + event_text
				else:
					$ColorRect/HBC/VBC2/OpenLinkedObjectButton.text = "Open encounter: \"" + event_text + ".\""
				if (null != error_report.reported_script):
					if (error_report.reported_object.acceptability_script == error_report.reported_script):
						$ColorRect/HBC/VBC2/OpenLinkedScriptButton.visible = true
						$ColorRect/HBC/VBC2/OpenLinkedScriptButton.text = "Open acceptability script."
					elif (error_report.reported_object.desirability_script == error_report.reported_script):
						$ColorRect/HBC/VBC2/OpenLinkedScriptButton.visible = true
						$ColorRect/HBC/VBC2/OpenLinkedScriptButton.text = "Open desirability script."
			elif (error_report.reported_object is Option):
				$ColorRect/HBC/VBC2/OpenLinkedObjectButton.visible = true
				var event_text = error_report.reported_object.get_truncated_text(25)
				if ("" == event_text):
					event_text = "[Blank Option]"
					$ColorRect/HBC/VBC2/OpenLinkedObjectButton.text = "Open option: " + event_text
				else:
					$ColorRect/HBC/VBC2/OpenLinkedObjectButton.text = "Open option: \"" + event_text + ".\""
				if (null != error_report.reported_script):
					if (error_report.reported_object.visibility_script == error_report.reported_script):
						$ColorRect/HBC/VBC2/OpenLinkedScriptButton.visible = true
						$ColorRect/HBC/VBC2/OpenLinkedScriptButton.text = "Open visibility script."
					elif (error_report.reported_object.performability_script == error_report.reported_script):
						$ColorRect/HBC/VBC2/OpenLinkedScriptButton.visible = true
						$ColorRect/HBC/VBC2/OpenLinkedScriptButton.text = "Open performability script."
			elif (error_report.reported_object is Reaction):
				$ColorRect/HBC/VBC2/OpenLinkedObjectButton.visible = true
				var event_text = error_report.reported_object.get_truncated_text(25)
				if ("" == event_text):
					event_text = "[Blank Reaction]"
					$ColorRect/HBC/VBC2/OpenLinkedObjectButton.text = "Open reaction: " + event_text
				else:
					$ColorRect/HBC/VBC2/OpenLinkedObjectButton.text = "Open reaction: \"" + event_text + ".\""
				if (null != error_report.reported_script):
					if (error_report.reported_object.desirability_script == error_report.reported_script):
						$ColorRect/HBC/VBC2/OpenLinkedScriptButton.visible = true
						$ColorRect/HBC/VBC2/OpenLinkedScriptButton.text = "Open desirability script."
			elif (error_report.reported_object is SWEffect):
				if (error_report.reported_script is ScriptManager):
					if (error_report.reported_object.asssignment_script == error_report.reported_script):
						$ColorRect/HBC/VBC2/OpenLinkedScriptButton.visible = true
						$ColorRect/HBC/VBC2/OpenLinkedScriptButton.text = "Open effect \"to\" script."
			elif (error_report.reported_object is Actor):
				$ColorRect/HBC/VBC2/OpenLinkedObjectButton.visible = true
				$ColorRect/HBC/VBC2/OpenLinkedObjectButton.text = "Open character: \"" + error_report.reported_object.char_name + ".\""
		$ColorRect/HBC/VBC2.visible = true
		$ColorRect/HBC/VBC2/ErrorReportDisplay.visible = true
		$ColorRect/HBC/VBC2/ErrorReportDisplay.text = error_report.error_details

func _on_OpenLinkedObjectButton_pressed():
	if (null != current_error_report):
		if (current_error_report is ErrorReport):
			if (current_error_report.reported_object is Encounter):
				var encounter = current_error_report.reported_object
				emit_signal("request_load_event", encounter, null, null)
			elif (current_error_report.reported_object is Option):
				var option = current_error_report.reported_object
				var encounter = option.encounter
				emit_signal("request_load_event", encounter, option, null)
			elif (current_error_report.reported_object is Reaction):
				var reaction = current_error_report.reported_object
				var option = reaction.option
				var encounter = option.encounter
				emit_signal("request_load_event", encounter, option, reaction)

func _on_OpenLinkedScriptButton_pressed():
	var title = ""
	var open = false
	if (current_error_report is ErrorReport and null != current_error_report.reported_object and current_error_report.reported_script is ScriptManager):
		if (current_error_report.reported_object is Encounter):
			var event_text = current_error_report.reported_object.title
			if ("" == event_text):
				event_text = "[Untitled Encounter]"
				title = event_text
			else:
				title = "Encounter: \"" + event_text + "\""
			if (current_error_report.reported_object.acceptability_script == current_error_report.reported_script):
				open = true
				title += " acceptability script."
			elif (current_error_report.reported_object.desirability_script == current_error_report.reported_script):
				open = true
				title += " desirability script."
		elif (current_error_report.reported_object is Option):
			var event_text = current_error_report.reported_object.get_truncated_text(25)
			if ("" == event_text):
				event_text = "[Blank Option]"
				title = event_text
			else:
				title = "Option: \"" + event_text + ".\""
			if (current_error_report.reported_object.visibility_script == current_error_report.reported_script):
				open = true
				title += " visibility script."
			elif (current_error_report.reported_object.performability_script == current_error_report.reported_script):
				open = true
				title += " performability script."
		elif (current_error_report.reported_object is Reaction):
			var event_text = current_error_report.reported_object.get_truncated_text(25)
			if ("" == event_text):
				event_text = "[Blank Reaction]"
				title = event_text
			else:
				title  = "Reaction: \"" + event_text + ".\""
			if (current_error_report.reported_object.desirability_script == current_error_report.reported_script):
				open = true
				title += " desirability script."
		elif (current_error_report.reported_object is SWEffect):
			if (current_error_report.reported_object.asssignment_script == current_error_report.reported_script):
				open = true
				title += "Effect \"to\" script."
	if (open):
		$ScriptEditWindow.window_title = title
		$ScriptEditWindow/ScriptEditScreen.storyworld = storyworld
		$ScriptEditWindow/ScriptEditScreen.script_to_edit = current_error_report.reported_script
		$ScriptEditWindow/ScriptEditScreen.allow_root_character_editing = true
		$ScriptEditWindow/ScriptEditScreen.refresh_script_display()
		$ScriptEditWindow.popup_centered()
