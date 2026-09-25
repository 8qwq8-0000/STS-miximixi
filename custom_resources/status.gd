class_name Status
extends Resource

signal status_applied(status: Status)
signal status_changed

enum Type {START_OF_TURN, END_OF_TURN, EVENT_BASED}
enum StackType {NONE, INTENSITY, DURATION}

@export_group("Status Data")
@export var id: String
## 什么时候结算这一层。
##
## START_OF_TURN：持有者的回合一开始就算（增益基本都用这个）。
## END_OF_TURN：回合结束后才算 —— **负面效果必须用这个**。敌人是在自己的回合里
## 给你挂 debuff 的，如果用 START_OF_TURN，轮到你的回合时它先掉一层，等于你还没
## 动过它就没了；用 END_OF_TURN 才能完整覆盖你接下来的一整个回合。
## EVENT_BASED：不自动结算，只由别处的代码手动消耗。
@export var type: Type
@export var stack_type: StackType
@export var can_expire: bool
## Marks the status as a 负面效果 so 净化 knows what to swallow.
@export var is_debuff: bool = false
@export var duration: int : set = set_duration
@export var stacks: int : set = set_stacks

@export_group("Status Visuals")
@export var icon: Texture
@export_multiline var tooltip: String


func initialize_status(_target: Node) -> void:
	pass


func apply_status(_target: Node) -> void:
	status_applied.emit(self)


func get_tooltip() -> String:
	return tooltip


func set_duration(new_duration: int) -> void:
	duration = new_duration
	status_changed.emit()


func set_stacks(new_stacks: int) -> void:
	stacks = new_stacks
	status_changed.emit()
