extends EditorInspectorPlugin

var TileMapExportInspector = preload("res://addons/tile_map_image_exporter/tile_map_export_images_inspector.gd")

func can_handle(object):
	if object is TileMap:
		tilemap = object
		return true
	return false
	
var is_tilemap:bool = false
var tilemap:TileMap

func parse_end():
	add_custom_control(TileMapExportInspector.new(tilemap))
