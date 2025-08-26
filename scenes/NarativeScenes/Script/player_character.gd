# player_character.gd - Simple version without animations
extends CharacterBody3D

var animated_sprite: AnimatedSprite3D
var is_lying_down = true

func _ready():
	# Ensure AnimatedSprite3D exists
	if not has_node("AnimatedSprite3D"):
		animated_sprite = AnimatedSprite3D.new()
		animated_sprite.name = "AnimatedSprite3D"
		add_child(animated_sprite)
	else:
		animated_sprite = $AnimatedSprite3D
	
	setup_player_appearance()

func setup_player_appearance():
	# Setup AnimatedSprite3D properties
	animated_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # Always face camera

# Required methods for narrative controller - just print messages
func stand_up():
	print("Player stands up...")
	is_lying_down = false

func look_at_hands():
	print("Player looks at their hands...")

func listen_action():
	print("Player listens to the wind...")

# Alias methods for narrative controller consistency
func stand_up_action():
	stand_up()

func look_hands_action():
	look_at_hands()
