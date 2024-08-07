extends Control

var sweepweave_version_number = ""
var station = "https://www.sweepweave.org/sw_broadcast/"
var user_agent = ""

func _ready():
	pass

func refresh():
	$VBC/WebText.clear()
	$VBC/WebText.append_text("Checking for updates...")
	user_agent = "user-agent: (" + OS.get_name() + ") SweepWeave/" + sweepweave_version_number
	$HTTPRequest.request("https://www.sweepweave.org/sw_broadcast/sweepweave_version_report.json", [user_agent])

func _on_HTTPRequest_request_completed(result, _response_code, _headers, body):
	var report = null
	if (result == HTTPRequest.RESULT_SUCCESS):
		var json_parser = JSON.new()
		var parse_result = json_parser.parse(body.get_string_from_utf8())
		if (parse_result == OK):
			report = json_parser.get_data()
		else:
			var error_message = "JSON Parse Error: " + json_parser.get_error_message() + " at line " + str(json_parser.get_error_line())
			print (error_message)
	$VBC/WebText.clear()
	if (null == report):
		if ("https://www.sweepweave.org/sw_broadcast/" == station):
			print("Error: Failed to obtain sweepweave version report from www.sweepweave.org. Checking www.emptiestvoid.com.")
			station = "https://www.emptiestvoid.com/sw_broadcast/"
			$HTTPRequest.request("https://www.emptiestvoid.com/sw_broadcast/sweepweave_version_report.json", [user_agent])
		elif ("https://www.emptiestvoid.com/sw_broadcast/" == station):
			$VBC/WebText.append_text("Failed to obtain sweepweave version report. Please try again later, or visit www.sweepweave.org for news regarding updates to SweepWeave.")
			print("Error: Failed to obtain sweepweave version report from www.emptiestvoid.com.")
			station = "https://www.sweepweave.org/sw_broadcast/"
	else:
		station = "https://www.sweepweave.org/sw_broadcast/"
		if (report.has("latest_stable_version")):
			if (sweepweave_version_number == report["latest_stable_version"]):
				$VBC/WebText.append_text("You currently have the latest stable version of SweepWeave.")
			else:
				$VBC/WebText.append_text("Latest stable version: " + report["latest_stable_version"])
		else:
			$VBC/WebText.append_text("Error: Could not determine latest stable version number.")

func _on_DownloadButton_pressed():
	OS.shell_open("https://github.com/FrobozzWaxwing/Sweep_Weave/releases")
