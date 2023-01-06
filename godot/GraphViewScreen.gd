extends VBoxContainer

var storyworld = null
var node_scene = preload("res://graphview_node.tscn")

signal load_encounter_from_graphview(encounter)

func _ready():
	pass

#Graphview Functionality

func load_Encounter(encounter):
	emit_signal("load_encounter_from_graphview", encounter)

func load_encounter_in_graphview(encounter, zoom_level):
	var encounter_graph_node = node_scene.instance()
	encounter_graph_node.set_my_encounter(encounter)
	encounter_graph_node.offset += encounter.graph_position
	encounter_graph_node.title = encounter.title
	encounter_graph_node.set_excerpt(encounter.main_text.left(64))
	encounter_graph_node.add_to_group("graphview_nodes")
	encounter_graph_node.connect("load_encounter_from_graphview", self, "load_Encounter")
	$GraphEdit.add_child(encounter_graph_node)
	encounter.graphview_node = encounter_graph_node

func load_connections_in_graphview(encounter, zoom_level):
	if (encounter is Encounter):
		var encounter_graph_node = encounter.graphview_node
		if (encounter.acceptability_script is ScriptManager):
			var acceptability_pointers = encounter.acceptability_script.find_all_eventpointers()
			for each in acceptability_pointers:
				if (each is EventPointer and each.encounter is Encounter):
					$GraphEdit.connect_node(each.encounter.graphview_node.get_name(), 0, encounter_graph_node.get_name(), 0)
		for option in encounter.options:
			if (option is Option):
				for reaction in option.reactions:
					if (reaction is Reaction and null != reaction.consequence and reaction.consequence is Encounter):
						$GraphEdit.connect_node(encounter_graph_node.get_name(), 1, reaction.consequence.graphview_node.get_name(), 1)
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

func _on_GraphEdit__end_node_move():
	get_tree().call_group("graphview_nodes", "save_position")
