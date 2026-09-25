class_name MetallicizeStatus
extends Status

## 金属化 — flat block at the start of every turn, for the whole battle.
## It never decays, so it is the one buff that does not use DecayingStatus.

func get_tooltip() -> String:
	return tooltip % stacks


func apply_status(target: Node) -> void:
	if target.get("stats"):
		target.stats.block += stacks

	status_applied.emit(self)
