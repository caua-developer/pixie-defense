extends Node2D

const SaveManagerScript = preload("res://scripts/save_manager.gd")

@onready var base: Node = $Base
@onready var mago: Node2D = $Mago
@onready var mana_label: Label = $HUD/Root/VBox/ManaLabel
@onready var base_life_label: Label = $HUD/Root/VBox/BaseLifeLabel
@onready var game_over_label: Label = $HUD/Root/VBox/GameOverLabel
@onready var essence_tracker: Node = $EssenceTracker
@onready var essence_label: Label = $HUD/Root/VBox/EssenceLabel
@onready var skill_tree_button: Button = $HUD/Root/VBox/SkillTreeButton
@onready var skill_tree_panel: PanelContainer = $HUD/SkillTreePanel
@onready var specialization_panel: PanelContainer = $HUD/SpecializationSelectPanel

var save_manager: RefCounted

func _ready() -> void:
	save_manager = SaveManagerScript.new()
	var existing_specialization: String = save_manager.load_specialization()
	if existing_specialization != "":
		mago.specialization = existing_specialization
	else:
		specialization_panel.open(_on_specialization_chosen)
	game_over_label.visible = false
	base.base_defeated.connect(_on_base_defeated)
	skill_tree_button.pressed.connect(skill_tree_panel.open)

func _process(_delta: float) -> void:
	mana_label.text = "Mana: %d/%d" % [int(mago.mana), int(mago.MAX_MANA)]
	base_life_label.text = "Vida da Base: %d/%d" % [int(base.current_life), int(base.MAX_LIFE)]
	essence_label.text = "Essência: %d (Fragmentos: %d/10)" % [essence_tracker.essence, essence_tracker.fragments]

func _on_base_defeated() -> void:
	base_life_label.text = "Vida da Base: %d/%d" % [int(base.current_life), int(base.MAX_LIFE)]
	game_over_label.visible = true
	get_tree().paused = true

func _on_specialization_chosen(tree_name: String) -> void:
	mago.specialization = tree_name
	save_manager.save_specialization(tree_name)
