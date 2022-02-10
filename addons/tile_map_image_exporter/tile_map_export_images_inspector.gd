extends VBoxContainer

var group_label = Label.new()
var button_this_tile_only = Button.new()
var option_button_all = OptionButton.new()
const OPTION_TILEMAP_THIS = 0
const OPTION_TILEMAP_ALL = 1
var option_button_create_sprite = OptionButton.new()
const OPTION_CREATE_SPRITE = 0
const OPTION_CREATE_SPRITE_NOT = 1
var option_button_nav_node = OptionButton.new()
const OPTION_OVERRIDE_NAV = 0
const OPTION_NEW_CREATE_NAV = 1
var filename_h_con:HBoxContainer = HBoxContainer.new()
var filename_label:Label = Label.new()
var filename_edit:LineEdit = LineEdit.new()

var updating = false
var _map:TileMap

func _init(tilemap:TileMap):
	_map = tilemap
	
	alignment = BoxContainer.ALIGN_CENTER
	size_flags_horizontal = SIZE_EXPAND_FILL
	
	add_child(group_label)
	group_label.size_flags_horizontal = SIZE_EXPAND_FILL
	group_label.align = Label.ALIGN_CENTER
	group_label.valign = Label.VALIGN_CENTER
	group_label.rect_min_size = Vector2(0,28)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color( 0.27451, 0.27451, 0.27451,1)
	group_label.add_stylebox_override("normal",stylebox)
	
	add_child(option_button_all)
	option_button_all.connect("item_selected",self,"_gui_changed")
	
	add_child(option_button_create_sprite)
	option_button_create_sprite.connect("item_selected",self,"_gui_changed")
	
	add_child(filename_h_con)
	filename_h_con.add_child(filename_label)
	filename_label.rect_min_size = Vector2(32,28)
	filename_label.size_flags_stretch_ratio = .3
	filename_label.size_flags_horizontal = SIZE_EXPAND_FILL
	filename_h_con.add_child(filename_edit)
	filename_edit.connect("text_changed",self,"_text_changed")
	filename_edit.rect_min_size = Vector2(96,28)
	filename_edit.text = "res://[name].png"
	filename_edit.size_flags_stretch_ratio = .7
	filename_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	
	add_child(button_this_tile_only)
	button_this_tile_only.rect_min_size = Vector2(0,32)
	button_this_tile_only.size_flags_horizontal = SIZE_EXPAND_FILL
	button_this_tile_only.modulate = Color.dodgerblue
	button_this_tile_only.connect("pressed",self,"_on_this_only_button_pressed")
	
	var lang = OS.get_locale_language()
	if lang == 'ja':
		group_label.text = "画像出力"
		option_button_all.add_item("このTileMapのみ",OPTION_TILEMAP_THIS)
		option_button_all.add_item("シーン上すべてのTileMap",OPTION_TILEMAP_ALL)
		option_button_create_sprite.add_item("Spriteを作ってシーンに追加",OPTION_CREATE_SPRITE)
		option_button_create_sprite.add_item("画像出力のみ",OPTION_CREATE_SPRITE_NOT)
		button_this_tile_only.text = "[TileMap画像出力] 実行"
		filename_label.text = "ファイルパス"
		filename_label.hint_tooltip = "[name]はNodeの名前に置き換えられます。res://かOSの絶対パスでもOK"
		filename_edit.hint_tooltip = "[name]はNodeの名前に置き換えられます。res://かOSの絶対パスでもOK"
	else:
		button_this_tile_only.text = "Create Navigation by TileMap"
		
		group_label.text = "Export Image"
		option_button_all.add_item("selected TileMap Node Only.",OPTION_TILEMAP_THIS)
		option_button_all.add_item("All TileMap Node at This Scene.",OPTION_TILEMAP_ALL)
		option_button_create_sprite.add_item("Add Sprite Node.",OPTION_CREATE_SPRITE)
		option_button_create_sprite.add_item("NOT Add SpriteNode.",OPTION_CREATE_SPRITE_NOT)
		button_this_tile_only.text = "[Export Image] Execute"
		filename_label.text = "FilePath"
		filename_label.hint_tooltip = "[name] = Node Name. res:// or OS absolute path"
		filename_edit.hint_tooltip = "[name] = Node Name. res:// or OS absolute path"
		
	# default
	option_button_create_sprite.select(OPTION_CREATE_SPRITE_NOT)
		
#	保持データ復元
	var fl = File.new()
	if fl.file_exists("user://tile_map_export_images_inspector.dat"):
		fl.open("user://tile_map_export_images_inspector.dat",File.READ)
		var data = JSON.parse(fl.get_line()).result
		if data and data.has("option_button_all"):
			option_button_all.select(data.option_button_all)
		if data and data.has("option_button_create_sprite"):
			option_button_create_sprite.select(data.option_button_create_sprite)
		if data and data.has("filename_edit"):
			filename_edit.text = data.filename_edit
		if data and data.has("option_button_nav_node"):
			option_button_nav_node.select(data.option_button_nav_node)
	
func _gui_changed(_event) -> void:
	var fl = File.new()
	var data = {
		option_button_all = option_button_all.selected,
		option_button_create_sprite = option_button_create_sprite.selected,
		option_button_nav_node = option_button_nav_node.selected,
		filename_edit = filename_edit.text
	}
	fl.open("user://tile_map_export_images_inspector.dat",File.WRITE)
	fl.store_line(to_json(data))
	fl.close()
	
func _text_changed():
	_gui_changed(null)

func _on_this_only_button_pressed() -> void:
	if (updating):
		return
	updating = true
	make_outline_collision_hole()
	updating = false
	
func make_outline_collision_hole() -> void:
	var maps = []
	# 対象とするTileMap
	if option_button_all.selected == OPTION_TILEMAP_ALL:
		var root_node = _map.get_tree().get_root()
		var all_nodes = []
		maps = _get_all_node(root_node, all_nodes)
	else:
		maps.append(_map)
	
	# 全体のサイズを取得して包括するViewportを作る
	var tmp_viewport = Viewport.new()
	tmp_viewport.transparent_bg = true
	tmp_viewport.usage = Viewport.USAGE_2D
	tmp_viewport.disable_3d = true
	tmp_viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	get_tree().get_root().add_child(tmp_viewport)
	var right_x = 0
	var bottom_y = 0
	var left_x = 0
	var top_y = 0
	for map in maps:
		if !(map is TileMap):
			continue
		var map_rect:Rect2 = map.get_used_rect()
		var right_bottom = (map_rect.position + map_rect.size) * map.cell_size
		var top_left = map_rect.position * map.cell_size
		print("Cell Pos[",map.name,"] ",map_rect.position)
		print("Cell Size[",map.name,"] ",map_rect.size)
#		print("Real Size[",map.name,"] ",Vector2(width,height))
		# 最終的なRectは包括にしたいので一番大きかったらサイズ更新する
		if right_bottom.x > right_x:
			right_x = right_bottom.x
		if right_bottom.y > bottom_y:
			bottom_y = right_bottom.y
		if top_left.x < left_x:
			left_x = top_left.x
		if top_left.y < top_y:
			top_y = top_left.y
		
		# 一時Viewportの子に追加する
		var dup_map = map.duplicate()
		tmp_viewport.add_child(dup_map)
		tmp_viewport.size = Vector2(right_x - left_x, bottom_y - top_y)
		print(tmp_viewport.size)
		yield(VisualServer, "frame_post_draw")
		var image_data = tmp_viewport.get_texture().get_data()
		image_data.flip_y()
		var save_path = filename_edit.text.replace("[name]",map.name)
		image_data.save_png(save_path)
		tmp_viewport.remove_child(dup_map)
		print(save_path + " saved.")
		
		if option_button_create_sprite.selected == OPTION_CREATE_SPRITE:
			var sprite = Sprite.new()
			sprite.texture = load(save_path)
			sprite.position = Vector2(left_x, top_y)
			sprite.centered = false
			sprite.name = "Sprite" + map.name
			map.get_parent().add_child(sprite)
			var map_tree_pos = map.get_position_in_parent()
			map.get_parent().move_child(sprite, map_tree_pos + 1)
			sprite.owner = map.get_parent()

func _get_all_node(node:Node, array:Array)-> Array:
	for n in node.get_children():
		array.append(n)
		array = _get_all_node(n, array)
	return array
