extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = $Camera_Mount/Visual/AnimatedSprite3D
@onready var camera_mount: Node3D = $Camera_Mount
@onready var camera_3d: Camera3D = $Camera_Mount/Camera3D  # Adjust path as needed

# Add this variable at the top of your script to remember direction
var last_direction = "down"
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Camera collision settings
const CAMERA_COLLISION_LAYERS = 1  # Set which collision layers to check
const MIN_CAMERA_DISTANCE = 0.5    # Minimum distance from walls
var original_camera_position: Vector3
var camera_collision_mask = 0xFFFFFFFF  # Check all layers by default

func _ready():
	# Store the original camera position relative to the mount
	if camera_3d:
		original_camera_position = camera_3d.position

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
	# Handle camera collision after movement
	handle_camera_collision()
	
	# Call the animation function after movement
	set_animation()

func handle_camera_collision():
	if not camera_3d or not camera_mount:
		return
	
	# Get world space positions
	var mount_position = camera_mount.global_position
	var target_camera_position = mount_position + (camera_mount.transform.basis * original_camera_position)
	
	# Create a raycast from mount to target camera position
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		mount_position, 
		target_camera_position,
		camera_collision_mask
	)
	
	# Exclude the player character from collision
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Collision detected - move camera closer to mount
		var hit_point = result.position
		var direction_to_camera = (target_camera_position - mount_position).normalized()
		var safe_distance = mount_position.distance_to(hit_point) - MIN_CAMERA_DISTANCE
		safe_distance = max(safe_distance, MIN_CAMERA_DISTANCE)  # Ensure minimum distance
		
		# Calculate new camera position in local space
		var new_world_position = mount_position + direction_to_camera * safe_distance
		camera_3d.global_position = new_world_position
	else:
		# No collision - use original position
		camera_3d.position = original_camera_position

# Alternative method using Area3D for more complex collision detection
func setup_camera_collision_area():
	# Create an Area3D as child of camera for collision detection
	var area = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.3
	
	collision_shape.shape = sphere_shape
	area.add_child(collision_shape)
	camera_3d.add_child(area)
	
	# Connect the signal
	area.body_entered.connect(_on_camera_collision_entered)
	area.body_exited.connect(_on_camera_collision_exited)
	
	return area

func _on_camera_collision_entered(body):
	# Handle when camera collides with something
	if body != self:  # Ignore player collision
		print("Camera collision detected with: ", body.name)

func _on_camera_collision_exited(body):
	# Handle when camera exits collision
	if body != self:
		print("Camera collision ended with: ", body.name)

func set_animation():
	# Determine if the character is moving
	var is_moving = velocity.length() > 0.1
	
	# Get the dominant movement direction
	var animation_suffix = ""
	
	if is_moving:
		# Find the dominant axis of movement
		var abs_x = abs(velocity.x)
		var abs_z = abs(velocity.z)
		
		if abs_x > abs_z:
			# Moving more horizontally
			if velocity.x > 0:
				animation_suffix = "right"
			else:
				animation_suffix = "left"
		else:
			# Moving more vertically (in 3D space, z-axis is typically forward/back)
			if velocity.z > 0:
				animation_suffix = "down"  # or "forward" depending on your setup
			else:
				animation_suffix = "up"    # or "backward" depending on your setup
		
		# Remember this direction for idle animation
		last_direction = animation_suffix
		
		# Play running animation
		animated_sprite_3d.play("run_" + animation_suffix)
	else:
		# Character is idle - use the last movement direction
		animated_sprite_3d.play("idle_" + last_direction)
