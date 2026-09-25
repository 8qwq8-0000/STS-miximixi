class_name MinionHandler
extends Node2D

## Owns the minions for one battle and runs their turn.
##
## Battle wires the turn order as:
##   player_hand_discarded -> MinionHandler.start_turn
##   MinionHandler.turn_finished -> EnemyHandler.start_turn
## which is what makes minions swing before the enemies do.

signal turn_finished

const MINION_SCENE := preload("res://scenes/minion/minion.tscn")

## Spawn slots relative to the player, in the 640x360 battle design space.
const SPAWN_OFFSETS: Array[Vector2] = [
	Vector2(-75, -55),
	Vector2(75, -55),
	Vector2(-75, 55),
	Vector2(75, 55),
	Vector2(0, -72.5),
	Vector2(0, 72.5),
]
const VIEW_MARGIN := 32.5

@export var player: Player

var acting_minions: Array[Minion] = []
var spawn_index := 0


func _ready() -> void:
	Events.minion_summon_requested.connect(_on_minion_summon_requested)
	Events.player_hand_drawn.connect(_on_player_hand_drawn)


func setup_minions(minion_stats: Array[EnemyStats]) -> void:
	for child in get_children():
		child.queue_free()

	spawn_index = 0
	for stats in minion_stats:
		_spawn(stats)


## Called by a MinionCard. Temporary minions live for this battle only: they are
## never written back to the run's minion roster.
func summon_temporary(minion_stats: EnemyStats) -> void:
	_spawn(minion_stats)


func _on_minion_summon_requested(minion_stats: EnemyStats) -> void:
	summon_temporary(minion_stats)


func _spawn(minion_stats: EnemyStats) -> void:
	if minion_stats == null:
		return

	var minion := MINION_SCENE.instantiate() as Minion
	add_child(minion)
	minion.global_position = _slot_position(_origin(), spawn_index)
	spawn_index += 1
	minion.configure(minion_stats)


func _origin() -> Vector2:
	return player.global_position if player else Vector2.ZERO


func start_turn() -> void:
	acting_minions.clear()
	for child in get_children():
		if child is Minion:
			acting_minions.append(child)

	_start_next_minion()


func _start_next_minion() -> void:
	while not acting_minions.is_empty() and not is_instance_valid(acting_minions[0]):
		acting_minions.remove_at(0)

	if acting_minions.is_empty():
		reset_actions()
		turn_finished.emit()
		return

	var minion: Minion = acting_minions.pop_front()
	minion.action_finished.connect(_start_next_minion, CONNECT_ONE_SHOT)
	minion.perform_turn()


## Minions roll a fresh intent once their turn is over, exactly like enemies do.
func reset_actions() -> void:
	for child in get_children():
		if child is Minion:
			child.current_action = null
			child.update_action()


func _on_player_hand_drawn() -> void:
	for child in get_children():
		if child is Minion:
			child.update_intent()


## Ring of slots around the player; every extra six minions pushes the ring out.
func _slot_position(origin: Vector2, index: int) -> Vector2:
	var slot_count := SPAWN_OFFSETS.size()
	var ring := index / slot_count
	var offset := SPAWN_OFFSETS[index % slot_count] * (1.0 + 0.34 * float(ring))

	var view := get_viewport_rect().size
	return Vector2(
		clampf(origin.x + offset.x, VIEW_MARGIN, view.x - VIEW_MARGIN),
		clampf(origin.y + offset.y, VIEW_MARGIN, view.y - VIEW_MARGIN)
	)
