extends Node3D

signal wave_changed(current_wave: int, max_alive: int)

@export var zombie_scenes: Array[PackedScene]
@export var player_path: NodePath = ^"Player"
@export var zombies_root_path: NodePath = ^"Zombies"
@export var poi_root_path: NodePath = ^"POI"
@export var base_max_zombies: int = 12
@export var max_zombies_per_wave_step: int = 4
@export var spawn_interval: float = 1.75
@export var wave_duration: float = 45.0
@export var min_spawn_distance: float = 25.0
@export var max_spawn_distance: float = 65.0

var current_wave: int = 1
var _poi_nodes: Array[Node3D] = []

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer = $WaveTimer
@onready var player: CharacterBody3D = get_node(player_path)
@onready var zombies_root: Node3D = get_node(zombies_root_path)
@onready var poi_root: Node3D = get_node(poi_root_path)

func _ready() -> void:
	_cache_poi_nodes()
	spawn_timer.wait_time = spawn_interval
	wave_timer.wait_time = wave_duration
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	spawn_timer.start()
	wave_timer.start()
	_emit_wave_changed()

func _cache_poi_nodes() -> void:
	_poi_nodes.clear()
	for child in poi_root.get_children():
		if child is Node3D:
			_poi_nodes.append(child)

func _get_current_max_zombies() -> int:
	return base_max_zombies + (current_wave - 1) * max_zombies_per_wave_step

func _get_spawn_batch_size() -> int:
	return min(1 + int((current_wave - 1) / 2), 4)

func _on_spawn_timer_timeout() -> void:
	if zombie_scenes.is_empty():
		return

	var max_alive := _get_current_max_zombies()
	if zombies_root.get_child_count() >= max_alive:
		return

	var batch := _get_spawn_batch_size()
	for _index in range(batch):
		if zombies_root.get_child_count() >= max_alive:
			break
		_spawn_single_zombie()

func _spawn_single_zombie() -> void:
	var spawn_pos := _pick_spawn_position()
	var zombie_scene := _pick_zombie_scene()
	var zombie := zombie_scene.instantiate() as CharacterBody3D
	zombie.global_position = spawn_pos
	zombies_root.add_child(zombie)

func _pick_zombie_scene() -> PackedScene:
	var idx := 0
	if current_wave >= 3 and zombie_scenes.size() >= 2 and randf() < 0.35:
		idx = 1
	if current_wave >= 5 and zombie_scenes.size() >= 3 and randf() < 0.2:
		idx = 2
	return zombie_scenes[idx]

func _pick_spawn_position() -> Vector3:
	var use_poi := _poi_nodes.size() > 0 and randf() < 0.65
	if use_poi:
		var poi := _poi_nodes[randi_range(0, _poi_nodes.size() - 1)]
		var jitter := Vector3(randf_range(-14.0, 14.0), 0.0, randf_range(-14.0, 14.0))
		return poi.global_position + jitter

	var angle := randf_range(0.0, TAU)
	var distance := randf_range(min_spawn_distance, max_spawn_distance)
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * distance
	return player.global_position + offset

func _on_wave_timer_timeout() -> void:
	current_wave += 1
	_emit_wave_changed()

func _emit_wave_changed() -> void:
	wave_changed.emit(current_wave, _get_current_max_zombies())
