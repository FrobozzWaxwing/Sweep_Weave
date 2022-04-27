extends Object
class_name EncounterSorter

static func sort_a_z(a, b):
#	if a.title < b.title:
#		return true
#	return false
	if (a.title < b.title):
		return true
	elif (a.title == b.title && a.id < b.id):
		return true
	return false
static func sort_z_a(a, b):
	if a.title > b.title:
		return true
	return false
static func sort_created(a, b):
	if a.creation_time < b.creation_time:
		return true
	return false
static func sort_r_created(a, b):
	if a.creation_time > b.creation_time:
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
static func sort_e_turn(a, b):
	if a.earliest_turn < b.earliest_turn:
		return true
	return false
static func sort_r_e_turn(a, b):
	if a.earliest_turn > b.earliest_turn:
		return true
	return false
static func sort_l_turn(a, b):
	if a.latest_turn < b.latest_turn:
		return true
	return false
static func sort_r_l_turn(a, b):
	if a.latest_turn > b.latest_turn:
		return true
	return false
static func sort_antagonist(a, b):
	if a.antagonist.char_name < b.antagonist.char_name:
		return true
	return false
static func sort_r_antagonist(a, b):
	if a.antagonist.char_name > b.antagonist.char_name:
		return true
	return false
static func sort_options(a, b):
	if a.options.size() < b.options.size():
		return true
	return false
static func sort_r_options(a, b):
	if a.options.size() > b.options.size():
		return true
	return false
static func sort_reactions(a, b):
	var a_count = 0
	for option in a.options:
		for reaction in option.reactions:
			a_count += 1
	var b_count = 0
	for option in b.options:
		for reaction in option.reactions:
			b_count += 1
	if a_count < b_count:
		return true
	return false
static func sort_r_reactions(a, b):
	var a_count = 0
	for option in a.options:
		for reaction in option.reactions:
			a_count += 1
	var b_count = 0
	for option in b.options:
		for reaction in option.reactions:
			b_count += 1
	if a_count > b_count:
		return true
	return false
static func sort_word_count(a, b):
	if a.word_count > b.word_count:
		return true
	return false
static func sort_r_word_count(a, b):
	if a.word_count < b.word_count:
		return true
	return false