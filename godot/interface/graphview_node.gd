extends GraphNode

var my_encounter = null

signal load_encounter_from_graphview(encounter)
signal encounter_modified(encounter)

# Called when the node enters the scene tree for the first time.
func _ready():
	set_slot(0, true, 0, Color(0.2, 0.85, 0.4), true, 0, Color(0.2, 0.85, 0.4))
	set_slot(1, true, 1, Color(0.1, 0.4, 0.80), true, 1, Color(0.1, 0.4, 0.80))

func set_excerpt(text:String):
	$VBC/Excerpt.text = text

func set_my_encounter(encounter):
	my_encounter = encounter

func refresh_bnumber_property_lists():
	if (my_encounter is Encounter and my_encounter.desirability_script is ScriptManager):
		$VBC/MinimalEncounterDesirabilityScriptingInterface.storyworld = my_encounter.storyworld
		$VBC/MinimalEncounterDesirabilityScriptingInterface.script_to_edit = my_encounter.desirability_script
	$VBC/MinimalEncounterDesirabilityScriptingInterface.refresh_bnumber_property_lists()

func refresh_quick_encounter_scripting_interface():
	if (my_encounter is Encounter and my_encounter.desirability_script is ScriptManager):
		$VBC/MinimalEncounterDesirabilityScriptingInterface.storyworld = my_encounter.storyworld
		$VBC/MinimalEncounterDesirabilityScriptingInterface.script_to_edit = my_encounter.desirability_script
		$VBC/MinimalEncounterDesirabilityScriptingInterface.refresh()
	else:
		$VBC/MinimalEncounterDesirabilityScriptingInterface.script_to_edit = null
		$VBC/MinimalEncounterDesirabilityScriptingInterface.set_visible(false)

func set_display_encounter_excerpts(display:bool):
	$VBC/Excerpt.set_visible(display)

func set_display_encounter_qdse(display:bool):
	$VBC/MinimalEncounterDesirabilityScriptingInterface.set_visible(display)

func save_position():
	if (selected):
		my_encounter.graph_position = offset

func delete():
	queue_free()

func _on_Control_dragged(from, to):
	my_encounter.graph_position = offset
	emit_signal("encounter_modified", my_encounter)

func _on_MinimalEncounterDesirabilityScriptingInterface_sw_script_changed(sw_script):
	emit_signal("encounter_modified", my_encounter)

func _on_EditButton_pressed():
	emit_signal("load_encounter_from_graphview", my_encounter)

#GUI Themes:

onready var edit_icon_light = preload("res://icons/edit.svg")
onready var edit_icon_dark = preload("res://icons/edit_dark.svg")

func set_gui_theme(theme_name, background_color):
	match theme_name:
		"Clarity":
			$VBC/EditButton.icon = edit_icon_dark
		"Lapis Lazuli":
			$VBC/EditButton.icon = edit_icon_light

func set_light_mode(light_mode):
	if (light_mode):
		$VBC/EditButton.icon = edit_icon_dark
	else:
		$VBC/EditButton.icon = edit_icon_light
