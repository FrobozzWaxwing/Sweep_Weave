extends Object
class_name Actor

var char_name = ""
var pronoun = ""
var Bad_Good = 0
var False_Honest = 0
var Timid_Dominant = 0
var pBad_Good = 0
var pFalse_Honest = 0
var pTimid_Dominant = 0

func _init(in_char_name, in_pronoun,
		   in_Bad_Good, in_False_Honest, in_Timid_Dominant,
		   in_pBad_Good, in_pFalse_Honest, in_pTimid_Dominant):
	char_name = in_char_name
	pronoun = in_pronoun
	Bad_Good = in_Bad_Good
	False_Honest = in_False_Honest
	Timid_Dominant = in_Timid_Dominant
	pBad_Good = in_pBad_Good
	pFalse_Honest = in_pFalse_Honest
	pTimid_Dominant = in_pTimid_Dominant

func compile():
	var result = {}
	result["name"] = char_name
	result["pronoun"] = pronoun
	result["Bad_Good"] = Bad_Good
	result["False_Honest"] = False_Honest
	result["Timid_Dominant"] = Timid_Dominant
	result["pBad_Good"] = pBad_Good
	result["pFalse_Honest"] = pFalse_Honest
	result["pTimid_Dominant"] = pTimid_Dominant
	return result
