extends AttackData

func _init():
	cost = 15
	dmg = 5
	movename = "Combo (Heavy)"
	knockback_val = 250
	hitspark = "slash"
	knockback_dir = Vector2(1,-.2) #KNOCKBACK AWAY + LAUNCH

	running_type = false
	stagger = true

	screenshake_duration = .1
	screenshake_amp = 5

	hitstun = .75


	pass # Replace with function body.