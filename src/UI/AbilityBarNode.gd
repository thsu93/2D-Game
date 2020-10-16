extends TextureProgress
class_name AbilityBarNode

# # Declare member variables here. Examples:
# # var a = 2
# # var b = "text"
# var nodeInfo
# var active = true
# var on_cooldown = false
# var selectable = true

# # Called when the node enters the scene tree for the first time.
# func _ready():
# 	pass

# func set_ability(newNode):
# 	nodeInfo = newNode
# 	tint_progress = nodeInfo.moveColor
# 	set_unselected()
# 	self.value = 100
# 	$Label.visible = false


# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(_delta):

# 	selectable = nodeInfo.selectable

# 	if nodeInfo.on_cooldown:
# 		$Label.visible = true
# 		value = (1 - nodeInfo.current_cd_time/nodeInfo.max_cd_time) * 100
# 		$Label.text =("%.2f" % nodeInfo.current_cd_time)
			
# 		#Probably save value up to step, subtract step from value, add step.
# 		#currently just have step set to ~delta value, but probably poor workaround

# 	else:
# 		value = 100
# 		$Label.visible = false

func set_selected():
	tint_over = Color( 1, 1, 1, .8)

func set_unselected():
	tint_over = Color( 1, 1, 1, 0)

# func get_instance():
# 	return nodeInfo.return_instance()














# ##TODO: Determine if needed? Can have a full break mechanic
# #func break_node():
# #	active = false
# #	tint_progress = Color.black
# #	set_unselected()
