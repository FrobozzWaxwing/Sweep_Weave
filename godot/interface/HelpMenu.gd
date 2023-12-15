extends MenuButton

func _ready():
	get_popup().add_item("About")
	get_popup().add_item("Validate and Troubleshoot")
	get_popup().add_item("Check for Updates")
