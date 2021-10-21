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

func compile(character_list):
	var output = {}
	output["character"] = character_list.find(character)
	output["pValue"] = pValue
	output["point"] = point
	return output
