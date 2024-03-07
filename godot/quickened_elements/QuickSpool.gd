extends Object
class_name QuickSpool
#A group of encounters.
#SweepWeave uses spools when deciding which encounter to present next.

var storyworld = null
var id = ""
var spool_name = ""
var starts_active = true #This variable tracks whether or not the spool is active at the start of play.

#Variables for playtesting:
var is_active = true #This variable tracks whether or not the spool is currently active. Used during playtesting.

var sorted_encounters = []
var unsorted_encounters = []

func _init(in_storyworld, original_spool):
	storyworld = in_storyworld
	id = original_spool.id
	spool_name = original_spool.spool_name
	starts_active = original_spool.starts_active
	is_active = original_spool.starts_active

func get_index():
	if (null != storyworld):
		return storyworld.spools.find(self)
	return -1

func get_listable_text(maximum_output_length:int = 70):
	var text = spool_name
	if ("" == text):
		return "[Untitled Spool]"
	elif (maximum_output_length >= text.length()):
		return text
	else:
		return text.left(maximum_output_length - 3) + "..."

func get_encounters():
	var encounters = sorted_encounters.duplicate()
	encounters.append_array(unsorted_encounters)
	return encounters

func activate():
	#Activates the spool so that its encounters are available for selection. Used during playtesting.
	is_active = true

func deactivate():
	#Deactivates the spool so that its encounters are unavailable for selection. Used during playtesting.
	is_active = false
