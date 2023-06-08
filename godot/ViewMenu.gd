extends MenuButton
var popup = get_popup()
var encounters_sub_menu = PopupMenu.new()
var play_sub_menu = PopupMenu.new()
var theme_sub_menu = PopupMenu.new()

signal menu_input(sub_menu, id, checked)

func _ready():
	#Encounter tab submenu:
	encounters_sub_menu.set_name("encounters_sub_menu")
	encounters_sub_menu.add_check_item("Encounter list")
	encounters_sub_menu.set_item_checked(0, true)
	encounters_sub_menu.add_check_item("Quick reaction script editor")
	encounters_sub_menu.set_item_checked(1, true)
	popup.add_child(encounters_sub_menu)
	popup.add_submenu_item("Encounters tab ", "encounters_sub_menu")
	encounters_sub_menu.connect("id_pressed", self, "_on_encounters_sub_menu_id_pressed")
	#Play tab submenu:
	play_sub_menu.set_name("play_sub_menu")
	play_sub_menu.add_check_item("Spoolbook")
	play_sub_menu.set_item_checked(0, true)
	popup.add_child(play_sub_menu)
	popup.add_submenu_item("Play tab ", "play_sub_menu")
	play_sub_menu.connect("id_pressed", self, "_on_play_sub_menu_id_pressed")
	#GUI theme submenu:
	theme_sub_menu.set_name("theme_sub_menu")
	theme_sub_menu.add_radio_check_item("Clarity")
	theme_sub_menu.add_radio_check_item("Lapis Lazuli")
	theme_sub_menu.set_item_checked(0, true)
	popup.add_child(theme_sub_menu)
	popup.add_submenu_item("GUI themes ", "theme_sub_menu")
	theme_sub_menu.connect("id_pressed", self, "_on_theme_sub_menu_id_pressed")
	#Other menu options:
	popup.add_item("Summary")

func _on_encounters_sub_menu_id_pressed(id):
	var check = !encounters_sub_menu.is_item_checked(id)
	encounters_sub_menu.set_item_checked(id, check)
	emit_signal("menu_input", "Encounters", id, check)

func _on_play_sub_menu_id_pressed(id):
	var check = !play_sub_menu.is_item_checked(id)
	play_sub_menu.set_item_checked(id, check)
	emit_signal("menu_input", "Play", id, check)

func _on_theme_sub_menu_id_pressed(id):
	for index in range(theme_sub_menu.get_item_count()):
		if (id == index):
			theme_sub_menu.set_item_checked(index, true)
		else:
			theme_sub_menu.set_item_checked(index, false)
	emit_signal("menu_input", "Themes", id, true)
