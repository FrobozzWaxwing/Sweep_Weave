extends Control

var storyworld = null
var language_codes = {} #Used to quickly convert codes to indices.

func _ready():
	#Load data from file:
	var path = "res://custom_resources/iso_language_codes.json"
	var file = File.new()
	file.open(path, File.READ)
	var file_text = file.get_as_text()
	file.close()
	var language_code_dictionary = JSON.parse(file_text).result
	#Fill language options:
	var edit_button = $Scroll/VBC/LanguageEdit
	var index = 0
	for language in language_code_dictionary:
		edit_button.add_item(language["language"])
		edit_button.set_item_metadata(index, language["code"])
		language_codes[language["code"]] = index
		index += 1
	#Fill rating options:
	$Scroll/VBC/RatingEdit.add_item("general")
	$Scroll/VBC/RatingEdit.add_item("adult")
	$Scroll/VBC/RatingEdit.add_item("safe for kids")
	#Fill theme options:
	$Scroll/VBC/ThemeEdit.add_item("lilac")
	$Scroll/VBC/ThemeEdit.add_item("nightshade")
	#Fill font size options:
	$Scroll/VBC/FontEdit.add_item("14")
	$Scroll/VBC/FontEdit.add_item("16")
	$Scroll/VBC/FontEdit.add_item("18")
	$Scroll/VBC/FontEdit.add_item("20")

func refresh():
	$Scroll/VBC/TitleEdit.set_text(storyworld.storyworld_title)
	$Scroll/VBC/AuthorEdit.set_text(storyworld.storyworld_author)
	$Scroll/VBC/AboutTextEdit.set_text(storyworld.get_about_text())
	$Scroll/VBC/MetaDescriptionEdit.set_text(storyworld.meta_description)
	var language_code_index = language_codes[storyworld.language]
	if (language_code_index < $Scroll/VBC/LanguageEdit.get_item_count()):
		$Scroll/VBC/LanguageEdit.select(language_code_index)
	match storyworld.rating:
		"general":
			$Scroll/VBC/RatingEdit.select(0)
		"adult":
			$Scroll/VBC/RatingEdit.select(1)
		"safe for kids":
			$Scroll/VBC/RatingEdit.select(2)
	match storyworld.css_theme:
		"lilac":
			$Scroll/VBC/ThemeEdit.select(0)
		"nightshade":
			$Scroll/VBC/ThemeEdit.select(1)
	match storyworld.font_size:
		"14":
			$Scroll/VBC/FontEdit.select(0)
		"16":
			$Scroll/VBC/FontEdit.select(1)
		"18":
			$Scroll/VBC/FontEdit.select(2)
		"20":
			$Scroll/VBC/FontEdit.select(3)
	$Scroll/VBC/HBC1/IFIDDisplay.set_text("Storyworld IFID: " + storyworld.ifid)
	$Scroll/VBC/HBC2/DBMSwitch.pressed = storyworld.storyworld_debug_mode_on
	match storyworld.storyworld_display_mode:
		0:
			$Scroll/VBC/HBC3/DisplayModeSwitch.pressed = false
		1:
			$Scroll/VBC/HBC3/DisplayModeSwitch.pressed = true
	$Scroll/VBC/SavePathDisplay.set_text("Current project save path: " + get_node("../../../../").current_project_path)

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

func _on_AboutTextEdit_text_changed():
	storyworld.set_about_text($Scroll/VBC/AboutTextEdit.get_text())
	log_update()

func _on_MetaDescriptionEdit_text_changed(new_text):
	storyworld.meta_description = new_text
	log_update()

func _on_LanguageEdit_item_selected(index):
	storyworld.language = $Scroll/VBC/LanguageEdit.get_item_metadata(index)
	log_update()

func _on_RatingEdit_item_selected(index):
	storyworld.rating = $Scroll/VBC/RatingEdit.get_item_text(index)
	log_update()

func _on_ThemeEdit_item_selected(index):
	storyworld.css_theme = $Scroll/VBC/ThemeEdit.get_item_text(index)
	log_update()

func _on_FontEdit_item_selected(index):
	storyworld.font_size = $Scroll/VBC/FontEdit.get_item_text(index)
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

func _on_IFIDResetButton_pressed():
	$ConfirmIFIDReset.popup_centered()

func _on_ConfirmIFIDReset_confirmed():
	storyworld.ifid = IFIDGenerator.IFID_from_creation_time(storyworld.creation_time)
	$Scroll/VBC/HBC1/IFIDDisplay.set_text("Storyworld IFID: " + storyworld.ifid)
	log_update()

#GUI Themes:

func set_gui_theme(theme_name, background_color):
	pass
