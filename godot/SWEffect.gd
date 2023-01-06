extends Object
class_name SWEffect

var effect_type = "Generic Effect"

func _init():
	pass

func enact(leaf = null):
	return true #The effect was enacted successfully.
	#return false #An error occurred.

func clear():
	pass

func remap(to_storyworld):
	pass
