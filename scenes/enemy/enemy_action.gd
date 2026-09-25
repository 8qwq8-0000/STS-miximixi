class_name EnemyAction
extends Node

enum Type {CONDITIONAL, CHANCE_BASED}

const LUNGE_DISTANCE := 80.0

@export var intent: Intent
@export var sound: AudioStream
@export var type: Type
@export_range(0.0, 10.0) var chance_weight := 0.0

@onready var accumulated_weight := 0.0

var enemy: Enemy
var target: Node2D

## Who receives this action's non-attack effects (block, buffs). Enemies buff
## themselves, so this stays empty for them; a minion points it at its owner,
## which makes a minion's defend intent hand the block to the player instead.
var buff_target_override: Node2D


func is_performable() -> bool:
	return false


func perform_action() -> void:
	pass


func get_buff_target() -> Node2D:
	return buff_target_override if buff_target_override else enemy


## 敌怪数值配置在这里过一道，手写动作和名册怪物用的是同一套倍率
## （res://enemy_config.tres）。
func scaled_damage(value: int) -> int:
	return EnemyConfig.get_config().scale_damage(value)


func scaled_block(value: int) -> int:
	return EnemyConfig.get_config().scale_block(value)


## Where the actor should stop when lunging at Target: in front of it, on
## whichever side the actor is coming from.
func get_lunge_position() -> Vector2:
	var direction := 1.0 if target.global_position.x > enemy.global_position.x else -1.0
	return target.global_position - Vector2.RIGHT * LUNGE_DISTANCE * direction


func update_intent_text() -> void:
	intent.current_text = intent.base_text
