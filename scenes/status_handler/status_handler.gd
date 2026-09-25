class_name StatusHandler
extends GridContainer

signal statuses_applied(type: Status.Type)

const STATUS_APPLY_INTERVAL := 0.25
const STATUS_UI = preload("res://scenes/status_handler/status_ui.tscn")

@export var status_owner: Node2D


func apply_statuses_by_type(type: Status.Type) -> void:
	if type == Status.Type.EVENT_BASED:
		return
		
	var status_queue: Array[Status] = _get_all_statuses().filter(
		func(status: Status):
			return status.type == type
	)
	if status_queue.is_empty():
		statuses_applied.emit(type)
		return
	
	var tween := create_tween()
	for status: Status in status_queue:
		tween.tween_callback(status.apply_status.bind(status_owner))
		tween.tween_interval(STATUS_APPLY_INTERVAL)
	
	tween.finished.connect(func(): statuses_applied.emit(type))


func add_status(status: Status) -> void:
	# 净化 spends a stack to swallow an incoming 负面效果 outright.
	if status.is_debuff and absorbs_debuff():
		return

	_warn_debuff_timing(status)

	var stackable := status.stack_type != Status.StackType.NONE
	
	# Add it if it's new
	if not _has_status(status.id):
		var new_status_ui := STATUS_UI.instantiate() as StatusUI
		add_child(new_status_ui)
		new_status_ui.status = status
		new_status_ui.status.status_applied.connect(_on_status_applied)
		new_status_ui.status.initialize_status(status_owner)
		return

	# If it's unique and we already have it, we can return
	if not status.can_expire and not stackable:
		return
	
	# If it's duration-stackable, expand it
	if status.can_expire and status.stack_type == Status.StackType.DURATION:
		_get_status(status.id).duration += status.duration
		return
	
	# If it's stackable, stack it
	if status.stack_type == Status.StackType.INTENSITY:
		_get_status(status.id).stacks += status.stacks
	

func _has_status(id: String) -> bool:
	return has_status(id)


func has_status(id: String) -> bool:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return true
			
	return false


func _get_status(id: String) -> Status:
	return get_status(id)


func get_status(id: String) -> Status:
	for status_ui: StatusUI in get_children():
		if status_ui.status.id == id:
			return status_ui.status
	
	return null


func _get_all_statuses() -> Array[Status]:
	return get_all_statuses()


func get_all_statuses() -> Array[Status]:
	var statuses: Array[Status] = []
	for status_ui: StatusUI in get_children():
		statuses.append(status_ui.status)
		
	return statuses


## Spends one 净化 stack and reports whether a debuff was absorbed.
func absorbs_debuff() -> bool:
	var purify := get_status("purify")
	if purify == null or purify.stacks <= 0:
		return false

	purify.stacks -= 1
	return true


## 负面效果如果配成「回合开始」结算，会在玩家行动之前就掉一层——这正是之前寄生
## 种子那个问题的成因。这里提醒一次，省得下次又踩。
static var _timing_warned: Array[String] = []


func _warn_debuff_timing(status: Status) -> void:
	if not status.is_debuff or status.type != Status.Type.START_OF_TURN:
		return
	if _timing_warned.has(status.id):
		return

	_timing_warned.append(status.id)
	push_warning(
		"状态 %s 标着负面效果，结算时机却是「回合开始」；负面效果应该用 END_OF_TURN，否则会在玩家行动前先掉一层。" % status.id
	)


func _on_status_applied(status: Status) -> void:
	if status.can_expire:
		status.duration -= 1


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		Events.status_tooltip_requested.emit(_get_all_statuses())
