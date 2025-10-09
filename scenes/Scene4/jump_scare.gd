extends Area3D

@export var jumpscare_duration: float = 3.0  # How long to show the jumpscare
@onready var jumpscare_camera: Camera3D = $"../JumpscareCamera"  # Camera positioned in front of NPC

var player_camera: Camera3D
var player: Node3D
var is_jumpscaring: bool = false
var jumpscare_timer: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	# Make sure jumpscare camera is disabled at start
	if jumpscare_camera:
		jumpscare_camera.current = false

func _on_body_entered(body):
	# Check if the player entered
	if body.is_in_group("player") and not is_jumpscaring:
		player = body
		# Find the camera inside the player node
		player_camera = find_camera_in_node(player)
		
		if player_camera and jumpscare_camera:
			trigger_jumpscare()
		else:
			if not player_camera:
				push_error("No Camera3D found in player!")
			if not jumpscare_camera:
				push_error("JumpscareCamera not found! Make sure it exists in the scene.")

func find_camera_in_node(node: Node) -> Camera3D:
	# Check if this node is a camera
	if node is Camera3D:
		return node
	
	# Search through children
	for child in node.get_children():
		var result = find_camera_in_node(child)
		if result:
			return result
	
	return null

func trigger_jumpscare():
	is_jumpscaring = true
	jumpscare_timer = 0.0
	
	# Switch to jumpscare camera
	jumpscare_camera.current = true
	
	# Disable player input (optional - add this method to your player script)
	if player.has_method("disable_input"):
		player.disable_input()

func _process(delta):
	if is_jumpscaring:
		jumpscare_timer += delta
		
		if jumpscare_timer >= jumpscare_duration:
			# Switch back to player camera
			player_camera.current = true
			
			# Re-enable player input
			if player and player.has_method("enable_input"):
				player.enable_input()
			
			is_jumpscaring = false
			
			# Optional: disable this area so it doesn't trigger again
			queue_free()
