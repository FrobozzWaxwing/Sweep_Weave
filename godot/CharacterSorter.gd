extends Object
class_name CharacterSorter

static func sort_a_z(a, b):
	if (a.char_name < b.char_name):
		return true
	elif (a.char_name == b.char_name && a.id < b.id):
		return true
	return false
static func sort_z_a(a, b):
	if a.char_name > b.char_name:
		return true
	return false
static func sort_created(a, b):
	if a.creation_time < b.creation_time:
		return true
	elif a.creation_time == b.creation_time:
		if a.creation_index < b.creation_index:
			return true
	return false
static func sort_r_created(a, b):
	if a.creation_time > b.creation_time:
		return true
	elif a.creation_time == b.creation_time:
		if a.creation_index > b.creation_index:
			return true
	return false
static func sort_modified(a, b):
	if a.modified_time > b.modified_time:
		return true
	return false
static func sort_r_modified(a, b):
	if a.modified_time < b.modified_time:
		return true
	return false
