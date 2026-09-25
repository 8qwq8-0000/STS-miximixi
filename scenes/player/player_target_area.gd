class_name PlayerTargetArea
extends Area2D

## Makes the player a legal drop target.
##
## Enemies are Area2Ds, so a card aimed at one finds it directly. The player is
## not, so this invisible zone stands in for it: CardUI swaps the zone for
## `target_node` before it asks the card whether it accepts the drop.

@export var target_node: Node2D
