extends RefCounted
class_name PetSelectionPolicy

const CLASSIC_PET_ID := "letsmakemoney-classic-pro"
const DUODUO_PET_ID := "duoduo-cat"
const LEGACY_V2_PET_ID := "cat_orange_v2"
const LEGACY_V1_PET_ID := "cat_orange_v1"
const PLACEHOLDER_PET_ID := "cat"


static func fallback_candidates(requested_id: String, package_fallback_ids: Array[String] = []) -> Array[String]:
	var candidates: Array[String] = []
	_append_unique(candidates, requested_id)
	for fallback_id in package_fallback_ids:
		_append_unique(candidates, fallback_id)
	for fallback_id in [CLASSIC_PET_ID, LEGACY_V2_PET_ID, LEGACY_V1_PET_ID, PLACEHOLDER_PET_ID]:
		_append_unique(candidates, fallback_id)
	return candidates


static func first_available(candidates: Array[String], available_ids: Array[String]) -> String:
	for candidate in candidates:
		if available_ids.has(candidate):
			return candidate
	return ""


static func _append_unique(output: Array[String], value: String) -> void:
	if not value.is_empty() and not output.has(value):
		output.append(value)
