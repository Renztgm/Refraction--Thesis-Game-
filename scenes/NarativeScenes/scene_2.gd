extends Node3D

# Add this to any scene and press Enter to test
func _input(event):
	if event.is_action_pressed("ui_home"):  # Enter key
		print("=== FULL SAVE/LOAD TEST ===")
		
		# Test save
		print("1. Testing save...")
		var save_result = SaveManager.save_game()
		print("Save result: ", save_result)
		
		# Test immediate count check
		print("2. Testing count immediately after save...")
		var count = SaveManager.get_save_count()
		print("Count: ", count)
		
		# Test load
		print("3. Testing load...")
		var load_result = SaveManager.load_game()
		print("Load result: ", load_result)
		
		# Test continue
		print("4. Testing continue...")
		var continue_result = SaveManager.has_save_file()
		print("Has save file: ", continue_result)
		
		print("=== TEST COMPLETE ===")
