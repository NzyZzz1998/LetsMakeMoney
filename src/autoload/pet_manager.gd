# src/autoload/pet_manager.gd
extends Node

# 兼容旧调用的单层状态枚举。v0.2 起内部使用“基础状态 + 交互覆盖”模型。
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

var available_pets: Array[PetResource] = []
var current_pet: PetResource = null
var current_state: PetState = PetState.IDLE
var current_base_state: PetBaseState = PetBaseState.IDLE
var current_interaction: PetInteraction = PetInteraction.NONE

# 当前是否处于交互覆盖层，交互状态优先于工作时间自动切换
var _interacting: bool = false

const PETS_DIR = "res://assets/pets/"


func _ready() -> void:
	Platform.write_boot_log("PetManager._ready: begin")
	_scan_pets()
	Platform.write_boot_log("PetManager._ready: scanned pets=%d" % available_pets.size())
	var saved_id := String(Config.get_value("pet_id", "cat"))
	switch_pet(saved_id)
	Platform.write_boot_log("PetManager._ready: current_pet=%s" % (current_pet.pet_id if current_pet != null else "null"))


func _scan_pets() -> void:
	available_pets.clear()
	var dir := DirAccess.open(PETS_DIR)
	if dir == null:
		push_warning("Pets directory not found: %s" % PETS_DIR)
		return
	dir.list_dir_begin()
	var dir_name := dir.get_next()
	while dir_name != "":
		if dir.current_is_dir() and not dir_name.begins_with(".") and dir_name != "raw":
			var res_path := PETS_DIR.path_join(dir_name).path_join(dir_name + "_resource.tres")
			if ResourceLoader.exists(res_path):
				var pet_res := load(res_path) as PetResource
				if pet_res:
					available_pets.append(pet_res)
		dir_name = dir.get_next()
	dir.list_dir_end()


func switch_pet(pet_id: String) -> void:
	for pet in available_pets:
		if pet.pet_id == pet_id:
			current_pet = pet
			Config.set_value("pet_id", pet_id)
			pet_changed.emit(pet_id)
			return
	# 找不到指定的，回退到第一个
	if available_pets.size() > 0:
		current_pet = available_pets[0]
		Config.set_value("pet_id", current_pet.pet_id)
		pet_changed.emit(current_pet.pet_id)


func get_current_pet() -> PetResource:
	return current_pet


func get_available_pets() -> Array[PetResource]:
	return available_pets


# 统一状态入口——由 pet.gd 调用
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
	current_interaction = PetInteraction.NONE
	_interacting = false
	current_state = _base_to_pet_state(new_base_state)
	if changed:
		state_changed.emit(current_state)


func request_interaction(interaction: PetInteraction) -> void:
	var changed := current_interaction != interaction
	current_interaction = interaction
	_interacting = interaction != PetInteraction.NONE
	current_state = _interaction_to_pet_state(interaction)
	if changed:
		state_changed.emit(current_state)


# 交互结束后回到工作/休息/待机状态
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
		return  # 交互状态由 pet.gd 显式控制
	# 自动切换 WORKING / RESTING / IDLE
	if SalaryEngine.monthly_salary <= 0:
		set_base_state(PetBaseState.IDLE)
	elif SalaryEngine.is_working_hours():
		set_base_state(PetBaseState.WORKING)
	else:
		set_base_state(PetBaseState.RESTING)


# 将旧状态枚举映射到通用 SpriteFrames 动画名，保留给旧素材和旧调用使用。
func state_to_anim_name(state: PetState) -> String:
	match state:
		PetState.IDLE: return "idle"
		PetState.WORKING: return "working"
		PetState.RESTING: return "resting"
		PetState.HOVER: return "hover"
		PetState.CLICKED_SINGLE: return "clicked_single"
		PetState.CLICKED_DOUBLE: return "clicked_double"
		PetState.CLICKED_HOLD: return "clicked_hold"
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
