class_name GameSettings
extends RefCounted

## 分辨率、音量与开发者模式的持久化设置，存放在 user://settings.cfg。
##
## 只提供设计分辨率 640x360 的整数倍档位：项目用的是整数缩放
## （display/window/stretch/scale_mode = integer），非整数倍会出现黑边。
## 音量按 Master / Music / SFX 三条总线线性保存，写回时转成分贝。

const CONFIG_PATH := "user://settings.cfg"
const DESIGN_SIZE := Vector2i(640, 360)
const MAX_SCALE := 6
## 没有任何存档时的默认窗口尺寸倍数（640x360 x 2 = 1280x720）。
const DEFAULT_SCALE := 2

static var window_size := DESIGN_SIZE * DEFAULT_SCALE
static var master_volume := 1.0
static var music_volume := 1.0
static var sfx_volume := 1.0

## 开发者模式：地图上任意房间都能点、战斗里玩家不掉血、右键点怪即秒杀。
##
## 只在本局有效：每次启动游戏都从「关闭」开始，不写进 settings.cfg。这样上次调试
## 留下的开关不会跟着带进下一次游玩，正常玩的人也不会莫名其妙拿到无敌和秒杀。
static var developer_mode := false

static var _loaded := false


## 首次调用时从磁盘读取；没有存档就沿用项目当前的窗口尺寸与总线音量。
static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true

	window_size = Vector2i(
		ProjectSettings.get_setting("display/window/size/window_width_override", DESIGN_SIZE.x * DEFAULT_SCALE),
		ProjectSettings.get_setting("display/window/size/window_height_override", DESIGN_SIZE.y * DEFAULT_SCALE)
	)
	master_volume = _read_bus_volume("Master")
	music_volume = _read_bus_volume("Music")
	sfx_volume = _read_bus_volume("SFX")

	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return

	window_size = Vector2i(
		config.get_value("display", "window_width", window_size.x),
		config.get_value("display", "window_height", window_size.y)
	)
	master_volume = config.get_value("audio", "master", master_volume)
	music_volume = config.get_value("audio", "music", music_volume)
	sfx_volume = config.get_value("audio", "sfx", sfx_volume)


static func apply_all() -> void:
	ensure_loaded()
	apply_audio()
	apply_window()


static func apply_audio() -> void:
	_write_bus_volume("Master", master_volume)
	_write_bus_volume("Music", music_volume)
	_write_bus_volume("SFX", sfx_volume)


static func apply_window() -> void:
	if window_size.x <= 0 or window_size.y <= 0:
		return

	DisplayServer.window_set_size(window_size)
	_center_window()


static func set_window_size(size: Vector2i) -> void:
	ensure_loaded()
	window_size = size
	apply_window()


static func save() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "window_width", window_size.x)
	config.set_value("display", "window_height", window_size.y)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.save(CONFIG_PATH)


## 能塞进当前显示器的整数倍档位，从小到大。
static func resolution_options() -> Array[Vector2i]:
	ensure_loaded()

	var screen := DisplayServer.screen_get_size()
	var options: Array[Vector2i] = []
	for step in range(1, MAX_SCALE + 1):
		var size := DESIGN_SIZE * step
		if size.x <= screen.x and size.y <= screen.y:
			options.append(size)

	if options.is_empty():
		options.append(DESIGN_SIZE)
	elif not options.has(window_size) and window_size.x <= screen.x and window_size.y <= screen.y:
		# 存档里的尺寸不是标准档位（比如手改过窗口），也让它出现在列表里。
		options.append(window_size)

	options.sort()
	return options


static func _read_bus_volume(bus_name: String) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return 1.0
	if AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


static func _write_bus_volume(bus_name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return

	var linear := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(index, linear <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.001)))


static func _center_window() -> void:
	var screen := DisplayServer.screen_get_size()
	var size := DisplayServer.window_get_size()
	var position := (screen - size) / 2
	DisplayServer.window_set_position(Vector2i(maxi(position.x, 0), maxi(position.y, 0)))
