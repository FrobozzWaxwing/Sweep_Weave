extends Object
class_name DocPage

var chapter = null
var id = ""
var title = ""
var sections = []

func _init(in_chapter, in_id = "", in_title = ""):
	chapter = in_chapter
	if ("" == in_id):
		id = UUID.v4().left(8)
	else:
		id = in_id
	title = in_title

func clear():
	chapter = null
	id = ""
	title = ""
	for section in sections:
		section.call_deferred("free")

func compile():
	var output = {}
	output["id"] = id
	output["title"] = title
	output["sections"] = []
	for section in sections:
		output["sections"].append(section.compile())
	return output

func display_title():
	if ("" != title):
		return title
	else:
		return "[Untitled Page]"

