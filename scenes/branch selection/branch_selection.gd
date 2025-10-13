extends Control

@onready var map_root = $MapRoot
@onready var title_label = $TitleLabel
@onready var description_label = $DescriptionLabel
@onready var line_layer: Node2D = $LineLayer
@onready var camera = $Camera2D

@onready var close_button: Button = $Control/CloseButton

var dragging := false
var drag_origin := Vector2()

@onready var background = $Background

var node_spacing_x := 250
var node_spacing_y := 150
var debug_show_all := true  # Set to false in production

func _ready():
	close_button.pressed.connect(_on_CloseButton_pressed)
	
	var root = load("res://scenes/branch selection/ch1_sn1.tres") as BranchNode
	if root:
		var saved_paths = get_saved_scene_paths()
		render_unlocked_nodes(root, Vector2(0, 0), saved_paths)
	else:
		push_error("❌ Failed to load root node")

func _process(delta):
	#background.position = camera.position
	close_button.position = Vector2(100, 100)

# ==============================
# Node Rendering
# ==============================
func render_node(node: BranchNode, position: Vector2, locked: bool):
	var btn = TextureButton.new()
	btn.texture_normal = preload("res://addons/pngs/node.png")
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = Vector2(128, 128)
	btn.position = position
	btn.tooltip_text = "🔒 Locked — complete previous scenes to unlock" if locked else node.description


	var label = Label.new()
	label.text = node.title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_autowrap_mode(TextServer.AUTOWRAP_WORD)

	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = 0.0
	label.offset_top = 0.0
	label.offset_right = 0.0
	label.offset_bottom = 0.0

	btn.add_child(label)

	# Always connect the signal
	btn.connect("pressed", func():
		if locked:
			print("🔒 Node is locked — cannot enter.")
			return
		
		print("Pressed node:", node.title)
		print("Scene path:", node.scene_path)
		print("Locked:", locked)
		
		title_label.text = node.title
		description_label.text = node.description

		if SaveManager:
			var scene_path = node.scene_path
			var branch_id = node.title.replace(" ", "_").to_lower()
			var logged := SaveManager.log_scene_completion(scene_path, branch_id)
			if logged:
				print("📌 Scene logged:", scene_path)
			else:
				print("ℹ️ Scene already logged or failed to log.")

		if ResourceLoader.exists(node.scene_path):
			get_tree().change_scene_to_file(node.scene_path)
		else:
			push_error("❌ Scene path not found: " + node.scene_path)
	)

	# Visual feedback
	btn.mouse_entered.connect(func():
		btn.modulate = Color(0.5, 0.5, 0.5) if locked else Color.LIGHT_BLUE
	)
	btn.mouse_exited.connect(func():
		btn.modulate = Color(0.5, 0.5, 0.5) if locked else Color.WHITE
	)

	# Initial appearance
	btn.modulate = Color(0.5, 0.5, 0.5) if locked else Color.WHITE
	map_root.add_child(btn)

# ==============================
# Recursive Branch Rendering
# ==============================
func render_unlocked_nodes(node: BranchNode, position: Vector2, saved_paths: Array):
	var is_root := position == Vector2(0, 0)
	if not is_root and not debug_show_all and not saved_paths.has(node.scene_path):
		return

	var is_locked := not saved_paths.has(node.scene_path)
	render_node(node, position, is_locked)

	print("Saved paths:", saved_paths)
	print("Node path:", node.scene_path)
	print("Unlocked:", saved_paths.has(node.scene_path))


	
	var parent_center = position + Vector2(64, 64)
	var child_count = node.children.size()

	for i in range(child_count):
		var child = node.children[i]
		var child_pos: Vector2

		if child_count == 1:
			child_pos = position + Vector2(node_spacing_x, 0)
		elif child_count == 2:
			var direction = -1 if i == 0 else 1
			var offset_y = node_spacing_y * 0.75
			child_pos = position + Vector2(node_spacing_x, direction * offset_y)
		else:
			var offset_y = (i - child_count / 2.0) * node_spacing_y
			child_pos = position + Vector2(node_spacing_x, offset_y)

		if debug_show_all or saved_paths.has(child.scene_path):
			var line = Line2D.new()
			line.width = 2
			line.default_color = Color.SKY_BLUE
			line.add_point(parent_center)
			line.add_point(child_pos + Vector2(64, 64))
			line_layer.add_child(line)

		render_unlocked_nodes(child, child_pos, saved_paths)

# ==============================
# Load Saved Scene Paths
# ==============================
func get_saved_scene_paths() -> Array:
	var db = SQLite.new()
	db.path = "user://game_data.db"
	var success = db.open_db()
	var paths: Array = []

	if success:
		var query_success = db.query("SELECT scene_path FROM game_path")
		if query_success and db.query_result.size() > 0:
			for row in db.query_result:
				paths.append(row["scene_path"])
	else:
		push_error("❌ Failed to open database")

	db = null
	return paths

# ==============================
# Camera Controls
# ==============================
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_origin = event.position
			else:
				dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= 0.9
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom *= 1.1
	elif event is InputEventMouseMotion and dragging:
		var delta = drag_origin - event.position
		camera.position += delta
		drag_origin = event.position

func _on_CloseButton_pressed():
	var previous_scene = get_meta("previous_scene")
	if previous_scene:
		previous_scene.visible = true
	self.queue_free()
