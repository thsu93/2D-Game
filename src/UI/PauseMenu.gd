extends Control

signal update_abilities(abilities)
signal unpause()

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var abilities_panel = $Panel/AbilitiesPanel
onready var pause_button = $Panel/PauseUnpause
onready var reset_button = $Panel/Reset

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_movelist(movelist):
	abilities_panel.populate(movelist)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_PauseUnpause_pressed():
	# emit_signal("update_abilities" , $Abilities/CharacterPanel.abilities)
	emit_signal("update_abilities", abilities_panel.get_updated_list())
	emit_signal("unpause")

func _on_Reset_pressed():
	get_tree().reload_current_scene()
	emit_signal("unpause")

func _on_AbilitiesPanel_holding(held):
	pause_button.disabled = held
	reset_button.disabled = held
