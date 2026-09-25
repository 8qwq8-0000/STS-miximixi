class_name IngredientData
extends Resource

## 一种食材。一个 .tres，放在 res://ingredients/ 下。
##
## id 就是怪物掉落表里引用的名字（见 res://monsters/<id>.tres 的 drops），所以改名
## 要连带把掉落一起改。

@export var id: String = ""

## 显示名，同时也是烹饪锅里显示的名字。
@export var display_name: String = ""

## 食材级别 1–4。下锅时按所有食材的级别之和决定能做出几级料理。
@export_range(1, 4, 1) var level := 1

@export var art: Texture2D
