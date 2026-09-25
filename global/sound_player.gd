extends Node

## 全局音乐播放器（autoload「MusicPlayer」）。
##
## 它是常驻节点，音乐不随场景切换中断：主菜单、地图、商店都用 default_track。战斗
## 场景会临时换成战斗曲，离开战斗时由 Battle 调 restore_default() 把全局曲接回来。
## 重复请求同一首会被直接忽略，播放位置保持不变。

## 游戏一启动就播的曲子；换曲子只要改 global/music_player.tscn 里的这个引用。
@export var default_track: AudioStream

## 当前这首放完之后要不要从头再来一遍。
##
## 战斗曲是 QOA 压缩的 wav，导入时打不了循环点（QOA 不存循环信息），所以用
## 「放完再放一遍」顶上；默认曲不开这个开关，放完就安静。
var repeat_current := false

## 这会儿轮到哪个播放器，用来分辨 finished 是谁发出来的。
var _current: AudioStreamPlayer

## 当前这首放完之后改放的下一首（Boss 战：boss 曲放一遍，接着放循环曲）。
## 为空就按 repeat_current 决定要不要重播自己。
var _next_track: AudioStream


func _ready() -> void:
	for player: AudioStreamPlayer in get_children():
		player.finished.connect(_on_player_finished.bind(player))

	if default_track:
		play(default_track, true)


## 播放一首曲子。single 为 true 时先停掉当前音乐（换曲子用）；
## repeat_forever 为 true 时这首放完会自己从头上再来一遍（战斗曲用）。
## next_track 不为空时，这首放完改放那一首，并且从那以后一直循环它。
##
## 已经在播的那首曲子会直接返回，播放位置保持不变，这样场景进出就不会把音乐
## 重置回开头。
func play(
	audio: AudioStream,
	single: bool = false,
	repeat_forever: bool = false,
	next_track: AudioStream = null,
) -> void:
	if audio == null or is_playing(audio):
		# 已经在播的这首：只更新循环与接续的设置，播放位置照旧不动。
		repeat_current = repeat_forever
		_next_track = next_track
		return

	if single:
		stop()

	repeat_current = repeat_forever
	_next_track = next_track

	for player: AudioStreamPlayer in get_children():
		if not player.playing:
			_current = player
			player.stream = audio
			player.play()
			return


func is_playing(audio: AudioStream) -> bool:
	if audio == null:
		return false

	for player: AudioStreamPlayer in get_children():
		if player.playing and player.stream == audio:
			return true

	return false


## 切回全局默认 BGM。离开战斗场景时调用：战斗曲只属于战斗，出了战斗就接回全局曲。
func restore_default() -> void:
	if default_track == null:
		return

	play(default_track, true)


func stop() -> void:
	_current = null
	repeat_current = false
	_next_track = null

	for player: AudioStreamPlayer in get_children():
		player.stop()


## 一首放完了。先看有没有排好的下一首，没有才按「还开着重播」续上自己；
## 两种情况都要求「没有别的播放器在响」，免得和换曲打架。
func _on_player_finished(player: AudioStreamPlayer) -> void:
	if player != _current:
		return

	for other: AudioStreamPlayer in get_children():
		if other.playing:
			return

	# 两段式：这首放完换成排好的下一首，换上之后就一直循环它。
	if _next_track:
		var following := _next_track
		_next_track = null
		repeat_current = true
		player.stream = following
		player.play()
		return

	if not repeat_current:
		return

	player.play()
