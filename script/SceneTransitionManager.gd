# SceneTransitionManager.gd
extends Node

# Singleton/Autoload script for handling scene transitions with loading screen
signal scene_transition_started
signal scene_transition_finished

var loading_screen_scene: PackedScene = preload("res://scenes/UI/LoadingScreen.tscn")
var loading_screen_instance: Node = null
var target_scene_path: String = ""

func transition_to_scene(scene_path: String):
	"""Main function to transition to a new scene with loading screen"""
	print("=== TRANSITION START ===")
	print("Target scene: ", scene_path)
	
	if scene_path.is_empty():
		print("Error: Scene path is empty")
		return
	
	target_scene_path = scene_path
	scene_transition_started.emit()
	
	# Show loading screen
	show_loading_screen()
	print("Loading screen should be visible now")
	
	# Small delay to ensure loading screen appears
	await get_tree().process_frame
	
	# Load the target scene with 3 second delay
	await load_scene_with_delay()

func show_loading_screen():
	"""Display the loading screen"""
	print("Attempting to show loading screen...")
	
	if loading_screen_instance:
		print("Cleaning up existing loading screen")
		loading_screen_instance.queue_free()
	
	print("Loading screen scene: ", loading_screen_scene)
	loading_screen_instance = loading_screen_scene.instantiate()
	print("Loading screen instance created: ", loading_screen_instance)
	
	get_tree().root.add_child(loading_screen_instance)
	print("Loading screen added to scene tree")
	
	# Move loading screen to front
	if loading_screen_instance is CanvasItem:
		loading_screen_instance.z_index = 100
		print("Set z_index to 100")
	else:
		print("Warning: Loading screen is not a CanvasItem, z_index not set")

func load_scene_with_delay():
	"""Load the target scene but ensure loading screen shows for at least 3 seconds"""
	var start_time = Time.get_ticks_msec()
	var loading_complete = false
	var packed_scene = null
	
	# Check if target scene exists first
	if not ResourceLoader.exists(target_scene_path):
		print("ERROR: Target scene does not exist: ", target_scene_path)
		hide_loading_screen()
		return
	
	# Try to load the scene directly first (simpler approach)
	packed_scene = ResourceLoader.load(target_scene_path)
	if not packed_scene:
		print("ERROR: Could not load target scene: ", target_scene_path)
		hide_loading_screen()
		return
	
	loading_complete = true
	print("Scene loaded successfully, waiting for 3 second timer...")
	
	# Wait for 3 seconds minimum
	while true:
		var elapsed_time = (Time.get_ticks_msec() - start_time) / 1000.0
		
		# Update loading screen progress
		if loading_screen_instance and loading_screen_instance.has_method("update_progress"):
			var display_progress = min(elapsed_time / 3.0, 1.0)
			loading_screen_instance.update_progress(display_progress)
		
		# Wait for 3 second minimum time
		if elapsed_time >= 3.0:
			print("3 seconds completed, changing scene...")
			change_to_scene(packed_scene)
			break
		
		await get_tree().process_frame

func change_to_scene(packed_scene: PackedScene):
	"""Change to the loaded scene and cleanup"""
	hide_loading_screen()
	get_tree().change_scene_to_packed(packed_scene)
	scene_transition_finished.emit()

func hide_loading_screen():
	"""Remove the loading screen"""
	if loading_screen_instance:
		loading_screen_instance.queue_free()
		loading_screen_instance = null
