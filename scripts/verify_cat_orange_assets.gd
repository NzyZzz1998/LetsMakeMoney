extends SceneTree

const RESOURCE_PATH := "res://assets/pets/cat_orange_v1/cat_orange_v1_resource.tres"
const REQUIRED_ANIMATIONS := [
	"idle",
	"working",
	"resting",
	"idle_clicked_single",
	"idle_clicked_double",
	"working_clicked_single",
	"working_clicked_double",
	"resting_clicked_single",
	"resting_clicked_double",
	"clicked_hold",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	if not ResourceLoader.exists(RESOURCE_PATH):
		push_error("Missing cat orange resource: %s" % RESOURCE_PATH)
		quit(1)
		return

	var pet := load(RESOURCE_PATH) as PetResource
	if pet == null:
		push_error("cat orange resource is not a PetResource")
		quit(1)
		return
	if pet.pet_id != "cat_orange_v1":
		push_error("cat orange pet_id expected cat_orange_v1 but got %s" % pet.pet_id)
		quit(1)
		return
	if pet.sprite_frames == null:
		push_error("cat orange sprite_frames is null")
		quit(1)
		return

	var manager := root.get_node_or_null("/root/PetManager")
	if manager == null:
		push_error("PetManager autoload not found")
		quit(1)
		return
	var found_in_scan := false
	for available_pet in manager.get_available_pets():
		if available_pet.pet_id == "cat_orange_v1":
			found_in_scan = true
	if not found_in_scan:
		push_error("PetManager did not scan cat_orange_v1")
		quit(1)
		return

	var ok := true
	for anim_name in REQUIRED_ANIMATIONS:
		if not pet.sprite_frames.has_animation(anim_name):
			push_error("cat orange SpriteFrames missing animation: %s" % anim_name)
			ok = false
			continue
		if pet.sprite_frames.get_frame_count(anim_name) <= 0:
			push_error("cat orange animation has no frames: %s" % anim_name)
			ok = false

	if ok:
		print("Cat orange asset verification passed.")
		quit(0)
	else:
		quit(1)
