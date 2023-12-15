extends OptionButton

var keyring_index = 0

signal keyring_change_requested(keyring_index, option_index, metadata)

func _ready():
	pass

func _on_KeyringOptionButton_item_selected(index):
	#Metadata contains either a character or a bounded number property name.
	var metadata = get_item_metadata(index)
	emit_signal("keyring_change_requested", keyring_index, index, metadata)
