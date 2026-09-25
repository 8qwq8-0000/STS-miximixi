class_name Card
extends Resource

## STATUS cards are unplayable filler. DISH and INGREDIENT are the cooking cards:
## both only exist for the duration of one battle.
enum Type {ATTACK, SKILL, POWER, STATUS, DISH, INGREDIENT}
enum Rarity {COMMON, UNCOMMON, RARE}
enum Target {SELF, SINGLE_ENEMY, ALL_ENEMIES, EVERYONE}

const RARITY_COLORS := {
	Card.Rarity.COMMON: Color.GRAY,
	Card.Rarity.UNCOMMON: Color.CORNFLOWER_BLUE,
	Card.Rarity.RARE: Color.GOLD,
}

@export_group("Card Attributes")
@export var id: String
@export var type: Type
@export var rarity: Rarity
@export var target: Target
@export var cost: int
@export var exhausts: bool = false
## Set on the rare card that can never be played even when mana allows it.
@export var unplayable: bool = false

@export_group("Card Visuals")
@export var icon: Texture
@export_multiline var tooltip_text: String
@export var sound: AudioStream


func is_single_targeted() -> bool:
	return target == Target.SINGLE_ENEMY


## Status cards are dead weight: the UI greys them out and the drag state never
## lets them leave the hand, so the only way out is an end-of-turn effect or a
## card that spends them.
func is_playable() -> bool:
	return not unplayable and type != Type.STATUS


## Temporary cards are handed out by the battle itself (a dish cooked mid-fight,
## an ingredient carved off a corpse). The run's deck is rebuilt from
## CharacterStats.deck at the start of every battle, so anything that never
## reaches that pile is gone once the battle ends.
func is_temporary() -> bool:
	return type == Type.DISH or type == Type.INGREDIENT


## Whether this card can be played on `target`.
##
## A single-targeted card only ever takes the creature it was aimed at; an
## untargeted card is played by dropping it anywhere on the play area, so it
## accepts anything. Cooking cards override this to take the cooking pot.
func accepts_target(target: Node) -> bool:
	if is_single_targeted():
		return target is Enemy

	return true


func _get_targets(targets: Array[Node]) -> Array[Node]:
	if not targets:
		return []
		
	var tree := targets[0].get_tree()
	
	match target:
		Target.SELF:
			return tree.get_nodes_in_group("player")
		Target.ALL_ENEMIES:
			return tree.get_nodes_in_group("enemies")
		Target.EVERYONE:
			return tree.get_nodes_in_group("player") + tree.get_nodes_in_group("enemies")
		_:
			return []


func play(targets: Array[Node], char_stats: CharacterStats, modifiers: ModifierHandler) -> void:
	Events.card_played.emit(self)
	char_stats.mana -= cost
	
	if is_single_targeted():
		_slay_minion_targets(targets)
		apply_effects(targets, modifiers)
	else:
		var resolved := _get_targets(targets)
		_slay_minion_targets(resolved)
		apply_effects(resolved, modifiers)


## 玩家攻击随从直接秒杀 — pointing an attack at your own minion does not trade
## damage with it, it simply removes it. Non-attack cards (a dish handed to a
## minion, say) still resolve normally.
func _slay_minion_targets(targets: Array[Node]) -> void:
	if type != Type.ATTACK:
		return

	for target in targets:
		if target is Minion and is_instance_valid(target):
			target.slay()


func apply_effects(_targets: Array[Node], _modifiers: ModifierHandler) -> void:
	pass


func get_default_tooltip() -> String:
	return tooltip_text


func get_updated_tooltip(_player_modifiers: ModifierHandler, _enemy_modifiers: ModifierHandler) -> String:
	return tooltip_text
	
