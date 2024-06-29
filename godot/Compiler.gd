extends Object
class_name Compiler

var template_path = ""
var output = ""
var ifid = ""

#File reading:
func get_template_from_file():
	var html_content = ""
	if not FileAccess.file_exists(template_path):
		print("Could not find template.")
		return # Error: File not found.
	var file = FileAccess.open(template_path, FileAccess.READ)
	if (null == file):
		print("Error opening template.")
	else:
		html_content = file.get_as_text()
		file.close()
	return html_content

func _init(game_data, storyworld, in_template_path = "res://custom_resources/encounter_engine.html"):
	template_path = in_template_path
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
