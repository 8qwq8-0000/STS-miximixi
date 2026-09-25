class_name DecayingStatus
extends Status

## A buff that spends one stack every time it fires and disappears with the
## last one (StatusUI frees any INTENSITY status whose stacks reach 0).
##
## 壁垒 / 带电 / 守护 / 保留 all behave this way and only differ in what they
## mean, so they share this script and are told apart by their `id`: the code
## that cares asks the status handler whether that id is present.

func get_tooltip() -> String:
	return tooltip % stacks


func apply_status(target: Node) -> void:
	_apply(target)

	if stacks > 0:
		stacks -= 1

	status_applied.emit(self)


## Hook for the subclasses that need to do something on their turn.
func _apply(_target: Node) -> void:
	pass
