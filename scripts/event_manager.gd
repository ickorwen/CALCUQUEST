extends Node

signal event_marked(event_name: String)

@export var events := {}

func mark_event(name: String) -> void:
	if not events.get(name, false):
		events[name] = true
		emit_signal("event_marked", name)

func has_event(name: String) -> bool:
	return events.get(name, false)
