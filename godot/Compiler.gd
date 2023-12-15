extends Object
class_name Compiler

var file_to_read = ""
var output = ""
var ifid = ""

#File reading:
func get_template_from_file():
	var html_content = ""
	var error_message = "Error: " + file_to_read + " file does not exist."
	var file = File.new()
	if (file.file_exists(file_to_read)):
		var error = file.open(file_to_read, File.READ)
		if (error == OK):
			print("Using template: " + file_to_read)
			html_content = file.get_as_text()
		else:
			print("Error opening the file: " + file_to_read)
		file.close()
	else:
		print(error_message)
	return html_content

func _init(game_data, storyworld, template = "res://custom_resources/encounter_engine.html"):
	file_to_read = template
	output = get_template_from_file()
	if (!storyworld.storyworld_debug_mode_on):
		var regex = RegEx.new()
		regex.compile("\\s*console\\.log\\(.*\\);")
		output = regex.sub(output, "", true)
	if ("" != storyworld.language):
		output = output.replacen("<html>", '<html lang="' + storyworld.language + '">')
	var meta = ""
	if ("" == storyworld.storyworld_title):
		meta += "<title>An Interactive Storyworld</title>"
	else:
		meta += "<title>" + storyworld.storyworld_title + "</title>"
	if ("" == storyworld.storyworld_author):
		meta += '<meta name="author" content="Anonymous">"'
	else:
		meta += '<meta name="author" content="' + storyworld.storyworld_author + '">'
	if ("" != storyworld.ifid):
		meta += '<meta prefix="ifiction: http://babel.ifarchive.org/protocol/iFiction/" property="ifiction:ifid" content="' + storyworld.ifid + '">'
	if ("" != storyworld.sweepweave_version_number):
		meta += '<meta name="generator" content="SweepWeave ' + storyworld.sweepweave_version_number + '">'
	if ("" != storyworld.meta_description):
		meta += '<meta name="description" content="' + storyworld.meta_description + '">'
	if ("" != storyworld.rating):
		meta += '<meta name="rating" content="' + storyworld.rating + '">'
	output = output.replacen("<!-- Storyworld Metadata -->", meta)
	output = output.replacen('<script type="text/javascript" src="storyworld_data.js"></script>', "<script>" + game_data.replacen("\\n", "<br>\\n") + "</script>")
