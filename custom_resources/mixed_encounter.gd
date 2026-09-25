class_name MixedEncounter
extends Resource

## 一场手写的混编遭遇。
##
## 放在 res://encounter_config.tres 的 mixed 列表里就会生效，和自动生成的通用
## 档一起参与抽取。列表里没有的组合永远不会出现；这里写了的组合一定会出现。

## 只用来在检查器里认人，不影响游戏。
@export var name: String = ""

## 关掉就整条不生效，方便临时把某个组合从池子里摘出去。
@export var enabled := true

## 战斗层级：0 = 前 3 层，1 = 中途，2 = Boss。
@export_range(0, 2, 1) var battle_tier := 1

## 和同层级的其它遭遇一起抽时的权重。
@export_range(0.0, 10.0, 0.1) var weight := 1.0

@export var gold_min := 20
@export var gold_max := 40

## 这一场由哪些怪、各几只组成，总数就是怪物数量。
@export var entries: Array[EncounterEntry] = []


func total_count() -> int:
	var total := 0
	for entry: EncounterEntry in entries:
		if entry:
			total += entry.count
	return total
