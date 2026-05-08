extends Node

var audio_player: AudioStreamPlayer

var sounds: Dictionary = {
	"start": "res://SoundEffects/Start.wav",
	"control": "res://SoundEffects/Control.wav",
	"talk": "res://SoundEffects/Talk.wav",
	"be_killed": "res://SoundEffects/BeKilled.wav",
	"uncontrol": "res://SoundEffects/Uncontrol.wav",
	"hurt": "res://SoundEffects/Hurt.wav",
	"use": "res://SoundEffects/Use.wav",
	"enhance": "res://SoundEffects/Enhance.wav",
	"choose": "res://SoundEffects/Choose.wav",
	"enemy_appear": "res://SoundEffects/EnemyAppear.wav"
}

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

func play_sound(sound_name: String) -> void:
	if sound_name in sounds:
		var path = sounds[sound_name]
		if ResourceLoader.exists(path):
			audio_player.stream = load(path)
			audio_player.play()

func play_start() -> void:
	play_sound("start")

func play_control() -> void:
	play_sound("control")

func play_talk() -> void:
	play_sound("talk")

func play_be_killed() -> void:
	play_sound("be_killed")

func play_uncontrol() -> void:
	play_sound("uncontrol")

func play_hurt() -> void:
	play_sound("hurt")

func play_use() -> void:
	play_sound("use")

func play_enhance() -> void:
	play_sound("enhance")

func play_choose() -> void:
	play_sound("choose")

func play_enemy_appear() -> void:
	play_sound("enemy_appear")