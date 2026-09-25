class_name Enemy
extends Area2D

const ARROW_OFFSET := 12.5
const WHITE_SPRITE_MATERIAL := preload("res://art/white_sprite_material.tres")
## 生物倒下的音效。随从 extends Enemy，走的是同一条死亡路径，所以这里响一次就够。
const DEATH_SOUND := preload("res://art/死亡音效.wav")

## Every monster reads at roughly the same size on screen. The 16px pixel art the
## enemies ship with already sits at a hand-tuned 2x and is left alone; bigger
## source images (the 宝可梦 sprites are 120px) are shrunk to match.
const BASE_SPRITE_SCALE := 2.5
const TARGET_SPRITE_SIZE := 50.0

@export var stats: EnemyStats : set = set_enemy_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var arrow: Sprite2D = $Arrow
@onready var stats_ui: StatsUI = $StatsUI
@onready var intent_ui: IntentUI = $IntentUI
@onready var status_handler: StatusHandler = $StatusHandler
@onready var modifier_handler: ModifierHandler = $ModifierHandler

var enemy_action_picker: EnemyActionPicker
var current_action: EnemyAction : set = set_current_action


func _ready() -> void:
	status_handler.status_owner = self
	input_event.connect(_on_input_event)


func set_current_action(value: EnemyAction) -> void:
	current_action = value
	update_intent()


func set_enemy_stats(value: EnemyStats) -> void:
	stats = value.create_instance()
	
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
		stats.stats_changed.connect(update_action)
	
	update_enemy()


func setup_ai() -> void:
	if enemy_action_picker:
		enemy_action_picker.queue_free()
		
	var new_action_picker := stats.ai.instantiate() as EnemyActionPicker
	new_action_picker.set("monster_id", stats.monster_id)
	add_child(new_action_picker)
	enemy_action_picker = new_action_picker
	enemy_action_picker.enemy = self


func update_stats() -> void:
	stats_ui.update_stats(stats)


func update_action() -> void:
	if not enemy_action_picker:
		return
	
	if not current_action:
		current_action = enemy_action_picker.get_action()
		return
	
	var new_conditional_action := enemy_action_picker.get_first_conditional_action()
	if new_conditional_action and current_action != new_conditional_action:
		current_action = new_conditional_action


func update_enemy() -> void:
	if not stats is Stats: 
		return
	if not is_inside_tree(): 
		await ready
	
	sprite_2d.texture = stats.art
	fit_sprite()
	arrow.position = Vector2.RIGHT * (
		sprite_2d.get_rect().size.x / 2 * sprite_2d.scale.x + ARROW_OFFSET
	)
	setup_ai()
	update_stats()


## Fits the current art to TARGET_SPRITE_SIZE without ever enlarging it.
func fit_sprite() -> void:
	if sprite_2d.texture == null:
		return

	var art_size := sprite_2d.texture.get_size()
	var longest := maxf(art_size.x, art_size.y)
	if longest <= 0.0:
		return

	var target_scale := TARGET_SPRITE_SIZE / longest
	var factor := minf(1.0, target_scale / BASE_SPRITE_SCALE)
	sprite_2d.scale = Vector2(BASE_SPRITE_SCALE, BASE_SPRITE_SCALE) * factor


func update_intent() -> void:
	if current_action:
		current_action.update_intent_text()
		intent_ui.update_intent(current_action.intent)


func do_turn() -> void:
	stats.block = 0
	
	if not current_action:
		return
	
	current_action.perform_action()


func take_damage(damage: int, which_modifier: Modifier.Type) -> void:
	if stats.health <= 0:
		return
	
	sprite_2d.material = WHITE_SPRITE_MATERIAL
	var modified_damage := modifier_handler.get_modified_value(damage, which_modifier)
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 32, 0.15))
	tween.tween_callback(stats.take_damage.bind(modified_damage))
	tween.tween_interval(0.17)

	tween.finished.connect(
		func():
			sprite_2d.material = null
			
			if stats.health <= 0:
				# 涅槃：先拿一层换一次满血复活。这一下不算死，所以既不会掉掉落物，
				# 也不会让这一只从场上消失 —— 战斗胜利是看场上还有没有怪，判定自然
				# 就排在涅槃后面。
				if _consume_status("nirvana"):
					stats.health = stats.max_health
					return

				SFXPlayer.play(DEATH_SOUND)
				Events.enemy_died.emit(self)
				queue_free()
	)


## Spends one stack of an INTENSITY status and reports whether it was there.
## StatusUI removes the status on its own once the last stack is gone.
func _consume_status(id: String) -> bool:
	if not status_handler:
		return false

	var status := status_handler.get_status(id)
	if status == null or status.stacks <= 0:
		return false

	status.stacks -= 1
	return true


func _on_area_entered(_area: Area2D) -> void:
	arrow.show()


func _on_area_exited(_area: Area2D) -> void:
	arrow.hide()


## 开发者模式专用：右键点一下这只怪就送它走。走的是正常的死亡流程，所以掉落、
## 战斗胜利判定都不会被跳过。
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not GameSettings.developer_mode:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		dev_kill()


## 垫到 1 血再打一大坨，格挡和减伤都没机会拦下来。
func dev_kill() -> void:
	if stats == null or stats.health <= 0:
		return

	stats.health = 1
	take_damage(9999, Modifier.Type.DMG_TAKEN)
