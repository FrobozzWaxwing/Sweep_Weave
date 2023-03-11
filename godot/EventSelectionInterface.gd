extends Control

var storyworld = null
var blacklist = [] #A list of encounters that should not be made available for selection. Could slow down the system if this array is too long.
var selected_event = null #An EventPointer.
var searchterm = ""
var display_options = true #If true, the refresh function will display the options of encounters as branches of those encounters in the EventTree.
var display_negated_checkbox = true

signal selected_event_changed(selected_event)
signal event_doubleclicked(selected_event)

func _ready():
	selected_event = EventPointer.new(null, null, null)
	if (0 < $Background/VBC/SortBar/SortMenu.get_item_count()):
		$Background/VBC/SortBar/SortMenu.select(0)

onready var event_selection_tree = get_node("Background/VBC/EventTree")

func reset():
	blacklist.clear()
	selected_event = EventPointer.new(null, null, null)
	searchterm = ""

func refresh():
	if (null == storyworld):
		return
	event_selection_tree.clear()
	var root = event_selection_tree.create_item()
	root.set_text(0, "Encounters: ")
	for encounter in storyworld.encounters:
#		if (encounter != current_encounter):
		if (!blacklist.has(encounter)):
			if ("" == searchterm or encounter.has_search_text(searchterm)):
				var entry_e = event_selection_tree.create_item(root)
				if (selected_event is EventPointer and encounter == selected_event.encounter):
					entry_e.select(0)
				if ("" == encounter.title):
					entry_e.set_text(0, "[Untitled]")
				else:
					entry_e.set_text(0, encounter.title)
				entry_e.set_metadata(0, {"encounter": encounter, "option": null, "reaction": null})
				if (display_options):
					for option in encounter.options:
						var entry_o = event_selection_tree.create_item(entry_e)
						var text = option.get_text()
						if ("" == text):
							entry_o.set_text(0, "[Blank Option]")
						else:
							entry_o.set_text(0, text)
						entry_o.set_metadata(0, {"encounter": encounter, "option": option, "reaction": null})
						for reaction in option.reactions:
							var entry_r = event_selection_tree.create_item(entry_o)
							text = reaction.get_text()
							if ("" == text):
								entry_r.set_text(0, "[Blank Reaction]")
							else:
								entry_r.set_text(0, text)
							entry_r.set_metadata(0, {"encounter": encounter, "option": option, "reaction": reaction})
	$Background/VBC/NegatedCheckBox.visible = display_negated_checkbox

func _on_LineEdit_text_entered(new_text):
	searchterm = new_text
	print("Searching events for \"" + new_text + "\"")
	refresh()

func _on_EventTree_item_selected():
	var item = event_selection_tree.get_selected()
	if(null != item && item is TreeItem && null != item.get_metadata(0) and selected_event is EventPointer):
		var metadata = item.get_metadata(0)
		var encounter = metadata["encounter"]
		var option = metadata["option"]
		var reaction = metadata["reaction"]
		selected_event.encounter = encounter
		selected_event.option = option
		selected_event.reaction = reaction
		emit_signal("selected_event_changed", selected_event)

func _on_NegatedCheckBox_pressed():
	selected_event.negated = $Background/VBC/NegatedCheckBox.pressed
	emit_signal("selected_event_changed", selected_event)

func _on_SortMenu_item_selected(index):
	var sort_method = $Background/VBC/SortBar/SortMenu.get_popup().get_item_text(index)
	if ("Word Count" == sort_method || "Rev. Word Count" == sort_method):
		for encounter in storyworld.encounters:
			encounter.wordcount() #Update recorded wordcount of each encounter.
	storyworld.sort_encounters(sort_method)
	refresh()

func _on_EventTree_item_activated():
	emit_signal("event_doubleclicked", selected_event)

#GUI Themes:

func set_gui_theme(theme_name, background_color):
	$Background.color = background_color
