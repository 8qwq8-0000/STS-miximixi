class_name EternalCompanionRelic
extends Relic

## Grants one permanent crab minion, which then follows the run into every
## battle (MinionHandler spawns Run.minions at the start of each fight).

const COMPANION = preload("res://enemies/crab/crab_enemy.tres")

## Identifies this one-shot grant inside the save. initialize_relic() also runs
## when a save is loaded, so without a remembered source id the crab would be
## handed out again on every load.
const SOURCE_ID := "eternal_companion"


func initialize_relic(owner: RelicUI) -> void:
	var run := owner.get_tree().get_first_node_in_group("run") as Run
	if run == null:
		return

	run.grant_minion(COMPANION, SOURCE_ID)
