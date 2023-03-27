extends Object
class_name SWEffect

var cause = null #This could be, for example, a reaction.
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

func data_to_string():
	var result = "Set a variable to: "
	if (assignment_script is ScriptManager):
		result += assignment_script.data_to_string()
	else:
		result += "[invalid script]"
	result += "."
	return result

func get_listable_text(maximum_output_length = 50):
	var text = data_to_string()
	if (maximum_output_length >= text.length()):
		return text
	else:
		return text.left(maximum_output_length - 3) + "..."

func get_index():
	if (null != cause):
		return cause.after_effects.find(self)
	return -1
