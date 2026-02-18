extends Control

@export var player_path: NodePath = ^"../../Player"
@export var main_path: NodePath = ^"../.."

@onready var player: CharacterBody3D = get_node_or_null(player_path)
@onready var main_node: Node = get_node_or_null(main_path)
@onready var health_bar: ProgressBar = $PanelContainer/MarginContainer/VBoxContainer/HealthBar
@onready var stamina_bar: ProgressBar = $PanelContainer/MarginContainer/VBoxContainer/StaminaBar
@onready var xp_bar: ProgressBar = $PanelContainer/MarginContainer/VBoxContainer/XPBar
@onready var level_label: Label = $PanelContainer/MarginContainer/VBoxContainer/LevelLabel
@onready var world_state_label: Label = $PanelContainer/MarginContainer/VBoxContainer/WorldStateLabel
@onready var medkit_label: Label = $PanelContainer/MarginContainer/VBoxContainer/MedkitLabel
@onready var scrap_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ScrapLabel
@onready var status_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var hint_label: Label = $Hint

func _ready() -> void:
	if player and player.has_signal("stats_changed"):
		player.stats_changed.connect(_on_player_stats_changed)
	if player and player.has_method("get_stats"):
		_on_player_stats_changed(player.get_stats())

	if main_node and main_node.has_signal("world_state_changed"):
		main_node.world_state_changed.connect(_on_world_state_changed)

	hint_label.text = "3rd person: мышь — камера | WASD — движение | Shift — бег | ЛКМ — удар | F — аптечка | E — крафт у верстака"

func _on_player_stats_changed(data: Dictionary) -> void:
	health_bar.max_value = data.max_health
	health_bar.value = data.health
	health_bar.get_node("ValueLabel").text = "HP: %d / %d" % [data.health, data.max_health]

	stamina_bar.max_value = data.max_stamina
	stamina_bar.value = data.stamina
	stamina_bar.get_node("ValueLabel").text = "Stamina: %d / %d" % [int(data.stamina), int(data.max_stamina)]

	xp_bar.max_value = data.xp_to_next
	xp_bar.value = data.xp
	xp_bar.get_node("ValueLabel").text = "XP: %d / %d" % [data.xp, data.xp_to_next]

	level_label.text = "Level %d" % data.level
	medkit_label.text = "Medkits: %d" % data.medkits
	scrap_label.text = "Scrap: %d" % data.scrap

	if data.status_text != "":
		status_label.text = data.status_text
	else:
		status_label.text = "Статус: в бою"

func _on_world_state_changed(phase: String, max_alive: int, threat: float) -> void:
	world_state_label.text = "%s | Max zombies: %d | Threat: %.1f" % [phase, max_alive, threat]
