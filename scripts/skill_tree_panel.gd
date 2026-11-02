extends PanelContainer

const NODE_COUNT: int = 4
const NODE_NAMES: Array[String] = ["Dano+", "Cooldown-", "Custo de Mana-", "Raio+"]
const NODE_COSTS: Array[int] = [1, 2, 3, 4]

var purchased: Array[bool] = [false, false, false, false]

@onready var mago: Node2D = get_tree().get_first_node_in_group("mago")
@onready var essence_tracker: Node = get_tree().get_first_node_in_group("essencia")
@onready var node_labels: Array[Label] = [
	$VBox/Node1Row/Node1Label, $VBox/Node2Row/Node2Label,
	$VBox/Node3Row/Node3Label, $VBox/Node4Row/Node4Label,
]
@onready var node_buttons: Array[Button] = [
	$VBox/Node1Row/Node1Button, $VBox/Node2Row/Node2Button,
	$VBox/Node3Row/Node3Button, $VBox/Node4Row/Node4Button,
]
@onready var close_button: Button = $VBox/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	for i in NODE_COUNT:
		node_buttons[i].pressed.connect(_on_node_pressed.bind(i))
	close_button.pressed.connect(close)
	_update_labels()

func open() -> void:
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _on_node_pressed(index: int) -> void:
	if purchased[index] or essence_tracker.essence < NODE_COSTS[index]:
		return
	essence_tracker.essence -= NODE_COSTS[index]
	purchased[index] = true
	match index:
		0: mago.upgrade_damage()
		1: mago.reduce_cooldown()
		2: mago.reduce_mana_cost()
		3: mago.increase_radius()
	_update_labels()

func _update_labels() -> void:
	for i in NODE_COUNT:
		var status: String = "comprado" if purchased[i] else "%d essência(s)" % NODE_COSTS[i]
		node_labels[i].text = "%s — %s" % [NODE_NAMES[i], status]
		node_buttons[i].disabled = purchased[i]
