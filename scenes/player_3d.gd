extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = $Camera_Mount/Visual/AnimatedSprite3D

# Add this variable at the top of your script to remember direction
var last_direction = "down"

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

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
	
	# Call the animation function after movement
	set_animation()

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
	
