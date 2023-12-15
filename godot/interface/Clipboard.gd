extends Object
class_name Clipboard

var storyworld = null
#Clipboard system variables:
var clipped_copies = [] #Copies of the clipped data.
var clipped_originals = [] #References to the original objects that were clipped.
enum clipboard_task_types {NONE, CUT, COPY}
var clipboard_task = clipboard_task_types.NONE
enum clippable_item_types {OPTION, REACTION, EFFECT}

func _init():
	pass

func clear():
	clipped_originals.clear()
	for item in clipped_copies:
		item.clear()
		item.call_deferred("free")
	clipped_copies.clear()
	clipboard_task = clipboard_task_types.NONE

func clip(items):
	clear()
	clipped_originals = items
	for item in items:
		if (item is Option):
			var copy = Option.new(null, "", "")
			copy.set_as_copy_of(item, false)
			clipped_copies.append(copy)
		elif (item is Reaction):
			var copy = Reaction.new(null, "", "")
			copy.set_as_copy_of(item, false)
			clipped_copies.append(copy)
		elif (item is BNumberEffect):
			var copy = BNumberEffect.new()
			copy.set_as_copy_of(item)
			clipped_copies.append(copy)
		elif (item is SpoolEffect):
			var copy = SpoolEffect.new()
			copy.set_as_copy_of(item)
			clipped_copies.append(copy)

func cut(items):
	clip(items)
	clipboard_task = clipboard_task_types.CUT

func copy(items):
	clip(items)
	clipboard_task = clipboard_task_types.COPY

func log_update(encounter = null):
	#If encounter == null, then the project as a whole is being updated, rather than a specific encounter, or an encounter has been added, deleted, or duplicated.
	if (null != encounter):
		encounter.log_update()
	storyworld.log_update()
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false
	emit_signal("refresh_encounter_list")

func delete_clipped_originals():
	if (clipped_originals.empty()):
		return
	for item in clipped_originals:
		if (item is Option):
			storyworld.delete_option_from_scripts(item)
			if (null != item.encounter):
				item.encounter.options.erase(item)
				item.encounter.wordcount()
				log_update(item.encounter)
			item.clear()
			item.call_deferred("free")
			emit_signal("refresh_graphview")
		elif (item is Reaction):
			storyworld.delete_reaction_from_scripts(item)
			if (null != item.option):
				item.option.reactions.erase(item)
				item.option.encounter.wordcount()
				log_update(item.option.encounter)
			item.clear()
			item.call_deferred("free")
			emit_signal("refresh_graphview")
		elif (item is BNumberEffect):
			if (null != item.cause):
				item.cause.after_effects.erase(item)
				log_update(item.cause.option.encounter)
			item.clear()
			item.call_deferred("free")
		elif (item is SpoolEffect):
			if (null != item.cause):
				item.cause.after_effects.erase(item)
				log_update(item.cause.option.encounter)
			item.clear()
			item.call_deferred("free")
	clipped_originals.clear()

func paste():
	var items_to_paste = []
	if (null == storyworld or !(storyworld is Storyworld)):
		#Cannot create new items without a storyworld to tie them to.
		return items_to_paste
	for item in clipped_copies:
		if (item is Option):
			var copy = storyworld.create_new_generic_option(null)
			copy.set_as_copy_of(item, false)
			items_to_paste.append(copy)
		elif (item is Reaction):
			var copy = storyworld.create_new_generic_reaction(null)
			copy.set_as_copy_of(item, false)
			items_to_paste.append(copy)
		elif (item is BNumberEffect):
			var copy = BNumberEffect.new()
			copy.set_as_copy_of(item)
			items_to_paste.append(copy)
		elif (item is SpoolEffect):
			var copy = SpoolEffect.new()
			copy.set_as_copy_of(item)
			items_to_paste.append(copy)
	return items_to_paste
