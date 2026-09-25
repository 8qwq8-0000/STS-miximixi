class_name NirvanaStatus
extends Status

## 涅槃 — the first lethal hit each stack absorbs is undone: you come back at
## full health and lose one stack. Player.take_damage owns the trigger.

func get_tooltip() -> String:
	return tooltip % stacks
