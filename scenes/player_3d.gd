extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = $Camera_Mount/Visual/AnimatedSprite3D
@onready var camera_mount: Node3D = $Camera_Mount
@onready var camera_3d: Camera3D = $Camera_Mount/Camera3D

var last_direction = "down"
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Camera collision settings
const CAMERA_COLLISION_LAYERS = 1
const MIN_CAMERA_DISTANCE = 0.5
var original_camera_position: Vector3
var camera_collision_mask = 0xFFFFFFFF

func _ready():
	if camera_3d:
		original_camera_position = camera_3d.position

func _physics_process(delta: float) -> void:
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump with Space key (KEY_SPACE = 32)
	#if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		#velocity.y = JUMP_VELOCITY
	
	# Get WASD input using direct key codes
	var input_dir = Vector2.ZERO
	
	# Check for WASD input using key codes
	if Input.is_key_pressed(KEY_A):      # A key (65)
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):      # D key (68)
		input_dir.x += 1
	if Input.is_key_pressed(KEY_W):      # W key (87)
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S):      # S key (83)
		input_dir.y += 1
	
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
