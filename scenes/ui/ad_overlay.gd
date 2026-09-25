class_name AdOverlay
extends Control

## 「激励广告」占位场景：点「我全都要」时播一段，看满 AD_DURATION 秒就发奖励
## 并自己关闭。
##
## 它只管播放和倒计时 —— 奖励由调用方接 ad_finished 之后自己发放，
## 广告场景不认识牌组、金币这些业务概念。

signal ad_finished

const AD_DURATION := 3.0

@onready var ad_title: Label = %AdTitle
@onready var countdown_label: Label = %AdCountdown
@onready var skip_button: Button = %AdSkipButton

## 剩余播放时间，用于显示「N 秒后自动发放」和「跳过广告（N）」。
var time_left := AD_DURATION


func _ready() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)

	_start_title_flash()
	_update_countdown()


func _process(delta: float) -> void:
	time_left = maxf(time_left - delta, 0.0)
	_update_countdown()

	if time_left <= 0.0:
		_finish()


## 广告得「动」起来才像广告：标题在暖黄和纯白之间来回闪。
func _start_title_flash() -> void:
	var flash := create_tween().set_loops()
	flash.tween_property(ad_title, "modulate", Color("#ffe08a"), 0.4)
	flash.tween_property(ad_title, "modulate", Color.WHITE, 0.4)


func _update_countdown() -> void:
	var seconds := ceili(time_left)
	countdown_label.text = "%d 秒后自动发放全部奖励" % seconds
	skip_button.text = "跳过广告（%d）" % seconds


## 播完了：发信号让调用方发奖励，然后自己退场。
func _finish() -> void:
	set_process(false)
	ad_finished.emit()
	queue_free()
