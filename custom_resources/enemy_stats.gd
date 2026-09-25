class_name EnemyStats
extends Stats

@export var display_name: String
@export var ai: PackedScene
## 掉落物 — ingredient ids handed to the player when this creature dies.
@export var drops: Array[String] = []
## Set when this stats resource was built from the 怪物名册, so a shared
## MoveCycleAI scene knows which move list to play.
@export var monster_id: String


## 敌怪数值配置在这里落地：手写敌人和名册怪物走的是同一条路，改
## res://enemy_config.tres 就能一起调。玩家召唤的随从用的是同一份数据，所以也会
## 跟着缩放。
func create_instance() -> Resource:
	var instance: EnemyStats = self.duplicate()
	instance.max_health = EnemyConfig.get_config().scale_health(max_health)
	instance.health = instance.max_health
	instance.block = 0
	return instance
