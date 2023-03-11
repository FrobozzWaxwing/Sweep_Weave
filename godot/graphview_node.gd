extends GraphNode

var my_encounter = null

signal load_encounter_from_graphview(encounter)

# Called when the node enters the scene tree for the first time.
func _ready():
	set_slot(0, true, 0, Color(0.2, 0.85, 0.4), true, 0, Color(0.2, 0.85, 0.4))
	set_slot(1, true, 1, Color(0.1, 0.4, 0.80), true, 1, Color(0.1, 0.4, 0.80))

func set_excerpt(text):
	$Excerpt.text = text

func set_my_encounter(encounter):
	my_encounter = encounter

func save_position():
	if (selected):
		my_encounter.graph_position = offset

func delete():
	queue_free()

func _on_Control_dragged(from, to):
	my_encounter.graph_position = offset

func _on_Button_pressed():
	emit_signal("load_encounter_from_graphview", my_encounter)

#GUI Themes:

onready var edit_icon_light = preload("res://custom_resources/edit-3.svg")
onready var edit_icon_dark = preload("res://custom_resources/edit-3_dark.svg")

func set_gui_theme(theme_name, background_color):
	match theme_name:
		"Clarity":
			$Button.icon = edit_icon_dark
		"Lapis Lazuli":
			$Button.icon = edit_icon_light

