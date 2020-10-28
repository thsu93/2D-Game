extends AttackData

func _init():
	dmg = 15
	cost = 15
	movename = "Corkscrew"
	knockback_val = 400
	knockback_dir = Vector2(1,0) #KNOCKBACK AWAY + LAUNCH

	running_type = false
	stagger = true

	screenshake_duration = .2
	screenshake_amp = 10

	pass # Replace with function body.
