# src/resources/pet_resource.gd
class_name PetResource
extends Resource

@export var pet_id: String = ""
@export var display_name: String = ""
@export var sprite_frames: SpriteFrames
@export var thumbnail: Texture2D

# 动画名与 SpriteFrames 中的动画名严格一致。
# 基础动画: idle / working / resting
# 交互动画优先使用状态感知命名，例如 idle_clicked_single / working_clicked_double；
# 若资源缺少状态感知动画，PetManager 会回退到 clicked_single / clicked_double / clicked_hold。
@export var animation_speeds: Dictionary = {
	"idle": 2.0,
	"working": 0.8,
	"resting": 3.0,
	"hover": 0.0,
	"idle_clicked_single": 0.6,
	"idle_clicked_double": 0.8,
	"working_clicked_single": 0.6,
	"working_clicked_double": 0.8,
	"resting_clicked_single": 0.6,
	"resting_clicked_double": 0.8,
	"clicked_single": 0.6,
	"clicked_double": 0.8,
	"clicked_hold": 1.0
}
