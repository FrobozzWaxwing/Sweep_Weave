extends Object
class_name DocSection
#Each section constitutes a part of a page, containing text and / or illustrations. Illustrations consist of specially made scenes, such as trees, and can be interactive, allowing an author to create an explorable explanation for use as documentation.

var page = null
var id = ""
var title = ""
var text = ""
var illustration = null #Integer or null value. For a section without an illustration, set this to null.

func _init(in_page, in_id = "", in_title = "", in_text = "", in_illustration = null):
	page = in_page
	if ("" == in_id):
		id = UUID.v4().left(8)
	else:
		id = in_id
	title = in_title
	text = in_text
	illustration = in_illustration

func compile():
	var output = {}
	output["id"] = id
	output["title"] = title
	output["text"] = text
	output["illustration"] = illustration
	return output

func display_title():
	if ("" != title):
		return title
	else:
		return "[Untitled Section]"
