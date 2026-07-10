extends RefCounted

const VERSION_SETTING := "application/config/version"
const FALLBACK_VERSION := "0.0.0-dev"


static func get_version() -> String:
	var version := String(ProjectSettings.get_setting(VERSION_SETTING, FALLBACK_VERSION)).strip_edges()
	return FALLBACK_VERSION if version.is_empty() else version


static func get_display_version() -> String:
	return "v%s" % get_version()
