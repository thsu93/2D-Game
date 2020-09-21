extends Control

onready var name_label = $DialogueBox/SpeakerName
onready var dialogue_label = $DialogueBox/Dialogue
onready var dialogue_player = $DialoguePlayer

signal dialogue_complete()

func start(dialogue):
	dialogue_player.start(dialogue)
	update_content()
	
func next():
	dialogue_player.next()
	update_content()
	
func _on_DialoguePlayer_dialogue_complete():
	emit_signal("dialogue_complete")
	
func update_content():
	name_label.text = dialogue_player.speaker_name
	dialogue_label.text = dialogue_player.current_dialogue
#	Speaker portrait 

func _on_Button_button_up():
	next()
	pass # Replace with function body.
