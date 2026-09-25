class_name EnemyHandler
extends Node2D

var acting_enemies: Array[Enemy] = []


func _ready() -> void:
	Events.enemy_died.connect(_on_enemy_died)
	Events.enemy_action_completed.connect(_on_enemy_action_completed)
	Events.player_hand_drawn.connect(_on_player_hand_drawn)


func setup_enemies(battle_stats: BattleStats) -> void:
	if not battle_stats:
		return
	
	for enemy: Enemy in get_children():
		enemy.queue_free()
	
	# A battle either points at a hand-made enemy scene or lists monsters from
	# the design document's roster.
	if not battle_stats.monster_ids.is_empty():
		_spawn_roster(battle_stats)
		return

	var all_new_enemies := battle_stats.enemies.instantiate()
	
	for new_enemy: Node2D in all_new_enemies.get_children():
		var new_enemy_child := new_enemy.duplicate() as Enemy
		add_child(new_enemy_child)
		new_enemy_child.status_handler.statuses_applied.connect(_on_enemy_statuses_applied.bind(new_enemy_child))
		
	all_new_enemies.queue_free()


## Where roster monsters stand, in the 640x360 battle design space. These are the
## same spots the hand-made bat/crab scenes use, so a 1/2/3-monster roster fight
## lines up with the blueprint it was modelled on.
const ROSTER_LAYOUTS := {
	1: [Vector2(525, 207.5)],
	2: [Vector2(452.5, 187.5), Vector2(565, 187.5)],
	3: [Vector2(430, 182.5), Vector2(502.5, 135), Vector2(582.5, 182.5)],
	4: [Vector2(400, 190), Vector2(472.5, 140), Vector2(547.5, 190), Vector2(615, 140)],
}

## Fallback ring for anything past three (should not happen: the generic tiers
## cap out at three, and a hand-made combo is meant to stay small).
const EXTRA_SLOT_OFFSETS: Array[Vector2] = [
	Vector2(0, -70),
	Vector2(-70, 70),
	Vector2(70, 70),
]


func _spawn_roster(battle_stats: BattleStats) -> void:
	var monster_ids := battle_stats.monster_ids
	var enemy_scene := preload("res://scenes/enemy/enemy.tscn")
	for i in range(monster_ids.size()):
		var stats := MonsterBook.make_enemy_stats(monster_ids[i])
		if stats == null:
			continue

		var enemy := enemy_scene.instantiate() as Enemy
		add_child(enemy)
		enemy.position = _roster_slot(battle_stats, monster_ids.size(), i)
		enemy.stats = stats
		enemy.status_handler.statuses_applied.connect(_on_enemy_statuses_applied.bind(enemy))


## 站位优先用这一场自带的表（EncounterTier.positions，抄自蓝本场景）；
## 没有表的遭遇（手写混编组合、蓝本场景本身）继续用下面这张通用表。
func _roster_slot(battle_stats: BattleStats, count: int, index: int) -> Vector2:
	var slots := battle_stats.slot_positions
	if index < slots.size():
		return slots[index]

	if not slots.is_empty():
		return slots[slots.size() - 1] + EXTRA_SLOT_OFFSETS[index % EXTRA_SLOT_OFFSETS.size()]

	var layout: Array = ROSTER_LAYOUTS.get(count, [])
	if index < layout.size():
		return layout[index] as Vector2

	var anchor: Vector2 = layout[0] if not layout.is_empty() else Vector2(512.5, 187.5)
	var offset: Vector2 = EXTRA_SLOT_OFFSETS[index % EXTRA_SLOT_OFFSETS.size()]
	return anchor + offset


func reset_enemy_actions() -> void:
	for enemy: Enemy in get_children():
		enemy.current_action = null
		enemy.update_action()


func start_turn() -> void:
	if get_child_count() == 0:
		return
	
	acting_enemies.clear()
	for enemy: Enemy in get_children():
		acting_enemies.append(enemy)

	_start_next_enemy_turn()


func _start_next_enemy_turn() -> void:
	if acting_enemies.is_empty():
		Events.enemy_turn_ended.emit()
		return
	
	acting_enemies[0].status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)


func _on_enemy_statuses_applied(type: Status.Type, enemy: Enemy) -> void:
	match type:
		Status.Type.START_OF_TURN:
			enemy.do_turn()
		Status.Type.END_OF_TURN:
			acting_enemies.erase(enemy)
			_start_next_enemy_turn()


func _on_enemy_died(enemy: Enemy) -> void:
	# Minions are Enemies too, but they are never part of the enemy turn.
	if not is_ancestor_of(enemy):
		return

	var is_enemy_turn := acting_enemies.size() > 0
	acting_enemies.erase(enemy)
	
	if is_enemy_turn:
		_start_next_enemy_turn()


func _on_enemy_action_completed(enemy: Enemy) -> void:
	if not is_ancestor_of(enemy):
		return

	enemy.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)


func _on_player_hand_drawn() -> void:
	for enemy: Enemy in get_children():
		enemy.update_intent()
