extends MenuButton

#One can add " (Temporarily disabled.)" to a menu item to disable it.

func _ready():
	get_popup().add_item("New Storyworld")
	get_popup().add_item("Open")
#	get_popup().add_item("Import from Storyworld")
	get_popup().add_item("Save")
	get_popup().add_item("Save As")
	get_popup().add_item("Compile to HTML")
	get_popup().add_item("Compile and Playtest")
	get_popup().add_item("Export as txt")
	get_popup().add_item("Quit")
