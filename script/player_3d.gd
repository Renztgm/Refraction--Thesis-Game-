extends CharacterBody3D
@onready var animated_sprite_3d: AnimatedSprite3D = $Camera_Mount/Visual/AnimatedSprite3D
@onready var camera_mount: Node3D = $Camera_Mount
@onready var camera_3d: Camera3D = $Camera_Mount/Camera3D

# ✅ Reference to the pause menu - get it from the scene
@onready var pause_menu: Control = get_node("../../PauseMenu")  # Adjust path as needed

var last_direction = "down"
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var can_move: bool = true  
# Camera collision settings
const CAMERA_COLLISION_LAYERS = 1
const MIN_CAMERA_DISTANCE = 0.5
var original_camera_position: Vector3
var camera_collision_mask = 0xFFFFFFFF

func _ready():
	if camera_3d:
		original_camera_position = camera_3d.position
	
	# Add player to "player" group so SaveManager can find it
	add_to_group("player")
	
	# Load saved position and direction if coming from continue
	if SaveManager.has_save_file():
		var saved_pos = SaveManager.get_saved_player_position()
		var saved_direction = SaveManager.get_saved_player_direction()
		
		if saved_pos != Vector3.ZERO:
			position = saved_pos
			last_direction = saved_direction
			print("Player position loaded: ", saved_pos)
			print("Player direction loaded: ", saved_direction)
	
	# ✅ Check if pause menu exists
	if pause_menu:
		print("Pause menu found! Player will control it.")
	else:
		print("Warning: Pause menu not found. Trying alternative path...")
		# Try different paths
		pause_menu = get_node_or_null("../../PauseMenu")
		if not pause_menu:
			pause_menu = get_tree().get_first_node_in_group("pause_menu")
		if pause_menu:
			print("Pause menu found via alternative method!")

# Add this function so SaveManager can get the last direction
func get_last_direction():
	return last_direction

func _input(event):
	# ✅ Handle ESC key to toggle pause menu
	if event.is_action_pressed("ui_cancel"):  # ESC key
		print("Player: ESC pressed!")
		toggle_pause_menu()
		return
	
	# Don't handle other input when game is paused
	if get_tree().paused:
		return
		
	# Save game when pressing Enter
	if event.is_action_pressed("ui_accept"):
		save_game_here()

# ✅ Function to toggle pause menu
func toggle_pause_menu():
	if pause_menu:
		if pause_menu.has_method("toggle_pause"):
			pause_menu.toggle_pause()
		else:
			# Manual toggle if pause menu doesn't have toggle_pause method
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
		# Fallback: simple pause
		get_tree().paused = not get_tree().paused

func save_game_here():
	if SaveManager.save_game():
		print("Game saved at position: ", position, " facing: ", last_direction)

func _physics_process(delta: float) -> void:
	# stop all player movement if locked by dialogue or paused
	if not can_move or get_tree().paused:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# WASD input
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1
	
	# Convert 2D input to 3D direction
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
	var query = PhysicsRayQueryParameters3D.create(
		mount_position, 
		target_camera_position,
		camera_collision_mask
	)
	
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
			if velocity.x > 0:
				animation_suffix = "right"
			else:
				animation_suffix = "left"
		else:
			if velocity.z > 0:
				animation_suffix = "down"
			else:
				animation_suffix = "up"
		
		last_direction = animation_suffix
		animated_sprite_3d.play("run_" + animation_suffix)
	else:
		animated_sprite_3d.play("idle_" + last_direction)
