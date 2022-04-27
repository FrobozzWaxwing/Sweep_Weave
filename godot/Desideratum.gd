extends Object
class_name Desideratum

var character = null
var pValue = ""
var point = 0

func _init(in_character, in_pValue, in_point):
	character = in_character
	pValue = in_pValue
	point = in_point

func summarize():
	var output = ""
	output += character.char_name + " / " + pValue + " / " + str(point)
	return output

func explain_pValue_change():
	var output = ""
	if (0 == point):
		output += "Leave (" + character.char_name + ")." + pValue + " the same."
	elif (0 < point):
		var percentage = point * 100
		output += "Increase (" + character.char_name + ")." + pValue + " " + str(percentage) + "% of the distance from its present value to 1."
	else:
		var percentage = point * 100
		output += "Decrease (" + character.char_name + ")." + pValue + " " + str(percentage) + "% of the distance from its present value to -1."
	return output

func sign_and_pValue():
	if (0 <= point):
		return pValue
	else:
		return "-" + pValue

func compile(character_list):
	var output = {}
	output["character"] = character_list.find(character)
	output["pValue"] = pValue
	output["point"] = point
	return output

func set_as_copy_of(original):
	character = original.character
	pValue = original.pValue
	point = original.point

func data_to_string():
	var result = "Character: ("
	if (null != character):
		result += character.char_name
	else:
		result += "null"
	result += ") Key: (" + pValue + ") Point: (" + str(point) + ")"
	return result
