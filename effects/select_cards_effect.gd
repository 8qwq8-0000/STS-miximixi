class_name SelectCardsEffect
extends Effect

## Asks the player to pick cards and then spends them.
##
## The selection UI is generic; only the two knobs below define what "spending"
## means. Defaults are the ones the tutorial needs most often: pick 1 card from
## the hand and exhaust it.
##
##     var effect := SelectCardsEffect.new()
##     effect.source = SelectCardsEffect.Source.HAND
##     effect.amount = 1
##     effect.exhausts = true
##     effect.prompt = "选择要消耗的牌"
##     effect.execute(targets)
##
## Exhausting a hand card means removing it from play without putting it into
## the discard pile, so it is gone for the rest of this combat — the same thing
## that happens to cards flagged `exhausts` when they are played.

enum Source {HAND, DRAW_PILE, DISCARD_PILE}

var amount := 1
var source := Source.HAND
var exhausts := true
var prompt := "选择卡牌"

## Holds a reference to this very effect while the dialog is open.
##
## Effect is a RefCounted, and neither a Callable nor a pending `await` keeps a
## RefCounted alive. Callers normally create the effect as a local inside
## apply_effects(), so without this self-reference the effect would be freed the
## moment that method returns — before the player has picked anything — and the
## "spend" half of the feature would silently never run.
var _keep_alive: SelectCardsEffect


func execute(targets: Array[Node]) -> void:
	if targets.is_empty():
		return

	var tree := targets[0].get_tree()
	var selector := tree.get_first_node_in_group("card_selector") as CardSelector
	var player_handler := tree.get_first_node_in_group("player_handler") as PlayerHandler
	if selector == null or player_handler == null:
		return

	var pool := _gather(player_handler)
	if pool.is_empty():
		return

	# The dialog hands the result back through a Callable. The self-reference
	# above is what keeps this effect alive until that callback fires.
	_keep_alive = self
	selector.request_cards(pool, amount, prompt, _on_selection_done.bind(player_handler))


func _on_selection_done(chosen: Array[Card], player_handler: PlayerHandler) -> void:
	for card: Card in chosen:
		_spend(player_handler, card)
	_keep_alive = null


func _gather(player_handler: PlayerHandler) -> Array[Card]:
	var result: Array[Card] = []
	match source:
		Source.DRAW_PILE:
			result.assign(player_handler.character.draw_pile.cards)
		Source.DISCARD_PILE:
			result.assign(player_handler.character.discard.cards)
		_:
			for card_ui: CardUI in player_handler.hand.get_children():
				result.append(card_ui.card)
	return result


func _spend(player_handler: PlayerHandler, card: Card) -> void:
	match source:
		Source.HAND:
			var card_ui := _find_in_hand(player_handler, card)
			if card_ui:
				card_ui.queue_free()
			if not exhausts:
				player_handler.character.discard.add_card(card)
		Source.DRAW_PILE:
			_remove_from_pile(player_handler.character.draw_pile, card)
			if not exhausts:
				player_handler.character.discard.add_card(card)
		Source.DISCARD_PILE:
			_remove_from_pile(player_handler.character.discard, card)


func _find_in_hand(player_handler: PlayerHandler, card: Card) -> CardUI:
	for card_ui: CardUI in player_handler.hand.get_children():
		if card_ui.card == card:
			return card_ui
	return null


func _remove_from_pile(pile: CardPile, card: Card) -> void:
	pile.cards.erase(card)
	pile.card_pile_size_changed.emit(pile.cards.size())
