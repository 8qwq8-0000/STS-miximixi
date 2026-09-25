class_name EncounterEntry
extends Resource

## 混编战斗里的一行：一种怪 + 数量。
##
## monster_id 就是怪物名册里的 id（caterpie、machamp……）。同一场遭遇里想放多
## 只同种怪，把 count 调大即可；要混别的怪就再加一行。

@export var monster_id: String = ""

@export_range(1, 4, 1) var count := 1
