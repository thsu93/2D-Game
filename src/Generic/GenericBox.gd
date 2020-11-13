class_name GenericBox
extends Area2D


export(String) var actor_type = null
onready var shape = $CollisionShape2D
var active = true

func enable():
	# shape.disabled = false
	active = true


func disable():
	# shape.disabled = true
	active = false

#sets the actor_type to be the name of the class of actor it belongs to  
func set_actor_type(_actor_type : String):
	actor_type = _actor_type