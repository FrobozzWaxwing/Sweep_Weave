extends OptionButton

func _ready():
	get_popup().add_item("Alphabetical")
	get_popup().add_item("Rev. Alphabetical")
	get_popup().add_item("Creation Time")
	get_popup().add_item("Rev. Creation Time")
	get_popup().add_item("Last Modified")
	get_popup().add_item("Rev. Last Modified")
#	get_popup().add_item("Earliest Turn")
#	get_popup().add_item("Rev. Earliest Turn")
#	get_popup().add_item("Latest Turn")
#	get_popup().add_item("Rev. Latest Turn")
	get_popup().add_item("Fewest Options")
	get_popup().add_item("Most Options")
	get_popup().add_item("Fewest Reactions")
	get_popup().add_item("Most Reactions")
	get_popup().add_item("Word Count")
	get_popup().add_item("Rev. Word Count")
