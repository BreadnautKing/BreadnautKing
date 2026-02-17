extends CharacterBody3D

@export var walk_speed: float = 5.5
@export var sprint_speed: float = 8.0
@export var acceleration: float = 10.0
@export var jump_velocity: float = 5.0
@export var gravity_scale: float = 1.0
@export var max_health: int = 100
@export var strength: int = 10
@export var attack_cooldown: float = 0.5
@export var base_attack_damage: int = 18

var health: int
var _can_attack: bool = true
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_pivot: Node3D = $CameraPivot
@onready var attack_area: Area3D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	health = max_health
	attack_area.monitoring = false
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.003)
		camera_pivot.rotate_x(-event.relative.y * 0.003)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-55), deg_to_rad(65))

	if event.is_action_pressed("attack"):
		_attack()

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * gravity_scale * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var horizontal_velocity := velocity
	horizontal_velocity.y = 0.0

	if direction != Vector3.ZERO:
		horizontal_velocity = horizontal_velocity.lerp(direction * target_speed, acceleration * delta)
	else:
		horizontal_velocity = horizontal_velocity.lerp(Vector3.ZERO, acceleration * delta)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	move_and_slide()

func get_attack_damage() -> int:
	return base_attack_damage + strength

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	if health <= 0:
		queue_free()

func _attack() -> void:
	if not _can_attack:
		return

	_can_attack = false
	attack_area.monitoring = true

	for body in attack_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(get_attack_damage())

	attack_area.monitoring = false
	attack_timer.start()

func _on_attack_timer_timeout() -> void:
	_can_attack = true
