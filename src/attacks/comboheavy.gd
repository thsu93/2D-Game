extends AttackData

func _init():
	cost = 15
	dmg = 5
	movename = "Combo (Heavy)"
	knockback_val = 60
	hitspark = "slash"
	knockback_dir = Vector2(0,-1) #KNOCKBACK AWAY + LAUNCH
	velocity = 350
	direction = Vector2(.75,0)
	anim_time = .2
	running_type = false
	pass # Replace with function body.