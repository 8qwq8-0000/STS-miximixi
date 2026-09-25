extends CardState

## Dragging the cursor into the bottom strip of the screen puts the card back in
## the hand, the way the tutorial's fixed line did.
##
## It has to be a share of the viewport instead of a pixel value: 345 was the
## bottom strip of the 640x360 design, and as soon as the viewport got taller the
## line ended up above the hand. The hand is anchored to the bottom, so every aim
## started below the line and was cancelled on the next mouse event, which is why
## no arrow ever appeared. 4% of the height is that same 15 px strip.
const SNAPBACK_STRIP_RATIO := 0.04

## True once the cursor has been above the cancel line at least once. Without
## this, a card grabbed from the bottom edge of the hand would cancel its own
## aim before the arrow could ever appear.
var escaped_snapback_strip := false


func enter() -> void:
	card_ui.targets.clear()
	var offset := Vector2(card_ui.parent.size.x / 2, -card_ui.size.y / 2)
	offset.x -= card_ui.size.x / 2
	card_ui.animate_to_position(card_ui.parent.global_position + offset, 0.2)
	card_ui.drop_point_detector.monitoring = false
	escaped_snapback_strip = false
	Events.card_aim_started.emit(card_ui)


func exit() -> void:
	Events.card_aim_ended.emit(card_ui)


func on_input(event: InputEvent) -> void:	
	var mouse_motion := event is InputEventMouseMotion
	var mouse_at_bottom := _mouse_in_snapback_strip()
	
	if (mouse_motion and mouse_at_bottom) or event.is_action_pressed("right_mouse"):
		card_ui.targets.clear()
		transition_requested.emit(self, CardState.State.BASE)
	elif event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse"):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, CardState.State.RELEASED)


## The strip along the bottom edge of the screen, below the hand.
func _mouse_in_snapback_strip() -> bool:
	var viewport_height := card_ui.get_viewport_rect().size.y
	if viewport_height <= 0.0:
		return false

	var in_strip := (
		card_ui.get_global_mouse_position().y > viewport_height * (1.0 - SNAPBACK_STRIP_RATIO)
	)
	if not in_strip:
		escaped_snapback_strip = true
		return false

	return escaped_snapback_strip
