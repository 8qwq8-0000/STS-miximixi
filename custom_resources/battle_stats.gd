class_name BattleStats
extends Resource

## 0 = 前 3 层，1 = 中途，2 = Boss，3 = 精英房。
@export_range(0, 3) var battle_tier: int
@export_range(0.0, 10.0) var weight: float
@export var gold_reward_min: int
@export var gold_reward_max: int
## Either point at a hand-made enemy scene, or list ids from the 怪物名册.
@export var enemies: PackedScene
@export var monster_ids: Array[String] = []
## 每只怪各自站哪里（设计分辨率坐标），空的话由 enemy_handler 的通用表决定。
## 通用遭遇档会把自己的站位表抄进来；手写混编组合留空即可。
@export var slot_positions: Array[Vector2] = []

var accumulated_weight: float = 0.0


func roll_gold_reward() -> int:
	var rolled := RNG.instance.randi_range(gold_reward_min, gold_reward_max)
	return EnemyConfig.get_config().scale_gold(rolled)
