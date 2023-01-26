extends Object
class_name SWEffect

var effect_type = "Generic Effect"
var assignee = null
var assignment_script = null

func _init():
	pass

func enact(leaf = null):
	return true #The effect was enacted successfully.
	#return false #An error occurred.

func clear():
	if (assignee is SWScriptElement):
		assignee.clear()
		assignee.call_deferred("free")
	assignee = null
	if (assignment_script is ScriptManager):
		assignment_script.clear()
		assignment_script.call_deferred("free")
	assignment_script = null

func remap(to_storyworld):
	pass
