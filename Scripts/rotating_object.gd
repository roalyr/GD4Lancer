extends Node3D

@export var rotation_speed = 0.1

func _physics_process(delta: float) -> void:
	self.rotate(Vector3(0.0, 1.0, 0.0), delta * rotation_speed)
