extends Object
class_name DocChapter

var title = ""
var pages = []

func _init(in_title = ""):
	title = in_title

func clear():
	title = ""
	for page in pages:
		page.clear()
		page.call_deferred("free")

func compile():
	var output = {}
	output["title"] = title
	output["pages"] = []
	for page in pages:
		output["pages"].append(page.compile())
	return output

func display_title():
	if ("" != title):
		return title
	else:
		return "[Untitled Chapter]"
