extends AttackData

func _init():
	dmg = 45
	movename = "Shoryuken"
	knockback_val = 500
	knockback_dir = Vector2(1,-1) #KNOCKBACK AWAY + LAUNCH
	velocity = 250
	direction = Vector2(.5,-1)
	anim_time = .5
	running_type = true
	pass # Replace with function body.