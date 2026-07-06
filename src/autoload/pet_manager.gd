# src/autoload/pet_manager.gd
extends Node

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

const PETS_DIR = "res://assets/pets/"
const DEFAULT_PET_ID = "cat_orange_v2"
const FALLBACK_PET_ID = "cat_orange_v1"
const BUILTIN_PET_RESOURCE_PATHS: Array[String] = [
	"res://assets/pets/cat/orange_v2/cat_orange_v2_resource.tres",
	"res://assets/pets/cat_orange_v1/cat_orange_v1_resource.tres",
	"res://assets/pets/cat/cat_resource.tres"
]

var available_pets: Array[PetResource] = []
var current_pet: PetResource = null
var current_state: PetState = PetState.IDLE
var current_base_state: PetBaseState = PetBaseState.IDLE
var current_interaction: PetInteraction = PetInteraction.NONE

var _interacting: bool = false
var _interaction_base_state: PetBaseState = PetBaseState.IDLE


func _ready() -> void:
	Platform.write_boot_log("PetManager._ready: begin")
	_scan_pets()
	Platform.write_boot_log("PetManager._ready: scanned pets=%d" % available_pets.size())
	var saved_id := String(Config.get_value("pet_id", DEFAULT_PET_ID))
	switch_pet(saved_id)
	Platform.write_boot_log("PetManager._ready: current_pet=%s" % (current_pet.pet_id if current_pet != null else "null"))


func _scan_pets() -> void:
	available_pets.clear()
	_scan_pet_resources_in_dir(PETS_DIR)
	_scan_builtin_pet_resources()
	_sort_available_pets()


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


func switch_pet(pet_id: String) -> void:
	var next_pet := _find_pet_by_id(pet_id)
	if next_pet == null and pet_id != DEFAULT_PET_ID:
		next_pet = _find_pet_by_id(DEFAULT_PET_ID)
	if next_pet == null:
		next_pet = _find_pet_by_id(FALLBACK_PET_ID)
	if next_pet == null and available_pets.size() > 0:
		next_pet = available_pets[0]

	if next_pet != null:
		current_pet = next_pet
		Config.set_value("pet_id", current_pet.pet_id)
		pet_changed.emit(current_pet.pet_id)


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
	var changed := current_base_state != new_base_state or current_interaction != PetInteraction.NONE
	current_base_state = new_base_state
	_interaction_base_state = new_base_state
	current_interaction = PetInteraction.NONE
	_interacting = false
	current_state = _base_to_pet_state(new_base_state)
	if changed:
		state_changed.emit(current_state)


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
	set_base_state(_interaction_base_state)


func return_to_auto_state() -> void:
	_interacting = false
	if SalaryEngine.monthly_salary <= 0:
		set_base_state(PetBaseState.IDLE)
	elif SalaryEngine.is_working_hours():
		set_base_state(PetBaseState.WORKING)
	else:
		set_base_state(PetBaseState.RESTING)


func _process(_delta: float) -> void:
	if current_pet == null:
		return
	if _interacting:
		return
	if SalaryEngine.monthly_salary <= 0:
		set_base_state(PetBaseState.IDLE)
	elif SalaryEngine.is_working_hours():
		set_base_state(PetBaseState.WORKING)
	else:
		set_base_state(PetBaseState.RESTING)


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
	return resolve_animation_name(current_base_state, current_interaction, frames)


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
