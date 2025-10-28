extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = $Camera_Mount/Visual/AnimatedSprite3D
@onready var camera_mount: Node3D = $Camera_Mount
@onready var camera_3d: Camera3D = $Camera_Mount/Camera3D

# Access the PauseMenu through the CanvasPause autoload
@onready var pause_menu: Control = CanvasPause.pause_menu

# InventoryUI.Tcsn
@onready var inventory_ui: Control = null

@onready var audio_manager = get_node("/root/Main/AudioManager")

var last_direction: String = "down"
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var can_move: bool = true  
var is_frozen: bool = false  # New: Track freeze state separately from can_move
const CAMERA_COLLISION_LAYERS = 1
const MIN_CAMERA_DISTANCE = 0.5
var original_camera_position: Vector3
var camera_collision_mask = 0xFFFFFFFF

func _ready():
	add_to_group("player")
	
	# -----------------------------
	#  InventoryUI
	# -----------------------------
	
	# Enable step-up behavior
	floor_snap_length = 0.5  # Try 0.2–0.4 depending on ledge height
	floor_block_on_wall = false
	floor_max_angle = deg_to_rad(45.0)  # Optional: allow steeper slopes
	# Load inventory UI into the CanvasLayer
	var ui_layer = get_tree().current_scene.get_node("UI")
	if not ui_layer:
		push_warning("⚠️ UI CanvasLayer not found in scene!")
		return
	
	if ui_layer:
		var inv_scene = preload("res://scenes/Inventory/InventoryUI.tscn")
		inventory_ui = inv_scene.instantiate()
		ui_layer.add_child(inventory_ui)
		inventory_ui.visible = false  # start hidden

	# -----------------------------
	# 1️⃣ New game → spawn point
	# -----------------------------
	if not SaveManager.has_save_data():
		_set_spawn_position()

	# -----------------------------
	# 2️⃣ Camera setup
	# -----------------------------
	if camera_3d:
		original_camera_position = camera_3d.position

	# -----------------------------
	# 3️⃣ Pause menu debug
	# -----------------------------
	if pause_menu:
		print("Pause menu found via CanvasPause!")
	else:
		print("⚠️ Pause menu is null – check your CanvasPause autoload setup.")

	# -----------------------------
	# 4️⃣ Debug: Print scene info
	# -----------------------------
	print_player_debug()
	


# -----------------------------
# Helper: Spawn point setup
# -----------------------------
func _set_spawn_position() -> void:
	var spawn_point: Marker3D = $SpawnPoint
	if spawn_point:
		position = spawn_point.global_position
		print("Player spawned at scene spawn point:", position)
	else:
		print("⚠️ No spawn point found! Using default position:", position)

func get_last_direction() -> String:
	return last_direction


# -----------------------------
# NEW: Freeze/Unfreeze Methods
# -----------------------------
func freeze_player() -> void:
	if is_frozen:
		return
	
	is_frozen = true
	can_move = false
	
	# Stop all movement immediately
	velocity = Vector3.ZERO
	
	# Force idle animation
	if animated_sprite_3d:
		animated_sprite_3d.play("idle_" + last_direction)
	
	print("DEBUG: Player frozen")

func unfreeze_player() -> void:
	if not is_frozen:
		return
	
	is_frozen = false
	can_move = true
	
	print("DEBUG: Player unfrozen")

# Optional: Check if player is currently frozen
func is_player_frozen() -> bool:
	return is_frozen


# -----------------------------
# Input handling
# -----------------------------
func _input(event):
	# Don't process input if frozen (except pause)
	if is_frozen and not event.is_action_pressed("ui_cancel"):
		return
		
	if event.is_action_pressed("ui_cancel"):  # ESC
		CanvasPause.toggle_pause_menu()
		return
	
	if get_tree().paused:
		return
		
	#if event.is_action_pressed("ui_accept"): # Enter
		#save_game_here()
		

func save_game_here():
	if SaveManager.save_game():
		print("Game saved at position: ", position, " facing: ", last_direction)

func _unhandled_input(event):
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()

func _on_inventory_button_pressed() -> void:
	toggle_inventory()

func toggle_inventory():
	if inventory_ui:
		inventory_ui.visible = not inventory_ui.visible
		print("Inventory toggled:", inventory_ui.visible)

		if inventory_ui.visible:
			freeze_player()
		else:
			unfreeze_player()


# -----------------------------
# Movement and animation
# -----------------------------
func _physics_process(delta: float) -> void:
	if not can_move or is_frozen or get_tree().paused:
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

	move_and_slide()  # This now respects floor snapping

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
	# Don't change animations if frozen (keep idle animation)
	if is_frozen:
		return
		
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
