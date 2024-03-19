@icon("res://Assets/Images/Icons/object_zone.svg")
extends Area3D
class_name ObjectZone

@export var env_exposure_variation = 0.0

var parent_name = ""

# TODO: add string name, music, etc.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent_name = get_parent().name


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
