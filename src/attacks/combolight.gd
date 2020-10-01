extends AttackData

func _init():
	dmg = 5
	movename = "Combo (Light)"
	knockback_val = 60
	knockback_dir = Vector2(0,-1) #KNOCKBACK AWAY + LAUNCH
	velocity = 350
	direction = Vector2(.5,0)
	anim_time = .2
	running_type = false
	pass # Replace with function body.