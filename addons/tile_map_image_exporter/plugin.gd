tool
extends EditorPlugin

var plugin

func get_plugin_name():
	return "tile_map_image_exporter"

func _enter_tree():
	plugin = preload("res://addons/tile_map_image_exporter/tile_map_image_exporter.gd").new()
	add_inspector_plugin(plugin)

func _exit_tree():
	remove_inspector_plugin(plugin)
