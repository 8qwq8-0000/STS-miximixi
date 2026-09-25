extends EnemyAction

@export var block := 6


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var block_effect := BlockEffect.new()
	block_effect.amount = scaled_block(block)
	block_effect.sound = sound
	block_effect.execute([get_buff_target()])
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
