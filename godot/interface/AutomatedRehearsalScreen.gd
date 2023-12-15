extends Control

var rehearsal = null
var reference_storyworld = null
enum rehearsal_statuses {SET, RUNNING, PAUSED, COMPLETE}
var rehearsal_status = rehearsal_statuses.SET
var time_stopwatch_started = 0
var elapsed_time = 0
var steps_per_frame = 1
var total_steps_taken = 0
var periodic_report = ""
var periodic_report_time = 0

func _ready():
	$Panel/VBC/Tree.set_column_title(0, "Event")
	$Panel/VBC/Tree.set_column_expand(0, true)
	$Panel/VBC/Tree.set_column_min_width(0, 5)
	$Panel/VBC/Tree.set_column_title(1, "Reachable")
	$Panel/VBC/Tree.set_column_expand(1, true)
	$Panel/VBC/Tree.set_column_min_width(1, 1)
	$Panel/VBC/Tree.set_column_title(2, "Yielding Paths")
	$Panel/VBC/Tree.set_column_expand(2, true)
	$Panel/VBC/Tree.set_column_min_width(2, 1)
	$RehearsalReportFileDialog.set_current_dir(OS.get_executable_path().get_base_dir())
	$RehearsalReportFileDialog.set_current_file("report.txt")
	$RehearsalReportFileDialog.set_filters(PoolStringArray(["*.txt ; TXT Files"]))

func reset_rehearsal():
	rehearsal_status = rehearsal_statuses.SET
	time_stopwatch_started = 0
	elapsed_time = 0
	if (null == rehearsal):
		rehearsal = Rehearsal.new(reference_storyworld)
	else:
		rehearsal.clear_all_data()
		rehearsal.storyworld.set_as_copy_of(reference_storyworld)
		rehearsal.initial_pValues.record_character_states(rehearsal.storyworld)
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
	if (0 < hours):
		time_description += "%s hours%s " % [hours, delimiter]
	if (1 == minutes):
		time_description += "%s minute%s " % [minutes, delimiter]
	if (0 < minutes):
		time_description += "%s minutes%s " % [minutes, delimiter]
	if (0 < days or 0 < hours or 0 < minutes):
		time_description += "and "
	if (1 == seconds):
		time_description += str(seconds) + " second"
	else:
		time_description += str(seconds) + " seconds"
	return time_description

func refresh():
	$Panel/VBC/Tree.clear()
	var root = $Panel/VBC/Tree.create_item()
	for encounter in rehearsal.storyworld.encounters:
		var encounter_branch = $Panel/VBC/Tree.create_item(root)
		encounter_branch.set_text(0, encounter.title)
		if (encounter.reachable):
			encounter_branch.set_text(1, "Yes")
		elif (rehearsal_statuses.COMPLETE == rehearsal_status):
			encounter_branch.set_text(1, "No")
		else:
			encounter_branch.set_text(1, "Unknown")
		encounter_branch.set_text(2, str(encounter.yielding_paths))
		for option in encounter.options:
			var option_branch = $Panel/VBC/Tree.create_item(encounter_branch)
			option_branch.set_text(0, option.get_listable_text())
			if (option.reachable):
				option_branch.set_text(1, "Yes")
			elif (rehearsal_statuses.COMPLETE == rehearsal_status):
				option_branch.set_text(1, "No")
			else:
				option_branch.set_text(1, "Unknown")
			option_branch.set_text(2, str(option.yielding_paths))
			for reaction in option.reactions:
				var reaction_branch = $Panel/VBC/Tree.create_item(option_branch)
				reaction_branch.set_text(0, reaction.get_listable_text())
				if (reaction.reachable):
					reaction_branch.set_text(1, "Yes")
				elif (rehearsal_statuses.COMPLETE == rehearsal_status):
					reaction_branch.set_text(1, "No")
				else:
					reaction_branch.set_text(1, "Unknown")
				reaction_branch.set_text(2, str(reaction.yielding_paths))
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
	$Panel/VBC/Tree.clear()

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

func export_rehearsal_report(path):
	var file_data = ""
	# Compile metadata:
	file_data += rehearsal.storyworld.storyworld_title + "\n"
	file_data += "by " + rehearsal.storyworld.storyworld_author + "\n"
	file_data += rehearsal.storyworld.ifid + "\n"
	# Compile heading:
	file_data += "Automated Rehearsal Report:\n"
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
	# Save to file:
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string(file_data)
	file.close()

func _on_PlayButton_pressed():
	if (rehearsal_statuses.SET == rehearsal_status or rehearsal_statuses.COMPLETE == rehearsal_status):
		reset_rehearsal()
		rehearsal_status = rehearsal_statuses.PAUSED
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
