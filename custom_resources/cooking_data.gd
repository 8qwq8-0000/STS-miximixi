class_name CookingData
extends RefCounted

## 食材与料理的读取入口。
##
## 数据本身不在这里 —— 一种食材一个 res://ingredients/<id>.tres，一道料理一个
## res://dishes/<菜名>.tres，效果和图片都能直接在检查器里改。
##
## 这个脚本只负责三件事：把两个文件夹读进来、把锅里的食材对上食谱、把结果做成卡牌。

const INGREDIENT_DIR := "res://ingredients"
const DISH_DIR := "res://dishes"

## 目录清单工具：编辑器里读 .tres，导出成 exe 之后读 .tres.remap，这里统一处理。
const ResourceFiles := preload("res://custom_resources/resource_dir.gd")

## 锅里最多放几格。
const MAX_INGREDIENTS := 4

const PLACEHOLDER := "res://art/占位符.png"

const STATUS_TEMPLATES := {
	"muscle": "res://statuses/muscle.tres",
	"exposed": "res://statuses/exposed.tres",
	"charged": "res://statuses/charged.tres",
	"metallicize": "res://statuses/metallicize.tres",
	"guard": "res://statuses/guard.tres",
	"nirvana": "res://statuses/nirvana.tres",
	"swift": "res://statuses/swift.tres",
	"retain": "res://statuses/retain.tres",
	"barricade": "res://statuses/barricade.tres",
	"purify": "res://statuses/purify.tres",
	"miracle": "res://statuses/miracle.tres",
	"dragon_flame": "res://statuses/dragon_flame.tres",
}

## DishData 和 DishCard 上同名的效果字段，生成卡牌时整批抄过去。
const EFFECT_FIELDS := [
	"heal", "max_health", "block", "energy",
	"damage_all", "exposed_all", "draw", "exhaust_cards", "extra_turn",
	"muscle", "muscle_min", "muscle_max", "random_buffs",
	"charged", "metallicize", "guard", "nirvana", "swift", "retain",
	"barricade", "purify", "miracle", "dragon_flame",
]

static var _ingredients: Dictionary
static var _dishes: Array[DishData]
static var _loaded := false


static func all_ingredients() -> Dictionary:
	_ensure_loaded()
	return _ingredients


static func all_dishes() -> Array[DishData]:
	_ensure_loaded()
	return _dishes


static func get_ingredient(ingredient_id: String) -> IngredientData:
	return all_ingredients().get(ingredient_id) as IngredientData


static func get_dish(dish_id: String) -> DishData:
	for dish: DishData in all_dishes():
		if dish.id == dish_id:
			return dish

	return null


static func ingredient_name(ingredient_id: String) -> String:
	var data := get_ingredient(ingredient_id)
	return data.display_name if data else ingredient_id


static func ingredient_level(ingredient_id: String) -> int:
	var data := get_ingredient(ingredient_id)
	return data.level if data else 1


static func status_template(status_id: String) -> Status:
	var path: String = STATUS_TEMPLATES.get(status_id, "")
	if path.is_empty():
		return null

	return load(path) as Status


## 掉落物卡：0 费、只能拖到烹饪锅上。
static func make_ingredient(ingredient_id: String) -> IngredientCard:
	var data := get_ingredient(ingredient_id)
	if data == null:
		return null

	var card := IngredientCard.new()
	card.ingredient_id = data.id
	card.level = data.level
	card.id = "ingredient_" + data.id
	card.type = Card.Type.INGREDIENT
	card.rarity = Card.Rarity.COMMON
	card.target = Card.Target.SINGLE_ENEMY
	card.cost = 0
	card.exhausts = true
	card.icon = data.art if data.art else load(PLACEHOLDER) as Texture2D
	card.tooltip_text = "[center][color=\"88dd66\"]%s[/color]（%d 级食材）\n把这张牌拖到烹饪锅上，它就作为材料下锅。[/center]" % [
		data.display_name, data.level,
	]
	return card


## 素材总级别 → 食物等级，规则来自设计文档。
static func level_for_total(total: int) -> int:
	if total >= 10:
		return 4
	if total >= 7:
		return 3
	if total >= 4:
		return 2
	return 1


static func total_level(ingredient_ids: Array[String]) -> int:
	var total := 0
	for ingredient_id in ingredient_ids:
		total += ingredient_level(ingredient_id)

	return total


## 锅里的食材对上哪道菜。要完全一致，顺序无关。
static func find_recipe(ingredient_ids: Array[String]) -> DishData:
	var wanted := _sorted(ingredient_ids)
	for dish: DishData in all_dishes():
		if _sorted(dish.ingredients) == wanted:
			return dish

	return null


## 凑不出食谱时按等级随机出菜。没有同等级的料理就**往下兼容**：先退一级找，再退两
## 级……绝不会往上取。
static func random_recipe_of_level(level: int) -> DishData:
	var dishes := all_dishes()
	if dishes.is_empty():
		return null

	var candidate := clampi(level, 1, 4)
	while candidate > 0:
		var pool: Array[DishData] = []
		for dish: DishData in dishes:
			if dish.level == candidate:
				pool.append(dish)

		if not pool.is_empty():
			return RNG.array_pick_random(pool)

		candidate -= 1

	return RNG.array_pick_random(dishes)


static func make_dish(dish: DishData) -> DishCard:
	if dish == null:
		return null

	var rarity_by_level := [
		Card.Rarity.COMMON, Card.Rarity.COMMON, Card.Rarity.UNCOMMON, Card.Rarity.RARE,
	]

	var card := DishCard.new()
	card.dish_name = dish.display_name
	card.dish_level = dish.level
	card.id = "dish_" + dish.id
	card.type = Card.Type.DISH
	card.rarity = rarity_by_level[clampi(dish.level, 1, 4) - 1]
	card.target = Card.Target.SINGLE_ENEMY
	card.cost = dish.cost
	card.exhausts = true
	card.uses = dish.uses
	card.icon = dish.art if dish.art else load(PLACEHOLDER) as Texture2D

	for field in EFFECT_FIELDS:
		card.set(field, dish.get(field))

	card.tooltip_text = describe(dish)
	return card


## 卡面说明由效果字段拼出来，加一条效果只要往上加一行。
static func describe(dish: DishData) -> String:
	var lines: Array[String] = []
	var patterns := {
		"heal": "回复 %d 点生命",
		"max_health": "最大生命 +%d",
		"block": "获得 %d 点格挡",
		"energy": "获得 %d 点能量",
		"damage_all": "对所有敌人造成 %d 点伤害",
		"exposed_all": "给予所有敌人 %d 层破绽",
		"draw": "抽 %d 张牌",
		"exhaust_cards": "选择 %d 张手牌消耗",
		"muscle": "获得 %d 点肌肉",
		"charged": "获得 %d 层带电",
		"metallicize": "获得 %d 层金属化",
		"guard": "获得 %d 层守护",
		"nirvana": "获得 %d 层涅槃",
		"swift": "获得 %d 层迅捷",
		"retain": "获得 %d 层保留",
		"barricade": "获得 %d 层壁垒",
		"purify": "获得 %d 层净化",
		"miracle": "获得 %d 层奇迹",
		"dragon_flame": "获得 %d 层龙炎",
	}
	for field: String in patterns.keys():
		var amount: int = dish.get(field)
		if amount > 0:
			lines.append(patterns[field] % amount)

	if dish.muscle_min > 0:
		lines.append("随机获得 %d~%d 点肌肉" % [dish.muscle_min, dish.muscle_max])
	if dish.random_buffs > 0:
		lines.append("获得 %d 个随机增益" % dish.random_buffs)
	if dish.extra_turn:
		lines.append("本回合结束后获得 1 个额外回合")
	if dish.uses > 1:
		lines.append("可食用 %d 次" % dish.uses)
	if lines.is_empty():
		lines.append("只是很好吃")

	return "[center][color=\"ffdf00\"]%s[/color]（%d 级料理）\n%s[/center]" % [
		dish.display_name, dish.level, "，".join(lines),
	]


static func _ensure_loaded() -> void:
	if _loaded:
		return

	_loaded = true
	_ingredients = {}
	_dishes = []

	for path in ResourceFiles.list_resource_paths(INGREDIENT_DIR):
		var entry := load(path) as IngredientData
		if entry == null:
			continue

		var id := entry.id if not entry.id.is_empty() else path.get_file().get_basename()
		_ingredients[id] = entry

	for path in ResourceFiles.list_resource_paths(DISH_DIR):
		var dish := load(path) as DishData
		if dish:
			_dishes.append(dish)

	if _ingredients.is_empty() or _dishes.is_empty():
		push_error("CookingData: 食材 %d 种、料理 %d 道，至少一边没读到。" % [
			_ingredients.size(), _dishes.size(),
		])
	else:
		print("CookingData: 载入 %d 种食材、%d 道料理。" % [_ingredients.size(), _dishes.size()])


static func _sorted(ids: Array) -> Array:
	var copy: Array = ids.duplicate()
	copy.sort()
	return copy
