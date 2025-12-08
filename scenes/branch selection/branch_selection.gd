extends Control

@onready var map_root = $MapRoot
@onready var title_label = $TitleLabel
@onready var description_label = $DescriptionLabel
@onready var line_layer: Node2D = $LineLayer
@onready var camera = $Camera2D

@onready var close_button: Button = $Control/CloseButton
@onready var background = $bg/bg

var dragging := false
var drag_origin := Vector2()

var node_spacing_x := 250
var node_spacing_y := 150
var debug_show_all := true  # Set to false in production

func _ready():
	close_button.pressed.connect(_on_CloseButton_pressed)

	# ------------------------------------------------------------
	# Verify profile system before loading branches
	# ------------------------------------------------------------
	if ProfileManager.active_profile_id == 0:
		push_error("❌ No active profile. Branch selection cannot load.")
		return

	var root = load("res://scenes/branch selection/ch1_sn1.tres") as BranchNode
	if root:
		var saved_paths = get_saved_scene_paths(ProfileManager.active_profile_id)
		render_unlocked_nodes(root, Vector2(0, 0), saved_paths)
	else:
		push_error("❌ Failed to load root node")


func _process(delta):
	close_button.position = Vector2(100, 100)
	background.position = camera.position

# ============================================================
# RENDER NODE BUTTON
# ============================================================
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
	btn.add_child(label)

	# ------------------------------------------------------------
	# Press handler (now includes PROFILE ID)
	# ------------------------------------------------------------
	btn.connect("pressed", func():
		if locked:
			print("🔒 Node locked:", node.title)
			return

		title_label.text = node.title
		description_label.text = node.description

		var profile_id = ProfileManager.active_profile_id
		if profile_id == 0:
			push_error("❌ Cannot log scene — no active profile")
			return

		if SaveManager:
			var scene_path = node.scene_path
			var branch_id = node.title.replace(" ", "_").to_lower()

			var logged := SaveManager.log_scene_completion(
				scene_path,
				branch_id,
				profile_id
			)

			self.queue_free()

			if logged:
				print("📌 Scene logged for profile:", profile_id)
			else:
				print("ℹ️ Scene already logged for this profile.")

		if ResourceLoader.exists(node.scene_path):
			get_tree().change_scene_to_file(node.scene_path)
		else:
			push_error("❌ Scene not found: " + node.scene_path)
	)

	# Hover visuals
	btn.mouse_entered.connect(func():
		btn.modulate = Color(0.5, 0.5, 0.5) if locked else Color.LIGHT_BLUE
	)
	btn.mouse_exited.connect(func():
		btn.modulate = Color(0.5, 0.5, 0.5) if locked else Color.WHITE
	)

	btn.modulate = Color(0.5, 0.5, 0.5) if locked else Color.WHITE
	map_root.add_child(btn)

# ============================================================
# RENDER RECURSIVELY
# ============================================================
func render_unlocked_nodes(node: BranchNode, position: Vector2, saved_paths: Array):
	var is_locked := not saved_paths.has(node.scene_path)
	render_node(node, position, is_locked)

	var parent_center = position + Vector2(64, 64)
	var child_count = node.children.size()

	for i in range(child_count):
		var child = node.children[i]
		var offset_y = (i - child_count / 2.0) * node_spacing_y
		var child_pos = position + Vector2(node_spacing_x, offset_y)

		if debug_show_all or saved_paths.has(child.scene_path):
			var line = Line2D.new()
			line.width = 5
			line.default_color = Color.SKY_BLUE
			line.add_point(parent_center)
			line.add_point(child_pos + Vector2(64, 64))
			line_layer.add_child(line)

		render_unlocked_nodes(child, child_pos, saved_paths)

# ============================================================
# LOAD UNLOCKED (SAVED) SCENE PATHS — PROFILE ONLY
# ============================================================
func get_saved_scene_paths(profile_id: int) -> Array:
	var db = SQLite.new()
	db.path = "user://game_data.db"

	var paths: Array = []

	if not db.open_db():
		push_error("❌ Cannot open DB")
		return paths

	var success := db.query_with_bindings(
		"SELECT scene_path FROM game_path WHERE profile_id = ?;",
		[profile_id]
	)

	if success and db.query_result.size() > 0:
		for row in db.query_result:
			paths.append(row["scene_path"])

	print("📜 Loaded saved paths for profile", profile_id, ":", paths)
	return paths

# ============================================================
# CAMERA DRAG + ZOOM
# ============================================================
var min_zoom := Vector2(0.5, 0.5)
var max_zoom := Vector2(2.0, 2.0)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			drag_origin = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= 0.9
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom *= 1.1

		camera.zoom = camera.zoom.clamp(min_zoom, max_zoom)

	elif event is InputEventMouseMotion and dragging:
		var delta = drag_origin - event.position
		camera.position += delta
		drag_origin = event.position

# ============================================================
# CLOSE BUTTON
# ============================================================
func _on_CloseButton_pressed():
	var previous_scene = get_meta("previous_scene")
	if previous_scene:
		previous_scene.visible = true
		if previous_scene.get_parent().get_node("Minimap"):
			previous_scene.get_parent().get_node("Minimap").visible = true
	queue_free()
