class_name MiracleStatus
extends DecayingStatus

## 奇迹 — at the start of the turn every other buff on the same creature grows
## by one stack, then 奇迹 itself spends one.

func _apply(target: Node) -> void:
	var handler: StatusHandler = target.get("status_handler")
	if handler == null:
		return

	for other: Status in handler.get_all_statuses():
		if other == self or other.id == "miracle" or other.stack_type != Status.StackType.INTENSITY:
			continue

		other.stacks += 1
