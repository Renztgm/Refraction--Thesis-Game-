extends GutTest

func test_main_menu_scene_exists():
	"""Test that main menu scene file exists"""
	var main_menu_path = "res://scenes/Main Menu/main_menu.tscn"
	var scene = load(main_menu_path)
	assert_not_null(scene, "Main menu scene should exist at %s" % main_menu_path)

func test_main_menu_can_instantiate():
	"""Test that main menu scene can be instantiated"""
	var main_menu_path = "res://scenes/Main Menu/main_menu.tscn"
	var scene = load(main_menu_path)
	assert_not_null(scene, "Main menu scene should be loaded")
	
	var main_menu = scene.instantiate()
	assert_not_null(main_menu, "Main menu should instantiate successfully")
	add_child_autofree(main_menu)
	await get_tree().process_frame

func test_main_menu_has_buttons():
	"""Test that main menu has Continue, New Game, and Quit buttons"""
	var main_menu_path = "res://scenes/Main Menu/main_menu.tscn"
	var scene = load(main_menu_path)
	var main_menu = scene.instantiate()
	add_child_autofree(main_menu)
	await get_tree().process_frame
	
	# Check for specific buttons
	var continue_button = main_menu.find_child("ContinueButton", true, false)
	var new_game_button = main_menu.find_child("NewGameButton", true, false)
	var quit_button = main_menu.find_child("QuitButton", true, false)
	
	assert_not_null(continue_button, "Main menu should have ContinueButton")
	assert_not_null(new_game_button, "Main menu should have NewGameButton")
	assert_not_null(quit_button, "Main menu should have QuitButton")
	
	print("✅ Found ContinueButton")
	print("✅ Found NewGameButton")
	print("✅ Found QuitButton")

func test_main_menu_buttons_connected():
	"""Test that main menu buttons have signal handlers connected"""
	var main_menu_path = "res://scenes/Main Menu/main_menu.tscn"
	var scene = load(main_menu_path)
	var main_menu = scene.instantiate()
	add_child_autofree(main_menu)
	await get_tree().process_frame
	
	var continue_button = main_menu.find_child("ContinueButton", true, false)
	var new_game_button = main_menu.find_child("NewGameButton", true, false)
	var quit_button = main_menu.find_child("QuitButton", true, false)
	
	# Check if buttons have pressed signal connections
	assert_gt(continue_button.pressed.get_connections().size(), 0, "ContinueButton should have signal connections")
	assert_gt(new_game_button.pressed.get_connections().size(), 0, "NewGameButton should have signal connections")
	assert_gt(quit_button.pressed.get_connections().size(), 0, "QuitButton should have signal connections")
	
	print("✅ All buttons have signal handlers connected")

func test_continue_button_initial_state():
	"""Test that Continue button state depends on SaveManager.has_save_file()"""
	var main_menu_path = "res://scenes/Main Menu/main_menu.tscn"
	var scene = load(main_menu_path)
	var main_menu = scene.instantiate()
	add_child_autofree(main_menu)
	await get_tree().process_frame
	
	var continue_button = main_menu.find_child("ContinueButton", true, false)
	assert_not_null(continue_button, "ContinueButton should exist")
	
	var has_save = SaveManager.has_save_file() if SaveManager else false
	var button_enabled = not continue_button.disabled
	
	assert_eq(button_enabled, has_save, "Continue button enabled state should match SaveManager.has_save_file()")
	
	if has_save:
		print("✅ Continue button is enabled (save file exists)")
	else:
		print("✅ Continue button is disabled (no save file)")
