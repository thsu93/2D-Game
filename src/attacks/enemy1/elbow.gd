extends AttackData

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# Called when the node enters the scene tree for the first time.
func _init():
	dmg = 50
	movename = "Elbow"
	knockback_val = 150
	damage_scaling = .3
	hitstun = .3

	screenshake_duration = .1
	screenshake_amp = 10

	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
