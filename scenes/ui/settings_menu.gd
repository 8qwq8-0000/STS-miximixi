class_name SettingsMenu
extends Control

## 设置界面：调分辨率（整数倍档位）、三条音频总线的音量，以及开发者模式开关。
## 主菜单和暂停菜单都实例化这一个场景，设置会写进 user://settings.cfg。

@onready var resolution_option: OptionButton = %ResolutionOption
@onready var master_slider: HSlider = %MasterSlider
@onready var master_value: Label = %MasterValue
@onready var music_slider: HSlider = %MusicSlider
@onready var music_value: Label = %MusicValue
@onready var sfx_slider: HSlider = %SfxSlider
@onready var sfx_value: Label = %SfxValue
@onready var dev_mode_button: CheckButton = %DevModeButton
@onready var back_button: Button = %BackButton

var _resolutions: Array[Vector2i] = []
var _refreshing := false


func _ready() -> void:
	_refresh()
	resolution_option.item_selected.connect(_on_resolution_selected)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	dev_mode_button.toggled.connect(_on_dev_mode_toggled)
	back_button.pressed.connect(close)


func _input(event: InputEvent) -> void:
	# Esc 同时是 ui_cancel 和游戏的 pause，两个都要接：
	# 开着设置时先关设置，而不是顺手继续游戏。
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	GameSettings.save()
	hide()
	queue_free()


func _refresh() -> void:
	_refreshing = true

	_resolutions = GameSettings.resolution_options()
	resolution_option.clear()
	for size: Vector2i in _resolutions:
		resolution_option.add_item("%d x %d" % [size.x, size.y])

	var index := _resolutions.find(GameSettings.window_size)
	if index < 0:
		# 存档尺寸在这台显示器上放不下：退回最大可用档位。
		index = _resolutions.size() - 1
		GameSettings.set_window_size(_resolutions[index])
	resolution_option.select(index)

	master_slider.value = roundf(GameSettings.master_volume * 100.0)
	music_slider.value = roundf(GameSettings.music_volume * 100.0)
	sfx_slider.value = roundf(GameSettings.sfx_volume * 100.0)
	dev_mode_button.button_pressed = GameSettings.developer_mode
	_update_value_labels()

	_refreshing = false


func _update_value_labels() -> void:
	master_value.text = str(roundi(master_slider.value))
	music_value.text = str(roundi(music_slider.value))
	sfx_value.text = str(roundi(sfx_slider.value))


func _on_resolution_selected(index: int) -> void:
	if _refreshing or index < 0 or index >= _resolutions.size():
		return

	GameSettings.set_window_size(_resolutions[index])
	GameSettings.save()


func _on_master_changed(value: float) -> void:
	if _refreshing:
		return

	GameSettings.master_volume = clampf(value / 100.0, 0.0, 1.0)
	GameSettings.apply_audio()
	_update_value_labels()


func _on_music_changed(value: float) -> void:
	if _refreshing:
		return

	GameSettings.music_volume = clampf(value / 100.0, 0.0, 1.0)
	GameSettings.apply_audio()
	_update_value_labels()


func _on_sfx_changed(value: float) -> void:
	if _refreshing:
		return

	GameSettings.sfx_volume = clampf(value / 100.0, 0.0, 1.0)
	GameSettings.apply_audio()
	_update_value_labels()


## 开发者模式：地图任意房间可点、战斗内玩家不掉血、右键点怪秒杀。
## 开关立刻生效，但只对这一局有效 —— 它不写进 settings.cfg，重开游戏就回到关闭。
## 地图靠 Events 的通知刷新自己的可点状态。
func _on_dev_mode_toggled(pressed: bool) -> void:
	if _refreshing:
		return

	GameSettings.developer_mode = pressed
	Events.developer_mode_changed.emit(pressed)
