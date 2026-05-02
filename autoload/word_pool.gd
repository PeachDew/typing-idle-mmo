extends Node

var _words: Array
var _index: int = 0
var english_json_path: String = "res://resources/languages/english.json"

func _ready() -> void:
	_load_words()
	for i in range(5):
		print(_words[i])

func _load_words() -> void:
	var file := FileAccess.open(english_json_path, FileAccess.READ)
	if not file:
		push_error("WordPool: failed to open path {english_json_path}")
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	_words = data["words"]
	_words.shuffle()
	_index = 0

func next_word() -> String:
	if _index >= _words.size():
		_words.shuffle()
		_index = 0
	var word: String = _words[_index]
	_index += 1
	return word
