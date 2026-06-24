# src/autoload/pet_manager.gd
extends Node

# 状态枚举——与 PetResource 动画名一一对应
enum PetState {
	IDLE,
	WORKING,
	RESTING,
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

# 当前是否处于交互状态（HOVER 或 CLICKED_*），交互状态优先于工作时间自动切换
var _interacting: bool = false

const PETS_DIR = "res://assets/pets/"


func _ready() -> void:
	_scan_pets()
	var saved_id := String(Config.get_value("pet_id", "cat"))
	switch_pet(saved_id)


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
	if new_state == PetState.HOVER or \
	   new_state == PetState.CLICKED_SINGLE or \
	   new_state == PetState.CLICKED_DOUBLE or \
	   new_state == PetState.CLICKED_HOLD:
		_interacting = true
	else:
		_interacting = false
	set_state(new_state)


func set_state(new_state: PetState) -> void:
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)


# 交互结束后回到工作/休息/待机状态
func return_to_auto_state() -> void:
	_interacting = false
	if SalaryEngine.monthly_salary <= 0:
		set_state(PetState.IDLE)
	elif SalaryEngine.is_working_hours():
		set_state(PetState.WORKING)
	else:
		set_state(PetState.RESTING)


func _process(_delta: float) -> void:
	if current_pet == null:
		return
	if _interacting:
		return  # 交互状态由 pet.gd 显式控制
	# 自动切换 WORKING / RESTING / IDLE
	if SalaryEngine.monthly_salary <= 0:
		set_state(PetState.IDLE)
	elif SalaryEngine.is_working_hours():
		set_state(PetState.WORKING)
	else:
		set_state(PetState.RESTING)


# 将状态枚举映射到 SpriteFrames 动画名
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
