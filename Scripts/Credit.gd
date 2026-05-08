extends Control

func _ready() -> void:
	var back_button = $BackButton
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	await TransitionManager.transition_to_title()
