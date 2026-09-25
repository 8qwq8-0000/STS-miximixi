class_name Treasure
extends Control

@export var treasure_relic_pool: Array[Relic]
@export var relic_handler: RelicHandler
@export var char_stats: CharacterStats

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var treasure_chest: TextureRect = $TreasureChest
var found_relic: Relic


func _ready() -> void:
	# 宝箱在点击前不可见，但必须仍然接收鼠标事件，所以用「完全透明」
	# 而不是 visible = false（隐藏的 Control 不会收到 gui_input）。
	treasure_chest.visible = true
	treasure_chest.modulate.a = 0.0


func generate_relic() -> void:
	var available_relics := treasure_relic_pool.filter(
		func(relic: Relic):
			var can_appear := relic.can_appear_as_reward(char_stats)
			var already_had_it := relic_handler.has_relic(relic.id)
			return can_appear and not already_had_it
	)
	found_relic = RNG.array_pick_random(available_relics)


# Called from the AnimationPlayer, at the
# end of the 'open' animation.
func _on_treasure_opened() -> void:
	Events.treasure_room_exited.emit(found_relic)


func _on_treasure_chest_gui_input(event: InputEvent) -> void:
	if animation_player.current_animation == "open":
		return
	
	if event.is_action_pressed("left_mouse"):
		# 点击前宝箱是「完全透明但可点击」的：隐藏的 Control 收不到鼠标事件，
		# 所以这里用透明度隐藏，点击后再让它显现并播放开箱动画。
		treasure_chest.modulate.a = 1.0
		animation_player.play("open")
