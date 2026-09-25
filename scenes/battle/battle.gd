class_name Battle
extends Node2D

# 一般战斗的曲子。
const BATTLE_MUSIC := preload("res://art/th06_04.wav")
# Boss 战的曲子。
const BOSS_MUSIC := preload("res://art/th06_05.wav")
# Boss 战的第二首：boss 曲放完接这首，之后一直循环它。
const BOSS_MUSIC_LOOP := preload("res://art/雨爱.mp3")
# Boss 房的战斗层级，和 battle_stats.gd 里的说明一致。
const BOSS_TIER := 2

@export var battle_stats: BattleStats
@export var char_stats: CharacterStats
## 手动指定的战斗曲；留空就按战斗层级自动选。
@export var music: AudioStream
@export var relics: RelicHandler
@export var minions: Array[EnemyStats]

@onready var battle_ui: BattleUI = $BattleUI
@onready var player_handler: PlayerHandler = $PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler
@onready var minion_handler: MinionHandler = $MinionHandler
@onready var player: Player = $Player
@onready var cooking_pot: CookingPot = $CookingPot


func _ready() -> void:
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)
	
	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(minion_handler.start_turn)
	minion_handler.turn_finished.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)
	Events.enemy_died.connect(_on_enemy_died)
	Events.dish_cooked.connect(_on_dish_cooked)
	Events.extra_turn_started.connect(_on_extra_turn_started)


## 战斗曲是 QOA 压缩的 wav，导入时存不下循环点，所以靠「放完再放一次」续上：
## 第三个参数让 MusicPlayer 监听 finished，播完自动从头再来一遍。
## Boss 战是两段式：boss 曲只放一遍，放完换 雨爱.mp3，之后循环第二首。
func _play_battle_music() -> void:
	if music == null and _is_boss_battle():
		MusicPlayer.play(BOSS_MUSIC, true, false, BOSS_MUSIC_LOOP)
		return

	MusicPlayer.play(_battle_music(), true, true)


## 离开战斗（胜利结算、玩家阵亡、暂停菜单退出，都会把战斗场景释放掉）时把全局
## BGM 接回来：战斗曲只属于战斗场景。
func _exit_tree() -> void:
	MusicPlayer.restore_default()


## Boss 战换成 Boss 曲；精英房和普通遭遇都算一般战斗。
func _battle_music() -> AudioStream:
	if music:
		return music

	if battle_stats and battle_stats.battle_tier == BOSS_TIER:
		return BOSS_MUSIC

	return BATTLE_MUSIC


## 这一场是不是 Boss 房（battle_tier 2，和地图生成器里的设定一致）。
func _is_boss_battle() -> bool:
	return battle_stats != null and battle_stats.battle_tier == BOSS_TIER


func start_battle() -> void:
	get_tree().paused = false
	_play_battle_music()

	cooking_pot.clear_pot()
	
	battle_ui.char_stats = char_stats
	player.stats = char_stats
	player_handler.relics = relics
	enemy_handler.setup_enemies(battle_stats)
	enemy_handler.reset_enemy_actions()
	minion_handler.setup_minions(minions)
	
	relics.relics_activated.connect(_on_relics_activated)
	relics.activate_relics_by_type(Relic.Type.START_OF_COMBAT)


func _on_enemies_child_order_changed() -> void:
	if enemy_handler.get_child_count() == 0 and is_instance_valid(relics):
		relics.activate_relics_by_type(Relic.Type.END_OF_COMBAT)


func _on_enemy_turn_ended() -> void:
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()


## The enemies sit out the bonus turn 传说盛宴 hands out.
func _on_extra_turn_started() -> void:
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()


## 掉落物 — every corpse can leave ingredients behind. The card goes to the hand,
## and a full hand pushes it to the discard pile instead.
func _on_enemy_died(enemy: Enemy) -> void:
	if enemy == null or enemy.stats == null:
		return

	for ingredient_id in enemy.stats.drops:
		grant_card(CookingData.make_ingredient(ingredient_id))


func _on_dish_cooked(dish: DishCard) -> void:
	grant_card(dish)


func grant_card(card: Card) -> void:
	if card == null:
		return

	var hand := player_handler.hand
	if hand == null:
		return

	if hand.is_full():
		player_handler.character.discard.add_card(card)
		return

	hand.add_card(card)


func _on_player_died() -> void:
	Events.battle_over_screen_requested.emit("游戏结束！", BattleOverPanel.Type.LOSE)
	SaveGame.delete_data()


func _on_relics_activated(type: Relic.Type) -> void:
	match type:
		Relic.Type.START_OF_COMBAT:
			player_handler.start_battle(char_stats)
			battle_ui.initialize_card_pile_ui()
		Relic.Type.END_OF_COMBAT:
			# Boss 战不摆「胜利！」面板：怪一清空就直接切胜利画面。
			if _is_boss_battle():
				Events.battle_won.emit()
				return

			Events.battle_over_screen_requested.emit("胜利！", BattleOverPanel.Type.WIN)
