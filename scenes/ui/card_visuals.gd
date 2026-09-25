class_name CardVisuals
extends Control

@export var card: Card : set = set_card

@onready var panel: Panel = $Panel
@onready var cost: Label = $Cost
@onready var icon: TextureRect = $Icon
@onready var rarity: TextureRect = $Rarity


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	# A card that can never be played has no meaningful cost, so show a dash
	# instead of a misleading "0", and dim the frame so it reads as dead weight.
	cost.text = str(card.cost) if card.is_playable() else "—"
	panel.modulate = Color.WHITE if card.is_playable() else Color(0.7, 0.7, 0.78)
	icon.texture = card.icon
	rarity.modulate = Card.RARITY_COLORS[card.rarity]
