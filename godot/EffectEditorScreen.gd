extends Control

var storyworld = null

func _ready():
	pass

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
	$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.allow_coefficient_editing = true
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
	$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.allow_coefficient_editing = true
	$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.refresh_script_display()

func refresh():
	$TabContainer/BNumberProperty/VBC/PropertySelector.storyworld = storyworld
	$TabContainer/BNumberProperty/VBC/PropertySelector.refresh()
	$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.storyworld = storyworld
	$TabContainer/BNumberProperty/VBC/ScriptEditingInterface.refresh_script_display()
	$TabContainer/SpoolStatus/VBC/SpoolSelector.storyworld = storyworld
	$TabContainer/SpoolStatus/VBC/SpoolSelector.refresh()
	$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.storyworld = storyworld
	$TabContainer/SpoolStatus/VBC/ScriptEditingInterface.refresh_script_display()
