extends VBoxContainer

var storyworld = null
var node_scene = preload("res://interface/graphview_node.tscn")
#Display options:
#Track whether or not to display the quick desirability script editor for each encounter.
var display_encounter_excerpts = false
var display_encounter_qdse = false
#Clarity is a light mode theme, while Lapis Lazuli is a dark mode theme.
var light_mode = true

signal load_encounter_from_graphview(encounter)
signal encounter_modified(encounter)

func _ready():
	pass

func log_update(encounter = null):
	#If encounter == null, then the project as a whole is being updated, rather than a specific encounter, or an encounter has been added, deleted, or duplicated.
	if (null != encounter):
		encounter.log_update()
	storyworld.log_update()
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false
	emit_signal("refresh_encounter_list")

func set_display_encounter_excerpts(display:bool):
	display_encounter_excerpts = display
	get_tree().call_group("graphview_nodes", "set_display_encounter_excerpts", display)

func set_display_encounter_qdse(display:bool):
	display_encounter_qdse = display
	get_tree().call_group("graphview_nodes", "set_display_encounter_qdse", display)

#Graphview Functionality

func load_Encounter(encounter):
	emit_signal("load_encounter_from_graphview", encounter)

func load_encounter_in_graphview(encounter, zoom_level):
	var encounter_graph_node = node_scene.instance()
	encounter_graph_node.set_my_encounter(encounter)
	encounter_graph_node.offset += encounter.graph_position
	encounter_graph_node.title = encounter.title
	$GraphEdit.add_child(encounter_graph_node)
	encounter_graph_node.set_excerpt(encounter.get_excerpt(128))
	encounter_graph_node.set_display_encounter_excerpts(display_encounter_excerpts)
	encounter_graph_node.refresh_quick_encounter_scripting_interface()
	encounter_graph_node.set_display_encounter_qdse(display_encounter_qdse)
	encounter_graph_node.set_light_mode(light_mode)
	encounter_graph_node.add_to_group("graphview_nodes")
	encounter_graph_node.connect("load_encounter_from_graphview", self, "load_Encounter")
	encounter_graph_node.connect("encounter_modified", self, "_on_encounter_modified")
	encounter.graphview_node = encounter_graph_node

func load_connections_in_graphview(encounter, zoom_level):
	if (encounter is Encounter):
		var encounter_graph_node = encounter.graphview_node
		if (encounter.acceptability_script is ScriptManager):
			var acceptability_pointers = encounter.acceptability_script.find_all_eventpointers()
			for each in acceptability_pointers:
				if (each is EventPointer and each.encounter is Encounter):
					$GraphEdit.connect_node(each.encounter.graphview_node.get_name(), 0, encounter_graph_node.get_name(), 0)
		if (encounter.desirability_script is ScriptManager):
			var desirability_pointers = encounter.desirability_script.find_all_eventpointers()
			for each in desirability_pointers:
				if (each is EventPointer and each.encounter is Encounter):
					$GraphEdit.connect_node(each.encounter.graphview_node.get_name(), 0, encounter_graph_node.get_name(), 0)
		for option in encounter.options:
			if (option is Option):
				if (option.visibility_script is ScriptManager):
					var visibility_pointers = option.visibility_script.find_all_eventpointers()
					for each in visibility_pointers:
						if (each is EventPointer):
							$GraphEdit.connect_node(each.encounter.graphview_node.get_name(), 0, encounter_graph_node.get_name(), 0)
				if (option.performability_script is ScriptManager):
					var performability_pointers = option.performability_script.find_all_eventpointers()
					for each in performability_pointers:
						if (each is EventPointer):
							$GraphEdit.connect_node(each.encounter.graphview_node.get_name(), 0, encounter_graph_node.get_name(), 0)
				for reaction in option.reactions:
					if (reaction is Reaction and null != reaction.consequence and reaction.consequence is Encounter):
						$GraphEdit.connect_node(encounter_graph_node.get_name(), 1, reaction.consequence.graphview_node.get_name(), 1)
					if (reaction.desirability_script is ScriptManager):
						var desirability_pointers = reaction.desirability_script.find_all_eventpointers()
						for each in desirability_pointers:
							if (each is EventPointer and each.encounter is Encounter):
								$GraphEdit.connect_node(each.encounter.graphview_node.get_name(), 0, encounter_graph_node.get_name(), 0)
					for effect in reaction.after_effects:
						if (effect.assignment_script is ScriptManager):
							var effect_pointers = effect.assignment_script.find_all_eventpointers()
							for each in effect_pointers:
								if (each is EventPointer and each.encounter is Encounter):
									$GraphEdit.connect_node(each.encounter.graphview_node.get_name(), 0, encounter_graph_node.get_name(), 0)

func clear_graphview():
	$GraphEdit.clear_connections()
	get_tree().call_group("graphview_nodes", "delete")

func refresh_graphview():
	clear_graphview()
	for each in storyworld.encounters:
		load_encounter_in_graphview(each, 0)
	for each in storyworld.encounters:
		#Two passes are required to ensure that all nodes are loaded before attempting to load connections.
		load_connections_in_graphview(each, 0)

func refresh_quick_scripting_interfaces():
	get_tree().call_group("graphview_nodes", "refresh_quick_encounter_scripting_interface")

func _on_encounter_modified(encounter):
	log_update(encounter)
	emit_signal("encounter_modified", encounter)

#GUI Themes:

func set_gui_theme(theme_name, background_color):
	match theme_name:
		"Clarity":
			light_mode = true
		"Lapis Lazuli":
			light_mode = false
	get_tree().call_group("graphview_nodes", "set_gui_theme", theme_name, background_color)

