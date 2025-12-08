
extends CharacterBody3D

@onready var animated_sprite_3d: AnimatedSprite3D = $Camera_Mount/Visual/AnimatedSprite3D
@onready var camera_mount: Node3D = $Camera_Mount
@onready var camera_3d: Camera3D = $Camera_Mount/Camera3D
@onready var camera_ray: RayCast3D = $Camera_Mount/RayCast3D

@onready var inventory_ui: Control = null
@onready var quest_ui: CanvasLayer = $"../UI/QuestUi"
@onready var quest_button: Button = $hud/questButton
@onready var death_ui: CanvasLayer = $deathui

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 10.0

var SPEED = 5.0
const JUMP_VELOCITY = 4.5

const MIN_CAMERA_DISTANCE: float = 0.3   # how close camera can get to player
const CAMERA_COLLISION_MASK: int = 1 << 1   # layer 2 only

var original_camera_position: Vector3 = Vector3(0, 2, 4)  # default offset

var last_direction: String = "down"
var is_frozen: bool = false
var can_move: bool = true

var mouse_sensitivity := 0.003

func _ready():
	# Lock mouse at start
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


	camera_3d.position = Vector3(0, 2, 4)  # 2 units up, 4 units back
	camera_3d.look_at(global_transform.origin, Vector3.UP)
	
	var ui_layer = get_tree().current_scene.get_node("UI")
	if not ui_layer:
		push_warning("⚠️ UI CanvasLayer not found in scene!")
		return
	
	if ui_layer:
		var inv_scene = preload("res://scenes/Inventory/InventoryUI.tscn")
		inventory_ui = inv_scene.instantiate()
		ui_layer.add_child(inventory_ui)
		inventory_ui.visible = false  # start hidden


func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and not get_tree().paused:
		camera_mount.rotate_y(-event.relative.x * mouse_sensitivity)
		camera_3d.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-60), deg_to_rad(60))

	# Hold CTRL to release mouse
	if event is InputEventKey and event.keycode == KEY_CTRL:
		if event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	# Don't process input if frozen (except pause)
	if is_frozen and not event.is_action_pressed("ui_cancel"):
		return
		
	if event.is_action_pressed("ui_cancel"):  # ESC
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		CanvasPause.toggle_pause_menu()
		return
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if get_tree().paused:
		return
		
	if event.is_action_pressed("quest"):
		_on_quest_button_pressed()
		



func _physics_process(delta: float) -> void:
	if not can_move or is_frozen or get_tree().paused:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	# Movement input
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	if Input.is_key_pressed(KEY_W): input_dir.y += 1
	if Input.is_key_pressed(KEY_S): input_dir.y -= 1

	var forward = -camera_mount.transform.basis.z
	var right   = camera_mount.transform.basis.x
	var move_dir = (forward * input_dir.y + right * input_dir.x).normalized()
	
	if Input.is_key_pressed(KEY_SHIFT):
		SPEED = sprint_speed
	else:
		SPEED = walk_speed
	if move_dir != Vector3.ZERO:
		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	set_animation(move_dir)

	# ✅ Camera collision check
	handle_camera_collision()


func set_animation(move_dir: Vector3):
	if is_frozen:
		return

	if move_dir.length() > 0.1:
		var local_dir = camera_mount.global_transform.basis.inverse() * move_dir
		if abs(local_dir.x) > abs(local_dir.z):
			last_direction = "right" if local_dir.x > 0 else "left"
		else:
			last_direction = "up" if local_dir.z < 0 else "down"

		animated_sprite_3d.play("run_" + last_direction)

		# ✅ Adjust speed scale based on sprint
		if Input.is_key_pressed(KEY_SHIFT):
			animated_sprite_3d.speed_scale = 2.0   # sprint faster
		else:
			animated_sprite_3d.speed_scale = 1.0   # normal run
	else:
		animated_sprite_3d.play("idle_" + last_direction)
		animated_sprite_3d.speed_scale = 1.0


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
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			freeze_player()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			unfreeze_player()


func _on_quest_button_pressed():
	if quest_ui:
		quest_ui.visible = not quest_ui.visible
		print("Quest UI toggled:", quest_ui.visible)
		
		# ✅ Only refresh when opening
		if quest_ui.visible:
			QuestManager.load_all_quests()   # reload from DB or file
			quest_ui.refresh_quests()        # rebuild UIq


func _on_pause_button_pressed() -> void:
	CanvasPause.toggle_pause_menu()

func die() -> void:
	print("💀 Player has died!")
	GameOverUi.show_death_screen()

	

func reload():
	get_tree().reload_current_scene()
	
func handle_camera_collision() -> void:
	if not camera_3d or not camera_mount:
		return
	
	var mount_position: Vector3 = camera_mount.global_position
	var target_camera_position: Vector3 = mount_position + (camera_mount.transform.basis * original_camera_position)
	
	var space_state = get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(mount_position, target_camera_position, CAMERA_COLLISION_MASK)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_point: Vector3 = result.position
		var direction_to_camera: Vector3 = (target_camera_position - mount_position).normalized()
		var safe_distance: float = mount_position.distance_to(hit_point) - MIN_CAMERA_DISTANCE
		safe_distance = max(safe_distance, MIN_CAMERA_DISTANCE)
		var new_world_position: Vector3 = mount_position + direction_to_camera * safe_distance
		camera_3d.global_position = new_world_position
	else:
		camera_3d.position = original_camera_position
