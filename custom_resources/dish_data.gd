class_name DishData
extends Resource

## 一道料理。一个 .tres，放在 res://dishes/ 下。
##
## ingredients 是「需要哪些食材」，顺序无关、必须完全一致才算命中这道菜；凑不出任何
## 食谱时，锅会按素材总级别随机给一道同级料理（见 CookingData）。

@export var id: String = ""

## 显示名，会写进卡面说明里。
@export var display_name: String = ""

@export_range(1, 4, 1) var level := 1

## 打出费用。生成时按等级给的默认值（1–2 级 0 费，3–4 级 1 费），可以单独改。
@export_range(0, 3, 1) var cost := 0

@export var art: Texture2D

## 需要的食材 id，顺序无关。
@export var ingredients: Array[String] = []

## 可食用次数。大于 1 时打完会回到手牌，直到用完。
@export_range(1, 9, 1) var uses := 1

@export_group("恢复")

@export var heal := 0
@export var max_health := 0
@export var block := 0
@export var energy := 0

@export_group("战斗")

@export var damage_all := 0
@export var exposed_all := 0
@export var draw := 0
@export var exhaust_cards := 0
@export var extra_turn := false

@export_group("增益")

@export var muscle := 0
@export var muscle_min := 0
@export var muscle_max := 0
@export var random_buffs := 0
@export var charged := 0
@export var metallicize := 0
@export var guard := 0
@export var nirvana := 0
@export var swift := 0
@export var retain := 0
@export var barricade := 0
@export var purify := 0
@export var miracle := 0
@export var dragon_flame := 0
