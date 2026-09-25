class_name EnemyConfig
extends Resource

## 敌怪数值总开关。
##
## Edit res://enemy_config.tres in the inspector — no code changes needed. The
## scales are applied where the numbers are actually used, so one file covers the
## hand-made enemies (蝙蝠 / 螃蟹 / 毒幽灵), the whole 怪物名册, and any monster
## the player summons as a minion.
##
## 这里只有一层：全局倍率。想单独调某一只怪，去改它自己的文件
## res://monsters/<id>.tres —— 血量、招式数值都是那只怪的原始数据。
##
## 名单表的「敌怪生命值 / 攻击」是为完整版游戏算的，比这个教程角色（35 血、单回合
## 十来点伤害）大好几倍。把生命/伤害一起调到 0.3 左右，整份名册就会落到现有螃蟹、
## 毒幽灵那一档。

const PATH := "res://enemy_config.tres"

@export_group("数值倍率")

## 生命值。0.3 会把绿毛虫从 160 压到 48。
@export_range(0.05, 3.0, 0.05) var health_scale := 1.0

## 攻击伤害。
@export_range(0.05, 3.0, 0.05) var damage_scale := 1.0

## 敌人给自己加的格挡。
@export_range(0.05, 3.0, 0.05) var block_scale := 1.0

## 敌人给自己回的血。
@export_range(0.05, 3.0, 0.05) var heal_scale := 1.0

## 战斗金币奖励。
@export_range(0.0, 5.0, 0.1) var gold_scale := 1.0

static var _cached: EnemyConfig


## Shared instance. The loader caches resources, so this is the very object the
## inspector edits.
static func get_config() -> EnemyConfig:
	if _cached:
		return _cached

	_cached = load(PATH) as EnemyConfig
	if _cached == null:
		push_warning("EnemyConfig: 找不到 %s，先用默认倍率 1.0 顶着。" % PATH)
		_cached = EnemyConfig.new()

	return _cached


## Drops the cache and reads the file again. Only needed if something edits the
## config mid-session; a fresh play session always picks the file up anyway.
## (Named `load_config` rather than `reload` so it cannot collide with anything on
## Resource.)
static func load_config() -> EnemyConfig:
	_cached = null
	return get_config()


func scale_health(value: int) -> int:
	return _scale(value, health_scale)


func scale_damage(value: int) -> int:
	return _scale(value, damage_scale)


func scale_block(value: int) -> int:
	return _scale(value, block_scale)


func scale_heal(value: int) -> int:
	return _scale(value, heal_scale)


func scale_gold(value: int) -> int:
	return _scale(value, gold_scale)


## Zero stays zero; anything else is scaled and never rounded away to nothing.
static func _scale(value: int, factor: float) -> int:
	if value == 0 or factor == 1.0:
		return value

	return maxi(1, roundi(value * factor))
