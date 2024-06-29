extends Object
class_name EncounterSorter

static func sort_a_z(a, b):
	if (a.title < b.title):
		return true
	elif (a.title == b.title && a.id < b.id):
		return true
	return false

static func sort_z_a(a, b):
	if a.title > b.title:
		return true
	elif (a.title == b.title && a.id > b.id):
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

static func sort_desirability(a, b):
	if a.calculate_desirability() > b.calculate_desirability():
		return true
	return false

static func sort_r_desirability(a, b):
	if a.calculate_desirability() < b.calculate_desirability():
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
		a_count += option.reactions.size()
	var b_count = 0
	for option in b.options:
		b_count += option.reactions.size()
	if a_count < b_count:
		return true
	return false

static func sort_r_reactions(a, b):
	var a_count = 0
	for option in a.options:
		a_count += option.reactions.size()
	var b_count = 0
	for option in b.options:
		b_count += option.reactions.size()
	if a_count > b_count:
		return true
	return false

static func sort_effects(a, b):
	var a_count = 0
	for option in a.options:
		for reaction in option.reactions:
			a_count += reaction.after_effects.size()
	var b_count = 0
	for option in b.options:
		for reaction in option.reactions:
			b_count += reaction.after_effects.size()
	if a_count < b_count:
		return true
	return false

static func sort_r_effects(a, b):
	var a_count = 0
	for option in a.options:
		for reaction in option.reactions:
			a_count += reaction.after_effects.size()
	var b_count = 0
	for option in b.options:
		for reaction in option.reactions:
			b_count += reaction.after_effects.size()
	if a_count > b_count:
		return true
	return false

static func sort_characters(a, b):
	var cursor = 0
	while (a.connected_characters.size() > cursor and b.connected_characters.size() > cursor):
		var name_a = a.connected_characters[cursor].char_name
		var name_b = b.connected_characters[cursor].char_name
		if (name_a < name_b):
			return true
		elif (name_a > name_b):
			return false
		else:
			cursor += 1
	if a.connected_characters.size() < b.connected_characters.size():
		return true
	return false

static func sort_r_characters(a, b):
	var cursor = 0
	while (a.connected_characters.size() > cursor and b.connected_characters.size() > cursor):
		var name_a = a.connected_characters[cursor].char_name
		var name_b = b.connected_characters[cursor].char_name
		if (name_a > name_b):
			return true
		elif (name_a < name_b):
			return false
		else:
			cursor += 1
	if a.connected_characters.size() > b.connected_characters.size():
		return true
	return false

static func sort_spools(a, b):
	if (b.connected_spools.is_empty()):
		if (a.connected_spools.is_empty()):
			if (a.title < b.title):
				return true
			elif (a.title == b.title && a.id < b.id):
				return true
			return false
		return true
	elif (a.connected_spools.is_empty()):
		return false
	var cursor = 0
	while (a.connected_spools.size() > cursor and b.connected_spools.size() > cursor):
		var name_a = a.connected_spools[cursor].spool_name
		var name_b = b.connected_spools[cursor].spool_name
		if (name_a < name_b):
			return true
		elif (name_a > name_b):
			return false
		else:
			cursor += 1
	if (a.connected_spools.size() < b.connected_spools.size()):
		return true
	if (a.calculate_desirability() > b.calculate_desirability()):
		return true
	return false

static func sort_r_spools(a, b):
	if (b.connected_spools.is_empty()):
		if (a.connected_spools.is_empty()):
			if (a.title < b.title):
				return false
			elif (a.title == b.title && a.id < b.id):
				return false
			return true
		return false
	elif (a.connected_spools.is_empty()):
		return true
	var cursor = 0
	while (a.connected_spools.size() > cursor and b.connected_spools.size() > cursor):
		var name_a = a.connected_spools[cursor].spool_name
		var name_b = b.connected_spools[cursor].spool_name
		if (name_a < name_b):
			return false
		elif (name_a > name_b):
			return true
		else:
			cursor += 1
	if (a.connected_spools.size() < b.connected_spools.size()):
		return false
	if (a.calculate_desirability() > b.calculate_desirability()):
		return false
	return true

static func sort_word_count(a, b):
	if a.word_count > b.word_count:
		return true
	return false

static func sort_r_word_count(a, b):
	if a.word_count < b.word_count:
		return true
	return false
