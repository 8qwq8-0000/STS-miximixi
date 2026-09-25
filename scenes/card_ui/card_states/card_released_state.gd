extends CardState


func enter() -> void:
	var accepted := card_ui.get_accepted_targets()
	if accepted.is_empty():
		return

	card_ui.targets = accepted
	Events.tooltip_hide_requested.emit()
	card_ui.play()


func post_enter() -> void:
	transition_requested.emit(self, CardState.State.BASE)
