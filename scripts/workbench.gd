extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("set_near_workbench"):
		body.set_near_workbench(true)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("set_near_workbench"):
		body.set_near_workbench(false)
