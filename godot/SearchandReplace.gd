extends Control

var storyworld = null
#var selected_event = null #An EventPointer.
var searchterm = ""

#signal selected_event_changed(selected_event)
#signal event_doubleclicked(selected_event)
#
#func _ready():
#	selected_event = EventPointer.new(null, null, null)
#	if (0 < $Background/VBC/SortBar/SortMenu.get_item_count()):
#		$Background/VBC/SortBar/SortMenu.select(0)
#
#onready var $VBC/Results = get_node("Background/VBC/EventTree")
#
#func reset():
#	blacklist.clear()
#	selected_event = EventPointer.new(null, null, null)
#	searchterm = ""
#
#func refresh():
#	if (null == storyworld):
#		return
#	$VBC/Results.clear()
#	var root = $VBC/Results.create_item()
#	root.set_text(0, "Encounters: ")
#	for encounter in storyworld.encounters:
##		if (encounter != current_encounter):
#		if (!blacklist.has(encounter)):
#			if ("" == searchterm or encounter.has_search_text(searchterm)):
#				var entry_e = $VBC/Results.create_item(root)
#				if (selected_event is EventPointer and encounter == selected_event.encounter):
#					entry_e.select(0)
#				if ("" == encounter.title):
#					entry_e.set_text(0, "[Untitled]")
#				else:
#					entry_e.set_text(0, encounter.title)
#				entry_e.set_metadata(0, {"encounter": encounter, "option": null, "reaction": null})
#				if (display_options):
#					for option in encounter.options:
#						var entry_o = $VBC/Results.create_item(entry_e)
#						var text = option.get_text()
#						if ("" == text):
#							entry_o.set_text(0, "[Blank Option]")
#						else:
#							entry_o.set_text(0, text)
#						entry_o.set_metadata(0, {"encounter": encounter, "option": option, "reaction": null})
#						for reaction in option.reactions:
#							var entry_r = $VBC/Results.create_item(entry_o)
#							text = reaction.get_text()
#							if ("" == text):
#								entry_r.set_text(0, "[Blank Reaction]")
#							else:
#								entry_r.set_text(0, text)
#							entry_r.set_metadata(0, {"encounter": encounter, "option": option, "reaction": reaction})
#
#func _on_LineEdit_text_entered(new_text):
#	searchterm = new_text
#	print("Searching events for \"" + new_text + "\"")
#	refresh()
#
#func _on_EventTree_item_selected():
#	var item = $VBC/Results.get_selected()
#	if(null != item && item is TreeItem && null != item.get_metadata(0) and selected_event is EventPointer):
#		var metadata = item.get_metadata(0)
#		var encounter = metadata["encounter"]
#		var option = metadata["option"]
#		var reaction = metadata["reaction"]
#		selected_event.encounter = encounter
#		selected_event.option = option
#		selected_event.reaction = reaction
#		emit_signal("selected_event_changed", selected_event)
#
#func _on_SortMenu_item_selected(index):
#	var sort_method = $Background/VBC/SortBar/SortMenu.get_popup().get_item_text(index)
#	if ("Word Count" == sort_method):
#		for encounter in storyworld.encounters:
#			encounter.wordcount() #Update recorded wordcount of each encounter.
#	storyworld.sort_encounters(sort_method)
#	refresh()
#
#func _on_EventTree_item_activated():
#	emit_signal("event_doubleclicked", selected_event)

func find_occurrences_of_string(needle, haystack):
	var results = []
	var index = 0
	while (-1 != index):
		index = haystack.find(needle, index)
		if (-1 != index):
			results.append(index)
			index += 1
	return results

func get_excerpt(index):
	pass

#func _ready():
#	var haystack = "Meet the new boss. Same as the old boss."
#	var needle = "boss"
#	searchterm = needle
#	var results = text_search(needle, haystack)
#	var root = $VBC/Results.create_item()
#	$VBC/Results.set_hide_root(true)
#	add_results(results, haystack)

func highlight_searchterm(treeitem, rect):
	var haystack = treeitem.get_text(0)
	var index = treeitem.get_metadata(0)
	var match_rect = rect
	var font = $VBC/Results.get_font("font")
	match_rect.position.x += font.get_string_size(haystack.left(index)).x - 1
	match_rect.size.x = font.get_string_size(searchterm).x + 2
	var color = Color(0.882353, 0.882353, 0.882353, 0.392157)
	$VBC/Results.draw_rect(match_rect, color)

func add_results(results, haystack):
	for result in results:
		var root = $VBC/Results.get_root()
		var child1 = $VBC/Results.create_item(root)
		child1.set_cell_mode(0, TreeItem.CELL_MODE_CUSTOM)
		child1.set_text(0, haystack)
		child1.set_metadata(0, result)
		child1.set_custom_draw(0, self, "highlight_searchterm")

func search_storyworld(needle):
	var results = {}
	results["element"] = []
	results["match_index"] = []
	searchterm = needle
	if (null == storyworld):
		return
	$VBC/Results.clear()
	var root = $VBC/Results.create_item()
#	for character in storyworld.characters:
#		#Search character name
#
	for encounter in storyworld.encounters:
		#Search encounter title
		#Search encounter text script
		var matches = encounter.text_script.find_occurrences_of_string(needle)
		if (!matches.empty()):
			pass
#		for option in encounter.options:
			#Search option text script
#			for reaction in option.reactions:
				#Search reaction text script
