class_name MoveCycleAI
extends EnemyActionPicker

## 攻击模式 — plays a scripted cycle instead of rolling weighted dice.
##
## The design document gives every monster a fixed sequence such as
## 吐丝 → 虫咬 → 蜷缩 → 撞击. This picker walks that list in order and loops
## back to the top, which is what makes a monster's turn readable and lets the
## player plan around it.

@export var monster_id: String

var _actions: Array[EnemyAction] = []
var _index := 0


func _ready() -> void:
	_build()
	target = get_tree().get_first_node_in_group("player")


## A scripted cycle is never overridden by a "smarter" branch mid-round.
func get_first_conditional_action() -> EnemyAction:
	return null


func get_action() -> EnemyAction:
	if _actions.is_empty():
		return null

	var action := _actions[_index % _actions.size()]
	_index += 1
	return action


func _build() -> void:
	for move in MonsterBook.moves(monster_id):
		var action := MonsterBook.make_action(move)
		add_child(action)
		_actions.append(action)
