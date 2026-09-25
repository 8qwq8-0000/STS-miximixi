class_name CardSelector
extends Control

## In-battle "pick N cards" dialog.
##
## Usage — the dialog owns the interaction, the caller owns the meaning:
##
##     selector.request_cards(hand_cards, 1, "选择要消耗的牌", _on_cards_chosen)
##
## It shows the pool, lets the player toggle exactly `amount` cards, and hands
## them to `on_confirmed` once the confirm button is pressed. Selecting past the
## limit drops the oldest pick, so a "choose 1" dialog behaves like a radio group.
##
## The result arrives through a Callable rather than an `await` on purpose.
## Callers are usually short-lived `Effect` (RefCounted) objects, and a pending
## coroutine on one of those dies with it as soon as the caller's local goes out
## of scope. Holding the callback keeps the caller alive until the pick is made.

const CARD_OPTION := preload("res://scenes/ui/card_selector/card_selector_option.tscn")

@onready var title: Label = %Title
@onready var cards: GridContainer = %Cards
@onready var confirm_button: Button = %ConfirmButton

var _required := 1
var _chosen: Array[Card] = []
var _options: Array[CardSelectorOption] = []
var _on_confirmed := Callable()


func _ready() -> void:
	hide()


## Shows the dialog; `on_confirmed` receives the picked cards (possibly empty).
func request_cards(
	pool: Array[Card], amount: int, prompt := "", on_confirmed := Callable()
) -> void:
	if pool.is_empty() or amount <= 0:
		var none: Array[Card] = []
		if on_confirmed.is_valid():
			on_confirmed.call(none)
		return

	_build(pool)
	_required = mini(amount, pool.size())
	title.text = "%s（共 %d 张）" % [prompt if prompt else "选择卡牌", pool.size()]
	_refresh()
	_on_confirmed = on_confirmed
	show()


func _build(pool: Array[Card]) -> void:
	_clear()
	for card: Card in pool:
		var option := CARD_OPTION.instantiate() as CardSelectorOption
		cards.add_child(option)
		option.card = card
		option.toggled.connect(_on_option_toggled)
		_options.append(option)


func _clear() -> void:
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	_options.clear()
	_chosen.clear()


func _on_option_toggled(option: CardSelectorOption) -> void:
	if option.selected:
		option.selected = false
		_chosen.erase(option.card)
	else:
		while _chosen.size() >= _required and not _chosen.is_empty():
			_drop_oldest()
		option.selected = true
		_chosen.append(option.card)
	_refresh()


func _drop_oldest() -> void:
	var oldest: Card = _chosen.pop_front()
	for option in _options:
		if is_instance_valid(option) and option.card == oldest:
			option.selected = false
			return


func _refresh() -> void:
	confirm_button.text = "选择 %d/%d" % [_chosen.size(), _required]
	confirm_button.disabled = _chosen.size() != _required


func _on_confirm_pressed() -> void:
	var chosen: Array[Card] = _chosen.duplicate()
	var callback := _on_confirmed
	_on_confirmed = Callable()
	hide()
	_clear()
	if callback.is_valid():
		callback.call(chosen)
