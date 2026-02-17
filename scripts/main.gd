extends Node3D

@export var zombie_scene: PackedScene
@export var player_path: NodePath = ^"Player"
@export var zombies_root_path: NodePath = ^"Zombies"
@export var poi_root_path: NodePath = ^"POI"
@export var max_zombies: int = 24
@export var spawn_interval: float = 1.75
@export var min_spawn_distance: float = 25.0
@export var max_spawn_distance: float = 65.0

var _poi_nodes: Array[Node3D] = []

@onready var spawn_timer: Timer = $SpawnTimer
@onready var player: CharacterBody3D = get_node(player_path)
@onready var zombies_root: Node3D = get_node(zombies_root_path)
@onready var poi_root: Node3D = get_node(poi_root_path)

func _ready() -> void:
	_cache_poi_nodes()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _cache_poi_nodes() -> void:
	_poi_nodes.clear()
	for child in poi_root.get_children():
		if child is Node3D:
			_poi_nodes.append(child)

func _on_spawn_timer_timeout() -> void:
	if zombies_root.get_child_count() >= max_zombies:
		return

	var spawn_pos := _pick_spawn_position()
	var zombie := zombie_scene.instantiate() as CharacterBody3D
	zombie.global_position = spawn_pos
	zombies_root.add_child(zombie)

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
