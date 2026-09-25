class_name EncounterConfig
extends Resource

## 遭遇战配置：通用档 + 手写的混编组合。
##
## Edit res://encounter_config.tres in the inspector.
##
## `tiers` 是通用档：几只怪、落在哪一层、权重、金币。够格的怪会自动平摊这一档的
## 权重，所以加怪不会改变各档的比重。
##
## `mixed` 是手写组合：指定哪几只怪一起上，爱写几只写几只，权重单独给。

const PATH := "res://encounter_config.tres"

@export_group("通用档")
@export var tiers: Array[EncounterTier] = []

@export_group("手写混编组合")
@export var mixed: Array[MixedEncounter] = []

static var _cached: EncounterConfig


static func get_config() -> EncounterConfig:
	if _cached:
		return _cached

	_cached = load(PATH) as EncounterConfig
	if _cached == null:
		push_warning("EncounterConfig: 找不到 %s，本次跳过混编遭遇。" % PATH)
		_cached = EncounterConfig.new()

	return _cached


## 通用档产出的遭遇。每档的权重按每只怪自己的 encounter_weight 平摊下去。
func tier_battles() -> Array[BattleStats]:
	var result: Array[BattleStats] = []

	for tier: EncounterTier in tiers:
		if tier == null or not tier.enabled:
			continue

		var ids: Array[String] = []
		var total_weight := 0.0
		for monster_id in MonsterBook.all().keys():
			var id := str(monster_id)
			if not MonsterBook.can_fill_tier(id, tier):
				continue

			var share := MonsterBook.encounter_weight(id)
			if share <= 0.0:
				continue

			ids.append(id)
			total_weight += share

		if ids.is_empty() or total_weight <= 0.0:
			continue

		for monster_id in ids:
			var share := tier.weight * MonsterBook.encounter_weight(monster_id) / total_weight
			result.append(tier.make_battle(monster_id, share))

	return result


## The hand-made fights, as ready-to-use BattleStats.
##
## A row is all-or-nothing: if it names a monster that does not exist, or one
## that has been switched off in enemy_config.tres, the whole row is skipped. A
## half-strength version of an authored pairing would not be the fight anyone
## asked for.
func battles() -> Array[BattleStats]:
	var result: Array[BattleStats] = []

	for encounter: MixedEncounter in mixed:
		if encounter == null or not encounter.enabled:
			continue

		var ids: Array[String] = []
		var usable := true
		for entry: EncounterEntry in encounter.entries:
			if entry == null or not MonsterBook.has_monster(entry.monster_id):
				usable = false
				break
			if not MonsterBook.can_be_encounter(entry.monster_id):
				usable = false
				break

			for _i in range(entry.count):
				ids.append(entry.monster_id)

		if not usable or ids.is_empty():
			continue

		var battle := BattleStats.new()
		battle.battle_tier = encounter.battle_tier
		battle.weight = encounter.weight
		battle.gold_reward_min = encounter.gold_min
		battle.gold_reward_max = encounter.gold_max
		battle.monster_ids = ids
		result.append(battle)

	return result


## 一档里够格的怪有多少只，用来在检查器里对不上号时排查。
func eligible_monsters(tier: EncounterTier) -> Array[String]:
	var result: Array[String] = []
	if tier == null:
		return result

	for monster_id in MonsterBook.all().keys():
		var id := str(monster_id)
		if MonsterBook.can_fill_tier(id, tier):
			result.append(id)
	return result
