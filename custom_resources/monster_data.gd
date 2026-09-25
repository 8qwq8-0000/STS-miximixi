class_name MonsterData
extends Resource

## 一只怪物的全部属性，一只一个 .tres，放在 res://monsters/ 下。
##
## 这里是「表格原值」：血量、招式数值都是名单表里写的数。实际出场时还会乘上
## res://enemy_config.tres 里的倍率（那只怪的 entry 乘全局）。

enum Rank {NORMAL, ELITE, BOSS}

## 名册里的唯一标识。和文件名保持一致最省事。
@export var id: String = ""

@export var display_name: String = ""

@export_group("数值")

@export_range(1, 9999, 1) var max_health := 1

## 威胁等级，1–4。只用来决定它能凑几只一起上（见 MonsterBook.MAX_GROUP_BY_THREAT）
## 和随从池权重。
@export_range(1, 4, 1) var threat_level := 1

## 定位：普通怪 / 精英（进精英房）/ Boss（进最终 Boss 池）。
@export var rank: Rank = Rank.NORMAL

@export_group("出场资格")

## 能不能作为遭遇出场。关掉就永远碰不到它。
@export var encounter_eligible := true

## 能不能被玩家召唤成随从。关掉就不会进随从池。
@export var minion_eligible := true

@export_group("出现频率")

## 在遭遇池里的相对权重。调大更容易抽到，调 0 表示只保留手写组合里的出场。
@export_range(0.0, 10.0, 0.1) var encounter_weight := 1.0

@export_group("资源")

@export var art: Texture2D

## 击杀后掉落的食材 id，见 cooking_data.gd 的 INGREDIENTS 表。
@export var drops: Array[String] = []

@export_group("攻击模式")

## 按顺序循环出招。
@export var moves: Array[MonsterMove] = []
