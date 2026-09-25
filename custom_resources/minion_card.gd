class_name MinionCard
extends Card

## A zero-cost minion summon.
##
## It is a POWER card on purpose: PlayerHandler never discards POWER cards, so
## playing it removes it from the deck for the rest of this combat while the
## card itself stays in the deck for the next battle.
##
## The summon is routed through the event bus instead of the card's targets so
## it works no matter what the card was dropped on.

@export var minion_stats: EnemyStats

## 名册随从：只写 id，数值等召唤时再去 res://monsters/ 取。
##
## 手写的随从（蝙蝠、螃蟹、毒幽灵）直接给上面那份 minion_stats；怪物名册里的怪
## （小火龙这些）只在这里记个 monster_id，免得同一只怪的血量、立绘、招式在两个
## 地方各写一份 —— 改 monsters/*.tres 的时候不用回头改卡。见
## MonsterBook.make_enemy_stats()。
@export var monster_id: String


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	var summon_stats := _summon_stats()
	if summon_stats == null:
		return

	Events.minion_summon_requested.emit(summon_stats)


## 两份数据二选一：填了 minion_stats 就用它，否则拿 monster_id 去名册里现取一份。
func _summon_stats() -> EnemyStats:
	if minion_stats:
		return minion_stats

	if monster_id.is_empty():
		return null

	return MonsterBook.make_enemy_stats(monster_id)
