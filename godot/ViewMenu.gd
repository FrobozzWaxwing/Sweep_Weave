extends MenuButton
var popup = get_popup()
var encounters_sub_menu = PopupMenu.new()
var play_sub_menu = PopupMenu.new()

signal menu_input(tab, id, checked)

func _ready():
	#Encounter tab submenu:
	encounters_sub_menu.set_name("encounters_sub_menu")
	encounters_sub_menu.add_check_item("Encounter list")
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
