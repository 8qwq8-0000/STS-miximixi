class_name MonsterBook
extends RefCounted

## 怪物名册。
##
## 每只怪一个 .tres，放在 res://monsters/ 下，可以直接在 Godot 检查器里改血量、招式、
## 掉落、立绘和定位 —— 改完不用碰任何代码。
##
## 这里只留「规则」，不放单只怪的数据：谁算精英、谁能当随从、几只怪能一起上。

const DATA_DIR := "res://monsters"
const AI_SCENE := "res://scenes/enemy/move_cycle_ai.tscn"

## 目录清单工具：编辑器里读 .tres，导出成 exe 之后读 .tres.remap，这里统一处理。
const ResourceFiles := preload("res://custom_resources/resource_dir.gd")

const ATTACK_ICON := "res://art/attack_negative.png"
const DEFEND_ICON := "res://art/tile_0102.png"
const BUFF_ICON := "res://art/muscle.png"
const DEBUFF_ICON := "res://art/expose.png"
const STATUS_ICON := "res://art/占位符.png"

## 威胁等级 → 随从池出现权重。越弱越常见。
const MINION_THREAT_WEIGHTS := {1: 4.0, 2: 2.5, 3: 1.2, 4: 1.0}

## 威胁等级 → 最多几只一起出现。蓝本里的分法是「蝙蝠成群、螃蟹成双、毒幽灵单干」，
## 这里就按同一套逻辑：越弱的怪越能成群，越硬越只能单只。
const MAX_GROUP_BY_THREAT := {1: 3, 2: 2, 3: 1}

static var _by_id: Dictionary
static var _loaded := false


## id → MonsterData。第一次访问时把 res://monsters/ 读一遍，之后走缓存。
static func all() -> Dictionary:
	if not _loaded:
		_load_all()

	return _by_id


static func get_data(monster_id: String) -> MonsterData:
	return all().get(monster_id) as MonsterData


static func has_monster(monster_id: String) -> bool:
	return all().has(monster_id)


static func display_name(monster_id: String) -> String:
	var data := get_data(monster_id)
	return data.display_name if data else monster_id


static func threat_level(monster_id: String) -> int:
	var data := get_data(monster_id)
	return data.threat_level if data else 1


static func is_elite(monster_id: String) -> bool:
	var data := get_data(monster_id)
	return data != null and data.rank != MonsterData.Rank.NORMAL


static func is_boss(monster_id: String) -> bool:
	var data := get_data(monster_id)
	return data != null and data.rank == MonsterData.Rank.BOSS


static func moves(monster_id: String) -> Array[MonsterMove]:
	var result: Array[MonsterMove] = []
	var data := get_data(monster_id)
	if data == null:
		return result

	return data.moves


## 能不能被玩家召唤成随从。精英和 Boss 不行，另外每只怪自己在 .tres 里也能关。
static func can_be_minion(monster_id: String) -> bool:
	var data := get_data(monster_id)
	return data != null and data.minion_eligible and not is_elite(monster_id)


## 精英随从：精英房打完之后额外给的那张卡。规则和普通随从池只差一点 —— 这里放开
## 精英。Boss 永远不行，每只怪自己的 minion_eligible 照样说话。
static func can_be_elite_minion(monster_id: String) -> bool:
	var data := get_data(monster_id)
	return data != null and data.minion_eligible and is_elite(monster_id) and not is_boss(monster_id)


## 精英房的额外奖励：把这一场真正上过场的精英做成随从卡。同一只怪只给一张
## （一档里「两只巨金怪」也只对应一张卡），Boss 会被跳过。
static func make_elite_minion_cards(monster_ids: Array[String]) -> Array[Card]:
	var cards: Array[Card] = []
	var seen: Array[String] = []

	for monster_id in monster_ids:
		if seen.has(monster_id) or not can_be_elite_minion(monster_id):
			continue

		seen.append(monster_id)
		var card := make_minion_card(monster_id)
		if card:
			cards.append(card)

	return cards


## 能不能作为遭遇出场（每只怪自己在 .tres 里开关）。
static func can_be_encounter(monster_id: String) -> bool:
	var data := get_data(monster_id)
	return data != null and data.encounter_eligible


## 在遭遇池里的相对权重（1.0 = 正常）。
static func encounter_weight(monster_id: String) -> float:
	var data := get_data(monster_id)
	return maxf(0.0, data.encounter_weight) if data else 0.0


## How often this monster shows up in the 随从卡牌池.
static func minion_weight(monster_id: String) -> float:
	return float(MINION_THREAT_WEIGHTS.get(threat_level(monster_id), 1.0))


## Whether this monster is allowed to fill a given tier.
##
## Two rules decide it. First the audience: a normal tier only takes ordinary
## monsters, an elite tier only takes elites, so 「三只巨金怪」 cannot happen.
## Then the blueprint's grouping rule — weak monsters show up in groups (like the
## bats), tougher ones only pair off (like the crab), and the hardest only ever
## come alone (like the toxic ghost).
static func can_fill_tier(monster_id: String, tier: EncounterTier) -> bool:
	var data := get_data(monster_id)
	if data == null or not data.encounter_eligible:
		return false

	var elite := is_elite(monster_id)
	match tier.audience:
		EncounterTier.Audience.BOSS:
			if not is_boss(monster_id):
				return false
		EncounterTier.Audience.ELITE:
			# Boss 那几只只在 Boss 层露面，不进精英房。
			if not elite or is_boss(monster_id):
				return false
		_:
			if elite:
				return false

	return tier.count <= int(MAX_GROUP_BY_THREAT.get(data.threat_level, 1))


## A zero-cost summon card for one of the roster monsters.
static func make_minion_card(monster_id: String) -> MinionCard:
	var stats := make_enemy_stats(monster_id)
	if stats == null:
		return null

	var card := MinionCard.new()
	card.id = "minion_" + monster_id
	card.type = Card.Type.POWER
	card.rarity = Card.Rarity.COMMON
	card.target = Card.Target.SELF
	card.cost = 0
	card.icon = stats.art
	card.minion_stats = stats
	card.tooltip_text = "[center]召唤 [color=\"ffdf00\"]“%s”[/color]\n（%d 级威胁）[/center]" % [
		stats.display_name, threat_level(monster_id),
	]
	return card


## 生成出场用的敌人数据。血量等数值用 .tres 里的原值，实际倍率在
## EnemyStats.create_instance() 里乘（见 res://enemy_config.tres）。
static func make_enemy_stats(monster_id: String) -> EnemyStats:
	var data := get_data(monster_id)
	if data == null:
		return null

	var stats := EnemyStats.new()
	stats.display_name = data.display_name
	stats.max_health = data.max_health
	stats.art = data.art
	stats.monster_id = monster_id
	stats.ai = load(AI_SCENE) as PackedScene
	stats.drops = data.drops
	return stats


static func make_action(move: MonsterMove, monster_id := "") -> MoveAction:
	var config := EnemyConfig.get_config()
	var action := MoveAction.new()
	action.move_name = move.move_name
	action.damage = config.scale_damage(move.damage)
	action.hits = move.hits
	action.block = config.scale_block(move.block)
	action.heal = config.scale_heal(move.heal)
	action.buff_id = move.buff_id
	action.buff_amount = move.buff_amount
	action.debuff_id = move.debuff_id
	action.debuff_amount = move.debuff_amount
	action.status_card = move.status_card
	action.status_card_amount = move.status_card_amount
	action.intent = _make_intent(move)
	return action


static func _load_all() -> void:
	_loaded = true
	_by_id = {}

	for path in ResourceFiles.list_resource_paths(DATA_DIR):
		var data := load(path) as MonsterData
		if data == null:
			continue

		var id := data.id
		if id.is_empty():
			id = path.get_file().get_basename()
			push_warning("MonsterBook: %s 没填 id，暂用文件名 %s。" % [path, id])

		_by_id[id] = data

	if _by_id.is_empty():
		push_error("MonsterBook: %s 下一只怪都没读到，本局只能用教程三怪。" % DATA_DIR)
	else:
		print("MonsterBook: 名册载入 %d 只怪。" % _by_id.size())


static func _make_intent(move: MonsterMove) -> Intent:
	var intent := Intent.new()
	intent.base_text = ""
	intent.current_text = ""
	intent.icon = load(_icon_for(move)) as Texture2D
	return intent


static func _icon_for(move: MonsterMove) -> String:
	if move.damage > 0:
		return ATTACK_ICON
	if move.block > 0:
		return DEFEND_ICON
	if not move.buff_id.is_empty():
		return BUFF_ICON
	if not move.debuff_id.is_empty():
		return DEBUFF_ICON
	return STATUS_ICON
