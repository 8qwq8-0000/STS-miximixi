class_name IngredientCard
extends Card

## 掉落物卡牌 — carved off a corpse in the middle of a fight.
##
## The only thing it can be pointed at is the cooking pot: dropping it there
## hands the ingredient over and spends the card. It is a battle-only card, so
## nothing about it survives into the next fight.

@export var ingredient_id: String
@export var level := 1

## The pot refuses to take more once it is full, so the card stays in hand.
func accepts_target(target: Node) -> bool:
	if target is CookingPot:
		return not target.is_full()

	return false


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	for target in targets:
		if target is CookingPot:
			target.add_ingredient(self)
			return
