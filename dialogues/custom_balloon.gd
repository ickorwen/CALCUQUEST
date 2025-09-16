class_name CustomBalloon extends DialogueManagerExampleBalloon
## A custom dialogue balloon that supports a countdown timer

# Reference to EventManager for timeout events
@onready var EventManager = get_node("/root/EventManager")
@onready var dialogue_sound: AudioStreamPlayer = $DialogueSound

## Timer-related variables
var is_timed_dialogue: bool = false
var dialogue_timeout: float = 0
var time_remaining: float = 0

# Simple timer UI elements reference
@onready var timer_label: RichTextLabel = $Balloon/PanelContainer/TimerLabel

func _ready() -> void:
	# Call the parent _ready function first
	super()
	
	# Get a reference to the timer label if it wasn't found initially
	if not timer_label:
		timer_label = get_node_or_null("Balloon/PanelContainer/TimerLabel")
		if not timer_label:
			# Try finding it with a different path
			timer_label = find_child("TimerLabel", true, false)
			
	# Setup and hide the timer by default
	if timer_label:
		# Get reference to the timer container
		var timer_container = get_node_or_null("Balloon/PanelContainer")
		
		# Make sure we preserve the original font size from the theme (81)
		# This ensures that any existing theme overrides are not accidentally removed
		
		# Hide both container and label initially
		if timer_container:
			timer_container.hide()
		timer_label.hide()
	else:
		push_error("Timer label not found. Countdown timer will not work.")

func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio = dialogue_label.visible_ratio
		self.dialogue_line = await resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for input
	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


#region Signals

func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)

#endregion

#region Timer functionality

# Show the timer and set a timeout
func set_timeout(timeout: float) -> void:
	# Get reference to the timer container
	var timer_container = get_node_or_null("Balloon/PanelContainer")
	
	if timeout <= 0:
		is_timed_dialogue = false
		if timer_container:
			timer_container.hide()
		if timer_label:
			timer_label.hide()
		return
		
	is_timed_dialogue = true
	dialogue_timeout = timeout
	time_remaining = timeout
	
	# Show and update the timer
	if timer_label and timer_container:
		# Show both container and label
		timer_container.visible = true
		timer_container.show()
		timer_label.visible = true
		timer_label.show()
		
		_update_timer_display()
	else:
		push_error("Timer UI elements not available. Cannot show timer.")

# Hide the timer
func hide_timer() -> void:
	is_timed_dialogue = false
	# Hide both container and label
	var timer_container = get_node_or_null("Balloon/PanelContainer")
	if timer_container:
		timer_container.hide()
	if timer_label:
		timer_label.hide()

# Override _process to handle timer countdown
func _process(delta: float) -> void:
	# Update the timer if this is a timed dialogue
	if is_timed_dialogue:
		# Ensure timer container and label are visible at all times while active
		var timer_container = get_node_or_null("Balloon/PanelContainer")
		
		if timer_container and not timer_container.visible:
			timer_container.visible = true
			timer_container.show()
			
		if timer_label and not timer_label.visible:
			timer_label.visible = true
			timer_label.show()
			
		if time_remaining > 0:
			time_remaining -= delta
			if time_remaining <= 0:
				# Time's up! This dialogue should close
				time_remaining = 0
				
				# Set time up text and emit event
				if timer_label:
					timer_label.text = "TIME UP!"
					timer_label.visible = true  # Ensure it's visible
					
					# Emit a timeout event for the game to handle
					if resource and dialogue_line:
						# Notify the game that time ran out
						EventManager.mark_event("dialogue_timeout_" + str(dialogue_line.id))
					
					# Close after a short delay
					await get_tree().create_timer(0.5).timeout
					queue_free()
					return
				else:
					queue_free()
			
			# Update the timer display
			_update_timer_display()

# Update the timer display with formatted time
func _update_timer_display() -> void:
	if timer_label:
		# Get reference to container
		var timer_container = get_node_or_null("Balloon/PanelContainer")
		
		# Force visibility of both container and label
		if timer_container and not timer_container.visible:
			timer_container.visible = true
			timer_container.show()
			
		if not timer_label.visible:
			timer_label.visible = true
			timer_label.show()
		
		var minutes = floor(time_remaining / 60)
		var seconds = int(time_remaining) % 60
		var formatted_time = "%d:%02d" % [minutes, seconds]
		timer_label.text = formatted_time
		
		# Make it more noticeable
		if time_remaining <= 5:
			# Make it red when time is running out - preserve the original font size from the theme
			timer_label.add_theme_color_override("default_color", Color(1, 0, 0, 1))
			# Do not override the font size here - use the one from the scene (81)
		else:
			# Normal appearance - keep original font size
			timer_label.remove_theme_color_override("default_color")
			# Do not override the font size
	else:
		push_error("Cannot update timer display - timer_label is null")

# Function to force the timer to be visible (can be called from outside if needed)
func force_show_timer() -> void:
	var timer_container = get_node_or_null("Balloon/PanelContainer")
	
	if timer_container and timer_label:
		# Make both container and label visible
		timer_container.visible = true
		timer_container.show()
		timer_container.modulate = Color(1, 1, 1, 1)
		
		timer_label.visible = true
		timer_label.show()
		timer_label.modulate = Color(1, 1, 1, 1)
		
		_update_timer_display()

#endregion


func _on_dialogue_label_spoke(letter: String, letter_index: int, speed: float) -> void:
	if not letter in [" ", "."]:
		dialogue_sound.pitch_scale = randf_range(1.5, 2.0)
		dialogue_sound.play()
