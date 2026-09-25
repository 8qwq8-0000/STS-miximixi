class_name Player
extends Node2D

const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")

@export var stats: CharacterStats : set = set_character_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var stats_ui: StatsUI = $StatsUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler


func _ready() -> void:
	status_handler.status_owner = self


func set_character_stats(value: CharacterStats) -> void:
	stats = value
	
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)

	update_player()


func update_player() -> void:
	if not stats is CharacterStats: 
		return
	if not is_inside_tree(): 
		await ready

	sprite_2d.texture = stats.art
	update_stats()


func update_stats() -> void:
	stats_ui.update_stats(stats)


func take_damage(damage: int, which_modifier: Modifier.Type) -> void:
	# 开发者模式：一滴血都不掉，连闪白和震屏都省了。
	if GameSettings.developer_mode:
		return

	if stats.health <= 0:
		return
	
	sprite_2d.material = WHITE_SPRITE_MATERIAL
	# 守护 spends one stack and blanks the hit completely.
	if _consume_status("guard"):
		return

	var modified_damage := modifier_handler.get_modified_value(damage, which_modifier)
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 32, 0.15))
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)
	
	tween.finished.connect(
		func():
			sprite_2d.material = null
			
			if stats.health <= 0:
				# 涅槃 undoes the killing blow instead of ending the run.
				if _consume_status("nirvana"):
					stats.health = stats.max_health
					return

				Events.player_died.emit()
				queue_free()
	)


## Spends one stack of an INTENSITY status and reports whether it was there.
## StatusUI removes the status on its own once the last stack is gone.
func _consume_status(id: String) -> bool:
	if not status_handler:
		return false

	var status := status_handler.get_status(id)
	if status == null or status.stacks <= 0:
		return false

	status.stacks -= 1
	return true
