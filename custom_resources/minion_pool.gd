class_name MinionPool
extends Resource

## The friendly enemies a player can receive as a minion.
##
## Two things feed the offer: the hand-made cards in `minion_cards`, and the
## 怪物名册 roster in `monster_ids`. Roster monsters are picked with a weight
## based on their 威胁等级, so the weak ones come up far more often than the ones
## that could solo a fight on their own. Elites are never offered.

@export var pool: Array[EnemyStats]
@export var minion_cards: Array[Card]
@export var monster_ids: Array[String] = []


func get_random() -> EnemyStats:
	return RNG.array_pick_random(pool) as EnemyStats


## Distinct cards, so a "pick one of two" offer can never show a duplicate.
func get_random_cards(amount: int) -> Array[Card]:
	var result: Array[Card] = []
	var entries := _entries()
	if entries.is_empty() or amount <= 0:
		return result

	var take := amount
	if take > entries.size():
		take = entries.size()
	for index in take:
		var entry := _pick_weighted(entries)
		entries.erase(entry)
		result.append(entry["card"] as Card)

	return result


## One weighted entry per candidate card.
func _entries() -> Array:
	var entries: Array = []

	for card: Card in minion_cards:
		if card:
			entries.append({"card": card, "weight": 1.0})

	for monster_id in monster_ids:
		if not MonsterBook.can_be_minion(monster_id):
			continue

		var card := MonsterBook.make_minion_card(monster_id)
		if card:
			entries.append({"card": card, "weight": MonsterBook.minion_weight(monster_id)})

	return entries


func _pick_weighted(entries: Array) -> Dictionary:
	var total := 0.0
	for entry: Dictionary in entries:
		total += float(entry["weight"])

	var roll := RNG.instance.randf_range(0.0, total)
	var running := 0.0
	for entry: Dictionary in entries:
		running += float(entry["weight"])
		if running > roll:
			return entry

	return entries[entries.size() - 1] as Dictionary
