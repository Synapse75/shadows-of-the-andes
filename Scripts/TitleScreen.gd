extends Control

func _ready() -> void:
	var start_button = $VBoxContainer/StartButton
	var credit_button = $VBoxContainer/CreditButton
	var exit_button = $VBoxContainer/ExitButton

	# Keep only signal connections; styling will be handled in the editor
	start_button.pressed.connect(_on_start_pressed)
	credit_button.pressed.connect(_on_credit_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	await TransitionManager.transition_to_story()

func _on_credit_pressed() -> void:
	await TransitionManager.transition_to_credit()

func _on_exit_pressed() -> void:
	get_tree().quit()
