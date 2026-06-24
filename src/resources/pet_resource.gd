# src/resources/pet_resource.gd
class_name PetResource
extends Resource

@export var pet_id: String = ""
@export var display_name: String = ""
@export var sprite_frames: SpriteFrames
@export var thumbnail: Texture2D

# 动画名与 SpriteFrames 中的动画名严格一致
# 动画名约定: idle / working / resting / hover / clicked_single / clicked_double / clicked_hold
@export var animation_speeds: Dictionary = {
	"idle": 2.0,
	"working": 0.8,
	"resting": 3.0,
	"hover": 0.0,
	"clicked_single": 0.6,
	"clicked_double": 0.8,
	"clicked_hold": 1.0
}
