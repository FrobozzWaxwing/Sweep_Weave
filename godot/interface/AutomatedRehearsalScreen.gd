extends Control

var rehearsal = null
var reference_storyworld = null
enum rehearsal_statuses {SET, RUNNING, PAUSED, COMPLETE}
var rehearsal_status = rehearsal_statuses.SET
var time_stopwatch_started = 0
var time_rehearsal_started = null
var elapsed_time = 0
var steps_per_frame = 1
var total_steps_taken = 0
var periodic_report = ""
var periodic_report_time = 0
var initial_steps_per_frame = 1 # The number of steps per frame when the rehearsal begins.
#Clarity is a light mode theme, while Lapis Lazuli is a dark mode theme.
var light_mode = true

func _ready():
	$Panel/VBC/ReportTabs.set_tab_title(0, "Event Index")
	$Panel/VBC/ReportTabs/EventIndex/EventTree.set_column_title(0, "Event")
	$Panel/VBC/ReportTabs/EventIndex/EventTree.set_column_expand(0, true)
	$Panel/VBC/ReportTabs/EventIndex/EventTree.set_column_custom_minimum_width(0, 5)
	$Panel/VBC/ReportTabs/EventIndex/EventTree.set_column_title(1, "Reachable")
	$Panel/VBC/ReportTabs/EventIndex/EventTree.set_column_expand(1, true)
	$Panel/VBC/ReportTabs/EventIndex/EventTree.set_column_custom_minimum_width(1, 1)
	$Panel/VBC/ReportTabs/EventIndex/EventTree.set_column_title(2, "Yielding Paths")
	$Panel/VBC/ReportTabs/EventIndex/EventTree.set_column_expand(2, true)
	$Panel/VBC/ReportTabs/EventIndex/EventTree.set_column_custom_minimum_width(2, 1)
	$Panel/VBC/ReportTabs.set_tab_title(1, "Cast Properties Index")
	$Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.set_column_title(0, "Property")
	$Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.set_column_expand(0, true)
	$Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.set_column_custom_minimum_width(0, 5)
	$Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.set_column_title(1, "Minimum")
	$Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.set_column_expand(1, true)
	$Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.set_column_custom_minimum_width(1, 1)
	$Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.set_column_title(2, "Maximum")
	$Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.set_column_expand(2, true)
	$Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.set_column_custom_minimum_width(2, 1)
	$Panel/VBC/ReportTabs.set_tab_title(2, "Notable Outcome Index")
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_title(0, "Event")
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_expand(0, true)
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_custom_minimum_width(0, 5)
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_title(1, "Impact")
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_expand(1, true)
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_custom_minimum_width(1, 1)
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_title(2, "Range")
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_expand(2, true)
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_custom_minimum_width(2, 1)
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_title(3, "Occurrences")
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_expand(3, true)
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_custom_minimum_width(3, 1)
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_title(4, "Percentage")
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_expand(4, true)
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.set_column_custom_minimum_width(4, 1)
	$RehearsalReportFileDialog.set_current_dir(OS.get_executable_path().get_base_dir())
	$RehearsalReportFileDialog.set_current_file("report.txt")
	$RehearsalReportFileDialog.set_filters(PackedStringArray(["*.txt ; TXT Files"]))

func reset_rehearsal():
	rehearsal_status = rehearsal_statuses.SET
	time_stopwatch_started = 0
	elapsed_time = 0
	total_steps_taken = 0
	periodic_report = ""
	periodic_report_time = 0
	if (null == rehearsal):
		rehearsal = AutoRehearsal.new(reference_storyworld)
	else:
		rehearsal.reset(reference_storyworld)
	rehearsal.storyworld.trace_referenced_events()
	rehearsal.storyworld.check_for_parallels()
	$PeriodicReportTimer.set_paused(true)
	$PeriodicReportTimer.start(300)

func update_elapsed_time():
	if (rehearsal_statuses.RUNNING == rehearsal_status):
		var time = Time.get_ticks_msec()
		elapsed_time += time - time_stopwatch_started
		time_stopwatch_started = time

func say_time(time):
	var days = (time/86400000)
	var hours = (time/3600000)%24
	var minutes = (time/60000)%60
	var seconds = (time/1000)%60
	var time_description = ""
	var delimiter = ""
	if (1 < int(bool(days)) + int(bool(hours)) + int(bool(minutes))):
		#If more than one of the three is greater than 0, use commas as delimiters.
		delimiter = ","
	if (1 == days):
		time_description += "%s day%s " % [days, delimiter]
	elif (0 < days):
		time_description += "%s days%s " % [days, delimiter]
	if (1 == hours):
		time_description += "%s hour%s " % [hours, delimiter]
	elif (0 < hours):
		time_description += "%s hours%s " % [hours, delimiter]
	if (1 == minutes):
		time_description += "%s minute%s " % [minutes, delimiter]
	elif (0 < minutes):
		time_description += "%s minutes%s " % [minutes, delimiter]
	if (0 < days or 0 < hours or 0 < minutes):
		time_description += "and "
	if (1 == seconds):
		time_description += str(seconds) + " second"
	else:
		time_description += str(seconds) + " seconds"
	return time_description

func readable_datetime(unixdatetime):
	var datetime = Time.get_datetime_dict_from_unix_time(unixdatetime)
	var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
	var result = str(datetime.day)
	if (1 == datetime.day or 21 == datetime.day or 31 == datetime.day):
		result += "st"
	elif (2 == datetime.day or 22 == datetime.day):
		result += "nd"
	elif (3 == datetime.day or 23 == datetime.day):
		result += "rd"
	else:
		result += "th"
	result += " "
	var month = datetime.month -1
	result += months[month]
	result += " "
	result += str(datetime.year)
	result += " @ " + str(datetime.hour) + ":" + str(datetime.minute)
	result += " (UTC)"
	return result

func sort_encounters(encounters, sort_method, reverse):
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

func refresh_event_index():
	$Panel/VBC/ReportTabs/EventIndex/EventTree.clear()
	var root = $Panel/VBC/ReportTabs/EventIndex/EventTree.create_item()
	for encounter in rehearsal.storyworld.encounters:
		var encounter_branch = $Panel/VBC/ReportTabs/EventIndex/EventTree.create_item(root)
		encounter_branch.set_text(0, encounter.title)
		if (encounter.reachable):
			encounter_branch.set_text(1, "Yes")
		elif (rehearsal_statuses.COMPLETE == rehearsal_status):
			encounter_branch.set_text(1, "No")
		else:
			encounter_branch.set_text(1, "Unknown")
		encounter_branch.set_text(2, str(encounter.yielding_paths))
		for option in encounter.get_options():
			var option_branch = $Panel/VBC/ReportTabs/EventIndex/EventTree.create_item(encounter_branch)
			option_branch.set_text(0, option.get_listable_text())
			if (option.reachable):
				option_branch.set_text(1, "Yes")
			elif (rehearsal_statuses.COMPLETE == rehearsal_status):
				option_branch.set_text(1, "No")
			else:
				option_branch.set_text(1, "Unknown")
			option_branch.set_text(2, str(option.yielding_paths))
			for reaction in option.reactions:
				var reaction_branch = $Panel/VBC/ReportTabs/EventIndex/EventTree.create_item(option_branch)
				reaction_branch.set_text(0, reaction.get_listable_text())
				if (reaction.reachable):
					reaction_branch.set_text(1, "Yes")
				elif (rehearsal_statuses.COMPLETE == rehearsal_status):
					reaction_branch.set_text(1, "No")
				else:
					reaction_branch.set_text(1, "Unknown")
				reaction_branch.set_text(2, str(reaction.yielding_paths))

func recursive_refresh_castbook(root_display_branch:TreeItem, onion, keyring:Array):
	var cast = rehearsal.storyworld.characters
	for perceived_character in cast:
		if (onion.has(perceived_character.id)):
			var value = onion[perceived_character.id]
			keyring.append(perceived_character.id)
			if (TYPE_DICTIONARY == typeof(value)):
				var leaf = $Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.create_item(root_display_branch)
				leaf.set_text(0, perceived_character.char_name)
				recursive_refresh_castbook(leaf, value, keyring)
			elif (TYPE_INT == typeof(value) or TYPE_FLOAT == typeof(value)):
				var leaf = $Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.create_item(root_display_branch)
				var text = perceived_character.char_name + ": " + str(value)
				leaf.set_text(0, text)
			keyring.pop_back()

func estimate_event_impacts():
	var notable_events = []
	for encounter in rehearsal.storyworld.encounters:
		if (encounter.potential_ending):
			notable_events.append(encounter)
	notable_events.sort_custom(Callable(EncounterSorter, "sort_a_z"))
	for encounter in rehearsal.storyworld.encounters:
		var options = encounter.get_options()
		var option_count = options.size()
		encounter.impact = 0
		encounter.outcome_range = 0
		if (2 > option_count):
			# If the encounter has no options, or only has one option, then the encounter's impact is 0.
			if (1 == option_count):
				# If the encounter has a single option, that option's impact is also 0.
				var option = options.front()
				option.impact = 0
				option.outcome_range = 0
			continue
		# If the encounter has more than one option:
		var divisor = option_count - 1
		for option_index in range(option_count):
			var option = options[option_index]
			option.impact = 0
			option.outcome_range = 0
			if (0 == option.yielding_paths):
				# The rehearsal system has not finished updating this option. Skip it.
				continue
			for comparison_index in range(option_count):
				if (option_index != comparison_index):
					var comparison = options[comparison_index]
					if (0 == comparison.yielding_paths):
						# The rehearsal system has not finished updating this option. Skip it.
						continue
					var distance = 0
					for event in notable_events:
						var x = 0
						if (option.notable_outcomes.has(event)):
							x = float(option.notable_outcomes[event]) / float(option.yielding_paths)
						var y = 0
						if (comparison.notable_outcomes.has(event)):
							y = float(comparison.notable_outcomes[event]) / float(comparison.yielding_paths)
						distance += abs(x - y) / 2
					if (distance > option.outcome_range):
						option.outcome_range = distance
					option.impact += distance
			if (option.outcome_range > encounter.outcome_range):
				encounter.outcome_range = option.outcome_range
			option.impact /= divisor
			encounter.impact += option.impact
		encounter.impact /= option_count

func refresh_outcome_index():
	estimate_event_impacts()
	$Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.clear()
	var root = $Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.create_item()
	var sort_method_id = $Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/SortMenu.get_selected_id()
	var sort_method = $Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/SortMenu.get_popup().get_item_text(sort_method_id)
	var reversed = $Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/ToggleReverseButton.is_pressed()
	#Duplicate the list of encounters before sorting it.
	#Resorting the rehearsal's internal encounter list shouldn't cause any issues, but I want to avoid having to worry about the order when changing the rehearsal class.
	var list_of_encounters = rehearsal.storyworld.encounters.duplicate()
	sort_encounters(list_of_encounters, sort_method, reversed)
	for encounter in list_of_encounters:
		var encounter_branch = $Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.create_item(root)
		encounter_branch.set_text(0, encounter.title)
		encounter_branch.set_text(1, encounter.get_listable_impact())
		encounter_branch.set_text(2, encounter.get_listable_outcome_range())
		encounter_branch.set_text(3, str(encounter.yielding_paths))
		for option in encounter.get_options():
			var option_branch = $Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.create_item(encounter_branch)
			option_branch.set_text(0, option.get_listable_text())
			option_branch.set_text(1, option.get_listable_impact())
			option_branch.set_text(2, option.get_listable_outcome_range())
			option_branch.set_text(3, str(option.yielding_paths))
			var outcomes = option.notable_outcomes.keys()
			outcomes.sort_custom(Callable(EncounterSorter, "sort_a_z"))
			# Sort?
			for outcome in outcomes:
				var outcome_branch = $Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.create_item(option_branch)
				outcome_branch.set_text(0, outcome.title)
				outcome_branch.set_text(3, str(option.notable_outcomes[outcome]))
				if (0 < option.yielding_paths):
					var percentage = float(option.notable_outcomes[outcome]) / float(option.yielding_paths)
					percentage *= 100
					percentage = floor(percentage)
					outcome_branch.set_text(4, str(percentage) + "%")

func refresh():
	# Refresh Event Index:
	refresh_event_index()
	# Refresh Cast Variable Index:
	var trait_text = "Cast trait constants:\n"
	for pointer in rehearsal.cast_trait_constants:
		trait_text += pointer.data_to_string() + " : " + str(pointer.get_value()) + "\n"
	trait_text += "Cast trait variables:\n"
	for index in range(rehearsal.cast_traits_legend.size()):
		var pointer = rehearsal.cast_traits_legend[index]
		trait_text += pointer.data_to_string() + " min: " + str(rehearsal.cast_traits_min[index]) + " max: " + str(rehearsal.cast_traits_max[index]) + "\n"
	$Panel/VBC/ReportTabs/CastVariablesIndex/TraitList.set_text(trait_text)
#	$Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.clear()
#	root = $Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.create_item()
#	$Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.set_hide_root(true)
#	for character in rehearsal.storyworld.characters:
#		if (character.is_queued_for_deletion()):
#			continue
#		var listing = $Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.create_item(root)
#		listing.set_text(0, character.char_name)
#		for bnumber_property in character.authored_properties:
#			var onion = character.bnumber_properties[bnumber_property.id]
#			if (TYPE_DICTIONARY == typeof(onion) and onion.empty()):
#				continue
#			var entry = $Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.create_item(listing)
#			var keyring = []
#			keyring.append(bnumber_property.id)
#			entry.set_metadata(0, keyring)
#			if (0 == bnumber_property.depth):
#				var text = bnumber_property.get_property_name() + ": " + str(character.get_bnumber_property(keyring))
#				entry.set_text(0, text)
#			elif (0 < bnumber_property.depth):
#				var entry_text = bnumber_property.get_property_name() + ": "
#				entry.set_text(0, entry_text)
#				recursive_refresh_castbook(entry, onion, keyring)
	# Refresh Notable Outcome Index:
	refresh_outcome_index()
	# Refresh Elapsed Time:
	update_elapsed_time()
	var elapsed_time_description = say_time(elapsed_time)
	if (rehearsal_statuses.COMPLETE == rehearsal_status):
		elapsed_time_description = "Rehearsal took " + elapsed_time_description + " to complete."
	else:
		elapsed_time_description = "Rehearsal has been running for " + elapsed_time_description + " so far."
	elapsed_time_description += " " + report_steps()
	$Panel/VBC/HBC/ElapsedTimeDisplay.set_text(elapsed_time_description)

func clear():
	reset_rehearsal()
	$Panel/VBC/HBC/PlayButton.set_text("Play")
	$Panel/VBC/HBC/PlayButton.set_visible(true)
	$Panel/VBC/ReportTabs/EventIndex/EventTree.clear()

func rehearse():
	if (null != rehearsal and null != reference_storyworld):
		var step = 0
		var steps_per_loop = steps_per_frame
		while (step < steps_per_loop):
			if (rehearsal.rehearse_depth_first()):
				rehearsal_status = rehearsal_statuses.COMPLETE
				elapsed_time += Time.get_ticks_msec() - time_stopwatch_started
				$Panel/VBC/HBC/PlayButton.set_text("Play")
				$Panel/VBC/HBC/PlayButton.set_visible(false)
				refresh()
				total_steps_taken += step + 1
				$PeriodicReportTimer.stop()
				return
			step += 1
		total_steps_taken += step

func _process(_delta):
	if (rehearsal_statuses.RUNNING == rehearsal_status):
		rehearse()

func report_steps():
	var seconds = (elapsed_time/1000)
	if (0 < seconds):
		return str(total_steps_taken) + " steps, " + str(floor(total_steps_taken / seconds)) + " steps per second."
	else:
		return ""

func add_to_report():
	periodic_report_time += 5
	update_elapsed_time()
	periodic_report += str(periodic_report_time) + " minutes: " + report_steps() + "\n"

func export_rehearsal_report(file_path):
	var file_data = ""
	# Compile metadata:
	file_data += rehearsal.storyworld.storyworld_title + "\n"
	file_data += "by " + rehearsal.storyworld.storyworld_author + "\n"
	file_data += rehearsal.storyworld.ifid + "\n"
	# Compile heading:
	file_data += "Automated Rehearsal Report:\n"
	file_data += "Rehearsal started: " + readable_datetime(time_rehearsal_started) + "\n"
	file_data += "Speed set at " + str(initial_steps_per_frame) + " steps per frame.\n"
	# Compile runtime:
	update_elapsed_time()
	var elapsed_time_description = say_time(elapsed_time)
	if (rehearsal_statuses.COMPLETE == rehearsal_status):
		elapsed_time_description = "Rehearsal took " + elapsed_time_description + " to complete.\n"
	else:
		elapsed_time_description = "Rehearsal ran for " + elapsed_time_description + ", but did not reach completion.\n"
	file_data += elapsed_time_description
	# Compile step count:
	file_data += periodic_report
	file_data += "End: " + report_steps() + "\n"
	# Compile yielding path counts of endings:
	file_data += "Endings:\n"
	for encounter in rehearsal.storyworld.encounters:
		if (encounter.potential_ending):
			file_data += encounter.title + " : " + str(encounter.yielding_paths) + "\n"
	# Compile character traits:
	file_data += "Cast trait constants:\n"
	for pointer in rehearsal.cast_trait_constants:
		file_data += pointer.data_to_string() + " : " + str(pointer.get_value()) + "\n"
	file_data += "Cast trait variables:\n"
	for index in range(rehearsal.cast_traits_legend.size()):
		var pointer = rehearsal.cast_traits_legend[index]
		file_data += pointer.data_to_string() + " min: " + str(rehearsal.cast_traits_min[index]) + " max: " + str(rehearsal.cast_traits_max[index]) + "\n"
	# Compile encounter impact and range estimates:
	file_data += "Encounter impact and range estimates:\n"
	var list_of_encounters = rehearsal.storyworld.encounters.duplicate()
	sort_encounters(list_of_encounters, "Spools", false)
	for encounter in list_of_encounters:
		file_data += encounter.title + "," + encounter.get_listable_impact() + "," + encounter.get_listable_outcome_range() + "\n"
	# Save to file:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(file_data)
	file.close()

func _on_PlayButton_pressed():
	if (rehearsal_statuses.SET == rehearsal_status or rehearsal_statuses.COMPLETE == rehearsal_status):
		reset_rehearsal()
		time_rehearsal_started = Time.get_unix_time_from_system()
		rehearsal_status = rehearsal_statuses.PAUSED
		initial_steps_per_frame = steps_per_frame
	if (rehearsal_statuses.PAUSED == rehearsal_status):
		#Being rehearsing.
		rehearsal_status = rehearsal_statuses.RUNNING
		$Panel/VBC/HBC/PlayButton.set_text("Pause")
		time_stopwatch_started = Time.get_ticks_msec()
		$PeriodicReportTimer.set_paused(false)
	else:
		#Pause rehearsing.
		rehearsal_status = rehearsal_statuses.PAUSED
		$Panel/VBC/HBC/PlayButton.set_text("Play")
		elapsed_time += Time.get_ticks_msec() - time_stopwatch_started
		$PeriodicReportTimer.set_paused(true)
		refresh()

func _on_ResetButton_pressed():
	clear()

func _on_RefreshButton_pressed():
	refresh()

func _on_SpinBox_value_changed(value):
	steps_per_frame = value

func _on_SaveReportButton_pressed():
	$RehearsalReportFileDialog.invalidate()
	$RehearsalReportFileDialog.popup_centered()

func _on_RehearsalReportFileDialog_file_selected(path):
	export_rehearsal_report(path)

func _on_PeriodicReportTimer_timeout():
	add_to_report()
	refresh()

func _on_CollapseAllEvents_pressed():
	var branch = $Panel/VBC/ReportTabs/EventIndex/EventTree.get_root().get_first_child()
	while (null != branch):
		branch.call_recursive("set_collapsed", true)
		branch = branch.get_next()

func _on_ExpandAllEvents_pressed():
	var branch = $Panel/VBC/ReportTabs/EventIndex/EventTree.get_root().get_first_child()
	while (null != branch):
		branch.call_recursive("set_collapsed", false)
		branch = branch.get_next()

func _on_CollapseAllCast_pressed():
	var branch = $Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.get_root().get_first_child()
	while (null != branch):
		branch.set_collapsed(true)
		branch = branch.get_next()

func _on_ExpandAllCast_pressed():
	var branch = $Panel/VBC/ReportTabs/CastVariablesIndex/CastTree.get_root().get_first_child()
	while (null != branch):
		branch.set_collapsed(false)
		branch = branch.get_next()

func _on_CollapseAllOutcomes_pressed():
	var branch = $Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.get_root().get_first_child()
	while (null != branch):
		branch.call_recursive("set_collapsed", true)
		branch = branch.get_next()

func _on_ExpandToOptions_pressed():
	var branch = $Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.get_root().get_first_child()
	while (null != branch):
		branch.set_collapsed(false)
		for leaf in branch.get_children():
			leaf.set_collapsed(true)
		branch = branch.get_next()

func _on_ExpandToOutcomes_pressed():
	var branch = $Panel/VBC/ReportTabs/NotableOutcomeIndex/EventTree.get_root().get_first_child()
	while (null != branch):
		branch.call_recursive("set_collapsed", false)
		branch = branch.get_next()

@onready var sort_alpha_icon_light = preload("res://icons/sort-alpha-down.svg")
@onready var sort_alpha_icon_dark = preload("res://icons/sort-alpha-down_dark.svg")
@onready var sort_rev_alpha_icon_light = preload("res://icons/sort-alpha-down-alt.svg")
@onready var sort_rev_alpha_icon_dark = preload("res://icons/sort-alpha-down-alt_dark.svg")
@onready var sort_numeric_icon_light = preload("res://icons/sort-numeric-down.svg")
@onready var sort_numeric_icon_dark = preload("res://icons/sort-numeric-down_dark.svg")
@onready var sort_rev_numeric_icon_light = preload("res://icons/sort-numeric-down-alt.svg")
@onready var sort_rev_numeric_icon_dark = preload("res://icons/sort-numeric-down-alt_dark.svg")

func refresh_outcome_sort_icon():
	var sort_index = $Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/SortMenu.get_selected()
	var sort_method = $Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/SortMenu.get_popup().get_item_text(sort_index)
	var reversed = $Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/ToggleReverseButton.is_pressed()
	if (light_mode):
		if ("Alphabetical" == sort_method or "Characters" == sort_method or "Spools" == sort_method):
			if (reversed):
				$Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/ToggleReverseButton.icon = sort_rev_alpha_icon_dark
			else:
				$Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/ToggleReverseButton.icon = sort_alpha_icon_dark
		else:
			if (reversed):
				$Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/ToggleReverseButton.icon = sort_rev_numeric_icon_dark
			else:
				$Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/ToggleReverseButton.icon = sort_numeric_icon_dark
	else:
		if ("Alphabetical" == sort_method or "Characters" == sort_method or "Spools" == sort_method):
			if (reversed):
				$Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/ToggleReverseButton.icon = sort_rev_alpha_icon_light
			else:
				$Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/ToggleReverseButton.icon = sort_alpha_icon_light
		else:
			if (reversed):
				$Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/ToggleReverseButton.icon = sort_rev_numeric_icon_light
			else:
				$Panel/VBC/ReportTabs/NotableOutcomeIndex/HBC/ToggleReverseButton.icon = sort_numeric_icon_light

func _on_OutcomeSortMenu_item_selected(_index):
	refresh_outcome_index()
	refresh_outcome_sort_icon()

func _on_toggle_reverse_button_toggled(_toggled_on):
	refresh_outcome_index()
	refresh_outcome_sort_icon()

func set_gui_theme(theme_name, _background_color):
	match theme_name:
		"Clarity":
			light_mode = true
		"Lapis Lazuli":
			light_mode = false
	refresh_outcome_sort_icon()
