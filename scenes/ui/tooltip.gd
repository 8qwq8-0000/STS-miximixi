class_name Tooltip
extends PanelContainer

@export var fade_seconds := 0.2

@onready var tooltip_icon: TextureRect = %TooltipIcon
@onready var tooltip_text_label: RichTextLabel = %TooltipText

var tween: Tween
var is_visible_now := false


func _ready() -> void:
	Events.card_tooltip_requested.connect(show_tooltip)
	Events.tooltip_hide_requested.connect(hide_tooltip)
	modulate = Color.TRANSPARENT
	hide()


## 战斗胜利（Boss 也一样）会把整个战斗场景释放掉。拆场景的时候，手里的卡牌先一步
## 离开场景树，并把 mouse_exited 抛出来 —— 那时这个提示框已经不在树上了，
## get_tree() 是 null，再拿它建计时器就会报错，调试器一停游戏就像闪退一样卡住。
## 所以离开场景树时先摘掉监听，顺手把没跑完的 tween 收干净。
func _exit_tree() -> void:
	if Events.card_tooltip_requested.is_connected(show_tooltip):
		Events.card_tooltip_requested.disconnect(show_tooltip)

	if Events.tooltip_hide_requested.is_connected(hide_tooltip):
		Events.tooltip_hide_requested.disconnect(hide_tooltip)

	if tween:
		tween.kill()


func show_tooltip(icon: Texture, text: String) -> void:
	if not is_inside_tree():
		return

	is_visible_now = true
	if tween:
		tween.kill()
	
	tooltip_icon.texture = icon
	tooltip_text_label.text = text
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(show)
	tween.tween_property(self, "modulate", Color.WHITE, fade_seconds)


func hide_tooltip() -> void:
	is_visible_now = false
	if tween:
		tween.kill()

	# 已经不在场景树上就没有计时器可建，也没什么需要淡出的。
	if not is_inside_tree():
		return

	get_tree().create_timer(fade_seconds, false).timeout.connect(hide_animation)


func hide_animation() -> void:
	if not is_inside_tree():
		return

	if not is_visible_now:
		tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_seconds)
		tween.tween_callback(hide)
