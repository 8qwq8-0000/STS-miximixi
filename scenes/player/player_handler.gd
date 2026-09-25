# Player turn order:
# 1. START_OF_TURN Relics 
# 2. START_OF_TURN Statuses
# 3. Draw Hand
# 4. End Turn 
# 5. END_OF_TURN Relics 
# 6. END_OF_TURN Statuses
# 7. Discard Hand
class_name PlayerHandler
extends Node

const HAND_DRAW_INTERVAL := 0.25
const HAND_DISCARD_INTERVAL := 0.25

const BURN_CARD := preload("res://common_cards/burn.tres")

## 带电 zaps a random enemy every time you play a card while it is up.
const CHARGED_DAMAGE := 8
const DRAGON_FLAME_DAMAGE := 10

@export var relics: RelicHandler
@export var player: Player
@export var hand: Hand

var character: CharacterStats
var extra_turn_pending := false


func _ready() -> void:
	Events.card_played.connect(_on_card_played)


func start_battle(char_stats: CharacterStats) -> void:
	character = char_stats
	character.draw_pile = character.deck.custom_duplicate()
	character.draw_pile.shuffle()
	character.discard = CardPile.new()
	character.exhaust = CardPile.new()
	relics.relics_activated.connect(_on_relics_activated)
	player.status_handler.statuses_applied.connect(_on_statuses_applied)
	start_turn()


func start_turn() -> void:
	# 壁垒 banks the block you ended last turn with; everything else resets.
	if not has_status("barricade"):
		character.block = 0
	character.reset_mana()
	# 龙炎 pays out two extra energy on top of the normal refill.
	if has_status("dragon_flame"):
		character.mana += 2
	relics.activate_relics_by_type(Relic.Type.START_OF_TURN)


func end_turn() -> void:
	hand.disable_hand()

	# 传说盛宴 hands out one extra turn: the enemies sit this round out and the
	# player goes straight back to a fresh turn.
	if consume_extra_turn():
		Events.extra_turn_started.emit()
		return

	relics.activate_relics_by_type(Relic.Type.END_OF_TURN)


func grant_extra_turn() -> void:
	extra_turn_pending = true


func consume_extra_turn() -> bool:
	if not extra_turn_pending:
		return false

	extra_turn_pending = false
	return true


func draw_card() -> void:
	reshuffle_deck_from_discard()
	if hand.is_full():
		return

	var card := character.draw_pile.draw_card()
	if card == null:
		return

	hand.add_card(card)
	reshuffle_deck_from_discard()


func draw_cards(amount: int, is_start_of_turn_draw: bool = false) -> void:
	var tween := create_tween()
	for i in range(amount):
		tween.tween_callback(draw_card)
		tween.tween_interval(HAND_DRAW_INTERVAL)
	
	tween.finished.connect(
		func(): 
			hand.enable_hand()
			if is_start_of_turn_draw:
				Events.player_hand_drawn.emit()
	)


func discard_cards() -> void:
	if hand.get_child_count() == 0:
		Events.player_hand_discarded.emit()
		return

	var tween := create_tween()
	for card_ui: CardUI in hand.get_children():
		tween.tween_callback(character.discard.add_card.bind(card_ui.card))
		tween.tween_callback(hand.discard_card.bind(card_ui))
		tween.tween_interval(HAND_DISCARD_INTERVAL)
	
	tween.finished.connect(
		func():
			Events.player_hand_discarded.emit()
	)


func reshuffle_deck_from_discard() -> void:
	if not character.draw_pile.empty():
		return

	while not character.discard.empty():
		character.draw_pile.add_card(character.discard.draw_card())

	character.draw_pile.shuffle()


func _on_card_played(card: Card) -> void:
	if has_status("charged"):
		damage_random_enemy(CHARGED_DAMAGE)
	if has_status("dragon_flame"):
		damage_random_enemy(DRAGON_FLAME_DAMAGE)

	# 蜜糖坚果塔 is eaten one bite at a time: it goes back to the hand until the
	# last use is spent.
	if card is DishCard and card.uses > 1:
		card.uses -= 1
		hand.add_card.call_deferred(card)
		return

	# Exhausted cards, power cards and the battle-only cooking cards all leave
	# play instead of going to the discard pile.
	if card.exhausts or card.type == Card.Type.POWER or card.is_temporary():
		character.exhaust.add_card(card)
		return
	
	character.discard.add_card(card)


func _on_statuses_applied(type: Status.Type) -> void:
	match type:
		Status.Type.START_OF_TURN:
			draw_cards(character.cards_per_turn, true)
		Status.Type.END_OF_TURN:
			apply_status_card_effects()
			# 保留 keeps the hand through the end of the turn. The minion turn
			# is wired to player_hand_discarded, so the event still has to fire.
			if has_status("retain"):
				Events.player_hand_discarded.emit()
			else:
				discard_cards()


func has_status(id: String) -> bool:
	if not player or not player.status_handler:
		return false

	return player.status_handler.has_status(id)


## 灼烧 / 眩晕 / 恐惧 / 混乱 all resolve here, once, at the end of the turn.
func apply_status_card_effects() -> void:
	var damage := 0
	var exhaust_random := 0
	var add_burn := 0
	var ethereal: Array[CardUI] = []

	for card_ui: CardUI in hand.get_children():
		var status_card := card_ui.card as StatusCard
		if status_card == null:
			continue

		if status_card.ethereal:
			ethereal.append(card_ui)

		damage += status_card.end_of_turn_damage
		exhaust_random += status_card.end_of_turn_exhaust_random
		add_burn += status_card.end_of_turn_add_burn

	for card_ui: CardUI in ethereal:
		exhaust_card_ui(card_ui)

	for _i in range(exhaust_random):
		exhaust_random_hand_card()

	for _i in range(add_burn):
		character.draw_pile.add_card(BURN_CARD.duplicate())

	if damage > 0:
		player.take_damage(damage, Modifier.Type.DMG_TAKEN)


func exhaust_card_ui(card_ui: CardUI) -> void:
	if not is_instance_valid(card_ui):
		return

	character.exhaust.add_card(card_ui.card)
	hand.discard_card(card_ui)


## 恐惧 eats a card of the player's choosing at random, never another status card
## (otherwise a hand full of 恐惧 would just eat itself and do nothing).
func exhaust_random_hand_card() -> void:
	var candidates: Array[CardUI] = []
	for card_ui: CardUI in hand.get_children():
		if card_ui.card is StatusCard:
			continue
		candidates.append(card_ui)

	if candidates.is_empty():
		return

	exhaust_card_ui(RNG.array_pick_random(candidates))


func damage_random_enemy(amount: int) -> void:
	var living: Array[Node] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			living.append(node)

	if living.is_empty():
		return

	var damage_effect := DamageEffect.new()
	damage_effect.amount = amount
	damage_effect.execute([RNG.array_pick_random(living) as Node2D])


func _on_relics_activated(type: Relic.Type) -> void:
	match type:
		Relic.Type.START_OF_TURN:
			player.status_handler.apply_statuses_by_type(Status.Type.START_OF_TURN)
		Relic.Type.END_OF_TURN:
			player.status_handler.apply_statuses_by_type(Status.Type.END_OF_TURN)
