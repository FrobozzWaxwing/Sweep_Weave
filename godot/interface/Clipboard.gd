extends Object
class_name Clipboard

var storyworld = null
#Clipboard system variables:
var clipped_copies = [] #Copies of the clipped data.
var clipped_originals = [] #References to the original objects that were clipped.
enum clipboard_task_types {NONE, CUT, COPY}
var clipboard_task = clipboard_task_types.NONE
enum clippable_item_types {OPTION, REACTION, EFFECT}

signal refresh_graphview()
signal encounter_updated()

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
			var item_copy = Option.new(null, "", "")
			item_copy.set_as_copy_of(item, false)
			clipped_copies.append(item_copy)
		elif (item is Reaction):
			var item_copy = Reaction.new(null, "", "")
			item_copy.set_as_copy_of(item, false)
			clipped_copies.append(item_copy)
		elif (item is BNumberEffect):
			var item_copy = BNumberEffect.new()
			item_copy.set_as_copy_of(item)
			clipped_copies.append(item_copy)
		elif (item is SpoolEffect):
			var item_copy = SpoolEffect.new()
			item_copy.set_as_copy_of(item)
			clipped_copies.append(item_copy)

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
	#get_window().set_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false
	encounter_updated.emit()

func delete_clipped_originals():
	if (clipped_originals.is_empty()):
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
			refresh_graphview.emit()
		elif (item is Reaction):
			storyworld.delete_reaction_from_scripts(item)
			if (null != item.option):
				item.option.reactions.erase(item)
				item.option.encounter.wordcount()
				log_update(item.option.encounter)
			item.clear()
			item.call_deferred("free")
			refresh_graphview.emit()
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
			var item_copy = storyworld.create_new_generic_option(null)
			item_copy.set_as_copy_of(item, false)
			items_to_paste.append(item_copy)
		elif (item is Reaction):
			var item_copy = storyworld.create_new_generic_reaction(null)
			item_copy.set_as_copy_of(item, false)
			items_to_paste.append(item_copy)
		elif (item is BNumberEffect):
			var item_copy = BNumberEffect.new()
			item_copy.set_as_copy_of(item)
			items_to_paste.append(item_copy)
		elif (item is SpoolEffect):
			var item_copy = SpoolEffect.new()
			item_copy.set_as_copy_of(item)
			items_to_paste.append(item_copy)
	return items_to_paste
