class_name CookingPot
extends Area2D

## 烹饪锅 — the battle's cooking station.
##
## Ingredients are dropped straight onto it (the card's target resolves to this
## node). Pressing 烹饪 turns whatever is in the pot into a dish card: an exact
## 食谱 match wins, otherwise the pot hands back a random dish of the same
## 食物等级, which is the fallback rule from the design document.

const COOK_SOUND := preload("res://art/true_strength.ogg")

@onready var button: Button = $Button
@onready var contents: Label = $Contents

var ingredients: Array[String] = []


func _ready() -> void:
	button.pressed.connect(cook)
	_refresh()


func is_full() -> bool:
	return ingredients.size() >= CookingData.MAX_INGREDIENTS


func add_ingredient(card: IngredientCard) -> void:
	if card == null or is_full():
		return

	ingredients.append(card.ingredient_id)
	_refresh()


func clear_pot() -> void:
	ingredients.clear()
	_refresh()


## Produces the dish card for the current contents, or null when the pot is
## empty. The caller decides where the card goes.
func cook() -> DishCard:
	if ingredients.is_empty():
		return null

	var recipe := CookingData.find_recipe(ingredients)
	if recipe == null:
		recipe = CookingData.random_recipe_of_level(
			CookingData.level_for_total(CookingData.total_level(ingredients))
		)

	clear_pot()

	var dish := CookingData.make_dish(recipe)
	if dish == null:
		# 配置里一道菜都没有时不要炸，锅里的东西已经倒掉了。
		push_warning("烹饪锅：res://dishes/ 里一道料理都没有，出不了菜。")
		return null

	SFXPlayer.play(COOK_SOUND)
	dish.sound = COOK_SOUND
	Events.dish_cooked.emit(dish)
	return dish


func contents_text() -> String:
	if ingredients.is_empty():
		return "空锅"

	var names: Array[String] = []
	for ingredient_id in ingredients:
		names.append(CookingData.ingredient_name(ingredient_id))

	return "%d/%d  %s" % [ingredients.size(), CookingData.MAX_INGREDIENTS, "、".join(names)]


func _refresh() -> void:
	contents.text = contents_text()
	button.disabled = ingredients.is_empty()
