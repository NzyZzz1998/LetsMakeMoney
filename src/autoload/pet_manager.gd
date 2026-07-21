# src/autoload/pet_manager.gd
extends Node

const PetPackageImporterScript := preload("res://src/utils/pet_package_importer.gd")
const PetActionProfileScript := preload("res://src/utils/pet_action_profile.gd")
const PetSelectionPolicyScript := preload("res://src/utils/pet_selection_policy.gd")

# Compatibility state enum. Internally v0.2+ uses base state + interaction overlay.
enum PetState {
	IDLE,
	WORKING,
	RESTING,
	HOVER,
	CLICKED_SINGLE,
	CLICKED_DOUBLE,
	CLICKED_HOLD
}

enum PetBaseState {
	IDLE,
	WORKING,
	RESTING
}

enum PetInteraction {
	NONE,
	HOVER,
	CLICKED_SINGLE,
	CLICKED_DOUBLE,
	CLICKED_HOLD
}

signal pet_changed(pet_id: String)
signal state_changed(new_state: PetState)
signal base_animation_changed(animation_name: String)

const PETS_DIR = "res://assets/pets/"
const PET_PACKAGE_DIRS: Array[String] = [
	"res://assets/pets/packages/letsmakemoney-classic-pro",
	"res://assets/pets/packages/duoduo-cat"
]
const DEFAULT_PET_ID = PetSelectionPolicyScript.CLASSIC_PET_ID
const LEGACY_DEFAULT_PET_ID = PetSelectionPolicyScript.LEGACY_V2_PET_ID
const FALLBACK_PET_ID = PetSelectionPolicyScript.LEGACY_V1_PET_ID
const BUILTIN_PET_RESOURCE_PATHS: Array[String] = [
	"res://assets/pets/cat/orange_v2/cat_orange_v2_resource.tres",
	"res://assets/pets/cat_orange_v1/cat_orange_v1_resource.tres",
	"res://assets/pets/cat/cat_resource.tres"
]

var available_pets: Array[PetResource] = []
var shadow_package_pets: Dictionary = {}
var current_pet: PetResource = null
var current_state: PetState = PetState.IDLE
var current_base_state: PetBaseState = PetBaseState.IDLE
var current_interaction: PetInteraction = PetInteraction.NONE

var _interacting: bool = false
var _interaction_base_state: PetBaseState = PetBaseState.IDLE
var _base_animation_name: String = "awake_rest"


func _ready() -> void:
	Platform.write_boot_log("PetManager._ready: begin")
	_scan_pets()
	Platform.write_boot_log("PetManager._ready: scanned pets=%d" % available_pets.size())
	var saved_id := String(Config.get_value("pet_id", DEFAULT_PET_ID))
	switch_pet(saved_id, false)
	Platform.write_boot_log("PetManager._ready: current_pet=%s" % (current_pet.pet_id if current_pet != null else "null"))


func _scan_pets() -> void:
	available_pets.clear()
	shadow_package_pets.clear()
	_scan_pet_resources_in_dir(PETS_DIR)
	_scan_builtin_pet_resources()
	_scan_shadow_packages()
	_sort_available_pets()


func _scan_shadow_packages() -> void:
	var importer = PetPackageImporterScript.new()
	for package_root in PET_PACKAGE_DIRS:
		var result: Dictionary = importer.import_package(package_root)
		if not bool(result.get("ok", false)):
			Platform.write_boot_log("PetManager.package rejected root=%s errors=%s" % [package_root, str(result.get("errors", []))])
			continue
		var pet = result.get("pet")
		if pet is PetResource:
			shadow_package_pets[pet.pet_id] = pet
			_add_available_pet(pet)
			Platform.write_boot_log("PetManager.package shadow_loaded id=%s version=%s" % [pet.pet_id, pet.runtime_profile.package_version])


func get_shadow_package_pet(pet_id: String) -> PetResource:
	return shadow_package_pets.get(pet_id) as PetResource


func _scan_pet_resources_in_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("Pets directory not found: %s" % path)
		return

	dir.list_dir_begin()
	var entry_name := dir.get_next()
	while not entry_name.is_empty():
		var child_path := path.path_join(entry_name)
		if dir.current_is_dir():
			if not _should_skip_pet_dir(entry_name):
				_scan_pet_resources_in_dir(child_path)
		elif entry_name.ends_with("_resource.tres") and ResourceLoader.exists(child_path):
			var pet_res := load(child_path) as PetResource
			if pet_res != null:
				_add_available_pet(pet_res)
		entry_name = dir.get_next()
	dir.list_dir_end()


func _scan_builtin_pet_resources() -> void:
	for resource_path in BUILTIN_PET_RESOURCE_PATHS:
		_load_pet_resource(resource_path)


func _load_pet_resource(resource_path: String) -> void:
	if not ResourceLoader.exists(resource_path):
		Platform.write_boot_log("PetManager._load_pet_resource: missing %s" % resource_path)
		return
	var pet_res := load(resource_path) as PetResource
	if pet_res == null:
		Platform.write_boot_log("PetManager._load_pet_resource: invalid %s" % resource_path)
		return
	_add_available_pet(pet_res)


func switch_pet(pet_id: String, persist_selection: bool = true) -> void:
	var available_ids: Array[String] = []
	for pet in available_pets:
		available_ids.append(String(pet.pet_id))
	var package_fallbacks: Array[String] = []
	var requested_pet := _find_pet_by_id(pet_id)
	if requested_pet != null and requested_pet.runtime_profile != null:
		package_fallbacks = requested_pet.runtime_profile.fallback_ids.duplicate()
	var selected_id := PetSelectionPolicyScript.first_available(
		PetSelectionPolicyScript.fallback_candidates(pet_id, package_fallbacks),
		available_ids
	)
	var next_pet := _find_pet_by_id(selected_id)
	if next_pet == null and available_pets.size() > 0:
		next_pet = available_pets[0]

	if next_pet != null:
		var previous_pet_id := String(current_pet.pet_id) if current_pet != null else ""
		current_pet = next_pet
		if persist_selection:
			Config.set_value("pet_id", current_pet.pet_id)
			_update_package_identity(current_pet)
		if pet_id != current_pet.pet_id:
			Platform.write_info_log("pet_fallback: requested=%s selected=%s" % [pet_id, current_pet.pet_id])
		elif persist_selection and previous_pet_id == DEFAULT_PET_ID and current_pet.pet_id == LEGACY_DEFAULT_PET_ID:
			Platform.write_info_log("classic.rollback: result=success target=%s" % LEGACY_DEFAULT_PET_ID)
		pet_changed.emit(current_pet.pet_id)


func rollback_classic_to_v08() -> bool:
	var legacy_pet := _find_pet_by_id(LEGACY_DEFAULT_PET_ID)
	if legacy_pet == null:
		Platform.write_error_log("classic.rollback: result=failed reason=legacy_v2_missing")
		return false
	switch_pet(LEGACY_DEFAULT_PET_ID, true)
	return true


func get_current_pet() -> PetResource:
	return current_pet


func get_available_pets() -> Array[PetResource]:
	return available_pets


func request_state(new_state: PetState) -> void:
	match new_state:
		PetState.IDLE:
			set_base_state(PetBaseState.IDLE)
		PetState.WORKING:
			set_base_state(PetBaseState.WORKING)
		PetState.RESTING:
			set_base_state(PetBaseState.RESTING)
		PetState.HOVER:
			request_interaction(PetInteraction.HOVER)
		PetState.CLICKED_SINGLE:
			request_interaction(PetInteraction.CLICKED_SINGLE)
		PetState.CLICKED_DOUBLE:
			request_interaction(PetInteraction.CLICKED_DOUBLE)
		PetState.CLICKED_HOLD:
			request_interaction(PetInteraction.CLICKED_HOLD)


func set_state(new_state: PetState) -> void:
	request_state(new_state)


func set_base_state(new_base_state: PetBaseState) -> void:
	match new_base_state:
		PetBaseState.WORKING:
			_set_schedule_base_animation("working")
		PetBaseState.IDLE, PetBaseState.RESTING:
			_set_schedule_base_animation("awake_rest")


func request_interaction(interaction: PetInteraction) -> void:
	var changed := current_interaction != interaction
	if interaction != PetInteraction.NONE:
		_interaction_base_state = current_base_state
	current_interaction = interaction
	_interacting = interaction != PetInteraction.NONE
	current_state = _interaction_to_pet_state(interaction)
	if changed:
		state_changed.emit(current_state)


func return_to_interaction_base_state() -> void:
	_set_schedule_base_animation(_base_animation_name)


func return_to_auto_state() -> void:
	_interacting = false
	if SalaryEngine.monthly_salary <= 0:
		_set_schedule_base_animation("awake_rest")
	else:
		_set_schedule_base_animation(SalaryEngine.get_animation_state_name())


func _process(_delta: float) -> void:
	if current_pet == null:
		return
	if _interacting:
		return
	if SalaryEngine.monthly_salary <= 0:
		_set_schedule_base_animation("awake_rest")
	else:
		_set_schedule_base_animation(SalaryEngine.get_animation_state_name())


func state_to_anim_name(state: PetState) -> String:
	match state:
		PetState.IDLE:
			return "idle"
		PetState.WORKING:
			return "working"
		PetState.RESTING:
			return "resting"
		PetState.HOVER:
			return "hover"
		PetState.CLICKED_SINGLE:
			return "clicked_single"
		PetState.CLICKED_DOUBLE:
			return "clicked_double"
		PetState.CLICKED_HOLD:
			return "clicked_hold"
	return "idle"


func get_current_animation_name() -> String:
	var frames: SpriteFrames = null
	if current_pet != null:
		frames = current_pet.sprite_frames
	if current_interaction == PetInteraction.NONE:
		return PetActionProfileScript.first_available(PetActionProfileScript.base_candidates(_base_animation_name), frames)
	return PetActionProfileScript.first_available(
		PetActionProfileScript.interaction_candidates(_base_animation_name, _interaction_debug_name(current_interaction)),
		frames
	)


func get_current_base_animation_name() -> String:
	return _base_animation_name


func resolve_animation_name(base_state: PetBaseState, interaction: PetInteraction = PetInteraction.NONE, sprite_frames: SpriteFrames = null) -> String:
	var base_name := base_state_to_anim_name(base_state)
	if interaction == PetInteraction.NONE:
		return base_name

	var candidates: Array[String] = []
	match interaction:
		PetInteraction.HOVER:
			candidates = ["hover", base_name]
		PetInteraction.CLICKED_SINGLE:
			candidates = ["%s_clicked_single" % base_name, "clicked_single", base_name]
		PetInteraction.CLICKED_DOUBLE:
			candidates = ["%s_clicked_double" % base_name, "clicked_double", base_name]
		PetInteraction.CLICKED_HOLD:
			candidates = ["clicked_hold", base_name]

	if sprite_frames == null:
		return candidates[0] if candidates.size() > 0 else base_name
	for anim_name in candidates:
		if sprite_frames.has_animation(anim_name):
			return anim_name
	return base_name


func base_state_to_anim_name(base_state: PetBaseState) -> String:
	match base_state:
		PetBaseState.IDLE:
			return "idle"
		PetBaseState.WORKING:
			return "working"
		PetBaseState.RESTING:
			return "resting"
	return "idle"


func _set_schedule_base_animation(animation_name: String) -> void:
	var normalized := animation_name if animation_name in ["working", "awake_rest", "sleeping"] else "awake_rest"
	var next_base := PetBaseState.WORKING if normalized == "working" else PetBaseState.RESTING
	var changed := _base_animation_name != normalized or current_base_state != next_base or current_interaction != PetInteraction.NONE
	_base_animation_name = normalized
	current_base_state = next_base
	_interaction_base_state = next_base
	current_interaction = PetInteraction.NONE
	_interacting = false
	current_state = _base_to_pet_state(next_base)
	if changed:
		base_animation_changed.emit(_base_animation_name)
		state_changed.emit(current_state)


func _interaction_debug_name(interaction: PetInteraction) -> String:
	match interaction:
		PetInteraction.HOVER:
			return "hover"
		PetInteraction.CLICKED_SINGLE:
			return "clicked_single"
		PetInteraction.CLICKED_DOUBLE:
			return "clicked_double"
		PetInteraction.CLICKED_HOLD:
			return "clicked_hold"
	return "none"


func _base_to_pet_state(base_state: PetBaseState) -> PetState:
	match base_state:
		PetBaseState.IDLE:
			return PetState.IDLE
		PetBaseState.WORKING:
			return PetState.WORKING
		PetBaseState.RESTING:
			return PetState.RESTING
	return PetState.IDLE


func _interaction_to_pet_state(interaction: PetInteraction) -> PetState:
	match interaction:
		PetInteraction.HOVER:
			return PetState.HOVER
		PetInteraction.CLICKED_SINGLE:
			return PetState.CLICKED_SINGLE
		PetInteraction.CLICKED_DOUBLE:
			return PetState.CLICKED_DOUBLE
		PetInteraction.CLICKED_HOLD:
			return PetState.CLICKED_HOLD
	return _base_to_pet_state(current_base_state)


func _should_skip_pet_dir(dir_name: String) -> bool:
	return dir_name.begins_with(".") or dir_name.begins_with("_") or dir_name == "raw"


func _add_available_pet(pet: PetResource) -> void:
	for existing in available_pets:
		if existing.pet_id == pet.pet_id:
			return
	available_pets.append(pet)


func _find_pet_by_id(pet_id: String) -> PetResource:
	for pet in available_pets:
		if pet.pet_id == pet_id:
			return pet
	return null


func _update_package_identity(pet: PetResource) -> void:
	if pet.runtime_profile != null:
		Config.set_value("pet_package_id", String(pet.runtime_profile.package_id))
		Config.set_value("pet_package_version", String(pet.runtime_profile.package_version))
	else:
		Config.set_value("pet_package_id", "legacy-%s" % pet.pet_id.replace("_", "-"))
		Config.set_value("pet_package_version", "legacy")


func _sort_available_pets() -> void:
	available_pets.sort_custom(func(a: PetResource, b: PetResource) -> bool:
		if a.pet_id == DEFAULT_PET_ID:
			return true
		if b.pet_id == DEFAULT_PET_ID:
			return false
		if a.pet_id == FALLBACK_PET_ID:
			return true
		if b.pet_id == FALLBACK_PET_ID:
			return false
		return a.pet_id < b.pet_id
	)
