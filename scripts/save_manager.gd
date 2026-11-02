extends RefCounted

const SAVE_PATH: String = "user://save.json"
const SAVE_VERSION: int = 1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_specialization() -> String:
	if not has_save():
		return ""
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null or not data.has("specialization_tree"):
		return ""
	return data["specialization_tree"]

func save_specialization(tree_name: String) -> void:
	var data: Dictionary = {"version": SAVE_VERSION, "specialization_tree": tree_name}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
