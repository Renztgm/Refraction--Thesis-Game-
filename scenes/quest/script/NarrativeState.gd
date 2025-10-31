extends Node

var flags: Dictionary = {}

func set_flag(key: String, value: bool):
	flags[key] = value

func get_flag(key: String) -> bool:
	return flags.get(key, false)
