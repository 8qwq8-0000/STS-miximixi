class_name DragonFlameStatus
extends Status

## 龙炎 — two extra energy every turn, and every card you play burns a random
## enemy. It lasts for the rest of the battle, like 金属化.

func get_tooltip() -> String:
	return tooltip % stacks
