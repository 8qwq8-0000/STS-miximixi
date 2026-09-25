class_name SwiftStatus
extends DecayingStatus

## 迅捷 — draw N extra cards at the start of the turn, then lose one stack.

func _apply(target: Node) -> void:
	var handler := target.get_tree().get_first_node_in_group("player_handler") as PlayerHandler
	if handler == null:
		return

	handler.draw_cards(stacks)
