# GameManager.gd (autoload recommended)
extends Node

var current_building: String = ""

func _ready():
	# Optionally auto-connect via code, or connect via editor
	pass

func _on_player_entered(building_name: String):
	current_building = building_name
	print("Player entered ", building_name)
	# e.g., switch camera, hide roof, change lighting, etc.

func _on_player_exited(building_name: String):
	if current_building == building_name:
		current_building = ""
		print("Player exited ", building_name)
		# restore outside visuals
