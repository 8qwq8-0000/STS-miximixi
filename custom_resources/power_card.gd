class_name PowerCard
extends Card

## 能力牌 — a card that grants a lasting buff for the rest of the battle.
##
## Card.Type.POWER already carries the rule that matters here: PlayerHandler
## never sends a power card to the discard pile, so once it is played it is out
## of this battle while the copy in the deck survives for the next one. All this
## class has to do is hand its status to the player.

@export var power: Status


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if power == null or targets.is_empty():
		return

	var status_effect := StatusEffect.new()
	status_effect.status = power.duplicate()
	status_effect.execute(targets)
