class_name CardRewards
extends ColorRect

signal card_reward_selected(card: Card)
## 「我全都要」：看满广告后把这一轮报价整份交出去，而不是挑一张。
signal all_cards_taken(cards: Array[Card])

const CARD_MENU_UI = preload("res://scenes/ui/card_menu_ui.tscn")
const AD_OVERLAY := preload("res://scenes/ui/ad_overlay.tscn")

@export var rewards: Array[Card] : set = set_rewards

@onready var cards: HBoxContainer = %Cards
@onready var skip_card_reward: Button = %SkipCardReward
@onready var woquandouyao_button: Button = %woquandouyao
@onready var card_tooltip_popup: CardTooltipPopup = $CardTooltipPopup
@onready var take_button: Button = %TakeButton

var selected_card: Card

## 广告播放期间，不让「我全都要」被点第二下。
var ad_playing := false


func _ready() -> void:
	_clear_rewards()
	
	take_button.pressed.connect(
		func(): 
			card_reward_selected.emit(selected_card)
			queue_free()
	)
	
	skip_card_reward.pressed.connect(
		func(): 
			card_reward_selected.emit(null)
			queue_free()
	)
	
	woquandouyao_button.pressed.connect(_on_woquandouyao_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		card_tooltip_popup.hide_tooltip()


func _clear_rewards() -> void:
	for card: Node in cards.get_children():
		card.queue_free()
		
	card_tooltip_popup.hide_tooltip()

	selected_card = null


func _show_tooltip(card: Card) -> void:
	selected_card = card
	card_tooltip_popup.show_tooltip(card)


func set_rewards(new_cards: Array[Card]) -> void:
	rewards = new_cards
	
	if not is_node_ready():
		await ready
		
	_clear_rewards()
	for card: Card in rewards:
		var new_card := CARD_MENU_UI.instantiate() as CardMenuUI
		cards.add_child(new_card)
		new_card.card = card
		new_card.tooltip_requested.connect(_show_tooltip)


## 「我全都要」：先播一段「广告位招租」，播满 3 秒就把这一轮的报价整份交出去，
## 怎么进牌组由奖励界面决定 —— 选牌界面本身不认识牌组。
func _on_woquandouyao_pressed() -> void:
	if ad_playing:
		return

	ad_playing = true
	woquandouyao_button.disabled = true

	var ad := AD_OVERLAY.instantiate() as AdOverlay
	add_child(ad)
	await ad.ad_finished

	var taken: Array[Card] = []
	taken.assign(rewards)
	all_cards_taken.emit(taken)

	queue_free()
