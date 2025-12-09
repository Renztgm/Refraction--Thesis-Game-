extends Control

signal intro_finished

@export var next_scene_path: String = "res://scenes/Scene1/Scene1.tscn"

@export var type_min_delay := 0.045   # slow and dramatic
@export var type_max_delay := 0.095   # slight randomness
@export var after_line_pause := 0.35
@export var after_title_hold := 1.0
@export var final_fade_duration := 1.0


@onready var bg: ColorRect = $BlackBG
@onready var vbox: VBoxContainer = $TextVBox
@onready var title_main: Label = $TitleMain
@onready var title_sub: Label = $TitleSub

@onready var sfx_static: AudioStreamPlayer = $SFX_Static
@onready var sfx_heartbeat: AudioStreamPlayer = $SFX_Heartbeat
@onready var sfx_chime: AudioStreamPlayer = $SFX_Chime
@onready var sfx_wind: AudioStreamPlayer = $SFX_Wind
@onready var sfx_inhale: AudioStreamPlayer = $SFX_Inhale

func _ready() -> void:
	_init_visuals()
	_init_audio()
	await _start_sequence()


# -------------------------------------------------------------------
# INITIAL SETUP
# -------------------------------------------------------------------
func _init_visuals() -> void:
	for child in vbox.get_children():
		if child is Label:
			child.modulate.a = 0

	title_main.modulate.a = 0
	title_sub.modulate.a = 0
	bg.color = Color(0, 0, 0, 1)


func _init_audio() -> void:
	if sfx_static.stream:
		sfx_static.volume_db = -16
		sfx_static.loop = true
		sfx_static.play()

	if sfx_wind.stream:
		sfx_wind.volume_db = -24
		sfx_wind.loop = true
		sfx_wind.play()

	if sfx_heartbeat.stream:
		sfx_heartbeat.volume_db = -30
		sfx_heartbeat.loop = true
		sfx_heartbeat.play()


# -------------------------------------------------------------------
# MAIN SEQUENCE
# -------------------------------------------------------------------
func _start_sequence() -> void:
	await get_tree().create_timer(0.4).timeout

	var lines: Array[Label] = []
	for c in vbox.get_children():
		if c is Label:
			lines.append(c)

	await _typing_sequence(lines)

	if sfx_inhale.stream:
		sfx_inhale.play()
	await get_tree().create_timer(0.6).timeout

	if sfx_chime.stream:
		sfx_chime.play()

	await _heartbeat_swell(0.7, -6.0)
	await _reveal_title()

	await get_tree().create_timer(after_title_hold).timeout
	await _final_fade_and_change_scene()


# -------------------------------------------------------------------
# TYPING SEQUENCE
# -------------------------------------------------------------------

func _typing_sequence(lines: Array[Label]) -> void:
	# --------------------------
	# GROUP 1 (Lines 1–4)
	# --------------------------
	for i in range(0, 4):
		await _fadein_typing(lines[i])

	await get_tree().create_timer(0.5).timeout
	await _fadeout_group(lines, 0, 4)


	# --------------------------
	# GROUP 2 (Lines 5–7)
	# --------------------------
	for i in range(4, 7):
		await _fadein_typing(lines[i])

	await get_tree().create_timer(0.5).timeout
	await _fadeout_group(lines, 4, 7)


	# --------------------------
	# GROUP 3 (Lines 8–9)
	# --------------------------
	for i in range(7, 9):
		await _fadein_typing(lines[i])

	# IMPORTANT:
	# These DO NOT fade out.
	await get_tree().create_timer(0.6).timeout

func _type_line(label: Label) -> void:
	var full_text := label.text
	label.text = ""
	label.modulate.a = 1.0

	for char in full_text:
		label.text += str(char)

		var delay := randf_range(type_min_delay, type_max_delay)
		await get_tree().create_timer(delay).timeout

func _fadein_typing(label: Label) -> void:
	var full := label.text
	label.text = ""
	label.modulate.a = 0

	# Fade-in the label
	var tw := get_tree().create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 0.35)

	# Type letter by letter
	for c in full:
		label.text += str(c)
		await get_tree().create_timer(randf_range(type_min_delay, type_max_delay)).timeout

func _fadeout_group(lines: Array[Label], start: int, end: int) -> void:
	var tw := get_tree().create_tween()

	for i in range(start, end):
		tw.tween_property(lines[i], "modulate:a", 0.0, 0.45)

	await tw.finished
	
#-----------------------------------------------------------------
# HEARTBEAT SWELL
# -------------------------------------------------------------------
func _heartbeat_swell(duration: float, peak_db: float) -> void:
	var base_db := sfx_heartbeat.volume_db
	var base_pitch := sfx_heartbeat.pitch_scale

	var tw_up := get_tree().create_tween()
	tw_up.tween_property(sfx_heartbeat, "volume_db", peak_db, duration * 0.4)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tw_up.tween_property(sfx_heartbeat, "pitch_scale", base_pitch * 1.08, duration * 0.4)

	await tw_up.finished

	var tw_down := get_tree().create_tween()
	tw_down.tween_property(sfx_heartbeat, "volume_db", base_db, duration * 0.6)
	tw_down.tween_property(sfx_heartbeat, "pitch_scale", base_pitch, duration * 0.6)

	await tw_down.finished


# -------------------------------------------------------------------
# TITLE SEQUENCE
# -------------------------------------------------------------------
func _reveal_title() -> void:
	title_main.visible = true
	title_main.scale = Vector2(0.96, 0.96)
	title_main.modulate.a = 0

	var tw := get_tree().create_tween()
	tw.tween_property(title_main, "modulate:a", 1.0, 1.0)
	tw.tween_property(title_main, "scale", Vector2(1, 1), 1.0)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.3).timeout

	title_sub.visible = true
	title_sub.modulate.a = 0

	var tw2 := get_tree().create_tween()
	tw2.tween_property(title_sub, "modulate:a", 1.0, 0.8)

	await tw2.finished


# -------------------------------------------------------------------
# FINAL FADE & SCENE CHANGE
# -------------------------------------------------------------------
func _final_fade_and_change_scene() -> void:
	var audio_fade := get_tree().create_tween()
	audio_fade.tween_property(sfx_static, "volume_db", -40, 1.0)
	audio_fade.tween_property(sfx_wind, "volume_db", -40, 1.0)
	audio_fade.tween_property(sfx_heartbeat, "volume_db", -40, 1.0)

	var screen_fade := get_tree().create_tween()
	screen_fade.tween_property(bg, "color:a", 1.0, final_fade_duration)

	await screen_fade.finished
	await get_tree().create_timer(0.15).timeout

	if next_scene_path != "":
		var result := get_tree().change_scene_to_file(next_scene_path)
		if result != OK:
			push_warning("Failed to change scene to: " + next_scene_path)
			emit_signal("intro_finished")
	else:
		emit_signal("intro_finished")
