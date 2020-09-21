extends Control

signal update_abilities(abilities)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	emit_signal("update_abilities" , $Abilities/CharacterPanel.abilities)
	get_tree().paused = false
	self.visible = false
