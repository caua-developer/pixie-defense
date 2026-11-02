extends Node2D

@onready var base: Node = $Base
@onready var mago: Node2D = $Mago
@onready var mana_label: Label = $HUD/Root/VBox/ManaLabel
@onready var base_life_label: Label = $HUD/Root/VBox/BaseLifeLabel
@onready var game_over_label: Label = $HUD/Root/VBox/GameOverLabel

func _ready() -> void:
	game_over_label.visible = false
	base.base_defeated.connect(_on_base_defeated)

func _process(_delta: float) -> void:
	mana_label.text = "Mana: %d/%d" % [int(mago.mana), int(mago.MAX_MANA)]
	base_life_label.text = "Vida da Base: %d/%d" % [int(base.current_life), int(base.MAX_LIFE)]

func _on_base_defeated() -> void:
	base_life_label.text = "Vida da Base: %d/%d" % [int(base.current_life), int(base.MAX_LIFE)]
	game_over_label.visible = true
	get_tree().paused = true
