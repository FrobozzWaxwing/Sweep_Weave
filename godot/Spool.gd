extends Object
class_name Spool
#A group of encounters, with some associated scripts.
#SweepWeave uses spools when deciding which encounter to present next.

var id = ""
var spool_name = ""
var encounters = [] #A list of encounters.
#If multiple encounters are tied for most desirable encounter, the earliest encounter in the list will be selected.
var before_effects = null #Effects that occur when this spool is first activated, but before the first encounter from this spool is presented to the player.
var per_encounter_after_effects = null #After each encounter from this spool is presented, and after an option and reaction are chosen and the effects of said reaction are brought about, the effects in this variable will also be brought about. These effects can be repeatedly effected.

#Variables for editor:
var creation_index = 0
var creation_time = OS.get_unix_time()
var modified_time = OS.get_unix_time()

func _init():
	pass

func log_update():
	modified_time = OS.get_unix_time()

func compile(parent_storyworld, include_editor_only_variables = false):
	var result = {}
	result["id"] = id
	result["spool_name"] = spool_name
	result["encounters"] = []
	for each in encounters:
		result["encounters"].append(each.id)
	if (include_editor_only_variables):
		#Editor only variables:
		result["creation_index"] = creation_index
		result["creation_time"] = creation_time
		result["modified_time"] = modified_time
	return result
