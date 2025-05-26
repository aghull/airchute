extends Area2D

var direction = Vector2(0,0)

func _process(delta: float) -> void:
	self.position += direction * delta * 60
