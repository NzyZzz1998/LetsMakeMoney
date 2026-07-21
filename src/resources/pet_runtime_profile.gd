extends Resource
class_name PetRuntimeProfile

@export var package_id: String = ""
@export var package_version: String = ""
@export var package_hash: String = ""
@export var package_root: String = ""
@export var logical_size: Vector2 = Vector2(192, 208)
@export var pivot: Vector2 = Vector2(96, 196)
@export var foot_baseline: float = 196.0
@export var hit_strategy: String = "action_union"
@export var animation_metadata: Dictionary = {}
@export var fallback_ids: Array[String] = []
