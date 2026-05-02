extends Control

@onready var _row_label: RichTextLabel = $Row1

var char_buff: CharBuffer

signal character_typed(correct: bool)


class CharBuffer:
	var _text: String = ""
	var _word_pool_ref: Object  # reference to WordPool autoload

	func _init(pool: Object) -> void:
		_word_pool_ref = pool
		while _text.length() < 120:
			_refill()

	func current_char() -> String:
		if _text.is_empty():
			return ""
		return _text[0]

	func advance() -> bool:
		if _text.is_empty():
			return false
		_text = _text.substr(1)
		if _text.length() < 120:
			_refill()
		return true

	func _refill() -> void:
		var word: String = _word_pool_ref.next_word()
		if _text.length() > 0:
			_text += " " + word
		else:
			_text = word

	func visible_text(max_chars: int) -> String:
		return _text.substr(0, min(max_chars, _text.length()))


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if key.echo or not key.pressed:
		return

	if key.unicode == 0:
		return
	var ch := char(key.unicode)

	var expected: String = char_buff.current_char()
	char_buff.advance()
	_render()
	if ch == expected:
		character_typed.emit(true)
	else:
		character_typed.emit(false)


func _ready():
	char_buff = CharBuffer.new(WordPool)
	_render()


func _render() -> void:
	_render_row(_row_label, char_buff)


func _render_row(label: RichTextLabel, buf: CharBuffer) -> void:
	var text := buf.visible_text(60)
	if text.is_empty():
		label.text = ""
		return

	var current := text[0]
	var rest := text.substr(1)
	if current == " ":
		label.text = "[bgcolor=#00ffff80] [/bgcolor]%s" % rest
	else:
		label.text = "[color=cyan]%s[/color]%s" % [current, rest]
