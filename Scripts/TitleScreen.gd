extends Control

func _ready() -> void:
	var start_button = $VBoxContainer/StartButton
	var credit_button = $VBoxContainer/CreditButton
	var exit_button = $VBoxContainer/ExitButton
	
	start_button.pressed.connect(_on_start_pressed)
	credit_button.pressed.connect(_on_credit_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_credit_pressed() -> void:
	# TODO: Implement credit scene
	pass

func _on_exit_pressed() -> void:
	get_tree().quit()
