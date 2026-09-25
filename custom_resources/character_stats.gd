class_name CharacterStats
extends Stats

@export_group("Visuals")
@export var character_name: String
@export_multiline var description: String
@export var portrait: Texture

@export_group("Gameplay Data")
@export var starting_deck: CardPile
@export var draftable_cards: CardPile
@export var cards_per_turn: int
@export var max_mana: int
@export var starting_relic: Relic

var mana: int : set = set_mana
var deck: CardPile
var discard: CardPile
var draw_pile: CardPile
## Cards spent through the 消耗 rule. Kept separate from the discard pile so a
## reshuffle can never bring them back during the same battle.
var exhaust: CardPile


func set_mana(value: int) -> void:
	mana = value
	stats_changed.emit()


func reset_mana() -> void:
	mana = max_mana


func take_damage(damage: int) -> void:
	var initial_health := health
	super.take_damage(damage)
	if initial_health > health:
		Events.player_hit.emit()


func can_play_card(card: Card) -> bool:
	return card.is_playable() and mana >= card.cost


func create_instance() -> Resource:
	var instance: CharacterStats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.reset_mana()
	# custom_duplicate() gives this run its own array *and* its own Card
	# instances. A plain Resource.duplicate() is shallow, so the run's deck
	# would share the starting deck's array: cards gained in one run would leak
	# into the starting deck of every later run, and cards that mutate
	# themselves (Confusing Staff rewriting a cost) would edit the .tres.
	instance.deck = instance.starting_deck.custom_duplicate()
	instance.draw_pile = CardPile.new()
	instance.discard = CardPile.new()
	instance.exhaust = CardPile.new()
	return instance
