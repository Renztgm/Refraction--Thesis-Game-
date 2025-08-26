extends CharacterBody3D

enum State { IDLE, WALKING, CHASING, RETURNING }

@onready var animated_sprite = $AnimatedSprite3D
@onready var state_timer = Timer.new()
@onready var interact_area: Area3D = $Area3D
@onready var interact_label: Label3D = $InteractLabel3D
@onready var hum_player: AudioStreamPlayer3D = $hum_player
var has_started_humming: bool = false

var current_state = State.IDLE
var speed = 2.0
var direction = Vector3.ZERO
var spawn_position: Vector3
var current_facing = "down"  # Track current facing direction
var player_in_range: bool = false
var dialogue_active: bool = false  # ✅ Prevent multiple dialogues

# ✅ This fixes your error
var can_move: bool = true

func _ready():
	spawn_position = global_position
	add_child(state_timer)
	state_timer.timeout.connect(_on_state_timer_timeout)

	# Connect interaction signals
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

	# Hide label initially
	if interact_label:
		interact_label.visible = false
		
	# Setup humming (but don’t start yet)
	hum_player.stream = preload("res://assets/audio/ambient/humming.mp3")
	hum_player.volume_db = -12
	hum_player.unit_size = 1.0      # how far sound carries
	hum_player.max_distance = 30.0  # fades out at 30 units
	hum_player.autoplay = false

	change_state(State.IDLE)

func _physics_process(delta):
	# ✅ Stop NPC completely if movement is locked
	if not can_move:
		velocity = Vector3.ZERO
		move_and_slide()
		play_directional_animation("idle")
		return

	match current_state:
		State.IDLE:
			velocity = Vector3.ZERO
			play_directional_animation("idle")
		
		State.WALKING:
			velocity = direction * speed
			update_facing_direction()
			move_and_slide()
			play_directional_animation("run")
		
		State.RETURNING:
			var return_direction = (spawn_position - global_position).normalized()
			velocity = return_direction * speed
			direction = return_direction
			update_facing_direction()
			move_and_slide()
			play_directional_animation("run")
			
			if global_position.distance_to(spawn_position) < 1.0:
				change_state(State.IDLE)

# ==============================
# 🔹 INTERACTION LOGIC
# ==============================

func _unhandled_input(event: InputEvent) -> void:
	# ✅ Only allow interaction if player is in range AND no dialogue is active
	if player_in_range and not dialogue_active and event.is_action_pressed("interact"):
		talk()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		if interact_label and not dialogue_active:  # ✅ Only show label if no dialogue active
			interact_label.visible = true
		print("Player entered NPC range")

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if interact_label:
			interact_label.visible = false
		print("Player left NPC range")
		
		# Start humming only once
		if not has_started_humming:
			hum_player.play()
			has_started_humming = true
			# Trigger background music after 30s
			start_background_music_after_delay()

func start_background_music_after_delay():
	await get_tree().create_timer(30.0).timeout
	var audio_manager = get_tree().get_first_node_in_group("audio_manager")
	if audio_manager:
		audio_manager.play_background_music()


func talk():
	# ✅ Double-check that dialogue isn't already active
	if dialogue_active:
		return
		
	dialogue_active = true  # ✅ Mark dialogue as active
	can_move = false  # Freeze NPC during dialogue
	
	# Hide interaction label during dialogue
	if interact_label:
		interact_label.visible = false
	
	var dialogue_box = preload("res://scenes/DialogueBox.tscn").instantiate()
	get_tree().current_scene.add_child(dialogue_box)

	dialogue_box.start_dialogue(
		["Yabang mo ah?!", "Gusto mo masaksak? nasa Tondo ka Boy."],
		get_tree().get_first_node_in_group("player")
	)

	# ✅ Reset dialogue state when finished
	dialogue_box.dialogue_finished.connect(func():
		dialogue_active = false  # ✅ Allow new dialogues
		can_move = true
		
		# Show interaction label again if player still in range
		if player_in_range and interact_label:
			interact_label.visible = true
	)

# ==============================
# 🔹 MOVEMENT / STATE LOGIC
# ==============================

func update_facing_direction():
	if direction == Vector3.ZERO:
		return
	
	if abs(direction.z) > abs(direction.x):
		if direction.z > 0:
			current_facing = "down"
		else:
			current_facing = "up"
	else:
		if direction.x > 0:
			current_facing = "right"
		else:
			current_facing = "right"
			animated_sprite.flip_h = true
			return
	
	animated_sprite.flip_h = false

func play_directional_animation(anim_type: String):
	var animation_name = anim_type.capitalize() + "_" + current_facing
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		var fallback = anim_type.capitalize() + "_down"
		if animated_sprite.sprite_frames.has_animation(fallback):
			animated_sprite.play(fallback)

func change_state(new_state: State):
	current_state = new_state
	
	match current_state:
		State.IDLE:
			state_timer.wait_time = randf_range(2.0, 4.0)
			state_timer.start()
		
		State.WALKING:
			choose_random_direction()
			state_timer.wait_time = randf_range(3.0, 6.0)
			state_timer.start()

func choose_random_direction():
	var angle = randf() * TAU
	direction = Vector3(cos(angle), 0, sin(angle))

func _on_state_timer_timeout():
	match current_state:
		State.IDLE:
			change_state(State.WALKING)
		State.WALKING:
			if randf() < 0.6:
				change_state(State.WALKING)
			else:
				change_state(State.RETURNING)
