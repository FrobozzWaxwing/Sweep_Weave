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

func refresh_quick_encounter_scripting_interface():
	if (my_encounter is Encounter and my_encounter.desirability_script is ScriptManager and my_encounter.desirability_script.contents is BNumberConstant):
		$VBC/Desirability/Spinner.set_value_no_signal(my_encounter.desirability_script.contents.get_value())
		$VBC/Desirability.set_visible(true)
	else:
		$VBC/Desirability.set_visible(false)

func set_display_encounter_excerpts(display:bool):
	$VBC/Excerpt.set_visible(display)

func set_display_encounter_qdse(display:bool):
	if (display):
		refresh_quick_encounter_scripting_interface()
	else:
		$VBC/Desirability.set_visible(false)

func save_position():
	if (selected):
		my_encounter.graph_position = position_offset

func delete():
	queue_free()

func _on_Control_dragged(from, to):
	my_encounter.graph_position = position_offset
	encounter_modified.emit(my_encounter)

func _on_spinner_value_changed(value):
	my_encounter.desirability_script.contents.set_value(value)
	encounter_modified.emit(my_encounter)

func _on_EditButton_pressed():
	load_encounter_from_graphview.emit(my_encounter)

#GUI Themes:

@onready var edit_icon_light = preload("res://icons/edit.svg")
@onready var edit_icon_dark = preload("res://icons/edit_dark.svg")

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
