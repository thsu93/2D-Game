extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func shoot(bullet, target, position):
	var dir = (target-position).normalized()
	bullet.set_dir(dir)
	bullet.position = position
	return bullet
