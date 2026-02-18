extends CharacterBody3D

@export var move_speed: float = 2.8
@export var max_health: int = 55
@export var contact_damage: int = 8
@export var attack_interval: float = 1.1
@export var xp_reward: int = 30

var health: int
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _target: CharacterBody3D

@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	health = max_health
	attack_timer.wait_time = attack_interval
	_target = get_tree().get_first_node_in_group("player") as CharacterBody3D

func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as CharacterBody3D
		return

	var direction := (_target.global_position - global_position)
	direction.y = 0

	if direction.length() > 1.3:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = 0
		velocity.z = 0
		_try_attack()

	if not is_on_floor():
		velocity.y -= _gravity * delta

	move_and_slide()

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	if health <= 0:
		if _target and _target.has_method("add_experience"):
			_target.add_experience(xp_reward)
		queue_free()

func _try_attack() -> void:
	if attack_timer.time_left > 0:
		return
	if _target and _target.has_method("take_damage"):
		_target.take_damage(contact_damage)
	attack_timer.start()
