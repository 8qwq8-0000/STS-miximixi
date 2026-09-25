class_name EncounterTier
extends Resource

## 一条通用遭遇档。
##
## 「哪几只怪」不写死在这里：够格的怪会自动平摊这一档的权重，所以一档加多少怪
## 都不会把这一档的比重冲歪。档本身只描述形状——几只怪、落在哪一层、多重、给多
## 少金币。

## 这一档收哪一类怪。BOSS 加在最后，免得改到已有数值。
enum Audience {NORMAL, ELITE, BOSS}

## 认人用的标识，同一份配置里不要重复。
@export var id: String = ""

## 只用来在检查器里认人，不影响游戏。
@export var name: String = ""

## 关掉这一档，它就不再产出任何遭遇。
@export var enabled := true

## 只有这一类怪能填这一档。普通怪和精英分开，就不会出现「三只巨金怪」。
@export var audience: Audience = Audience.NORMAL

## 这一档一场出几只怪。
@export_range(1, 4, 1) var count := 1

## 这一档的怪各自站哪里，按顺序一只一个坐标。
##
## 直接抄蓝本场景（螃蟹那一档）的摆放，这样自动生成的遭遇和手写的那一场是同一个
## 构图；写少了剩下的怪走引擎的通用兜底表，写多了忽略多余的坐标。
@export var positions: Array[Vector2] = []

## 战斗层级：0 = 前 3 层，1 = 中途，2 = Boss，3 = 精英房。
##
## 第 0 档是「开局的几场」专用，只放教程那三只（蝙蝠 / 螃蟹 / 毒幽灵）的固定编队；
## 名册怪和手写组合都放第 1 档，否则一开局就会碰上后面的怪。放错了引擎会警告。
@export_range(0, 3, 1) var battle_tier := 1

## 和同层级的其它档一起抽时的权重。整档共用，再按每只怪自己的
## encounter_weight 平摊下去。
@export_range(0.0, 10.0, 0.1) var weight := 1.0

@export var gold_min := 20
@export var gold_max := 40


func make_battle(monster_id: String, monster_weight: float) -> BattleStats:
	var battle := BattleStats.new()
	battle.battle_tier = battle_tier
	battle.gold_reward_min = gold_min
	battle.gold_reward_max = gold_max
	battle.weight = monster_weight
	battle.slot_positions = positions.duplicate()

	var ids: Array[String] = []
	for _i in range(count):
		ids.append(monster_id)
	battle.monster_ids = ids
	return battle
