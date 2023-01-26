extends Object
class_name ErrorReport

var reported_object = null
var reported_script = null
#enum sw_script_data_types {BOOLEAN, BNUMBER, STRING, VARIANT}
enum report_types {TEXT, ACCEPTABILITY, DESIRABILITY, VISIBILITY, PERFORMABILITY, EFFECT}
var script_type = null
var error_summary = ""
var error_details = ""

func _init(in_reported_object, in_reported_script, in_script_type, in_error_summary, in_error_details):
	reported_object = in_reported_object
	reported_script = in_reported_script
	script_type = in_script_type
	error_summary = in_error_summary
	error_details = in_error_details

func set_script_type(in_script_type):
	if (in_script_type.matchn("text")):
		script_type = report_types.TEXT
	elif (in_script_type.matchn("acceptability")):
		script_type = report_types.ACCEPTABILITY
	elif (in_script_type.matchn("desirability")):
		script_type = report_types.DESIRABILITY
	elif (in_script_type.matchn("visibility")):
		script_type = report_types.VISIBILITY
	elif (in_script_type.matchn("performability")):
		script_type = report_types.PERFORMABILITY
	elif (in_script_type.matchn("effect")):
		script_type = report_types.EFFECT
	else:
		script_type = null
