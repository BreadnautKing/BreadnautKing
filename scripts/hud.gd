extends Control

@export var player_path: NodePath = ^"../../Player"

@onready var player: CharacterBody3D = get_node_or_null(player_path)
@onready var health_bar: ProgressBar = $PanelContainer/MarginContainer/VBoxContainer/HealthBar
@onready var stamina_bar: ProgressBar = $PanelContainer/MarginContainer/VBoxContainer/StaminaBar
@onready var xp_bar: ProgressBar = $PanelContainer/MarginContainer/VBoxContainer/XPBar
@onready var level_label: Label = $PanelContainer/MarginContainer/VBoxContainer/LevelLabel
@onready var hint_label: Label = $Hint

func _ready() -> void:
	if player == null:
		return
	if player.has_signal("stats_changed"):
		player.stats_changed.connect(_on_player_stats_changed)
	if player.has_method("get_stats"):
		_on_player_stats_changed(player.get_stats())

	hint_label.text = "WASD — движение | Shift — бег (тратит стамину) | Space — прыжок | ЛКМ — удар (тратит стамину)"

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
