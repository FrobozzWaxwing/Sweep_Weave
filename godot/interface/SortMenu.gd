extends OptionButton

func _ready():
	var popup = get_popup()
	popup.add_item("Alphabetical")
	popup.add_item("Creation Time")
	popup.add_item("Modified Time")
	popup.add_item("Option Count")
	popup.add_item("Reaction Count")
	popup.add_item("Effect Count")
	popup.add_item("Characters")
	popup.add_item("Spools")
	popup.add_item("Word Count")
