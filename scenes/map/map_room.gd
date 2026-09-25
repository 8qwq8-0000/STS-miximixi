class_name MapRoom
extends Area2D

signal clicked(room: Room)
signal selected(room: Room)

const ICONS := {
	Room.Type.NOT_ASSIGNED: [null, Vector2.ONE],
	Room.Type.MONSTER: [preload("res://art/tile_0103.png"), Vector2(2.5, 2.5)],
	## 精英房沿用怪物图标，但放大一圈并染成红色，在地图上一眼能认出来。
	Room.Type.ELITE: [preload("res://art/tile_0103.png"), Vector2(3.5, 3.5)],
	Room.Type.TREASURE: [preload("res://art/tile_0089.png"), Vector2(2.5, 2.5)],
	Room.Type.CAMPFIRE: [preload("res://art/player_heart.png"), Vector2(1.5, 1.5)],
	Room.Type.SHOP: [preload("res://art/gold.png"), Vector2(1.5, 1.5)],
	Room.Type.BOSS: [preload("res://art/tile_0105.png"), Vector2(3.125, 3.125)],
	Room.Type.EVENT: [preload("res://art/rarity.png"), Vector2(2.25, 2.25)],
}

const ELITE_TINT := Color(1, 0.45, 0.45)
const ELITE_LINE := Color(0.85, 0.2, 0.2)
const DEFAULT_LINE := Color(0.529412, 0.529412, 0.529412)
## 探索过的房间调暗到这个透明度，和还能走的房间区分开。
const VISITED_ALPHA := 0.55

@onready var sprite_2d: Sprite2D = $Visuals/Sprite2D
@onready var line_2d: Line2D = $Visuals/Line2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var available := false : set = set_available
var room: Room : set = set_room


func set_available(new_value: bool) -> void:
	available = new_value
	
	if available:
		animation_player.play("highlight")
	elif not room.selected:
		animation_player.play("RESET")


func set_room(new_data: Room) -> void:
	room = new_data
	position = room.position
	line_2d.rotation_degrees = randi_range(0, 360)
	sprite_2d.texture = ICONS[room.type][0]
	sprite_2d.scale = ICONS[room.type][1]

	var is_elite := room.type == Room.Type.ELITE
	sprite_2d.modulate = ELITE_TINT if is_elite else Color.WHITE
	line_2d.default_color = ELITE_LINE if is_elite else DEFAULT_LINE


func show_selected() -> void:
	_set_visited_look()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not available or not event.is_action_pressed("left_mouse"):
		return

	# 探索过的房间只留白边作记号，不给二次进入。
	if room and room.selected:
		return

	room.selected = true
	clicked.emit(room)
	animation_player.play("select")
	_set_visited_look()


## 走过的房间：白边圈住 + 画面变暗。
func _set_visited_look() -> void:
	line_2d.modulate = Color.WHITE
	sprite_2d.modulate.a = VISITED_ALPHA


# Called by the AnimationPLayer when the 
# "select" animation finishes.
func _on_map_room_selected() -> void:
	selected.emit(room)
