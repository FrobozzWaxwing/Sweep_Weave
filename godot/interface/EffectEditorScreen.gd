extends Control

var storyworld = null

func _ready():
	$TabContainer/NextPage/VBC/NextPageOptionButton.get_popup().add_item("Select the next encounter automatically.")
	$TabContainer/NextPage/VBC/NextPageOptionButton.get_popup().add_item("Display a specific encounter next:")
	$TabContainer/NextPage/VBC/NextPageOptionButton.select(0)

func load_effect(effect):
	if (effect is BNumberEffect):
		$TabContainer/BNumberProperty/VBC/PropertySelector.selected_property.set_as_copy_of(effect.assignee)
		$TabContainer/BNumberProperty/VBC/PropertySelector.refresh()
		$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.script_to_edit.set_as_copy_of(effect.assignment_script)
		$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.refresh_script_display()
		$TabContainer.set_current_tab(0)
	elif (effect is SpoolEffect):
		$TabContainer/SpoolStatus/VBC/SpoolSelector.selected_pointer.set_as_copy_of(effect.assignee)
		$TabContainer/SpoolStatus/VBC/SpoolSelector.refresh()
		$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.script_to_edit.set_as_copy_of(effect.assignment_script)
		$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.refresh_script_display()
		$TabContainer.set_current_tab(1)
	elif (effect is Encounter):
		#Effect sets next_page to a specific encounter.
		$TabContainer/NextPage/VBC/EncounterSelector.selected_event.encounter = effect
		$TabContainer/NextPage/VBC/EncounterSelector.refresh()
		$TabContainer/NextPage/VBC/NextPageOptionButton.select(1)
		$TabContainer/NextPage/VBC/EncounterSelector.visible = true
		$TabContainer.set_current_tab(2)

func get_effect():
	if ($TabContainer/BNumberProperty == $TabContainer.get_current_tab_control()):
		if (null == $TabContainer/BNumberProperty/VBC/PropertySelector.selected_property or null == $TabContainer/BNumberProperty/VBC/ScriptEditingInterface.script_to_edit):
			print("Invalid bnumber effect.")
			return null
		var pointer = BNumberPointer.new()
		pointer.set_as_copy_of($TabContainer/BNumberProperty/VBC/PropertySelector.selected_property)
		var script = ScriptManager.new()
		script.set_as_copy_of($TabContainer/BNumberProperty/VBC/ScriptEditingInterface.script_to_edit)
		return BNumberEffect.new(pointer, script)
	elif ($TabContainer/SpoolStatus == $TabContainer.get_current_tab_control()):
		if (null == $TabContainer/SpoolStatus/VBC/SpoolSelector.selected_pointer or null == $TabContainer/SpoolStatus/VBC/ScriptEditingInterface.script_to_edit):
			print("Invalid spool effect.")
			return null
		var pointer = SpoolPointer.new()
		pointer.set_as_copy_of($TabContainer/SpoolStatus/VBC/SpoolSelector.selected_pointer)
		var script = ScriptManager.new()
		script.set_as_copy_of($TabContainer/SpoolStatus/VBC/ScriptEditingInterface.script_to_edit)
		return SpoolEffect.new(pointer, script)
	elif ($TabContainer/NextPage == $TabContainer.get_current_tab_control()):
		if (null == $TabContainer/NextPage/VBC/EncounterSelector.selected_event):
			print("Invalid next-page effect.")
			return null
		elif (null != $TabContainer/NextPage/VBC/EncounterSelector.selected_event.encounter and 1 == $TabContainer/NextPage/VBC/NextPageOptionButton.get_selected_id()):
			#Set consequence.
			return $TabContainer/NextPage/VBC/EncounterSelector.selected_event
		elif (0 == $TabContainer/NextPage/VBC/NextPageOptionButton.get_selected_id()):
			#Remove consequence.
			$TabContainer/NextPage/VBC/EncounterSelector.selected_event.encounter = null
			return $TabContainer/NextPage/VBC/EncounterSelector.selected_event
		else:
			return null

func reset():
	if (null == storyworld or storyworld.characters.empty() or storyworld.authored_properties.empty()):
		return false
	#Refresh bounded number tab:
	$TabContainer/BNumberProperty/VBC/PropertySelector.storyworld = storyworld
	$TabContainer/BNumberProperty/VBC/PropertySelector.allow_root_character_editing = true
	$TabContainer/BNumberProperty/VBC/PropertySelector.reset()
	$TabContainer/BNumberProperty/VBC/PropertySelector.refresh()
	var new_script = ScriptManager.new(BNumberConstant.new(0))
	$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.storyworld = storyworld
	if (null != $TabContainer/BNumberProperty/VBC/ScriptEditingInterface.script_to_edit and is_instance_valid($TabContainer/BNumberProperty/VBC/ScriptEditingInterface.script_to_edit) and $TabContainer/BNumberProperty/VBC/ScriptEditingInterface.script_to_edit is ScriptManager):
		$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.script_to_edit.call_deferred("free")
	$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.script_to_edit = new_script
	$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.allow_root_character_editing = true
	$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.refresh_script_display()
	#Refresh spool tab:
	$TabContainer/SpoolStatus/VBC/SpoolSelector.storyworld = storyworld
	$TabContainer/SpoolStatus/VBC/SpoolSelector.reset("SpoolPointer")
	$TabContainer/SpoolStatus/VBC/SpoolSelector.refresh()
	new_script = ScriptManager.new(BooleanConstant.new(true))
	$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.storyworld = storyworld
	if (null != $TabContainer/SpoolStatus/VBC/ScriptEditingInterface.script_to_edit and is_instance_valid($TabContainer/SpoolStatus/VBC/ScriptEditingInterface.script_to_edit) and $TabContainer/SpoolStatus/VBC/ScriptEditingInterface.script_to_edit is ScriptManager):
		$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.script_to_edit.call_deferred("free")
	$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.script_to_edit = new_script
	$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.allow_root_character_editing = true
	$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.refresh_script_display()
	#Refresh next-page tab:
	$TabContainer/NextPage/VBC/EncounterSelector.storyworld = storyworld
	$TabContainer/NextPage/VBC/EncounterSelector.display_options = false
	$TabContainer/NextPage/VBC/EncounterSelector.display_negated_checkbox = false
	$TabContainer/NextPage/VBC/EncounterSelector.reset()
	$TabContainer/NextPage/VBC/EncounterSelector.refresh()
	$TabContainer/NextPage/VBC/NextPageOptionButton.select(1)
	$TabContainer/NextPage/VBC/EncounterSelector.visible = true
	#Select first tab:
	$TabContainer.set_current_tab(0)

func refresh():
	$TabContainer/BNumberProperty/VBC/PropertySelector.storyworld = storyworld
	$TabContainer/BNumberProperty/VBC/PropertySelector.refresh()
	$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.storyworld = storyworld
	$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.refresh_script_display()
	$TabContainer/SpoolStatus/VBC/SpoolSelector.storyworld = storyworld
	$TabContainer/SpoolStatus/VBC/SpoolSelector.refresh()
	$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.storyworld = storyworld
	$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.refresh_script_display()
	$TabContainer/NextPage/VBC/EncounterSelector.storyworld = storyworld
	$TabContainer/NextPage/VBC/EncounterSelector.refresh()
	$TabContainer/NextPage/VBC/NextPageOptionButton.select(1)
	$TabContainer/NextPage/VBC/EncounterSelector.visible = true


func _on_NextPageOptionButton_item_selected(index):
	match index:
		0:
			$TabContainer/NextPage/VBC/EncounterSelector.selected_event.encounter = null
			$TabContainer/NextPage/VBC/EncounterSelector.refresh()
			$TabContainer/NextPage/VBC/EncounterSelector.visible = false
		1:
			$TabContainer/NextPage/VBC/EncounterSelector.visible = true

#GUI Themes:

func set_gui_theme(theme_name, background_color):
	$TabContainer/BNumberProperty.color = background_color
	$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.set_gui_theme(theme_name, background_color)
	$TabContainer/SpoolStatus.color = background_color
	$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.set_gui_theme(theme_name, background_color)
	$TabContainer/NextPage.color = background_color
	$TabContainer/NextPage/VBC/EncounterSelector.set_gui_theme(theme_name, background_color)


