extends CharacterBody2D
@export var movement_speed : float = 500
var character_direction : Vector2
var last_direction: Vector2 = Vector2.ZERO

func _physics_process(delta):
	character_direction.x = Input.get_axis("ui_left", "ui_right")
	character_direction.y = Input.get_axis("ui_up", "ui_down")
	
	# Yung code na to is magfli-flip don sa sprite na right to left
	# if yung direction nya is papunta sa right (x > 0)
	if character_direction.x > 0 : %sprite.flip_h = false # Right
	elif character_direction.x < 0 : %sprite.flip_h = true # Left
	
	if character_direction != Vector2.ZERO:
		velocity = character_direction * movement_speed
		last_direction = character_direction  # Store the last movement direction
		
		# Determine animation based on movement direction
		if character_direction.y < -0.1:  # Moving up
			if %sprite.animation != "Running_Up": 
				%sprite.animation = "Running_Up"
				%sprite.play()  # Ensure animation plays
		elif character_direction.y > 0.1:  # Moving down  
			if %sprite.animation != "Running_Down": 
				print("Switching to Running_Down")  # Debug
				%sprite.animation = "Running_Down"
				%sprite.play()  # Ensure animation plays
				print("Current animation: ", %sprite.animation)  # Debug
		else:  # Primarily horizontal movement
			if %sprite.animation != "Running": 
				%sprite.animation = "Running"
				%sprite.play()  # Ensure animation plays
	else:
		velocity = velocity.move_toward(Vector2.ZERO, movement_speed)
		
		# Determine idle animation based on last movement direction
		if last_direction.y < -0.1:  # Was moving up
			if %sprite.animation != "Idle_Up": 
				%sprite.animation = "Idle_Up"
				%sprite.play()  # Ensure animation plays
		elif last_direction.y > 0.1:  # Was moving down
			if %sprite.animation != "Idle_Down": 
				%sprite.animation = "Idle_Down"
				%sprite.play()  # Ensure animation plays
		else:  # Was moving horizontally or no significant vertical movement
			if %sprite.animation != "Idle": 
				%sprite.animation = "Idle"
				%sprite.play()  # Ensure animation plays
		
	move_and_slide()
