@icon("res://Assets/Images/Icons/star.svg")
extends Node3D
class_name Star

@export var autopilot_range = 1e10
@export var targetable = true
@export var translations_name = ""
@export var translations_description = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
