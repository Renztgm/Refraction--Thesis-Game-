extends Control

# Variables
var shards_obtained: int = 0
var current_chapter: int = 1
var next_chapter_scene_path: String = ""

# Node references
@onready var title_label: Label = $MarginContainer/VBoxContainer2/TitleLabel
@onready var shards_label: Label = $MarginContainer/VBoxContainer2/VBoxContainer/VBoxContainer/ShardsCount
@onready var next_chapter_button: Button = $MarginContainer/VBoxContainer2/VBoxContainer/ButtonContainer/NextChapterButton
@onready var branch_button: Button = $MarginContainer/VBoxContainer2/VBoxContainer/ButtonContainer/BranchButton
@onready var inventory_button: Button = $MarginContainer/VBoxContainer2/VBoxContainer/ButtonContainer/InventoryButton
@onready var inventory_ui: Control = $UI/InventoryUI # Make sure this path matches your scene
@onready var branch_map_viewer: Control = $BranchMapViewer
@onready var main_menu: Button = $MarginContainer/VBoxContainer2/VBoxContainer/ButtonContainer/MainMenu
var chapter = SaveManager.get_current_chapter()
func _ready() -> void:
	FadeOutCanvas.fade_in(1.0)
	
	var next_scene = SaveManager.get_next_scene_path()
	
	if chapter == 5:
		if next_chapter_button:
			next_chapter_button.visible = false
			main_menu.visible = true
			
			
	print("Initializing ChapterCompleteUI with chapter:", chapter, "next scene:", next_scene)
	setup_end_chapter_from_db(chapter, next_scene)
	if inventory_button:
		inventory_button.pressed.connect(_on_inventory_button_pressed)
	else:
		push_error("InventoryButton not found!")
		
	if next_chapter_button:
		next_chapter_button.pressed.connect(_on_next_chapter_button_pressed)
	else:
		push_error("NextChapterButton not found!")
		
	if branch_button:
		branch_button.pressed.connect(_on_branch_button_pressed)
	else:
		push_error("BranchButton not found!")
		
	if main_menu:
		main_menu.pressed.connect(_on_main_menu_pressed)
	else:
		push_error("MainMenu not found!")

	
	# Hide inventory UI initially
	if inventory_ui:
		inventory_ui.visible = false
	
	# Update shards display
	update_shards_display()

# Input handling for inventory toggle
func _unhandled_input(event):
	if Input.is_action_just_pressed("inventory"):
		if inventory_ui:
			inventory_ui.visible = not inventory_ui.visible
			print("Inventory toggled:", inventory_ui.visible)

			if inventory_ui.visible:
				freeze_player()
			else:
				unfreeze_player()

# Freeze/unfreeze player input (stub functions)
func freeze_player():
	print("Player frozen")
	# Add logic to disable player movement/input

func unfreeze_player():
	print("Player unfrozen")
	# Add logic to re-enable player movement/input

# Get total shards count from InventoryManager database
func load_shards_from_database() -> int:
	if SaveManager:  # Assuming this script is autoloaded as GameData
		return SaveManager.get_memory_shard_count()
	else:
		push_error("GameData not found! Make sure it's set as Autoload.")
		return 0


# Setup end chapter and load total shards from InventoryManager
func setup_end_chapter_from_db(chapter: int, next_scene: String = "") -> void:
	current_chapter = chapter
	shards_obtained = load_shards_from_database()
	next_chapter_scene_path = next_scene
	update_display()

# Update all display elements
func update_display() -> void:
	update_shards_display()
	if title_label:
		if chapter == 5:
			title_label.text = "Thanks for playing!"
		else:
			title_label.text = "Chapter %d Complete!" % current_chapter

# Update the shards label
func update_shards_display() -> void:
	if shards_label:
		shards_label.text = str(shards_obtained)

# Button callbacks
func _on_inventory_button_pressed() -> void:
	if inventory_ui:
		inventory_ui.visible = not inventory_ui.visible
		print("Inventory toggled:", inventory_ui.visible)

		if inventory_ui.visible:
			freeze_player()
		else:
			unfreeze_player()
	else:
		push_error("Inventory UI node not found!")


func _on_next_chapter_button_pressed() -> void:
	print("Next scene path:", next_chapter_scene_path)
	if next_chapter_scene_path != "":
		var new_chapter = current_chapter + 1
		NewChapterScene.transfer_scene(new_chapter)
		get_tree().change_scene_to_file(next_chapter_scene_path)
	else:
		print("No next chapter scene path set")


func _on_branch_button_pressed():
	var branch_map = load("res://scenes/branch selection/BranchMapViewer.tscn").instantiate()
	branch_map.set_meta("previous_scene", self)
	self.visible = false
	get_tree().root.add_child(branch_map)

func enable_branch_button(enable: bool) -> void:
	if branch_button:
		branch_button.visible = enable


func _on_main_menu_pressed() -> void:
		get_tree().change_scene_to_file("res://scenes/Main Menu/main_menu.tscn")
