class_name Hand
extends HBoxContainer

const CARD_UI_SCENE := preload("res://scenes/card_ui/card_ui.tscn")

## Most cards the hand will hold. Once it is full, further draws are skipped and
## the cards simply stay in the draw pile.
const MAX_CARDS := 15

## Layout numbers for the overlap. Cards are CARD_WIDTH wide; once the row would
## grow past the hand's own width the gap shrinks, going negative to overlap.
## MIN_VISIBLE_WIDTH is how much of a covered card is always left showing.
const CARD_WIDTH := 62.5
const MAX_SEPARATION := 5.0
const MIN_VISIBLE_WIDTH := 17.5
const FALLBACK_WIDTH := 375.0

@export var player: Player
@export var char_stats: CharacterStats

## Cards handed to the hand mid-turn (a corpse's drop, a finished dish) have to
## be playable right away, so remember whether the hand is currently enabled.
var hand_enabled := true


func _ready() -> void:
	child_order_changed.connect(_refresh_layout)
	resized.connect(_refresh_layout)
	_refresh_layout()


func is_full() -> bool:
	return get_child_count() >= MAX_CARDS


func add_card(card: Card) -> void:
	if card == null or is_full():
		return

	var new_card_ui := CARD_UI_SCENE.instantiate() as CardUI
	add_child(new_card_ui)
	new_card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
	new_card_ui.card = card
	new_card_ui.parent = self
	new_card_ui.char_stats = char_stats
	new_card_ui.player_modifiers = player.modifier_handler
	new_card_ui.disabled = not hand_enabled


## The container does the positioning, so overlapping is achieved by shrinking
## the gap between children - including into negative numbers.
##
## Children are drawn in tree order, so the later (right-hand) card covers the
## earlier (left-hand) one, which is the stacking order we want.
func _refresh_layout() -> void:
	var count := get_child_count()
	var separation := MAX_SEPARATION

	if count > 1:
		var hand_width := size.x if size.x > 0.0 else FALLBACK_WIDTH
		separation = (hand_width - float(count) * CARD_WIDTH) / float(count - 1)
		separation = clampf(separation, -CARD_WIDTH + MIN_VISIBLE_WIDTH, MAX_SEPARATION)

	# floori keeps the row at or under the hand's width instead of a rounding
	# error pushing the last card a pixel or two past the edge.
	add_theme_constant_override("separation", floori(separation))


func discard_card(card: CardUI) -> void:
	card.queue_free()


func enable_hand() -> void:
	hand_enabled = true
	for card: CardUI in get_children():
		card.disabled = false
		if card.is_hovered():
			card.card_state_machine.on_mouse_entered()


func disable_hand() -> void:
	hand_enabled = false
	for card: CardUI in get_children():
		card.disabled = true


func _on_card_ui_reparent_requested(child: CardUI) -> void:
	child.disabled = true
	child.reparent(self)
	var new_index := clampi(child.original_index, 0, get_child_count())
	move_child.call_deferred(child, new_index)
	child.set_deferred("disabled", false)
