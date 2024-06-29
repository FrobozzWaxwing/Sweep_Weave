extends Object
class_name Spool
#A group of encounters.
#SweepWeave uses spools when deciding which encounter to present next.

var storyworld = null
var id = ""
var spool_name = ""
var starts_active = true #This variable tracks whether or not the spool is active at the start of play.
var encounters = [] #A list of encounters.

#Variables for editor:
var creation_index = 0
var creation_time = Time.get_unix_time_from_system()
var modified_time = Time.get_unix_time_from_system()

#Variables for playtesting:
var is_active = true #This variable tracks whether or not the spool is currently active. Used during playtesting.

func _init():
	pass

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

func log_update():
	modified_time = Time.get_unix_time_from_system()

func set_as_copy_of(original, create_mutual_links:bool = true):
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
	modified_time = Time.get_unix_time_from_system()

func remap(to_storyworld):
	var new_encounters = []
	for encounter in encounters:
		if (to_storyworld.encounter_directory.has(encounter.id)):
			new_encounters.append(to_storyworld.encounter_directory[encounter.id])
	encounters = new_encounters.duplicate()

func compile(_parent_storyworld, _include_editor_only_variables:bool = false):
	var result = {}
	result["id"] = id
	result["spool_name"] = spool_name
	result["starts_active"] = starts_active
	result["encounters"] = []
	for each in encounters:
		result["encounters"].append(each.id)
	if (_include_editor_only_variables):
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
