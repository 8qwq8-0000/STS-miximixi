class_name Minion
extends Enemy

## A friendly enemy.
##
## It runs the very same AI scene its enemy uses — same actions, same intents,
## same weighted randomness — with two things redirected:
##   * attack intents are aimed at a random enemy instead of at the player;
##   * self-buffs (block, muscle) land on the player instead of on the minion.
## It acts right after the player ends their turn, which is before the enemies.

signal action_finished

const ACTION_TIMEOUT := 4.0

## Actions that carry a damage value are the ones aimed at the opponent.
const DAMAGE_PROPERTY := "damage"


## Takes over the enemy's data: looks, health and the whole action set.
func configure(minion_stats: EnemyStats) -> void:
	if minion_stats == null:
		return
	stats = minion_stats


## 秒杀 — a player attack aimed at one of their own minions takes it off the
## board outright. The overshoot goes through whatever block it banked, and the
## normal death path still runs (so it can leave a 掉落物 behind).
func slay() -> void:
	if not stats or stats.health <= 0:
		return

	take_damage(stats.health + stats.block + 1, Modifier.Type.DMG_TAKEN)


func update_enemy() -> void:
	if not stats is Stats:
		return
	if not is_inside_tree():
		await ready

	sprite_2d.texture = stats.art
	fit_sprite()
	update_stats()
	setup_ai()
	update_action()


## Same AI scene the enemy runs; only the buff receiver is redirected.
func setup_ai() -> void:
	if enemy_action_picker:
		enemy_action_picker.queue_free()

	var picker := stats.ai.instantiate() as EnemyActionPicker
	picker.set("monster_id", stats.monster_id)
	add_child(picker)
	enemy_action_picker = picker
	enemy_action_picker.enemy = self

	for action in picker.get_children():
		if action is EnemyAction:
			action.buff_target_override = enemy_action_picker.target


func update_intent() -> void:
	if current_action == null:
		intent_ui.hide()
		return

	if _deals_damage():
		if current_action is MoveAction:
			# A scripted move already describes itself, multi-hit attacks
			# included, and measures the minion's own damage bonus.
			current_action.update_intent_text()
		else:
			# Enemy attack intents are formatted against the player they are
			# about to hit. A minion hits a random enemy, so show the raw damage.
			current_action.intent.current_text = (
				current_action.intent.base_text % int(current_action.get(DAMAGE_PROPERTY))
			)
	else:
		current_action.update_intent_text()

	intent_ui.update_intent(current_action.intent)


func perform_turn() -> void:
	if current_action == null:
		update_action()
	if current_action == null:
		_finish_action()
		return

	if _deals_damage():
		var victim := _pick_enemy()
		if victim == null:
			_finish_action()
			return
		current_action.target = victim

	if not Events.enemy_action_completed.is_connected(_on_enemy_action_completed):
		Events.enemy_action_completed.connect(_on_enemy_action_completed)

	# Actions report back when they are done. The timer only exists so a
	# misbehaving action can never stall the turn forever.
	get_tree().create_timer(ACTION_TIMEOUT).timeout.connect(_finish_action)

	current_action.perform_action()


func _on_enemy_action_completed(enemy: Enemy) -> void:
	if enemy != self:
		return
	_finish_action()


func _finish_action() -> void:
	if Events.enemy_action_completed.is_connected(_on_enemy_action_completed):
		Events.enemy_action_completed.disconnect(_on_enemy_action_completed)
	action_finished.emit()


func _deals_damage() -> bool:
	if current_action == null:
		return false
	var value: Variant = current_action.get(DAMAGE_PROPERTY)
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _pick_enemy() -> Node2D:
	var living: Array[Node] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			living.append(node)
	if living.is_empty():
		return null
	return RNG.array_pick_random(living) as Node2D
