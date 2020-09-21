class_name Actor
extends KinematicBody2D

# Both the Player and Enemy inherit this scene as they have shared behaviours
# such as speed and are affected by gravity.

var actor_type = "unknown"

export var speed = Vector2(150.0, 450.0)
export var no_grav = false
onready var gravity = ProjectSettings.get("physics/2d/default_gravity")

const FLOOR_NORMAL = Vector2.UP

var _velocity = Vector2.ZERO

# _physics_process is called after the inherited _physics_process function.
# This allows the Player and Enemy scenes to be affected by gravity.
func _physics_process(delta):
	if no_grav:
		#HACK probably not the best way to handle this
		_velocity.y = 0
	else:
		_velocity.y += gravity * delta
