extends Node

# Global message logging system
# Emits signals for UI to listen to and display messages

signal message_added(message: String, type: String)
signal messages_cleared()

const MAX_HISTORY = 50

var message_history: Array[Dictionary] = []

func _ready() -> void:
	name = "MessageLog"

func add_message(text: String, type: String = "info") -> void:
	"""Add a new message to the log and emit signal"""
	if text.is_empty():
		return
	
	var message_dict = {
		"text": text,
		"type": type,
		"timestamp": Time.get_ticks_msec()
	}
	
	message_history.append(message_dict)
	
	# Keep only recent messages to prevent memory leak
	if message_history.size() > MAX_HISTORY:
		message_history.pop_front()
	
	print("[MessageLog] %s: %s" % [type.to_upper(), text])
	message_added.emit(text, type)

func clear_history() -> void:
	"""Clear all message history"""
	message_history.clear()
	messages_cleared.emit()

func get_all_messages() -> Array[Dictionary]:
	"""Return a copy of all messages"""
	return message_history.duplicate()

func get_recent_messages(count: int = 10) -> Array[Dictionary]:
	"""Return the N most recent messages"""
	var start = maxi(0, message_history.size() - count)
	return message_history.slice(start).duplicate()
