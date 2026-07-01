extends SceneTree

const ASSET_ROOT := "res://assets/pets/cat_orange_v1"
const FRAME_ROOT := ASSET_ROOT + "/frames"
const SPRITE_FRAMES_PATH := "res://assets/pets/cat_orange_v1/cat_orange_v1_sprite_frames.tres"
const PET_RESOURCE_PATH := "res://assets/pets/cat_orange_v1/cat_orange_v1_resource.tres"

const ANIMATIONS := [
	{"name": "idle", "frames": 4, "speed": 2.0, "loop": 1},
	{"name": "working", "frames": 4, "speed": 5.0, "loop": 1},
	{"name": "resting", "frames": 2, "speed": 0.67, "loop": 1},
	{"name": "idle_clicked_single", "frames": 3, "speed": 5.0, "loop": 0},
	{"name": "idle_clicked_double", "frames": 3, "speed": 3.75, "loop": 0},
	{"name": "working_clicked_single", "frames": 3, "speed": 5.0, "loop": 0},
	{"name": "working_clicked_double", "frames": 3, "speed": 3.75, "loop": 0},
	{"name": "resting_clicked_single", "frames": 3, "speed": 5.0, "loop": 0},
	{"name": "resting_clicked_double", "frames": 3, "speed": 3.75, "loop": 0},
	{"name": "clicked_hold", "frames": 2, "speed": 1.0, "loop": 1},
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var sprite_text := _build_sprite_frames_text()
	var pet_text := _build_pet_resource_text()
	if not _write_text(SPRITE_FRAMES_PATH, sprite_text):
		quit(1)
		return
	if not _write_text(PET_RESOURCE_PATH, pet_text):
		quit(1)
		return
	print("Built cat orange asset resources.")
	quit(0)


func _build_sprite_frames_text() -> String:
	var ids := {}
	var lines: Array[String] = ["[gd_resource type=\"SpriteFrames\" load_steps=31 format=3]", ""]
	var id_index := 1
	for spec in ANIMATIONS:
		var anim_name := String(spec["name"])
		for index in range(1, int(spec["frames"]) + 1):
			var id := "tex_%02d" % id_index
			var path := "%s/%s/%s_%02d.png" % [FRAME_ROOT, anim_name, anim_name, index]
			lines.append("[ext_resource type=\"Texture2D\" path=\"%s\" id=\"%s\"]" % [path, id])
			ids["%s:%d" % [anim_name, index]] = id
			id_index += 1

	lines.append("")
	lines.append("[resource]")
	lines.append("animations = [")
	for anim_index in range(ANIMATIONS.size()):
		var spec: Dictionary = ANIMATIONS[anim_index]
		var anim_name := String(spec["name"])
		lines.append("{")
		lines.append("\"frames\": [")
		for frame_index in range(1, int(spec["frames"]) + 1):
			var id: String = ids["%s:%d" % [anim_name, frame_index]]
			lines.append("{")
			lines.append("\"duration\": 1.0,")
			lines.append("\"texture\": ExtResource(\"%s\")" % id)
			lines.append("}%s" % ("," if frame_index < int(spec["frames"]) else ""))
		lines.append("],")
		lines.append("\"loop\": %d," % int(spec["loop"]))
		lines.append("\"name\": &\"%s\"," % anim_name)
		lines.append("\"speed\": %s" % str(spec["speed"]))
		lines.append("}%s" % ("," if anim_index < ANIMATIONS.size() - 1 else ""))
	lines.append("]")
	return "\n".join(lines) + "\n"


func _build_pet_resource_text() -> String:
	return "\n".join([
		"[gd_resource type=\"Resource\" script_class=\"PetResource\" load_steps=4 format=3]",
		"",
		"[ext_resource type=\"Script\" path=\"res://src/resources/pet_resource.gd\" id=\"1_script\"]",
		"[ext_resource type=\"SpriteFrames\" path=\"res://assets/pets/cat_orange_v1/cat_orange_v1_sprite_frames.tres\" id=\"2_frames\"]",
		"[ext_resource type=\"Texture2D\" path=\"res://assets/pets/cat_orange_v1/frames/idle/idle_01.png\" id=\"3_thumb\"]",
		"",
		"[resource]",
		"script = ExtResource(\"1_script\")",
		"pet_id = \"cat_orange_v1\"",
		"display_name = \"橘猫 v1\"",
		"sprite_frames = ExtResource(\"2_frames\")",
		"thumbnail = ExtResource(\"3_thumb\")",
		"animation_speeds = {",
		"\"clicked_hold\": 1.0,",
		"\"idle\": 2.0,",
		"\"idle_clicked_double\": 3.75,",
		"\"idle_clicked_single\": 5.0,",
		"\"resting\": 0.67,",
		"\"resting_clicked_double\": 3.75,",
		"\"resting_clicked_single\": 5.0,",
		"\"working\": 5.0,",
		"\"working_clicked_double\": 3.75,",
		"\"working_clicked_single\": 5.0",
		"}",
	]) + "\n"


func _write_text(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: %s" % path)
		return false
	file.store_string(content)
	file.close()
	return true
