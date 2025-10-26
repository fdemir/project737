extends Node

var session_type: String

func _ready() -> void:
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.contains("="):
			var key_value = argument.split("=")
			arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.trim_prefix("--")] = ""
	if arguments.has("host"):
		get_window().title = "Host"
		Global.session_type = "Host"
	else:
		get_window().title = "Client"
		Global.session_type = "Client"
		
