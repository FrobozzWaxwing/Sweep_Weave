extends VBoxContainer

var storyworld = null

func readable_date(unixdatetime):
	var datetime = Time.get_datetime_dict_from_unix_time(unixdatetime)
	var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
	var result = str(datetime.day)
	if (1 == datetime.day or 21 == datetime.day or 31 == datetime.day):
		result += "st"
	elif (2 == datetime.day or 22 == datetime.day):
		result += "nd"
	elif (3 == datetime.day or 23 == datetime.day):
		result += "rd"
	else:
		result += "th"
	result += " "
	result += months[datetime.month]
	result += " "
	result += str(datetime.year)
	result += " (UTC)"
	return result

func _ready():
	$StatTree.set_column_expand(0, true)
	$StatTree.set_column_min_width(0, 2)
	$StatTree.set_column_expand(1, true)
	$StatTree.set_column_min_width(1, 3)

func add_row_to_StatTree(root, label, value):
	var row = $StatTree.create_item(root)
	row.set_text(0, label)
	row.set_text(1, value)

#Statistical Overview interface elements.
func refresh_statistical_overview():
	var sum_options = 0
	var sum_reactions = 0
	var sum_effects = 0
	var sum_words = 0
	var regex = RegEx.new()
	regex.compile("\\S+") # Negated whitespace character class.
	for x in storyworld.encounters:
		for y in x.options:
			for z in y.reactions:
				sum_effects += z.after_effects.size()
				sum_words += z.text_script.wordcount()
			sum_reactions += y.reactions.size()
			sum_words += y.text_script.wordcount()
		sum_options += x.options.size()
		sum_words += regex.search_all(x.title).size()
		sum_words += x.text_script.wordcount()
	for x in storyworld.characters:
		sum_words += regex.search_all(x.char_name).size()
	$StatTree.clear()
	var root = $StatTree.create_item()
	add_row_to_StatTree(root, "Title: ", storyworld.storyworld_title)
	add_row_to_StatTree(root, "Author: ", storyworld.storyworld_author)
	add_row_to_StatTree(root, "Creation Date: ", readable_date(storyworld.creation_time))
	add_row_to_StatTree(root, "Last Modified Date: ", readable_date(storyworld.modified_time))
	add_row_to_StatTree(root, "IFID: ", storyworld.ifid)
	add_row_to_StatTree(root, "Total number of encounters: ", str(storyworld.encounters.size()))
	add_row_to_StatTree(root, "Total number of options: ", str(sum_options))
	add_row_to_StatTree(root, "Total number of reactions: ", str(sum_reactions))
	add_row_to_StatTree(root, "Total number of effects: ", str(sum_effects))
	add_row_to_StatTree(root, "Total number of characters: ", str(storyworld.characters.size()))
	add_row_to_StatTree(root, "Total number of spools: ", str(storyworld.spools.size()))
	add_row_to_StatTree(root, "Total number of properties: ", str(storyworld.authored_properties.size()))
	add_row_to_StatTree(root, "Total number of words: ", str(sum_words))
