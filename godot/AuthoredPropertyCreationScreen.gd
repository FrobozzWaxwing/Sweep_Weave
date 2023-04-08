extends Control

var storyworld = null
#var current_authored_property = null
var authored_properties_to_delete = []
enum possible_attribution_targets {STORYWORLD, CAST_MEMBERS, ENTIRE_CAST}

signal refresh_authored_property_lists()

func _ready():
	$ColorRect/VBC/HBC/BNumberEditPanel.connect("bnumber_property_name_changed", self, "refresh_property_name")
	$ColorRect/VBC/HBC/BNumberEditPanel.connect("affected_character_added", self, "on_character_properties_changed")
	$ColorRect/VBC/HBC/BNumberEditPanel.connect("affected_character_removed", self, "on_character_properties_changed")

func log_update(property = null):
	if (null != property):
		property.log_update()
	storyworld.log_update()
	OS.set_window_title("SweepWeave - " + storyworld.storyworld_title + "*")
	storyworld.project_saved = false

func load_authored_property(property_blueprint):
	$ColorRect/VBC/HBC/BNumberEditPanel.storyworld = storyworld
	$ColorRect/VBC/HBC/BNumberEditPanel.current_authored_property = property_blueprint
	$PropertyCreationWindow/VBC/BNumberEditPanel.creating_new_property = false
	$ColorRect/VBC/HBC/BNumberEditPanel.refresh()
	if (!storyworld.authored_properties.empty()):
		$ColorRect/VBC/HBC/VBC/PropertyList.select(storyworld.authored_properties.find(property_blueprint))

func refresh_property_list():
	$ColorRect/VBC/HBC/VBC/PropertyList.clear()
	var item_index = 0
	for property_blueprint in storyworld.authored_properties:
		$ColorRect/VBC/HBC/VBC/PropertyList.add_item(property_blueprint.get_property_name())
		$ColorRect/VBC/HBC/VBC/PropertyList.set_item_metadata(item_index, property_blueprint)
		item_index += 1
	if (!storyworld.authored_properties.empty()):
		load_authored_property(storyworld.authored_properties.front())

func refresh_property_name(property_blueprint):
	var index = storyworld.authored_properties.find(property_blueprint)
	if (property_blueprint == $ColorRect/VBC/HBC/VBC/PropertyList.get_item_metadata(index)):
		$ColorRect/VBC/HBC/VBC/PropertyList.set_item_text(index, property_blueprint.get_property_name())
	else:
		refresh_property_list()
	emit_signal("refresh_authored_property_lists")

func _on_AddButton_pressed():
	var index = storyworld.unique_id_seeds["authored_property"]
	#A new property id will be created if and when the author confirms creation of the new property.
	var draft_of_new_authored_property = BNumberBlueprint.new(storyworld, index, "", "", 0, 0)
	$PropertyCreationWindow/VBC/BNumberEditPanel.storyworld = storyworld
	$PropertyCreationWindow/VBC/BNumberEditPanel.current_authored_property = draft_of_new_authored_property
	$PropertyCreationWindow/VBC/BNumberEditPanel.creating_new_property = true
	$PropertyCreationWindow/VBC/BNumberEditPanel.refresh()
	$PropertyCreationWindow.popup_centered()

func _on_PropertyCreationWindow_confirmed():
	var property = $PropertyCreationWindow/VBC/BNumberEditPanel.current_authored_property
	if (property.attribution_target == property.possible_attribution_targets.CAST_MEMBERS and 0 == property.affected_characters.size()):
		print ("Cannot create a property that does not apply to any characters.")
		return
	var id = storyworld.unique_id("authored_property")
	property.id = id
	storyworld.add_authored_property(property)
	log_update(property)
	refresh_property_list()
	load_authored_property(property)
	emit_signal("refresh_authored_property_lists")

func _on_DeleteButton_pressed():
	#Clear window.
	var nodes_to_delete = $ConfirmPropertyDeletionWindow/VBC.get_children()
	for each in nodes_to_delete:
		each.call_deferred('free')
	#Refill window.
	var new_label = Label.new()
	var selected_indices = $ColorRect/VBC/HBC/VBC/PropertyList.get_selected_items()
	authored_properties_to_delete.clear()
	if (0 == selected_indices.size()):
		#No properties are currently selected.
		new_label.text = "No properties are currently selected."
		$ConfirmPropertyDeletionWindow/VBC.add_child(new_label)
	elif (storyworld.authored_properties.size() == selected_indices.size()):
		#Cannot delete all properties from storyworld. Hopefully later versions of SweepWeave will allow for this, though.
		new_label.text = "You cannot delete all authored properties from your storyworld."
		$ConfirmPropertyDeletionWindow/VBC.add_child(new_label)
	elif (1 == selected_indices.size()):
		var property_blueprint = $ColorRect/VBC/HBC/VBC/PropertyList.get_item_metadata(selected_indices[0])
		new_label.text = "Are you sure that you want to remove the \"" + property_blueprint.get_property_name() + "\" property from your storyworld?"
		$ConfirmPropertyDeletionWindow/VBC.add_child(new_label)
		authored_properties_to_delete.append(property_blueprint)
	else:
		new_label.text = "Are you sure that you want to remove the following authored properties? This will delete these properties from all characters and scripts."
		$ConfirmPropertyDeletionWindow/VBC.add_child(new_label)
		for index in selected_indices:
			var property_blueprint = $ColorRect/VBC/HBC/VBC/PropertyList.get_item_metadata(index)
			authored_properties_to_delete.append(property_blueprint)
			new_label = Label.new()
			new_label.text = property_blueprint.get_property_name()
			$ConfirmPropertyDeletionWindow/VBC.add_child(new_label)
	#	new_label = Label.new()
	#	new_label.text = "If you want to delete these properties, please select another property to replace them with in those scripts that currently use them."
	#	$ConfirmPropertyDeletionWindow/VBC.add_child(new_label)
	$ConfirmPropertyDeletionWindow.popup_centered()

func _on_ConfirmPropertyDeletionWindow_confirmed():
	if (0 == authored_properties_to_delete.size()):
		return
	#Put together a replacement bounded number pointer.
	var replacement_property = null
	var new_keyring = []
	for property in storyworld.authored_properties:
		if (property is BNumberBlueprint):
			if (authored_properties_to_delete.has(property)):
				continue
			else:
				replacement_property = property
				new_keyring.append(property.id)
				break
	if (null == replacement_property or !(replacement_property is BNumberBlueprint)):
		#An error has occurred. One cannot delete every property from a storyworld.
		return
	if (storyworld.characters.empty()):
		return
	#Build replacement pointer.
	var replacement = null
	if (replacement_property.possible_attribution_targets.ENTIRE_CAST == replacement_property.attribution_target):
		for layer in range(replacement_property.depth):
			new_keyring.append(storyworld.characters[0].id)
		replacement = BNumberPointer.new(storyworld.characters[0], new_keyring.duplicate(true))
	elif (replacement_property.possible_attribution_targets.CAST_MEMBERS == replacement_property.attribution_target):
		if (replacement_property.affected_characters.empty()):
			print ("Error when creating default bnumber pointer: chosen property has no affected characters.")
			return
		var character = replacement_property.affected_characters[0]
		for layer in range(replacement_property.depth):
			new_keyring.append(character.id)
		replacement = BNumberPointer.new(character, new_keyring.duplicate(true))
	#Replace property references with pointer.
	for property_blueprint in authored_properties_to_delete:
		print ("Replacing " + property_blueprint.get_property_name() + " with " + replacement.data_to_string() + ".")
		#Search scripts and replace the properties that we're deleting with the replacement pointer.
		for encounter in storyworld.encounters:
			encounter.acceptability_script.replace_property_with_pointer(property_blueprint, replacement)
			encounter.desirability_script.replace_property_with_pointer(property_blueprint, replacement)
			for option in encounter.options:
				option.visibility_script.replace_property_with_pointer(property_blueprint, replacement)
				option.performability_script.replace_property_with_pointer(property_blueprint, replacement)
				for reaction in option.reactions:
					reaction.desirability_script.replace_property_with_pointer(property_blueprint, replacement)
					print (reaction.desirability_script.data_to_string())
					for effect in reaction.after_effects:
						if (effect is BNumberEffect):
							if (effect.assignee.get_ap_blueprint().id == property_blueprint.id):
								effect.assignee.set_as_copy_of(replacement)
							effect.assignment_script.replace_property_with_pointer(property_blueprint, replacement)
						elif (effect is SpoolEffect):
							effect.assignment_script.replace_property_with_pointer(property_blueprint, replacement)
		#Delete property.
		storyworld.delete_authored_property(property_blueprint)
	#Update interface.
	log_update()
	refresh_property_list()
	emit_signal("refresh_authored_property_lists")

func _on_PropertyList_item_selected(index):
	var property_blueprint = $ColorRect/VBC/HBC/VBC/PropertyList.get_item_metadata(index)
	load_authored_property(property_blueprint)

func on_character_properties_changed(property, character):
	emit_signal("refresh_authored_property_lists")

#GUI Themes:

onready var add_icon_light = preload("res://custom_resources/add_icon.svg")
onready var add_icon_dark = preload("res://custom_resources/add_icon_dark.svg")
onready var delete_icon_light = preload("res://custom_resources/delete_icon.svg")
onready var delete_icon_dark = preload("res://custom_resources/delete_icon_dark.svg")

func set_gui_theme(theme_name, background_color):
	$ColorRect.color = background_color
	$ColorRect/VBC/ColorRect.color = background_color
	$ColorRect/VBC/HBC/BNumberEditPanel.set_gui_theme(theme_name, background_color)
	$PropertyCreationWindow/VBC/BNumberEditPanel.set_gui_theme(theme_name, background_color)
	match theme_name:
		"Clarity":
			$ColorRect/VBC/HBC/VBC/HBC/AddButton.icon = add_icon_dark
			$ColorRect/VBC/HBC/VBC/HBC/DeleteButton.icon = delete_icon_dark
		"Lapis Lazuli":
			$ColorRect/VBC/HBC/VBC/HBC/AddButton.icon = add_icon_light
			$ColorRect/VBC/HBC/VBC/HBC/DeleteButton.icon = delete_icon_light
