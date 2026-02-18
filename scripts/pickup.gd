extends Area3D

@export var item_id: String = "medkit"
@export var amount: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("add_item"):
		body.add_item(item_id, amount)
	queue_free()
