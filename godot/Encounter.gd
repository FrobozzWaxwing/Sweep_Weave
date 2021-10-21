extends Object
class_name Encounter

#id, title, main_text, prerequisites, disqualifiers, earliest_turn, latest_turn, antagonist, options, creation_index, creation_time, modified_time, graph_position, word_count

var id = ""
var title = ""
var main_text = ""
var prerequisites = []
var desiderata = []
var earliest_turn = 0
var latest_turn = 1000
var antagonist = null
var options = []

#Variables for editor:
var creation_index = 0
var creation_time = OS.get_unix_time()
var modified_time = OS.get_unix_time()
var graph_position = Vector2(40, 40)
var word_count = 0
var graphview_node = null

func _init(in_id, in_title, in_main_text, in_earliest_turn, in_latest_turn, in_antagonist, in_options,
		   in_creation_index, in_creation_time = OS.get_unix_time(), in_modified_time = OS.get_unix_time(), in_graph_position = Vector2(40, 40), in_word_count = 0):
	id = in_id
	title = in_title
	main_text = in_main_text
	earliest_turn = in_earliest_turn
	latest_turn = in_latest_turn
	antagonist = in_antagonist
	options = in_options
	creation_index = in_creation_index
	creation_time = in_creation_time
	modified_time = in_modified_time
	graph_position = in_graph_position
	word_count = in_word_count

func wordcount():
	var sum_words = 0
	var regex = RegEx.new()
	regex.compile("\\S+") # Negated whitespace character class.
	#I initially intended to make this a recursive algorithm,
	#but I'm not sure whether or not compiling multiple copies of the same regex would slow down the function too much.
	for y in options:
		for z in y.reactions:
			sum_words += regex.search_all(z.text).size()
		sum_words += regex.search_all(y.text).size()
	sum_words += regex.search_all(title).size()
	sum_words += regex.search_all(main_text).size()
	word_count = sum_words
	return sum_words

func compile(characters, include_editor_only_variables = false):
	var result = {}
	result["id"] = id
	result["title"] = title
	result["main_text"] = main_text
	result["prerequisites"] = []
	for each in prerequisites:
		result["prerequisites"].append(each.compile())
	result["desiderata"] = []
	for each in desiderata:
		result["desiderata"].append(each.compile(characters))
	result["earliest_turn"] = earliest_turn
	result["latest_turn"] = latest_turn
	result["antagonist"] = characters.find(antagonist)
	#print(characters.find(antagonist))
	result["options"] = []
	for each in options:
		result["options"].append(each.compile(characters, include_editor_only_variables))
	if (include_editor_only_variables):
		#Editor only variables:
		result["creation_index"] = creation_index
		result["creation_time"] = creation_time
		result["modified_time"] = modified_time
		result["graph_position_x"] = graph_position.x
		result["graph_position_y"] = graph_position.y
		result["word_count"] = wordcount()
	return result
