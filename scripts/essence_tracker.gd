extends Node

const FRAGMENTS_PER_ESSENCE: int = 10

var fragments: int = 0
var essence: int = 0

func _ready() -> void:
	add_to_group("essencia")

func add_fragments(amount: int) -> void:
	fragments += amount
	while fragments >= FRAGMENTS_PER_ESSENCE:
		fragments -= FRAGMENTS_PER_ESSENCE
		essence += 1
