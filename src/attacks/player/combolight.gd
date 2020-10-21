extends AttackData

func _init():
	dmg = 5
	movename = "Combo (Light)"
	
	knockback_val = 60
	knockback_dir = Vector2(1,-.2) #KNOCKBACK AWAY + LAUNCH
	running_type = false

	screenshake_duration = .05
	screenshake_amp = 3

	hitstun = .75

	pass # Replace with function body.