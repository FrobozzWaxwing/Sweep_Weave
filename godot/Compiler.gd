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

func _init(game_data, storyworld_title, storyworld_author, ifid, storyworld_debug_mode_on, template = "res://custom_resources/encounter_engine.html"):
	file_to_read = template
	output = get_template_from_file()
	if (!storyworld_debug_mode_on):
		var regex = RegEx.new()
		regex.compile("\\s*console\\.log\\(.*\\);")
		output = regex.sub(output, "", true)
	if ("" != storyworld_title):
		output = output.replacen("<title>SweepWeave Storyworld Interpreter</title>", "<title>" + storyworld_title + "</title>")
	if ("" != storyworld_author):
		output = output.replacen("<meta name=\"author\" content=\"Anonymous\">", "<meta name=\"author\" content=\"" + storyworld_author + "\">")
	if ("" != ifid):
		output = output.replacen("<meta prefix=\"ifiction: http://babel.ifarchive.org/protocol/iFiction/\" property=\"ifiction:ifid\" content=\"\">", "<meta prefix=\"ifiction: http://babel.ifarchive.org/protocol/iFiction/\" property=\"ifiction:ifid\" content=\"" + ifid + "\">")
	output = output.replacen('<script type="text/javascript" src="storyworld_data.js"></script>', "<script>" + game_data.replacen("\\n", "<br>\\n") + "</script>")
