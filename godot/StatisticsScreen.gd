extends VBoxContainer

var storyworld = null

func _ready():
	pass

#Statistical Overview interface elements.
func refresh_statistical_overview():
	var sum_options = 0
	var sum_reactions = 0
	var sum_words = 0
	var earliest_turn = 0
	var latest_turn = 0
	var regex = RegEx.new()
	regex.compile("\\S+") # Negated whitespace character class.
	for x in storyworld.encounters:
		for y in x.options:
			for z in y.reactions:
				sum_words += regex.search_all(z.text).size()
			sum_reactions += y.reactions.size()
			sum_words += regex.search_all(y.text).size()
		sum_options += x.options.size()
		sum_words += regex.search_all(x.title).size()
		sum_words += regex.search_all(x.main_text).size()
		if (x.earliest_turn < earliest_turn):
			earliest_turn = x.earliest_turn
		if (x.latest_turn > latest_turn):
			latest_turn = x.latest_turn
	for x in storyworld.characters:
		sum_words += regex.search_all(x.char_name).size()
	$StatEncounters.text = "Total number of encounters: " + str(storyworld.encounters.size())
	$StatOptions.text = "Total number of options: " + str(sum_options)
	$StatReactions.text = "Total number of reactions: " + str(sum_reactions)
	$StatCharacters.text = "Total number of characters: " + str(storyworld.characters.size())
	$StatWords.text = "Total number of words: " + str(sum_words)
	$StatEarliestTurn.text = "Earliest Turn: " + str(earliest_turn)
	$StatLatestTurn.text = "Latest Turn: " + str(latest_turn)

func _on_RefreshStats_pressed():
	refresh_statistical_overview()
