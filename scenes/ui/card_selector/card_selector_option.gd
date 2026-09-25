class_name CardSelectorOption
extends CenterContainer

## One card inside the in-battle card selector. Clicking it toggles the pick.

signal toggled(option: CardSelectorOption)

const BASE_STYLEBOX := preload("res://scenes/card_ui/card_base_stylebox.tres")
const SELECTED_STYLEBOX := preload("res://scenes/card_ui/card_drag_stylebox.tres")
const UNSELECTED_MODULATE := Color(0.62, 0.62, 0.62, 1.0)

@export var card: Card : set = set_card

var selected := false : set = set_selected

@onready var visuals: CardVisuals = $Visuals


func set_card(value: Card) -> void:
	if not is_node_ready():
		await ready

	card = value
	visuals.card = card


func set_selected(value: bool) -> void:
	selected = value

	if not is_node_ready():
		return

	visuals.panel.set(
		"theme_override_styles/panel",
		SELECTED_STYLEBOX if selected else BASE_STYLEBOX
	)
	visuals.modulate = Color.WHITE if selected else UNSELECTED_MODULATE


func _on_visuals_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		toggled.emit(self)
