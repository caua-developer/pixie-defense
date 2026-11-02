extends PanelContainer

@onready var destrutiva_button: Button = $VBox/DestrutivaButton
@onready var defensiva_button: Button = $VBox/DefensivaButton
@onready var maldicao_button: Button = $VBox/MaldicaoButton
@onready var selection_label: Label = $VBox/SelectionLabel
@onready var confirm_button: Button = $VBox/ConfirmButton

var _selected: String = ""
var _on_chosen: Callable

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	confirm_button.disabled = true
	destrutiva_button.pressed.connect(_select.bind("Destrutiva"))
	defensiva_button.pressed.connect(_select.bind("Defensiva"))
	maldicao_button.pressed.connect(_select.bind("Maldição"))
	confirm_button.pressed.connect(_confirm)

func open(on_chosen: Callable) -> void:
	_on_chosen = on_chosen
	visible = true
	get_tree().paused = true

func _select(tree_name: String) -> void:
	_selected = tree_name
	selection_label.text = "Selecionado: %s" % tree_name
	confirm_button.disabled = false

func _confirm() -> void:
	visible = false
	get_tree().paused = false
	_on_chosen.call(_selected)
