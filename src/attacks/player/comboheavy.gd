extends AttackData

func _init():
	cost = 15
	dmg = 5
	movename = "Combo (Heavy)"
	knockback_val = 250
	hitspark = "slash"
	knockback_dir = Vector2(1,0) #KNOCKBACK AWAY + LAUNCH
	velocity = 350
	direction = Vector2(.75,0)
	anim_time = .2
	running_type = false
	stagger = true
	pass # Replace with function body.