extends Control

var storyworld = null
#var current_project_path = ""

func refresh():
	$VBC/TitleEdit.text = storyworld.storyworld_title
	$VBC/AuthorEdit.text = storyworld.storyworld_author
	$VBC/SavePathDisplay.set_text("Current project save path: " + get_node("../../../../").current_project_path)
	$VBC/HBC1/IFIDDisplay.set_text("Storyworld IFID: " + storyworld.ifid)
	$VBC/HBC2/DBMSwitch.pressed = storyworld.storyworld_debug_mode_on
	match storyworld.storyworld_display_mode:
		0:
			$VBC/HBC3/DisplayModeSwitch.pressed = false
		1:
			$VBC/HBC3/DisplayModeSwitch.pressed = true

func log_update():
	#No arguments for this version of the function, as the settings screen never changes encounters or characters, and thus never needs to log an update on either type of object.
	storyworld.log_update()
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false

#Settings tab interface elements:
func _on_TitleEdit_text_changed(new_text):
	storyworld.storyworld_title = new_text
	log_update()

func _on_AuthorEdit_text_changed(new_text):
	storyworld.storyworld_author = new_text
	log_update()

func _on_DBMSwitch_toggled(button_pressed):
	if (button_pressed):
		storyworld.storyworld_debug_mode_on = true
	else:
		storyworld.storyworld_debug_mode_on = false
	log_update()

func _on_DisplayModeSwitch_toggled(button_pressed):
	if (button_pressed):
		storyworld.storyworld_display_mode = 1
	else:
		storyworld.storyworld_display_mode = 0
	log_update()

func _ready():
	pass

#GUI Themes:

func set_gui_theme(theme_name, background_color):
	pass

func _on_IFIDResetButton_pressed():
	$ConfirmIFIDReset.popup_centered()

func _on_ConfirmIFIDReset_confirmed():
	storyworld.ifid = IFIDGenerator.IFID_from_creation_time(storyworld.creation_time)
	$VBC/HBC1/IFIDDisplay.set_text("Storyworld IFID: " + storyworld.ifid)
	log_update()
