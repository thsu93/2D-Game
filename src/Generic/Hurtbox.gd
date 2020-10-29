class_name Hurtbox
extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export(String) var actor_type = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_actor_type(actor_name):
	actor_type = actor_name

func get_class():
	return "Hurtbox"

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
