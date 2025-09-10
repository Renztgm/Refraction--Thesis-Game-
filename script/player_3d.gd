extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = $Camera_Mount/Visual/AnimatedSprite3D
@onready var camera_mount: Node3D = $Camera_Mount
@onready var camera_3d: Camera3D = $Camera_Mount/Camera3D
@onready var pause_menu: Control = get_node_or_null("../PauseMenu")

@onready var audio_manager = get_node("/root/Main/AudioManager")

var last_direction: String = "down"
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var can_move: bool = true  
const CAMERA_COLLISION_LAYERS = 1
const MIN_CAMERA_DISTANCE = 0.5
var original_camera_position: Vector3
var camera_collision_mask = 0xFFFFFFFF

func _ready():
	add_to_group("player")
	
	# -----------------------------
	# 1️⃣ Determine if we're continuing a saved game
	# -----------------------------
	var continuing_game := false
	if SaveManager.has_save_file() and SaveManager.is_continuing_game:
		continuing_game = true

	# -----------------------------
	# 2️⃣ Set player position and direction
	# -----------------------------
	if continuing_game:
		var saved_pos = SaveManager.get_saved_player_position()
		var saved_dir = SaveManager.get_saved_player_direction()
		if saved_pos != Vector3.ZERO:
			position = saved_pos
			last_direction = saved_dir
			print("Player loaded from save:", position, "| Direction:", last_direction)
	else:
		# Use scene's spawn point (Marker3D)
		var spawn_point = $SpawnPoint
		if spawn_point:
			position = spawn_point.global_position
			print("Player spawned at scene spawn point:", position)
		else:
			print("⚠️ No spawn point found! Using default position:", position)

	# -----------------------------
	# 3️⃣ Camera setup
	# -----------------------------
	if camera_3d:
		original_camera_position = camera_3d.position

	# -----------------------------
	# 4️⃣ Pause menu
	# -----------------------------
	if not pause_menu:
		print("Warning: Pause menu not found. Trying alternative path...")
		pause_menu = get_tree().get_first_node_in_group("pause_menu")
	if pause_menu:
		print("Pause menu found!")

	# -----------------------------
	# 5️⃣ Debug: Print scene info
	# -----------------------------
	print_player_debug()


func get_last_direction() -> String:
	return last_direction

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC
		toggle_pause_menu()
		return
	
	if get_tree().paused:
		return
		
	if event.is_action_pressed("ui_accept"): # Enter
		save_game_here()

func toggle_pause_menu():
	if pause_menu:
		if pause_menu.has_method("toggle_pause"):
			pause_menu.toggle_pause()
		else:
			if pause_menu.visible:
				pause_menu.hide()
				get_tree().paused = false
				print("Player: Hiding pause menu")
			else:
				pause_menu.show()
				get_tree().paused = true
				print("Player: Showing pause menu")
	else:
		print("Player: No pause menu reference found!")
		get_tree().paused = not get_tree().paused

func save_game_here():
	if SaveManager.save_game():
		print("Game saved at position: ", position, " facing: ", last_direction)

func _physics_process(delta: float) -> void:
	if not can_move or get_tree().paused:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1
	
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	handle_camera_collision()
	set_animation()

func handle_camera_collision():
	if not camera_3d or not camera_mount:
		return
	
	var mount_position = camera_mount.global_position
	var target_camera_position = mount_position + (camera_mount.transform.basis * original_camera_position)
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(mount_position, target_camera_position, camera_collision_mask)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_point = result.position
		var direction_to_camera = (target_camera_position - mount_position).normalized()
		var safe_distance = mount_position.distance_to(hit_point) - MIN_CAMERA_DISTANCE
		safe_distance = max(safe_distance, MIN_CAMERA_DISTANCE)
		var new_world_position = mount_position + direction_to_camera * safe_distance
		camera_3d.global_position = new_world_position
	else:
		camera_3d.position = original_camera_position

func set_animation():
	var is_moving = velocity.length() > 0.1
	var animation_suffix = ""
	
	if is_moving:
		var abs_x = abs(velocity.x)
		var abs_z = abs(velocity.z)
		
		if abs_x > abs_z:
			animation_suffix = "right" if velocity.x > 0 else "left"
		else:
			animation_suffix = "down" if velocity.z > 0 else "up"
		
		last_direction = animation_suffix
		animated_sprite_3d.play("run_" + animation_suffix)
	else:
		animated_sprite_3d.play("idle_" + last_direction)

func print_player_debug():
	var current_scene = get_tree().current_scene
	var scene_path = current_scene.scene_file_path if current_scene else "No scene loaded"
	print("🟢 Scene:", scene_path, 
		  "| Position:", position, 
		  "| Direction:", last_direction)
