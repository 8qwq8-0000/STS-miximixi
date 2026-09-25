class_name MoveAction
extends EnemyAction

## One scripted step of a 攻击模式.
##
## Every move in the design document is a combination of the fields below, so a
## whole monster lives in the roster table instead of needing a scene per move.
## Three of the fields do something the old hand-written actions never did:
## multi-hit attacks, healing, and shuffling status cards into the player's pile.

const LUNGE_TIME := 0.4

@export var move_name := ""
@export var damage := 0
@export var hits := 1
@export var block := 0
@export var heal := 0
@export var buff_id := ""
@export var buff_amount := 0
@export var debuff_id := ""
@export var debuff_amount := 0
@export var status_card: Card
@export var status_card_amount := 0


func perform_action() -> void:
	if not is_instance_valid(enemy):
		Events.enemy_action_completed.emit(enemy)
		return

	var victim := target as Player
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := get_lunge_position() if target else start

	if damage > 0 and target:
		tween.tween_property(enemy, "global_position", end, LUNGE_TIME)
		for _i in range(maxi(hits, 1)):
			tween.tween_callback(_hit.bind(target))

	if block > 0:
		tween.tween_callback(_gain_block)
	if heal > 0:
		tween.tween_callback(_heal)
	if not buff_id.is_empty() and buff_amount > 0:
		tween.tween_callback(_apply_status.bind(get_buff_target(), buff_id, buff_amount))
	if victim and not debuff_id.is_empty() and debuff_amount > 0:
		tween.tween_callback(_apply_status.bind(victim, debuff_id, debuff_amount))
	if victim and status_card and status_card_amount > 0:
		tween.tween_callback(_deal_status_cards.bind(victim))

	tween.tween_interval(0.25)
	if target:
		tween.tween_property(enemy, "global_position", start, LUNGE_TIME)

	tween.finished.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)


func update_intent_text() -> void:
	if damage > 0:
		var final_damage := damage
		if is_instance_valid(enemy):
			final_damage = enemy.modifier_handler.get_modified_value(damage, Modifier.Type.DMG_DEALT)
		intent.current_text = ("%d×%d" % [final_damage, hits]) if hits > 1 else str(final_damage)
	elif block > 0:
		intent.current_text = str(block)
	else:
		intent.current_text = move_name


func _hit(victim: Node2D) -> void:
	if not is_instance_valid(victim) or not is_instance_valid(enemy):
		return

	var damage_effect := DamageEffect.new()
	damage_effect.amount = enemy.modifier_handler.get_modified_value(damage, Modifier.Type.DMG_DEALT)
	damage_effect.sound = sound
	damage_effect.execute([victim])


func _gain_block() -> void:
	var receiver := get_buff_target()
	if is_instance_valid(receiver) and receiver.get("stats"):
		receiver.stats.block += block


func _heal() -> void:
	var receiver := get_buff_target()
	if is_instance_valid(receiver) and receiver.get("stats"):
		receiver.stats.heal(heal)


func _apply_status(receiver: Node, status_id: String, amount: int) -> void:
	if not is_instance_valid(receiver):
		return

	var template := CookingData.status_template(status_id)
	if template == null:
		return

	var status: Status = template.duplicate()
	status.stacks = amount

	var effect := StatusEffect.new()
	effect.status = status
	effect.execute([receiver])


## 状态牌 go into the draw pile, exactly like the toxic ghost's toxin already did.
func _deal_status_cards(victim: Player) -> void:
	if not is_instance_valid(victim):
		return

	for _i in range(status_card_amount):
		victim.stats.draw_pile.add_card(status_card.duplicate())
