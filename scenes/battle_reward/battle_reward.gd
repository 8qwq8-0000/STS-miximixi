class_name BattleReward
extends Control

const CARD_REWARDS = preload("res://scenes/ui/card_rewards.tscn")
const REWARD_BUTTON = preload("res://scenes/ui/reward_button.tscn")
const GOLD_ICON := preload("res://art/gold.png")
const GOLD_TEXT := "%s 金币"
const CARD_ICON := preload("res://art/rarity.png")
const CARD_TEXT := "添加新卡牌"
const MINION_CARD_ICON := preload("res://art/deck.png")
const MINION_CARD_TEXT := "随从卡牌"
const ELITE_MINION_CARD_TEXT := "精英随从卡牌"
const MINION_CARDS_OFFERED := 2

@export var run_stats: RunStats
@export var character_stats: CharacterStats
@export var relic_handler: RelicHandler
@export var minion_pool: MinionPool

@onready var rewards: VBoxContainer = %Rewards

var card_reward_total_weight := 0.0
var card_rarity_weights := {
	Card.Rarity.COMMON: 0.0,
	Card.Rarity.UNCOMMON: 0.0,
	Card.Rarity.RARE: 0.0
}

## The reward rows that open a picker. They survive being pressed so the player
## can reopen them after skipping, and are removed once a card is taken.
var card_reward_row: RewardButton
var minion_card_row: RewardButton
## 精英房额外那一行，和上面那行各管各的报价。
var elite_minion_card_row: RewardButton

## Cached offers. Skipping and reopening must not become a free re-roll, so the
## cards are only rolled the first time the picker is opened.
var card_reward_offer: Array[Card] = []
var minion_card_offer: Array[Card] = []
var elite_minion_card_offer: Array[Card] = []


func _ready() -> void:
	for node: Node in rewards.get_children():
		node.queue_free()


func add_gold_reward(amount: int) -> void:
	var gold_reward := REWARD_BUTTON.instantiate() as RewardButton
	gold_reward.reward_icon = GOLD_ICON
	gold_reward.reward_text = GOLD_TEXT % amount
	gold_reward.pressed.connect(_on_gold_reward_taken.bind(amount))
	rewards.add_child.call_deferred(gold_reward)


func add_card_reward() -> void:
	var card_reward := REWARD_BUTTON.instantiate() as RewardButton
	card_reward.reward_icon = CARD_ICON
	card_reward.reward_text = CARD_TEXT
	card_reward.free_on_pressed = false
	card_reward.pressed.connect(_show_card_rewards)
	card_reward_row = card_reward
	rewards.add_child.call_deferred(card_reward)


## A bonus, always-available offer: pick one of two minion summon cards.
func add_minion_card_reward() -> void:
	if minion_pool == null:
		return

	minion_card_row = _add_minion_reward_row(MINION_CARD_TEXT, _show_minion_card_rewards)


## 精英房的额外一行：这一场打过的精英，各给一张对应的随从卡。报价不是掷骰子掷
## 出来的，就是刚才站在对面的那几只 —— 所以它不进普通随从池，也不受精英不能当
## 随从这条规则的约束（见 MonsterBook.can_be_elite_minion）。
func add_elite_minion_card_reward(cards: Array[Card]) -> void:
	if cards.is_empty():
		return

	elite_minion_card_offer.clear()
	elite_minion_card_offer.assign(cards)
	elite_minion_card_row = _add_minion_reward_row(
		ELITE_MINION_CARD_TEXT, _show_elite_minion_card_rewards
	)


## 随从奖励行长得都一样，只有文案和「点下去开哪个报价」不同。
func _add_minion_reward_row(text: String, on_pressed: Callable) -> RewardButton:
	var minion_reward := REWARD_BUTTON.instantiate() as RewardButton
	minion_reward.reward_icon = MINION_CARD_ICON
	minion_reward.reward_text = text
	minion_reward.free_on_pressed = false
	minion_reward.pressed.connect(on_pressed)
	rewards.add_child.call_deferred(minion_reward)
	return minion_reward


func _show_minion_card_rewards() -> void:
	if minion_pool == null:
		return

	if minion_card_offer.is_empty():
		minion_card_offer = minion_pool.get_random_cards(MINION_CARDS_OFFERED)

	_open_minion_card_picker(minion_card_offer, minion_card_row)


func _show_elite_minion_card_rewards() -> void:
	_open_minion_card_picker(elite_minion_card_offer, elite_minion_card_row)


## 随从报价的选牌界面：普通池和精英那一档共用，区别只在报价从哪来、拿走之后收哪一行。
func _open_minion_card_picker(offer: Array[Card], row: RewardButton) -> void:
	if offer.is_empty():
		return

	var card_picker := CARD_REWARDS.instantiate() as CardRewards
	add_child(card_picker)
	card_picker.card_reward_selected.connect(_on_minion_card_taken.bind(row))
	card_picker.all_cards_taken.connect(_on_all_cards_taken.bind(row))
	card_picker.rewards = offer
	card_picker.show()


func _on_minion_card_taken(card: Card, row: RewardButton) -> void:
	if not card or not character_stats:
		return

	character_stats.deck.add_card(card)
	_remove_reward_row(row)


func add_relic_reward(relic: Relic) -> void:
	if not relic:
		return

	var relic_reward := REWARD_BUTTON.instantiate() as RewardButton
	relic_reward.reward_icon = relic.icon
	relic_reward.reward_text = relic.relic_name
	relic_reward.pressed.connect(_on_relic_reward_taken.bind(relic))
	rewards.add_child.call_deferred(relic_reward)


func _show_card_rewards() -> void:
	if not run_stats or not character_stats:
		return

	if card_reward_offer.is_empty():
		card_reward_offer = _roll_card_rewards()

	var card_rewards := CARD_REWARDS.instantiate() as CardRewards
	add_child(card_rewards)
	card_rewards.card_reward_selected.connect(_on_card_reward_taken)
	card_rewards.all_cards_taken.connect(_on_all_cards_taken.bind(card_reward_row))
	card_rewards.rewards = card_reward_offer
	card_rewards.show()


func _roll_card_rewards() -> Array[Card]:
	var card_reward_array: Array[Card] = []
	var available_cards: Array[Card] = character_stats.draftable_cards.duplicate_cards()

	for i in run_stats.card_rewards:
		_setup_card_chances()
		var roll := RNG.instance.randf_range(0.0, card_reward_total_weight)

		for rarity: Card.Rarity in card_rarity_weights:
			if card_rarity_weights[rarity] > roll:
				_modify_weights(rarity)
				var picked_card := _get_random_available_card(available_cards, rarity)
				card_reward_array.append(picked_card)
				available_cards.erase(picked_card)
				break

	return card_reward_array


func _setup_card_chances() -> void:
	card_reward_total_weight = run_stats.common_weight + run_stats.uncommon_weight + run_stats.rare_weight
	card_rarity_weights[Card.Rarity.COMMON] = run_stats.common_weight
	card_rarity_weights[Card.Rarity.UNCOMMON] = run_stats.common_weight + run_stats.uncommon_weight
	card_rarity_weights[Card.Rarity.RARE] = card_reward_total_weight


func _modify_weights(rarity_rolled: Card.Rarity) -> void:
	if rarity_rolled == Card.Rarity.RARE:
		run_stats.rare_weight = RunStats.BASE_RARE_WEIGHT
	else:
		run_stats.rare_weight = clampf(run_stats.rare_weight + 0.3, run_stats.BASE_RARE_WEIGHT, 5.0)


func _get_random_available_card(available_cards: Array[Card], with_rarity: Card.Rarity) -> Card:
	var all_possible_cards := available_cards.filter(
		func(card: Card):
			return card.rarity == with_rarity
	)
	return RNG.array_pick_random(all_possible_cards)


func _on_gold_reward_taken(amount: int) -> void:
	if not run_stats:
		return
	
	run_stats.gold += amount


func _on_card_reward_taken(card: Card) -> void:
	# A null card means the player skipped: leave the reward row in place so the
	# picker can be opened again.
	if not character_stats or not card:
		return

	character_stats.deck.add_card(card)
	_remove_reward_row(card_reward_row)


func _remove_reward_row(row: RewardButton) -> void:
	if is_instance_valid(row):
		row.queue_free()


func _on_relic_reward_taken(relic: Relic) -> void:
	if not relic or not relic_handler:
		return
		
	relic_handler.add_relic(relic)


func _on_back_button_pressed() -> void: 
	Events.battle_reward_exited.emit()


## 「我全都要」看完广告后，把这一轮报价一张不落地塞进牌组，再把这一行奖励收掉。
func _on_all_cards_taken(cards: Array[Card], row: RewardButton) -> void:
	if character_stats:
		for card: Card in cards:
			if card:
				character_stats.deck.add_card(card)

	_remove_reward_row(row)
