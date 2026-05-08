extends Node

var audio_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var current_music: String = ""

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

var music_tracks: Dictionary = {
	"knees_beats": "res://Musics/382584__nttb__nttb-knees-beats.wav",
	"hidden": "res://Musics/556524__casonika__hidden.wav"
}

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.volume_db = -10.5  # 降低到30%音量
	add_child(audio_player)
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	# 连接音乐播放完毕信号以实现循环
	music_player.finished.connect(_on_music_finished)

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

func play_music(music_name: String) -> void:
	"""播放背景音乐（循环）"""
	if music_name in music_tracks:
		# 如果已经在播放同一首音乐，则不重新播放
		if current_music == music_name and music_player.playing:
			return
		
		var path = music_tracks[music_name]
		if ResourceLoader.exists(path):
			var stream = load(path)
			music_player.stream = stream
			music_player.bus = "Master"
			music_player.play()
			current_music = music_name

func stop_music() -> void:
	"""停止背景音乐"""
	if music_player.playing:
		music_player.stop()
	current_music = ""

func _on_music_finished() -> void:
	"""音乐播放完毕后自动重新播放（循环）"""
	if current_music != "":
		if current_music in music_tracks:
			var path = music_tracks[current_music]
			if ResourceLoader.exists(path):
				music_player.stream = load(path)
				music_player.play()
