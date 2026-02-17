extends CharacterBody3D

signal stats_changed(data: Dictionary)

@export var walk_speed: float = 5.5
@export var sprint_speed: float = 8.0
@export var acceleration: float = 10.0
@export var jump_velocity: float = 5.0
@export var gravity_scale: float = 1.0
@export var max_health: int = 100
@export var strength: int = 10
@export var attack_cooldown: float = 0.5
@export var base_attack_damage: int = 18
@export var max_stamina: float = 100.0
@export var stamina_regen_per_sec: float = 20.0
@export var sprint_stamina_cost_per_sec: float = 18.0
@export var attack_stamina_cost: float = 22.0
@export var medkit_heal_amount: int = 45

var health: int
var stamina: float
var level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 100
var medkits: int = 1
var scrap: int = 0

var _can_attack: bool = true
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_pivot: Node3D = $CameraPivot
@onready var attack_area: Area3D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	health = max_health
	stamina = max_stamina
	attack_area.monitoring = false
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_emit_stats_changed()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.003)
		camera_pivot.rotate_x(-event.relative.y * 0.003)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-55), deg_to_rad(65))

	if event.is_action_pressed("attack"):
		_attack()

	if event.is_action_pressed("heal_item"):
		use_medkit()

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * gravity_scale * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var wants_sprint := Input.is_action_pressed("sprint") and direction != Vector3.ZERO
	var can_sprint := wants_sprint and stamina > 0.0
	var target_speed := sprint_speed if can_sprint else walk_speed

	if can_sprint:
		stamina = max(stamina - sprint_stamina_cost_per_sec * delta, 0.0)
	else:
		stamina = min(stamina + stamina_regen_per_sec * delta, max_stamina)

	var horizontal_velocity := velocity
	horizontal_velocity.y = 0.0

	if direction != Vector3.ZERO:
		horizontal_velocity = horizontal_velocity.lerp(direction * target_speed, acceleration * delta)
	else:
		horizontal_velocity = horizontal_velocity.lerp(Vector3.ZERO, acceleration * delta)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	move_and_slide()
	_emit_stats_changed()

func get_attack_damage() -> int:
	return base_attack_damage + strength

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	_emit_stats_changed()
	if health <= 0:
		queue_free()

func add_experience(amount: int) -> void:
	if amount <= 0:
		return

	current_xp += amount
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		level += 1
		strength += 1
		max_health += 8
		health = max_health
		xp_to_next_level = int(round(float(xp_to_next_level) * 1.35))

	_emit_stats_changed()

func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return

	match item_id:
		"medkit":
			medkits += amount
		"scrap":
			scrap += amount
	_emit_stats_changed()

func use_medkit() -> void:
	if medkits <= 0 or health >= max_health:
		return

	medkits -= 1
	health = min(health + medkit_heal_amount, max_health)
	_emit_stats_changed()

func _attack() -> void:
	if not _can_attack or stamina < attack_stamina_cost:
		return

	stamina = max(stamina - attack_stamina_cost, 0.0)
	_can_attack = false
	attack_area.monitoring = true

	for body in attack_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(get_attack_damage())

	attack_area.monitoring = false
	attack_timer.start()
	_emit_stats_changed()

func get_stats() -> Dictionary:
	return {
		"health": health,
		"max_health": max_health,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"level": level,
		"xp": current_xp,
		"xp_to_next": xp_to_next_level,
		"medkits": medkits,
		"scrap": scrap
	}

func _emit_stats_changed() -> void:
	stats_changed.emit(get_stats())

func _on_attack_timer_timeout() -> void:
	_can_attack = true
