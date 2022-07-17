extends MenuButton

func _ready():
	get_popup().add_item("About")
	get_popup().add_item("New Storyworld")
	get_popup().add_item("Open")
	get_popup().add_item("Import from Storyworld")
#	get_popup().add_item("Import from XML")
	get_popup().add_item("Save")
	get_popup().add_item("Save As")
	get_popup().add_item("Compile to HTML")
	get_popup().add_item("Compile and Playtest")
	get_popup().add_item("Quit")
