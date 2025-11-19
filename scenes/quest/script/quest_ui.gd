extends CanvasLayer

@onready var active_list: VBoxContainer = $Panel/HBoxContainer/ActiveContainer/ActiveList
@onready var completed_list: VBoxContainer = $Panel/HBoxContainer/CompletedContainer/CompletedList
@onready var close_button = $Panel/CloseButton

func _ready():
	close_button.pressed.connect(hide)

	# ✅ Ensure quests are loaded before refreshing
	if QuestManager.active_quests.is_empty():
		QuestManager.load_all_quests()

	# ✅ Connect signal for live updates
	if not QuestManager.quest_updated.is_connected(_on_quest_updated):
		QuestManager.quest_updated.connect(_on_quest_updated)

	refresh_quests()

func refresh_quests():
	# 🔄 Clear both lists
	for child in active_list.get_children():
		child.queue_free()
	for child in completed_list.get_children():
		child.queue_free()

	print("🧭 Loaded quests:", QuestManager.active_quests.keys())

	for quest in QuestManager.active_quests.values():
		print("🔍 Displaying quest:", quest["id"], "-", quest["title"])

		var entry = preload("res://scenes/quest/QuestEntry.tscn").instantiate()

		# ✅ Defensive node access
		var title_label = entry.get_node("VBoxContainer/HBoxContainer/TitleLabel")
		if title_label:
			title_label.text = quest["title"]
		else:
			push_error("❌ TitleLabel not found in QuestEntry")

		var desc_label = entry.get_node("VBoxContainer/HBoxContainer/DescriptionLabel")
		if desc_label:
			desc_label.text = quest["description"]
		else:
			push_error("❌ DescriptionLabel not found in QuestEntry")

		var status_icon = entry.get_node("VBoxContainer/HBoxContainer/StatusIcon")
		if status_icon:
			var icon_path = "res://assets/ui/checkbox.png" if quest["is_completed"] else "res://assets/ui/missing.png"
			status_icon.texture = load(icon_path)
		else:
			push_error("❌ StatusIcon not found in QuestEntry")

		var objective_list = entry.get_node("VBoxContainer/ObjectiveList")
		if objective_list:
			for obj in quest["objectives"]:
				var label = Label.new()
				var prefix = "✔ " if obj["is_completed"] else "• "
				label.text = prefix + obj["text"]
				objective_list.add_child(label)
		else:
			push_error("❌ ObjectiveList not found in QuestEntry")

		print("🧾 Quest description:", quest["description"])

		# 🧭 Add to correct list
		if quest["is_completed"]:
			completed_list.add_child(entry)
		else:
			active_list.add_child(entry)

func _on_quest_updated(quest_id: String):
	var quest = QuestManager.active_quests.get(quest_id)
	if quest and quest.is_completed:
		var narrative = get_node_or_null("/root/NarrativeState")
		if narrative:
			narrative.set_flag("picture_restored", true)

	refresh_quests()


func _on_completed_container_visibility_changed() -> void:
	if visible:
		refresh_quests()
