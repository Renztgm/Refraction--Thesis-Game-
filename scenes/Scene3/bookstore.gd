# EntranceArea.gd
extends Area3D

@export var target_scene: String = "res://scenes/Scene3/Bookstore.tscn"

func _ready():
	body_entered.connect(_on_body_entered)
	# Debug: Check if target scene exists
	print("Checking if target scene exists: ", target_scene)
	print("Scene exists: ", ResourceLoader.exists(target_scene))

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Player entered building -> switching to scene: ", target_scene)
		
		# Check if the target scene exists before trying to transition
		if not ResourceLoader.exists(target_scene):
			print("ERROR: Target scene does not exist at path: ", target_scene)
			print("Please check the file path in the FileSystem dock")
			return
		
		SceneTransitionManager.transition_to_scene(target_scene)
