extends Node

signal event_marked(event_name: String)
signal event_falsified(event_name: String)
var orb_first_try = true

@export var events := {}

func mark_event(name: String) -> void:
	if not events.get(name, false):
		events[name] = true
		emit_signal("event_marked", name)

func falsify_event(name: String) -> void:
	if events.get(name, true):
		events[name] = false
		emit_signal("event_falsified", name)

func has_event(name: String) -> bool:
	return events.get(name, false)
