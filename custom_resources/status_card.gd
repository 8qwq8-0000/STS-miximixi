class_name StatusCard
extends Card

## 状态类卡牌 — unplayable filler that an enemy or an event shuffles into the
## player's piles.
##
## A status card cannot be played, so the only thing that can happen to it is
## the end-of-turn pass in PlayerHandler. Four knobs cover every status card in
## the design document, and they stack additively when several are in hand:
##
##   * end_of_turn_damage         — 灼烧: take N damage
##   * ethereal                   — 眩晕: exhausts itself at end of turn
##   * end_of_turn_exhaust_random — 恐惧: exhaust N other cards at random
##   * end_of_turn_add_burn       — 混乱: shuffle N 灼烧 into the draw pile

@export var end_of_turn_damage := 0
@export var ethereal := false
@export var end_of_turn_exhaust_random := 0
@export var end_of_turn_add_burn := 0
