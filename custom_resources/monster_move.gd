class_name MonsterMove
extends Resource

## 怪物的一个招式。
##
## 名字 + 一串可选的数值，MoveAction 会照着执行、并按这些值显示意图。同一只怪的招式
## 按 order 依次循环出招（见 MoveCycleAI），所以要改行动顺序就调整它在列表里的位置。

## 显示在意图旁边的招式名。
@export var move_name: String = ""

@export_group("攻击")

@export_range(0, 999, 1) var damage := 0

## 打几段。> 1 时意图会显示成「伤害×段数」。
@export_range(1, 6, 1) var hits := 1

@export_group("防御与恢复")

@export_range(0, 999, 1) var block := 0
@export_range(0, 999, 1) var heal := 0

@export_group("增益")

## 状态 id，见 statuses/ 目录（muscle、charged、nirvana…）。留空表示不加。
@export var buff_id: String = ""
@export_range(0, 99, 1) var buff_amount := 0

@export_group("负面效果")

@export var debuff_id: String = ""
@export_range(0, 99, 1) var debuff_amount := 0

@export_group("塞牌")

## 往玩家抽牌堆里塞的状态牌。
@export var status_card: Card
@export_range(0, 9, 1) var status_card_amount := 0
