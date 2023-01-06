extends Object
class_name Spool
#A group of encounters, with some associated scripts.
#SweepWeave uses spools when deciding which encounter to present next.

var id = ""
var spool_name = ""
var encounters = [] #A list of encounters.
#If multiple encounters are tied for most desirable encounter, the earliest encounter in the list will be selected.
var starts_active = true #This variable tracks whether or not the spool is active at the start of play.

#Variables for editor:
var creation_index = 0
var creation_time = OS.get_unix_time()
var modified_time = OS.get_unix_time()

#Variables for playtesting:
var is_active = true #This variable tracks whether or not the spool is currently active. Used during playtesting.

func _init():
	pass

func log_update():
	modified_time = OS.get_unix_time()

func set_as_copy_of(original, create_mutual_links = true):
	#If create_mutual_links == true then the present spool will be added to the connected_spools array of each encounter added to the encounters array of this spool.
	#When copying or duplicating a spool in order to add a new spool to the same storyworld as the original spool, create_mutual_links should be true.
	#When copying spools from one storyworld to another, either via the import feature or in order to playtest a storyworld, create_mutual_links should be false.
	id = original.id
	spool_name = original.spool_name
	for encounter in original.encounters:
		if (is_instance_valid(encounter)):
			encounters.append(encounter)
			if (create_mutual_links):
				encounter.connected_spools.append(self)
	starts_active = original.starts_active
	modified_time = OS.get_unix_time()

func remap(to_storyworld):
	var new_encounters = []
	for encounter in encounters:
		if (to_storyworld.encounter_directory.has(encounter.id)):
			new_encounters.append(to_storyworld.encounter_directory[encounter.id])
	encounters = new_encounters.duplicate()

func compile(parent_storyworld, include_editor_only_variables = false):
	var result = {}
	result["id"] = id
	result["spool_name"] = spool_name
	result["starts_active"] = starts_active
	result["encounters"] = []
	for each in encounters:
		result["encounters"].append(each.id)
	if (include_editor_only_variables):
		#Editor only variables:
		result["creation_index"] = creation_index
		result["creation_time"] = creation_time
		result["modified_time"] = modified_time
	return result

func activate():
	#Activates the spool so that its encounters are available for selection. Used during playtesting.
	is_active = true

func deactivate():
	#Deactivates the spool so that its encounters are unavailable for selection. Used during playtesting.
	is_active = false
