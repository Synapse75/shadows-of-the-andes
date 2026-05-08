extends Control

func _ready() -> void:
	var back_button = $BackButton
	back_button.pressed.connect(_on_back_pressed)
	
	# 播放背景音乐
	get_tree().root.get_node("AudioManager").play_music("hidden")

func _on_back_pressed() -> void:
	await TransitionManager.transition_to_title()
