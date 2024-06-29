extends Control

var current_spool = null
var currently_spooled_encounters = {}
var spool_to_delete = null
var storyworld = null
var col3_searchterm = ""
var light_mode = true

signal request_overview_change()
signal encounter_load_requested(encounter)

func _ready():
	$Background/HBC/Column1/Spools.item_moved.connect(_on_Spool_rearranged_via_draganddrop)
	if (0 < $Background/HBC/Column3/SortBar/AddableSortMenu.get_item_count()):
		$Background/HBC/Column3/SortBar/AddableSortMenu.select(0)

func refresh():
	if (null != storyworld):
		refresh_spools_list()
		if (!storyworld.spools.is_empty()):
			display_spool(storyworld.spools.front())
		else:
			current_spool = null
			$Background/HBC/Column1/Spools.clear()
			$Background/HBC/Column1/Spools.items_to_list.clear()
			for child in $Background/HBC/Column2.get_children():
				if ($Background/HBC/Column2/NoSpoolSelected == child or $Background/HBC/Column2/NoSpoolMargin == child):
					child.visible = true
				else:
					child.visible = false
		refresh_addable_encounters()

func refresh_spools_list():
	$Background/HBC/Column1/Spools.clear()
	$Background/HBC/Column1/Spools.items_to_list.clear()
	if (null != storyworld):
		$Background/HBC/Column1/Spools.items_to_list = storyworld.spools.duplicate()
	$Background/HBC/Column1/Spools.refresh()

func set_current_spool(spool:Spool):
	current_spool = spool
	currently_spooled_encounters.clear()
	for encounter in current_spool.encounters:
		currently_spooled_encounters[encounter.id] = encounter

func display_spool(spool:Spool):
	if (null == Spool):
		$Background/HBC/Column2.visible = false
		$Background/HBC/Column3.visible = false
		$Background/HBC/NoSpoolColumn.visible = true
	else:
		$Background/HBC/Column2.visible = true
		$Background/HBC/Column3.visible = true
		$Background/HBC/NoSpoolColumn.visible = false
		set_current_spool(spool)
		$Background/HBC/Column2/HBC/SpoolNameEdit.text = spool.spool_name
		$Background/HBC/Column2/HBC/SpoolStartsActiveCheckBox.button_pressed = spool.starts_active
		$Background/HBC/Column2/CurrentSpoolEncounterList.clear()
		var index = 0
		spool.encounters.sort_custom(Callable(EncounterSorter, "sort_desirability"))
		for encounter in spool.encounters:
			$Background/HBC/Column2/CurrentSpoolEncounterList.add_item(encounter.get_listable_text())
			$Background/HBC/Column2/CurrentSpoolEncounterList.set_item_metadata(index, encounter)
			index += 1
		refresh_addable_encounters()

func load_and_focus_first_spool():
	if (!storyworld.spools.is_empty()):
		display_spool(storyworld.spools.front())
		$Background/HBC/Column1/Spools.select_first_item()

func refresh_addable_encounters():
	$Background/HBC/Column3/AddableEncounters.clear()
	var index = 0
	for encounter in storyworld.encounters:
		if (!currently_spooled_encounters.has(encounter.id)):
			if ("" == col3_searchterm or encounter.has_search_text(col3_searchterm)):
				$Background/HBC/Column3/AddableEncounters.add_item(encounter.get_listable_text())
				$Background/HBC/Column3/AddableEncounters.set_item_metadata(index, encounter)
				index += 1

func refresh_add_encounter_button():
	var selected_indices = $Background/HBC/Column3/AddableEncounters.get_selected_items()
	if (1 >= selected_indices.size()):
		$Background/HBC/Column2/HBC2/AddEncounterButton.set_text("Add encounter")
	elif (1 < selected_indices.size()):
		$Background/HBC/Column2/HBC2/AddEncounterButton.set_text("Add encounters")

func refresh_remove_encounter_button():
	var selected_indices = $Background/HBC/Column2/CurrentSpoolEncounterList.get_selected_items()
	if (1 >= selected_indices.size()):
		$Background/HBC/Column2/HBC2/RemoveEncounterButton.set_text("Remove encounter")
	elif (1 < selected_indices.size()):
		$Background/HBC/Column2/HBC2/RemoveEncounterButton.set_text("Remove encounters")

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
	$Background/HBC/Column1/Spools.list_item(current_spool)
	display_spool(current_spool)
	$Background/HBC/Column1/Spools.deselect_all()
	$Background/HBC/Column1/Spools.select_last_item()

func _on_Spools_multi_selected(item, column, selected):
	display_spool($Background/HBC/Column1/Spools.get_first_selected_metadata())

func _on_SpoolNameEdit_text_changed(new_text):
	current_spool.spool_name = new_text
	refresh_spools_list()

func _on_SpoolStartsActiveCheckBox_pressed():
	current_spool.starts_active = $Background/HBC/Column2/HBC/SpoolStartsActiveCheckBox.is_pressed()

func add_encounter_to_current_spool(encounter:Encounter):
	if (!currently_spooled_encounters.has(encounter.id)):
		#Add encounter to spool.
		current_spool.encounters.append(encounter)
		encounter.connected_spools.append(current_spool)
		#Log update:
		encounter.log_update()

func remove_encounter_from_current_spool(encounter:Encounter):
	if (currently_spooled_encounters.has(encounter.id)):
		#Remove encounter from spool.
		current_spool.encounters.erase(encounter)
		encounter.connected_spools.erase(current_spool)
		#Log update:
		encounter.log_update()

func _on_AddEncounterButton_pressed():
	if (null == current_spool):
		return
	var selected_indices = $Background/HBC/Column3/AddableEncounters.get_selected_items()
	for index in selected_indices:
		var encounter = $Background/HBC/Column3/AddableEncounters.get_item_metadata(index)
		if (null != encounter):
			add_encounter_to_current_spool(encounter)
	#Log update:
	current_spool.log_update()
	storyworld.log_update()
	get_window().set_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false
	#Refresh display:
	display_spool(current_spool)
	request_overview_change.emit()

func _on_AddableEncounters_item_activated(index):
	if (null == current_spool):
		return
	var encounter = $Background/HBC/Column3/AddableEncounters.get_item_metadata(index)
	if (null != encounter):
		add_encounter_to_current_spool(encounter)
		#Log update:
		current_spool.log_update()
		storyworld.log_update()
		get_window().set_title("SweepWeave - " + storyworld.storyworld_title + "*")
		storyworld.project_saved = false
		#Refresh display:
		display_spool(current_spool)
		request_overview_change.emit()

func _on_AddableEncounters_multi_selected(index, selected):
	refresh_add_encounter_button()

func _on_CurrentSpoolEncounterList_multi_selected(index, selected):
	refresh_remove_encounter_button()

func _on_DeleteButton_pressed():
	if (1 == storyworld.spools.size()):
		$CannotDeleteSpoolNotification.popup_centered()
		return
	spool_to_delete = $Background/HBC/Column1/Spools.get_first_selected_metadata()
	if (null != spool_to_delete):
		var dialog_text = 'Are you sure you wish to delete the following spool?'
		dialog_text += " (" + spool_to_delete.spool_name + ")"
		$SpoolDeletionConfirmationDialog.dialog_text = dialog_text
		$SpoolDeletionConfirmationDialog.popup_centered()

func _on_SpoolDeletionConfirmationDialog_confirmed():
	if (null != spool_to_delete):
		storyworld.delete_spool(spool_to_delete)
		#Log update:
		storyworld.log_update()
		get_window().set_title("SweepWeave - " + storyworld.storyworld_title + "*")
		storyworld.project_saved = false
		refresh_spools_list()
		if (!storyworld.spools.is_empty()):
			display_spool(storyworld.spools.front())
			$Background/HBC/Column1/Spools.select_first_item()
		request_overview_change.emit()

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

func _on_RemoveEncounterButton_pressed():
	if (null == current_spool):
		return
	var selected_indices = $Background/HBC/Column2/CurrentSpoolEncounterList.get_selected_items()
	for index in selected_indices:
		var encounter = $Background/HBC/Column2/CurrentSpoolEncounterList.get_item_metadata(index)
		if (null != encounter):
			remove_encounter_from_current_spool(encounter)
	if (!selected_indices.is_empty()):
		#Log update:
		current_spool.log_update()
		storyworld.log_update()
		get_window().set_title("SweepWeave - " + storyworld.storyworld_title + "*")
		storyworld.project_saved = false
		#Refresh display:
		display_spool(current_spool)
		request_overview_change.emit()

func _on_CurrentSpoolEncounterList_item_activated(index):
	var encounter = $Background/HBC/Column2/CurrentSpoolEncounterList.get_item_metadata(index)
	if (null != encounter and encounter is Encounter):
		encounter_load_requested.emit(encounter)

func _on_AddableSearch_text_entered(new_text):
	col3_searchterm = new_text
	refresh_addable_encounters()

@onready var sort_alpha_icon_light = preload("res://icons/sort-alpha-down.svg")
@onready var sort_alpha_icon_dark = preload("res://icons/sort-alpha-down_dark.svg")
@onready var sort_rev_alpha_icon_light = preload("res://icons/sort-alpha-down-alt.svg")
@onready var sort_rev_alpha_icon_dark = preload("res://icons/sort-alpha-down-alt_dark.svg")
@onready var sort_numeric_icon_light = preload("res://icons/sort-numeric-down.svg")
@onready var sort_numeric_icon_dark = preload("res://icons/sort-numeric-down_dark.svg")
@onready var sort_rev_numeric_icon_light = preload("res://icons/sort-numeric-down-alt.svg")
@onready var sort_rev_numeric_icon_dark = preload("res://icons/sort-numeric-down-alt_dark.svg")

func refresh_sort_icon():
	var sort_index = $Background/HBC/Column3/SortBar/AddableSortMenu.get_selected()
	var sort_method = $Background/HBC/Column3/SortBar/AddableSortMenu.get_popup().get_item_text(sort_index)
	var reversed = $Background/HBC/Column3/SortBar/AddableToggleReverseButton.is_pressed()
	if (light_mode):
		if ("Alphabetical" == sort_method or "Characters" == sort_method or "Spools" == sort_method):
			if (reversed):
				$Background/HBC/Column3/SortBar/AddableToggleReverseButton.icon = sort_rev_alpha_icon_dark
			else:
				$Background/HBC/Column3/SortBar/AddableToggleReverseButton.icon = sort_alpha_icon_dark
		else:
			if (reversed):
				$Background/HBC/Column3/SortBar/AddableToggleReverseButton.icon = sort_rev_numeric_icon_dark
			else:
				$Background/HBC/Column3/SortBar/AddableToggleReverseButton.icon = sort_numeric_icon_dark
	else:
		if ("Alphabetical" == sort_method or "Characters" == sort_method or "Spools" == sort_method):
			if (reversed):
				$Background/HBC/Column3/SortBar/AddableToggleReverseButton.icon = sort_rev_alpha_icon_light
			else:
				$Background/HBC/Column3/SortBar/AddableToggleReverseButton.icon = sort_alpha_icon_light
		else:
			if (reversed):
				$Background/HBC/Column3/SortBar/AddableToggleReverseButton.icon = sort_rev_numeric_icon_light
			else:
				$Background/HBC/Column3/SortBar/AddableToggleReverseButton.icon = sort_numeric_icon_light

func _on_AddableSortMenu_item_selected(index):
	var sort_method = $Background/HBC/Column3/SortBar/AddableSortMenu.get_popup().get_item_text(index)
	if ("Word Count" == sort_method):
		for encounter in storyworld.encounters:
			encounter.wordcount() #Update recorded wordcount of each encounter.
	var reversed = $Background/HBC/Column3/SortBar/AddableToggleReverseButton.is_pressed()
	storyworld.sort_encounters(sort_method, reversed)
	refresh_addable_encounters()
	refresh_sort_icon()

func _on_AddableToggleReverseButton_toggled(button_pressed):
	var sort_index = $Background/HBC/Column3/SortBar/AddableSortMenu.get_selected()
	var sort_method = $Background/HBC/Column3/SortBar/AddableSortMenu.get_popup().get_item_text(sort_index)
	storyworld.sort_encounters(sort_method, button_pressed)
	refresh_addable_encounters()
	refresh_sort_icon()

#GUI Themes:

@onready var add_icon_light = preload("res://icons/add.svg")
@onready var add_icon_dark = preload("res://icons/add_dark.svg")
@onready var delete_icon_light = preload("res://icons/delete.svg")
@onready var delete_icon_dark = preload("res://icons/delete_dark.svg")

func set_gui_theme(theme_name, background_color):
	$Background.color = background_color
	match theme_name:
		"Clarity":
			$Background/HBC/Column1/HBC/AddButton.icon = add_icon_dark
			$Background/HBC/Column1/HBC/DeleteButton.icon = delete_icon_dark
			light_mode = true
		"Lapis Lazuli":
			$Background/HBC/Column1/HBC/AddButton.icon = add_icon_light
			$Background/HBC/Column1/HBC/DeleteButton.icon = delete_icon_light
			light_mode = false
	refresh_sort_icon()
