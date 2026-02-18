extends Node3D

signal world_state_changed(phase: String, max_alive: int, threat: float)

@export var zombie_scenes: Array[PackedScene]
@export var player_path: NodePath = ^"Player"
@export var zombies_root_path: NodePath = ^"Zombies"
@export var poi_root_path: NodePath = ^"POI"
@export var base_max_zombies: int = 10
@export var spawn_interval_day: float = 2.4
@export var spawn_interval_night: float = 1.6
@export var day_duration_seconds: float = 600.0
@export var night_duration_seconds: float = 300.0
@export var min_spawn_distance: float = 25.0
@export var max_spawn_distance: float = 65.0

var is_night: bool = false
var threat_level: float = 0.0
var _poi_nodes: Array[Node3D] = []

@onready var spawn_timer: Timer = $SpawnTimer
@onready var day_night_timer: Timer = $DayNightTimer
@onready var player: CharacterBody3D = get_node(player_path)
@onready var zombies_root: Node3D = get_node(zombies_root_path)
@onready var poi_root: Node3D = get_node(poi_root_path)

func _ready() -> void:
	_cache_poi_nodes()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	day_night_timer.timeout.connect(_on_day_night_timer_timeout)
	_apply_phase_settings()
	spawn_timer.start()
	day_night_timer.start()
	_emit_world_state_changed()

func _cache_poi_nodes() -> void:
	_poi_nodes.clear()
	for child in poi_root.get_children():
		if child is Node3D:
			_poi_nodes.append(child)

func _update_threat_level() -> void:
	var level_factor := 0.0
	if player and player.has_method("get_stats"):
		var stats: Dictionary = player.get_stats()
		level_factor = float(stats.get("level", 1))
	var day_night_bonus := 1.5 if is_night else 1.0
	threat_level = clamp((level_factor * 0.12) * day_night_bonus, 0.0, 5.0)

func _get_current_max_zombies() -> int:
	_update_threat_level()
	return base_max_zombies + int(round(threat_level * 3.0))

func _get_spawn_batch_size() -> int:
	var base_batch := 1 if not is_night else 2
	return min(base_batch + int(threat_level / 2.0), 4)

func _apply_phase_settings() -> void:
	spawn_timer.wait_time = spawn_interval_night if is_night else spawn_interval_day
	day_night_timer.wait_time = night_duration_seconds if is_night else day_duration_seconds

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
	if zombie_scenes.size() >= 2 and (is_night or threat_level >= 2.2) and randf() < 0.35:
		idx = 1
	if zombie_scenes.size() >= 3 and (is_night and threat_level >= 2.8) and randf() < 0.2:
		idx = 2
	return zombie_scenes[idx]

func _pick_spawn_position() -> Vector3:
	var use_poi := _poi_nodes.size() > 0 and randf() < 0.7
	if use_poi:
		var poi := _poi_nodes[randi_range(0, _poi_nodes.size() - 1)]
		var jitter := Vector3(randf_range(-14.0, 14.0), 0.0, randf_range(-14.0, 14.0))
		return poi.global_position + jitter

	var angle := randf_range(0.0, TAU)
	var distance := randf_range(min_spawn_distance, max_spawn_distance)
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * distance
	return player.global_position + offset

func _on_day_night_timer_timeout() -> void:
	is_night = not is_night
	_apply_phase_settings()
	spawn_timer.start()
	day_night_timer.start()
	_emit_world_state_changed()

func _emit_world_state_changed() -> void:
	var phase := "Night" if is_night else "Day"
	world_state_changed.emit(phase, _get_current_max_zombies(), threat_level)
