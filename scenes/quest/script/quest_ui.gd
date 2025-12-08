extends CanvasLayer


signal quest_ui_closed 

@onready var active_list: VBoxContainer = $Panel/HBoxContainer/ActiveContainer/ScrollContainer/ActiveList
@onready var completed_list: VBoxContainer = $Panel/HBoxContainer/CompletedContainer/ScrollContainer/CompletedList
@onready var close_button: Button = $Panel/CloseButton

const QUEST_ENTRY_SCENE := preload("res://scenes/quest/QuestEntry.tscn")

func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)

	var active_scroll = $Panel/HBoxContainer/ActiveContainer/ScrollContainer
	var completed_scroll = $Panel/HBoxContainer/CompletedContainer/ScrollContainer
	
	active_scroll.set_clip_contents(true)
	completed_scroll.set_clip_contents(true)

	if QuestManager.active_quests.is_empty():
		QuestManager.load_all_quests()

	if not QuestManager.quest_updated.is_connected(_on_quest_updated):
		QuestManager.quest_updated.connect(_on_quest_updated)

	refresh_quests()
func _on_close_button_pressed() -> void:
	quest_ui_closed.emit()

# -------------------------------------------------------
# 🔄 Refresh Quest UI
# -------------------------------------------------------
func refresh_quests() -> void:
	_clear_list(active_list)
	_clear_list(completed_list)

	for quest in QuestManager.active_quests.values():
		var entry: Control = QUEST_ENTRY_SCENE.instantiate() as Control
		entry = _create_quest_entry_instance(entry, quest)

		if quest.get("is_completed", false):
			completed_list.add_child(entry)
		else:
			active_list.add_child(entry)


# -------------------------------------------------------
# 🧹 Clear container children
# -------------------------------------------------------
func _clear_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()


# -------------------------------------------------------
# 🧩 Fill an existing quest entry instance with data
# -------------------------------------------------------
func _create_quest_entry_instance(entry: Control, quest: Dictionary) -> Control:
	# ----- Title -----
	var title_label := entry.get_node_or_null("Panel/VBoxContainer/HBoxContainer/TitleLabel") as Label
	if title_label:
		title_label.text = quest.get("title", "Untitled Quest")

	# ----- Description -----
	var desc_label := entry.get_node_or_null("Panel/VBoxContainer/DescriptionLabel") as Label
	if desc_label:
		desc_label.text = quest.get("description", "")

	# ----- Status Icon -----
	var status_icon := entry.get_node_or_null("Panel/VBoxContainer/HBoxContainer/StatusIcon") as TextureRect
	if status_icon:
		var icon_path := (
			"res://assets/ui/checkbox.png"
			if quest.get("is_completed", false)
			else "res://assets/ui/missing.png"
		)
		status_icon.texture = load(icon_path)

	# ----- Objectives -----
	var objective_list := entry.get_node_or_null("Panel/VBoxContainer/ObjectiveList") as VBoxContainer
	if objective_list:
		# clear existing children
		for child in objective_list.get_children():
			child.queue_free()

		for obj in quest.get("objectives", []):
			var label := Label.new()
			var prefix := "✔ " if obj.get("is_completed", false) else "• "
			label.text = prefix + obj.get("text", "")
			objective_list.add_child(label)

	return entry


# -------------------------------------------------------
# 🔄 Update triggered from QuestManager
# -------------------------------------------------------
func _on_quest_updated(quest_id: String) -> void:
	var quest: Dictionary = QuestManager.active_quests.get(quest_id)
	if quest and quest.get("is_completed", false):
		var narrative := get_node_or_null("/root/NarrativeState")
		if narrative:
			narrative.set_flag("picture_restored", true)

	refresh_quests()


# -------------------------------------------------------
# 🔄 Refresh when UI opens
# -------------------------------------------------------
func _on_completed_container_visibility_changed() -> void:
	if visible:
		refresh_quests()
