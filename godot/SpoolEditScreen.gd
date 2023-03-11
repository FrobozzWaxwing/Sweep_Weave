extends Control

var current_spool = null
var spool_to_delete = null
var storyworld = null

signal request_overview_change()

func _ready():
	$Background/HBC/Column1/Spools.connect("moved_item", self, "_on_Spool_rearranged_via_draganddrop")
	$Background/HBC/Column2/Encounters_on_current_spool.connect("moved_item", self, "_on_Encounter_rearranged_via_draganddrop")
	$Background/HBC/Column3/ListofAllEncounters.connect("event_doubleclicked", self, "add_encounter_to_current_spool")

func refresh():
	if (null != storyworld):
		refresh_spools_list()
		if (!storyworld.spools.empty()):
			display_spool(storyworld.spools.front())
		else:
			current_spool = null
			$Background/HBC/Column1/Spools.clear()
			$Background/HBC/Column1/Spools.list_to_display.clear()
			for child in $Background/HBC/Column2.get_children():
				if ($Background/HBC/Column2/NoSpoolSelected == child or $Background/HBC/Column2/NoSpoolMargin == child):
					child.visible = true
				else:
					child.visible = false
		refresh_list_of_all_encounters()

func refresh_spools_list():
	$Background/HBC/Column1/Spools.clear()
	$Background/HBC/Column1/Spools.list_to_display.clear()
	if (null != storyworld):
		for spool in storyworld.spools:
			var display_text = spool.spool_name
			if ("" == display_text):
				display_text = "[Untitled Spool]"
			var entry = {"text": display_text, "metadata": spool}
			$Background/HBC/Column1/Spools.list_to_display.append(entry)
	$Background/HBC/Column1/Spools.refresh()

func add_spool_to_list(spool):
	if (null != storyworld):
		var display_text = spool.spool_name
		if ("" == display_text):
			display_text = "[Untitled Spool]"
		var entry = {"text": display_text, "metadata": spool}
		$Background/HBC/Column1/Spools.list_to_display.append(entry)
	$Background/HBC/Column1/Spools.refresh()

func display_spool(spool:Spool):
	current_spool = spool
	for child in $Background/HBC/Column2.get_children():
		if ($Background/HBC/Column2/NoSpoolSelected == child or $Background/HBC/Column2/NoSpoolMargin == child):
			child.visible = false
		else:
			child.visible = true
	$Background/HBC/Column2/Encounters_on_current_spool.clear()
	$Background/HBC/Column2/Encounters_on_current_spool.list_to_display.clear()
	if (null != spool and spool is Spool):
		$Background/HBC/Column2/HBC/SpoolNameEdit.text = spool.spool_name
		$Background/HBC/Column2/HBC/SpoolStartsActiveCheckBox.pressed = spool.starts_active
		for encounter in spool.encounters:
			var display_text = encounter.title
			if ("" == display_text):
				display_text = "[Untitled Encounter]"
			var entry = {"text": display_text, "metadata": encounter}
			$Background/HBC/Column2/Encounters_on_current_spool.list_to_display.append(entry)
	$Background/HBC/Column2/Encounters_on_current_spool.refresh()

func load_and_focus_first_spool():
	if (0 < storyworld.spools.size()):
		display_spool(storyworld.spools.front())
		$Background/HBC/Column1/Spools.select_first_item()

func refresh_list_of_all_encounters():
	$Background/HBC/Column3/ListofAllEncounters.storyworld = storyworld
	$Background/HBC/Column3/ListofAllEncounters.display_options = false
	$Background/HBC/Column3/ListofAllEncounters.display_negated_checkbox = false
	$Background/HBC/Column3/ListofAllEncounters.refresh()

func create_new_spool():
	if (null == storyworld):
		return null
	var new_spool = Spool.new()
	var creation_index = storyworld.unique_id_seeds["spool"]
	new_spool.id = storyworld.unique_id("spool", 8)
	new_spool.spool_name = "Spool " + str(creation_index)
	new_spool.creation_index = creation_index
	storyworld.add_spool(new_spool)
	return new_spool

func _on_AddButton_pressed():
	current_spool = create_new_spool()
	add_spool_to_list(current_spool)
	display_spool(current_spool)
	$Background/HBC/Column1/Spools.select_last_item()

func _on_Spools_item_selected():
	display_spool($Background/HBC/Column1/Spools.get_selected_metadata())

func _on_SpoolNameEdit_text_changed(new_text):
	current_spool.spool_name = new_text
	refresh_spools_list()

func _on_SpoolStartsActiveCheckBox_pressed():
	current_spool.starts_active = $Background/HBC/Column2/HBC/SpoolStartsActiveCheckBox.pressed

func add_encounter_to_current_spool(event_pointer):
	if (null != event_pointer and null != event_pointer.encounter and null != current_spool):
		if (!current_spool.encounters.has(event_pointer.encounter)):
			#Add encounter to spool.
			current_spool.encounters.append(event_pointer.encounter)
			if (!event_pointer.encounter.connected_spools.has(current_spool)):
				event_pointer.encounter.connected_spools.append(current_spool)
			#Log update:
			current_spool.log_update()
			event_pointer.encounter.log_update()
			storyworld.log_update()
			OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
			storyworld.project_saved = false
			#Refresh display:
			display_spool(current_spool)
			emit_signal("request_overview_change")

func _on_DeleteButton_pressed():
	if (1 == storyworld.spools.size()):
		$CannotDeleteSpoolNotification.popup()
		return
	spool_to_delete = $Background/HBC/Column1/Spools.get_selected_metadata()
	if (null != spool_to_delete):
		var dialog_text = 'Are you sure you wish to delete the following spool?'
		dialog_text += " (" + spool_to_delete.spool_name + ")"
		$SpoolDeletionConfirmationDialog.dialog_text = dialog_text
		$SpoolDeletionConfirmationDialog.popup()

func _on_SpoolDeletionConfirmationDialog_confirmed():
	if (null != spool_to_delete):
		storyworld.delete_spool(spool_to_delete)
		#Log update:
		storyworld.log_update()
		OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
		storyworld.project_saved = false
		refresh_spools_list()
		if (!storyworld.spools.empty()):
			display_spool(storyworld.spools.front())
			$Background/HBC/Column1/Spools.select_first_item()
		emit_signal("request_overview_change")

func _on_Spool_rearranged_via_draganddrop(item, from_index, to_index):
	if (null == storyworld):
		return
	var spool = storyworld.spools.pop_at(from_index)
	if (to_index > from_index):
		to_index = to_index - 1
	if (to_index < storyworld.spools.size()):
		storyworld.spools.insert(to_index, spool)
	else:
		storyworld.spools.append(spool)

func _on_Encounter_rearranged_via_draganddrop(item, from_index, to_index):
	if (null == current_spool):
		return
	var encounter = current_spool.encounters.pop_at(from_index)
	if (to_index > from_index):
		to_index = to_index - 1
	if (to_index < current_spool.encounters.size()):
		current_spool.encounters.insert(to_index, encounter)
	else:
		current_spool.encounters.append(encounter)

func _on_AddEncounterButton_pressed():
	var selected_event = $Background/HBC/Column3/ListofAllEncounters.selected_event
	add_encounter_to_current_spool(selected_event)

func _on_RemoveEncounterButton_pressed():
	var encounter_to_remove = $Background/HBC/Column2/Encounters_on_current_spool.get_selected_metadata()
	if (null != encounter_to_remove and null != current_spool):
		#Remove encounter from spool.
		current_spool.encounters.erase(encounter_to_remove)
		encounter_to_remove.connected_spools.erase(current_spool)
		#Log update:
		current_spool.log_update()
		encounter_to_remove.log_update()
		storyworld.log_update()
		OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
		storyworld.project_saved = false
		#Refresh display:
		display_spool(current_spool)
		emit_signal("request_overview_change")

#GUI Themes:

onready var add_icon_light = preload("res://custom_resources/add_icon.svg")
onready var add_icon_dark = preload("res://custom_resources/add_icon_dark.svg")
onready var delete_icon_light = preload("res://custom_resources/delete_icon.svg")
onready var delete_icon_dark = preload("res://custom_resources/delete_icon_dark.svg")

func set_gui_theme(theme_name, background_color):
	$Background.color = background_color
	match theme_name:
		"Clarity":
			$Background/HBC/Column1/HBC/AddButton.icon = add_icon_dark
			$Background/HBC/Column1/HBC/DeleteButton.icon = delete_icon_dark
		"Lapis Lazuli":
			$Background/HBC/Column1/HBC/AddButton.icon = add_icon_light
			$Background/HBC/Column1/HBC/DeleteButton.icon = delete_icon_light
	$Background/HBC/Column3/ListofAllEncounters.set_gui_theme(theme_name, background_color)
