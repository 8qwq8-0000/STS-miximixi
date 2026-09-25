extends Control

const CHAR_SELECTOR_SCENE := preload("res://scenes/ui/character_selector.tscn")
const RUN_SCENE = preload("res://scenes/run/run.tscn")
const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")
## 退出游戏的音效。它走 SFX 总线，和 MusicPlayer 各用各的播放器，所以放它的时候
## 全局 BGM 照旧响着，不会被掐断；要等的是「音效放完」——直接 quit() 会把音频一起停掉。
const EXIT_SOUND := preload("res://art/程序退出.wav")

@export var run_startup: RunStartup

@onready var continue_button: Button = %Continue
@onready var exit_button: Button = %Exit

## 退出只走一次：音效放完之前再点按钮不再重复触发。
var _quitting := false


func _ready() -> void:
	get_tree().paused = false
	# 启动时套用存档里的分辨率与音量。
	GameSettings.apply_all()
	continue_button.disabled = SaveGame.load_data() == null


func _on_continue_pressed() -> void:
	run_startup.type = RunStartup.Type.CONTINUED_RUN
	get_tree().change_scene_to_packed(RUN_SCENE)


func _on_new_run_pressed() -> void:
	get_tree().change_scene_to_packed(CHAR_SELECTOR_SCENE)


func _on_settings_pressed() -> void:
	add_child(SETTINGS_MENU_SCENE.instantiate())


func _on_exit_pressed() -> void:
	if _quitting:
		return

	_quitting = true
	exit_button.disabled = true
	SFXPlayer.play(EXIT_SOUND)

	await get_tree().create_timer(EXIT_SOUND.get_length()).timeout
	get_tree().quit()
