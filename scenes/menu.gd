extends CanvasLayer

func _ready() -> void:
	if GameState.current_mode == GameState.GameMode.MENU:
		self.show()  # Make sure the menu is visible
		$Control/VBoxContainer/b_new_game.grab_focus()
	else:
		self.hide()  # Hide the menu if not in menu mode



func _on_button_pressed() -> void:
	GameState.current_mode = GameState.GameMode.PLAYING
	$".".hide()  # Hide the menu
	$"../CanvasLayer".show()         # Show the game HUD (if hidden initially)
