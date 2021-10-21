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

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Control_dragged(from, to):
	my_encounter.graph_position = offset


func _on_Button_pressed():
	emit_signal("load_encounter_from_graphview", my_encounter)
