extends AttackData

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# Called when the node enters the scene tree for the first time.
func _init():
	dmg = 5
	movename = "Jab"
	knockback_val = 75
	damage_scaling = .1
	hitstun = .5
	slow_time = 0.1
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass