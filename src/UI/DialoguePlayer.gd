extends Node
class_name DialogueAction

signal dialogue_complete

var speaker_name = ""
var current_dialogue = ""
var full_dialogue = []
var position = 0

func start(dialogue_path):
	index_dialogue(dialogue_path)
	position = 0
	update_text()
	
func load_dialogue(file_path):
	var file = File.new()
	assert (file.file_exists(file_path))

	file.open(file_path, file.READ)
	var dialogue = parse_json(file.get_as_text())
	assert (dialogue.size() > 0)
	return dialogue

func next():
	position += 1
	if position >= full_dialogue.size():
		emit_signal("dialogue_complete")
		return
	update_text()

func update_text():
	speaker_name = full_dialogue[position].name
	current_dialogue=full_dialogue[position].text
	print(current_dialogue)

func index_dialogue(dialogue_path):
	var dialogue = load_dialogue(dialogue_path)
	full_dialogue.clear()
	for key in dialogue:
		full_dialogue.append(dialogue[key])
