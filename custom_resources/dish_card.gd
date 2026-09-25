class_name DishCard
extends Card

## 料理卡牌 — what the cooking pot hands back.
##
## A dish only exists inside the battle it was cooked in (Card.Type.DISH), always
## carries the 消耗 keyword, and can be aimed at the player, a minion or an
## enemy. Every knob below is one line of the recipe table, so the recipes stay
## data instead of each needing a script of its own.

@export var dish_name: String
@export var dish_level := 1
## 蜜糖坚果塔 can be eaten more than once: the card returns to the hand and only
## leaves play when the last bite is gone.
@export var uses := 1

@export_group("恢复")
@export var heal := 0
@export var max_health := 0
@export var block := 0
@export var energy := 0

@export_group("战斗")
@export var damage_all := 0
@export var exposed_all := 0
@export var draw := 0
@export var exhaust_cards := 0
@export var extra_turn := false

@export_group("增益")
@export var muscle := 0
@export var muscle_min := 0
@export var muscle_max := 0
@export var random_buffs := 0
@export var charged := 0
@export var metallicize := 0
@export var guard := 0
@export var nirvana := 0
@export var swift := 0
@export var retain := 0
@export var barricade := 0
@export var purify := 0
@export var miracle := 0
@export var dragon_flame := 0


## 料理只能喂给「有血量的单位」：玩家、随从、敌人。
##
## 基类默认「单体牌只接受敌人」，那会把玩家挡在外面——玩家不是 Enemy 节点，瞄准
## 命中的是挂在玩家身上的 PlayerTargetArea，再由 CardUI 换回玩家本体。烹饪锅也不
## 接受料理。
func accepts_target(target: Node) -> bool:
	return target is Player or target is Enemy


func apply_effects(targets: Array[Node], _modifiers: ModifierHandler) -> void:
	if targets.is_empty():
		return

	var tree := targets[0].get_tree()
	var player_handler := tree.get_first_node_in_group("player_handler") as PlayerHandler

	for target in targets:
		_apply_to_target(target)

	if damage_all > 0:
		var hit := DamageEffect.new()
		hit.amount = damage_all
		hit.execute(tree.get_nodes_in_group("enemies"))

	if exposed_all > 0:
		_apply_status_to(tree.get_nodes_in_group("enemies"), "exposed", exposed_all)

	if player_handler:
		# 注意：回血不在这里，它跟着目标走（见 _apply_to_target）。加最大生命、
		# 加能量、抽牌、额外回合这几个是「这一顿让谁吃」都算玩家头上的。
		if max_health > 0:
			player_handler.character.max_health += max_health
		if energy > 0:
			player_handler.character.mana += energy
		if draw > 0:
			player_handler.draw_cards(draw)
		if extra_turn:
			player_handler.grant_extra_turn()

	if exhaust_cards > 0:
		var spend := SelectCardsEffect.new()
		spend.source = SelectCardsEffect.Source.HAND
		spend.amount = exhaust_cards
		spend.exhausts = true
		spend.prompt = "选择要消耗的牌"
		spend.execute(targets)


func _apply_to_target(target: Node) -> void:
	if target.get("stats"):
		# 格挡和回血都跟着目标走：喂给随从就补随从，喂给敌人就补敌人。
		if block > 0:
			target.stats.block += block
		if heal > 0:
			target.stats.heal(heal)

	var buffs := _buffs()
	for entry in buffs:
		var amount: int = entry[1]
		if amount > 0:
			_apply_status_to(_nodes(target), entry[0], amount)

	if muscle_min > 0 and muscle_max >= muscle_min:
		_apply_status_to(_nodes(target), "muscle", RNG.instance.randi_range(muscle_min, muscle_max))

	for _i in range(random_buffs):
		var pick: Array = RNG.array_pick_random(buffs)
		_apply_status_to(_nodes(target), pick[0], 1)


func _buffs() -> Array:
	return [
		["muscle", muscle],
		["charged", charged],
		["metallicize", metallicize],
		["guard", guard],
		["nirvana", nirvana],
		["swift", swift],
		["retain", retain],
		["barricade", barricade],
		["purify", purify],
		["miracle", miracle],
		["dragon_flame", dragon_flame],
	]


func _nodes(target: Node) -> Array[Node]:
	var list: Array[Node] = [target]
	return list


func _apply_status_to(nodes: Array[Node], status_id: String, amount: int) -> void:
	var template := CookingData.status_template(status_id)
	if template == null:
		return

	var status: Status = template.duplicate()
	status.stacks = amount

	var effect := StatusEffect.new()
	effect.status = status
	effect.execute(nodes)
