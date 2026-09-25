class_name BattleStatsPool
extends Resource

@export var pool: Array[BattleStats]

## When on, every monster in the 怪物名册 also becomes a possible encounter, so
## a roster of 37 does not need 37 hand-written battle scenes. The extra entries
## are plain BattleStats, which save with the map like any other.
@export var use_monster_roster := true

## 0 = 前 3 层，1 = 中途，2 = Boss，3 = 精英房。
const TIER_COUNT := 4

var total_weights_by_tier := [0.0, 0.0, 0.0, 0.0]

## The pool resource is cached by the loader, so this survives a second run in the
## same session and keeps the roster from being appended twice.
var _roster_built := false


func _get_all_battles_for_tier(tier: int) -> Array[BattleStats]:
	return pool.filter(
		func(battle: BattleStats):
			return battle.battle_tier == tier
	)


func _setup_weight_for_tier(tier: int) -> void:
	var battles := _get_all_battles_for_tier(tier)
	total_weights_by_tier[tier] = 0.0
	
	for battle: BattleStats in battles:
		total_weights_by_tier[tier] += battle.weight
		battle.accumulated_weight = total_weights_by_tier[tier]


func get_random_battle_for_tier(tier: int) -> BattleStats:
	if tier < 0 or tier >= total_weights_by_tier.size():
		return null
	if total_weights_by_tier[tier] <= 0.0:
		return null

	var roll := randf_range(0.0, total_weights_by_tier[tier])
	var battles := _get_all_battles_for_tier(tier)
	
	for battle: BattleStats in battles:
		if battle.accumulated_weight > roll:
			return battle
		
	return null


## Whether a tier has anything to offer — the map generator asks before it sends
## the player into an elite room.
func has_tier(tier: int) -> bool:
	return not _get_all_battles_for_tier(tier).is_empty()


func setup() -> void:
	_ensure_roster_encounters()
	for i in total_weights_by_tier.size():
		_setup_weight_for_tier(i)


func _ensure_roster_encounters() -> void:
	if _roster_built:
		return

	_roster_built = true
	var added: Array[BattleStats] = []

	# 手写的混编组合：不受 use_monster_roster 影响，只要有配置就进池。
	for battle in EncounterConfig.get_config().battles():
		pool.append(battle)
		added.append(battle)

	if not use_monster_roster:
		_warn_about_intro_tier(added)
		return

	# 通用档由 encounter_config.tres 定义，够格的怪自动平摊每档的权重。
	for battle in EncounterConfig.get_config().tier_battles():
		pool.append(battle)
		added.append(battle)

	_warn_about_intro_tier(added)


## 第 0 档是前 3 层的开局遭遇，只该放蝙蝠 / 螃蟹 / 毒幽灵那几场固定编队。名册怪或
## 手写组合被放进这一档时会警告一次 —— 不悄悄改数据，但也别让人蒙在鼓里。
static var _intro_tier_warned := false


func _warn_about_intro_tier(battles: Array[BattleStats]) -> void:
	if _intro_tier_warned:
		return

	for battle: BattleStats in battles:
		if battle.battle_tier == 0:
			_intro_tier_warned = true
			push_warning(
				"遭遇池：有名册怪或手写组合被放进了第 0 档（前 3 层的开局遭遇）。那一档只该放教程三怪的编队。"
			)
			return
