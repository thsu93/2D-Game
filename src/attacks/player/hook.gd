extends AttackData


# Called when the node enters the scene tree for the first time.
func _init():
	cost = 0
	dmg = 15
	movename = "Hook"
	running_type = true
	knockback_val = 300

	ground_type = true #can occur when standing on ground
	air_type = true #can occur when in the air
	crouch_type = true #can occur while crouching
	running_type = false #can occur while running (ie does not stop momentum)
	dashing_type = true #can occur while dashing (ie does not cancel dash)
	
	stagger = true


	pass # Replace with function body.