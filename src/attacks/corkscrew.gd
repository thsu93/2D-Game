extends AttackData

func _init():
	dmg = 45
	movename = "Corkscrew"
	knockback_val = 600
	knockback_dir = Vector2(0,-1) #KNOCKBACK AWAY + LAUNCH
	velocity = 350
	direction = Vector2(.5,0)
	anim_time = .2
	running_type = false
	pass # Replace with function body.