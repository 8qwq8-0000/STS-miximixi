class_name PauseMenu
extends CanvasLayer

signal save_and_quit

const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")

@onready var back_to_game_button: Button = %BackToGameButton
@onready var settings_button: Button = %SettingsButton
@onready var save_and_quit_button: Button = %SaveAndQuitButton

var _settings_menu: SettingsMenu


func _ready() -> void:
	back_to_game_button.pressed.connect(_unpause)
	settings_button.pressed.connect(_open_settings)
	save_and_quit_button.pressed.connect(_on_save_and_quit_button_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# 设置界面开着时，Esc 交给它自己关闭，不要顺手继续游戏。
		if _settings_open():
			return

		if visible:
			_unpause()
		else:
			_pause()
		
		get_viewport().set_input_as_handled()


func _open_settings() -> void:
	if _settings_open():
		return

	_settings_menu = SETTINGS_MENU_SCENE.instantiate()
	add_child(_settings_menu)


func _settings_open() -> bool:
	return is_instance_valid(_settings_menu) and _settings_menu.visible


func _pause() -> void:
	show()
	get_tree().paused = true


func _unpause() -> void:
	hide()
	get_tree().paused = false


func _on_save_and_quit_button_pressed() -> void:
	get_tree().paused = false
	save_and_quit.emit()
