class_name Map
extends Node2D

const SCROLL_SPEED := 37.5
const MAP_ROOM = preload("res://scenes/map/map_room.tscn")
const MAP_LINE = preload("res://scenes/map/map_line.tscn")

@onready var map_generator: MapGenerator = $MapGenerator
@onready var lines: Node2D = %Lines
@onready var rooms: Node2D = %Rooms
@onready var visuals: Node2D = $Visuals
@onready var camera_2d: Camera2D = $Camera2D
@onready var map_background: CanvasLayer = $MapBackground

var map_data: Array[Array]
var floors_climbed: int
var last_room: Room
var camera_edge_y: float
var _dragging := false


func _ready() -> void:
	camera_edge_y = MapGenerator.Y_DIST * (MapGenerator.FLOORS - 1)
	_layout_background()
	Events.developer_mode_changed.connect(_on_developer_mode_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		return

	if event is InputEventMouseMotion and _dragging:
		# 抓着地图拖：鼠标往下拖，地图内容就跟着往下走（相当于镜头往上爬一层）。
		_scroll_camera(-event.relative.y)
	elif event.is_action_pressed("scroll_up"):
		_scroll_camera(-SCROLL_SPEED)
	elif event.is_action_pressed("scroll_down"):
		_scroll_camera(SCROLL_SPEED)


func _scroll_camera(amount: float) -> void:
	camera_2d.position.y = clampf(camera_2d.position.y + amount, -camera_edge_y, 0.0)


## 三段背景（上/中/下）按纹理比例铺满一屏宽，自下而上叠在一起，
## 正好盖住整张地图的滚动范围；它们挂在 follow_viewport 的 CanvasLayer 上，
## 所以拖动地图时会和房间、连线一起移动。
func _layout_background() -> void:
	var viewport_size := get_viewport_rect().size
	var slices: Array[TextureRect] = []
	for child in map_background.get_children():
		if child is TextureRect:
			slices.append(child)

	for i in slices.size():
		var slice := slices[i]
		if slice.texture == null:
			continue

		var texture_size := slice.texture.get_size()
		var height := viewport_size.x * texture_size.y / texture_size.x
		var bottom := viewport_size.y - height * float(slices.size() - 1 - i)
		slice.offset_left = 0.0
		slice.offset_right = viewport_size.x
		slice.offset_top = bottom - height
		slice.offset_bottom = bottom


func generate_new_map() -> void:
	floors_climbed = 0
	map_data = map_generator.generate_map()
	create_map()


func load_map(map: Array[Array], floors_completed: int, last_room_climbed: Room) -> void:
	floors_climbed = floors_completed
	map_data = map
	last_room = last_room_climbed
	create_map()
	
	if floors_climbed > 0:
		unlock_next_rooms()
	else:
		unlock_floor()


func create_map() -> void:
	_layout_background()

	for current_floor: Array in map_data:
		for room: Room in current_floor:
			if room.next_rooms.size() > 0:
				_spawn_room(room)
	
	# Boss room has no next room but we need to spawn it
	var middle := floori(MapGenerator.MAP_WIDTH * 0.5)
	_spawn_room(map_data[MapGenerator.FLOORS-1][middle])

	var map_width_pixels := MapGenerator.X_DIST * (MapGenerator.MAP_WIDTH - 1)
	visuals.position.x = (get_viewport_rect().size.x - map_width_pixels) / 2
	visuals.position.y = get_viewport_rect().size.y / 2
	_apply_developer_unlock()


func unlock_floor(which_floor: int = floors_climbed) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == which_floor:
			map_room.available = true


func unlock_next_rooms() -> void:
	for map_room: MapRoom in rooms.get_children():
		if last_room.next_rooms.has(map_room.room):
			map_room.available = true


func show_map() -> void:
	show()
	camera_2d.enabled = true
	_dragging = false
	_apply_developer_unlock()


func hide_map() -> void:
	hide()
	camera_2d.enabled = false
	_dragging = false


func _spawn_room(room: Room) -> void:
	var new_map_room := MAP_ROOM.instantiate() as MapRoom
	rooms.add_child(new_map_room)
	new_map_room.room = room
	new_map_room.clicked.connect(_on_map_room_clicked)
	new_map_room.selected.connect(_on_map_room_selected)
	_connect_lines(room)
	
	if room.selected and room.row < floors_climbed:
		new_map_room.show_selected()


func _connect_lines(room: Room) -> void:
	if room.next_rooms.is_empty():
		return
		
	for next: Room in room.next_rooms:
		var new_map_line := MAP_LINE.instantiate() as Line2D
		new_map_line.add_point(room.position)
		new_map_line.add_point(next.position)
		lines.add_child(new_map_line)


func _on_map_room_clicked(room: Room) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == room.row:
			map_room.available = false


func _on_map_room_selected(room: Room) -> void:
	last_room = room
	floors_climbed += 1
	Events.map_exited.emit(room)


## 开发者模式：整张地图的房间全部亮起、都能点，不再受连线和层数限制。
func _apply_developer_unlock() -> void:
	if not GameSettings.developer_mode:
		return

	for map_room: MapRoom in rooms.get_children():
		# 探索过的房间不开：开发者模式也不是传送门。
		if map_room.room and map_room.room.selected:
			continue

		map_room.available = true


## 设置界面里刚把开关打开时也要立刻生效，所以顺手再刷一次。
func _on_developer_mode_changed(enabled: bool) -> void:
	if enabled:
		_apply_developer_unlock()
