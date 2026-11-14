extends Control

var ui_layer: CanvasLayer
var hp_label: Label
var gold_label: Label
var xp_label: Label

var journal_panel: Panel
var journal_scroll: ScrollContainer
var journal_content: VBoxContainer
var btn_tab_bestiary: Button
var btn_tab_materials: Button
var btn_tab_items: Button
var current_journal_tab = "bestiary"

var shop_panel: Panel
var shop_gold_label: Label
var shop_scroll: ScrollContainer
var shop_content: VBoxContainer
var btn_shop_buy_tab: Button
var btn_shop_sell_tab: Button
var current_shop_tab = "buy"

var inv_panel: Panel
var inv_scroll: ScrollContainer
var inv_items_container: VBoxContainer

var book_atlas: AtlasTexture
var book_icon: TextureRect

var hp_atlas: AtlasTexture
var gold_atlas: AtlasTexture

var shop_inventory = [
	{"id": "health_potion", "name": "Зелье лечения", "price": 15, "icon_x": 114, "icon_y": 145, "desc": "Восстанавливает 10 HP в бою."}
]

var item_count_labels = {}

var pause_overlay: ColorRect
var pause_panel: Panel
var confirm_panel: Panel

var font_title = load("res://assets/fonts/Rubik-Regular.ttf")
var font_text = load("res://assets/fonts/Nunito-Regular.ttf")

var world: Node2D
var camera: Camera2D
var is_dragging = false
var drag_start_pos = Vector2.ZERO

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	world = Node2D.new()
	add_child(world)
	
	camera = Camera2D.new()
	camera.position = Vector2(0, 0)
	camera.limit_left = -1500
	camera.limit_right = 1500
	camera.limit_top = -1500
	camera.limit_bottom = 1500
	camera.zoom = Vector2(1.0, 1.0)
	world.add_child(camera)
	
	create_city_map()
	
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	create_wooden_hud()
	create_ui_buttons()
	create_journal_ui()
	create_shop_ui()
	create_inventory_ui()
	create_pause_menu()
	
	if get_node_or_null("/root/SoundManager"):
		SoundManager.connect_ui_sounds(self)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if pause_overlay.visible:
			_on_pause_resume()
		else:
			pause_overlay.visible = true
			pause_panel.visible = true
			confirm_panel.visible = false
			get_tree().paused = true
		return 
	
	if get_tree().paused:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_start_pos = event.position
			else:
				is_dragging = false
				
	if event is InputEventMouseMotion and is_dragging:
		var drag_delta = event.position - drag_start_pos
		drag_start_pos = event.position
		camera.position -= drag_delta / camera.zoom.x

func create_city_map():
	var ground = ColorRect.new()
	ground.color = Color(0.2, 0.25, 0.15) 
	ground.position = Vector2(-1500, -1500)
	ground.size = Vector2(3000, 3000)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(ground)

	for r in range(1, 4):
		var radius = r * 300
		var road = Line2D.new()
		var pts = PackedVector2Array()
		for i in range(60):
			var angle = (i / 60.0) * TAU
			pts.append(Vector2(cos(angle) * radius, sin(angle) * radius))
		road.points = pts
		road.closed = true
		road.width = 40
		road.default_color = Color(0.5, 0.45, 0.4) 
		world.add_child(road)

	for i in range(4):
		var angle = i * (PI / 2)
		var road = Line2D.new()
		road.points = PackedVector2Array([Vector2(0, 0), Vector2(cos(angle) * 1500, sin(angle) * 1500)])
		road.width = 40
		road.default_color = Color(0.5, 0.45, 0.4)
		world.add_child(road)

	var tower_group = Node2D.new()
	world.add_child(tower_group)
	
	var tower_base = Polygon2D.new()
	var tb_pts = PackedVector2Array()
	for i in range(30):
		var angle = (i / 30.0) * TAU
		tb_pts.append(Vector2(cos(angle) * 150, sin(angle) * 150))
	tower_base.polygon = tb_pts
	tower_base.color = Color(0.4, 0.4, 0.45)
	tower_group.add_child(tower_base)
	
	var tower_body = Polygon2D.new()
	tower_body.polygon = PackedVector2Array([
		Vector2(-120, 0), Vector2(-40, -400), Vector2(40, -400), Vector2(120, 0)
	])
	tower_body.color = Color(0.5, 0.45, 0.5)
	tower_group.add_child(tower_body)
	
	var entrance = Polygon2D.new()
	entrance.polygon = PackedVector2Array([
		Vector2(-40, 60), Vector2(-30, -20), Vector2(30, -20), Vector2(40, 60)
	])
	entrance.color = Color(0.05, 0.05, 0.05)
	tower_group.add_child(entrance)

	var tower_btn = Button.new()
	tower_btn.size = Vector2(200, 200)
	tower_btn.position = Vector2(-100, -100)
	tower_btn.flat = true
	tower_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tower_btn.pressed.connect(_on_building_clicked.bind("dungeon"))
	tower_btn.mouse_entered.connect(func(): tower_group.modulate = Color(1.3, 1.3, 1.3))
	tower_btn.mouse_exited.connect(func(): tower_group.modulate = Color(1, 1, 1))
	world.add_child(tower_btn)

	var tower_label = Label.new()
	tower_label.text = "Вход в подземелье"
	tower_label.position = Vector2(-100, 80)
	tower_label.size = Vector2(200, 40)
	tower_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tower_label.add_theme_font_size_override("font_size", 22)
	tower_label.add_theme_color_override("font_color", Color(1, 1, 0.8))
	tower_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	tower_label.add_theme_constant_override("outline_size", 4)
	if font_title: tower_label.add_theme_font_override("font", font_title)
	world.add_child(tower_label)

	draw_building(Vector2(-400, 0), Color(0.7, 0.2, 0.2), "Лавка", "shop")
	draw_building(Vector2(400, 0), Color(0.2, 0.3, 0.6), "Гильдия", "guild")
	draw_building(Vector2(0, 400), Color(0.4, 0.4, 0.4), "Кузнец", "blacksmith")
	draw_building(Vector2(0, -400), Color(0.5, 0.3, 0.1), "Таверна", "tavern")

	for i in range(20):
		var angle = randf_range(0, TAU)
		var dist = randf_range(600, 1400)
		var pos = Vector2(cos(angle) * dist, sin(angle) * dist)
		var house_color = Color(randf_range(0.3, 0.6), randf_range(0.2, 0.4), randf_range(0.2, 0.4))
		draw_small_house(pos, house_color)

func draw_building(pos: Vector2, color: Color, title: String, action: String):
	var node = Node2D.new()
	node.position = pos
	world.add_child(node)

	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-60, 40), Vector2(-60, -40), Vector2(60, -40), Vector2(60, 40)])
	base.color = Color(0.8, 0.75, 0.7) 
	node.add_child(base)

	var roof = Polygon2D.new()
	roof.polygon = PackedVector2Array([Vector2(-70, -40), Vector2(0, -100), Vector2(70, -40)])
	roof.color = color
	node.add_child(roof)

	var label = Label.new()
	label.text = title
	label.position = Vector2(-40, -140)
	label.size = Vector2(80, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 4)
	if font_title: label.add_theme_font_override("font", font_title)
	node.add_child(label)

	if action == "shop":
		var coin = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in range(20):
			var angle = (i / 20.0) * TAU
			pts.append(Vector2(cos(angle) * 20, sin(angle) * 20) + Vector2(0, -90))
		coin.polygon = pts
		coin.color = Color(1.0, 0.8, 0.2)
		node.add_child(coin)

	var btn = Button.new()
	btn.size = Vector2(140, 140)
	btn.position = Vector2(-70, -100)
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_building_clicked.bind(action))
	btn.mouse_entered.connect(func(): node.modulate = Color(1.3, 1.3, 1.3))
	btn.mouse_exited.connect(func(): node.modulate = Color(1, 1, 1))
	node.add_child(btn)

func draw_small_house(pos: Vector2, color: Color):
	var house = Node2D.new()
	house.position = pos
	world.add_child(house)
	
	var base = Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-30, 20), Vector2(-30, -20), Vector2(30, -20), Vector2(30, 20)])
	base.color = Color(0.7, 0.65, 0.6)
	house.add_child(base)
	
	var roof = Polygon2D.new()
	roof.polygon = PackedVector2Array([Vector2(-40, -20), Vector2(0, -60), Vector2(40, -20)])
	roof.color = color
	house.add_child(roof)

func _on_building_clicked(action: String):
	if action == "shop":
		_on_open_shop()
	elif action == "guild":
		print("Гильдия: Доска заданий в разработке!")
	elif action == "blacksmith":
		print("Кузнец в разработке")
	elif action == "tavern":
		print("Таверна в разработке")
	elif action == "dungeon":
		_on_go_to_expedition()

func create_wooden_hud():
	var hud = Panel.new()
	hud.position = Vector2(20, 20)
	hud.size = Vector2(320, 160) 
	hud.z_index = 10
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.1) 
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.6, 0.4, 0.1) 
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	hud.add_theme_stylebox_override("panel", style)
	ui_layer.add_child(hud)

	var circle = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(30):
		var angle = (i / 30.0) * TAU
		pts.append(Vector2(cos(angle) * 45, sin(angle) * 45) + Vector2(60, 80)) 
	circle.polygon = pts
	circle.color = Color(0.1, 0.05, 0.0) 
	hud.add_child(circle)
	
	var circle_border = Line2D.new()
	circle_border.points = pts
	circle_border.closed = true
	circle_border.width = 4
	circle_border.default_color = Color(0.8, 0.5, 0.2)
	hud.add_child(circle_border)

	var avatar = TextureRect.new()
	var avatar_atlas = AtlasTexture.new()
	avatar_atlas.atlas = load("res://assets/tileset.png")
	avatar_atlas.region = Rect2(16, 128, 16, 16) 
	avatar.texture = avatar_atlas
	avatar.scale = Vector2(4.5, 4.5) 
	avatar.position = Vector2(20, 40) 
	hud.add_child(avatar)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(125, 15) 
	vbox.size = Vector2(180, 130)
	vbox.add_theme_constant_override("separation", 6)
	hud.add_child(vbox)

	var h_info = HBoxContainer.new()
	h_info.add_theme_constant_override("separation", 15)
	
	var level_label = Label.new()
	level_label.text = "Ур. 1"
	level_label.add_theme_font_size_override("font_size", 18) 
	level_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) 
	level_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	level_label.add_theme_constant_override("outline_size", 4)
	h_info.add_child(level_label)

	var rank_label = Label.new()
	rank_label.text = "Ранг F"
	rank_label.add_theme_font_size_override("font_size", 18)
	rank_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9)) 
	rank_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	rank_label.add_theme_constant_override("outline_size", 4)
	h_info.add_child(rank_label)
	vbox.add_child(h_info)

	var h_hp = HBoxContainer.new()
	h_hp.add_theme_constant_override("separation", 10)
	var icon_hp = create_animated_icon("hp", 1, 50)
	h_hp.add_child(icon_hp)
	hp_label = create_stat_label()
	h_hp.add_child(hp_label)
	vbox.add_child(h_hp)

	var h_gold = HBoxContainer.new()
	h_gold.add_theme_constant_override("separation", 10)
	var icon_gold = create_animated_icon("gold", 1, 65)
	h_gold.add_child(icon_gold)
	gold_label = create_stat_label()
	h_gold.add_child(gold_label)
	vbox.add_child(h_gold)

	var h_xp = HBoxContainer.new()
	h_xp.add_theme_constant_override("separation", 10)
	var icon_xp = create_static_icon("res://assets/tileset.png", Rect2(114, 161, 16, 16))
	h_xp.add_child(icon_xp)
	xp_label = create_stat_label()
	h_xp.add_child(xp_label)
	vbox.add_child(h_xp)

	update_info_ui()
	animate_icons_loop()

func create_stat_label() -> Label:
	var lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl

func create_animated_icon(type: String, start_x: int, start_y: int) -> TextureRect:
	var icon = TextureRect.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = load("res://assets/objects.png")
	atlas.region = Rect2(start_x, start_y, 13, 13)
	icon.texture = atlas
	icon.custom_minimum_size = Vector2(20, 20) 
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if type == "hp": hp_atlas = atlas
	if type == "gold": gold_atlas = atlas
	return icon

func create_static_icon(path: String, region: Rect2) -> TextureRect:
	var icon = TextureRect.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = load(path)
	atlas.region = region
	icon.texture = atlas
	icon.custom_minimum_size = Vector2(20, 20)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

func animate_icons_loop():
	var frame = 0
	var x_offsets = [1, 17, 33, 49]
	while true:
		await get_tree().create_timer(0.2).timeout
		frame = (frame + 1) % 4
		if is_instance_valid(hp_atlas): hp_atlas.region = Rect2(x_offsets[frame], 50, 13, 13)
		if is_instance_valid(gold_atlas): gold_atlas.region = Rect2(x_offsets[frame], 65, 13, 13)

func update_info_ui():
	hp_label.text = str(int(GameManager.player_hp)) + "/" + str(int(GameManager.max_hp))
	gold_label.text = str(int(GameManager.gold))
	xp_label.text = str(int(GameManager.xp))

func create_ui_buttons():
	create_inventory_button(Vector2(20, 190)) 
	create_journal_button(Vector2(20, 270))

func style_button(btn):
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.25, 0.15, 0.1, 0.95) 
	normal.border_width_left = 3
	normal.border_width_right = 3
	normal.border_width_top = 3
	normal.border_width_bottom = 3
	normal.border_color = Color(0.8, 0.5, 0.2) 
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.shadow_color = Color(0, 0, 0, 0.5)
	normal.shadow_size = 4
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.4, 0.25, 0.15, 0.95)
	hover.border_width_left = 3
	hover.border_width_right = 3
	hover.border_width_top = 3
	hover.border_width_bottom = 3
	hover.border_color = Color(1.0, 0.8, 0.4)
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	hover.shadow_color = Color(1.0, 0.6, 0.2, 0.3)
	hover.shadow_size = 6
	btn.add_theme_stylebox_override("hover", hover)

func create_inventory_button(pos: Vector2):
	var btn = Button.new()
	btn.position = pos
	btn.size = Vector2(70, 70)
	style_button(btn)
	btn.pressed.connect(_on_open_inventory)
	ui_layer.add_child(btn)
	
	var bag = Polygon2D.new()
	bag.polygon = PackedVector2Array([Vector2(20, 20), Vector2(50, 20), Vector2(55, 50), Vector2(35, 60), Vector2(15, 50)])
	bag.color = Color(0.8, 0.2, 0.15) 
	btn.add_child(bag)
	
	var cinch = ColorRect.new()
	cinch.color = Color(0.3, 0.15, 0.1) 
	cinch.position = Vector2(20, 15)
	cinch.size = Vector2(30, 8)
	cinch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(cinch)
	
	var symbol = Polygon2D.new()
	symbol.polygon = PackedVector2Array([Vector2(35, 35), Vector2(42, 45), Vector2(35, 55), Vector2(28, 45)])
	symbol.color = Color(1.0, 0.8, 0.2)
	btn.add_child(symbol)

func create_journal_button(pos: Vector2):
	var btn = Button.new()
	btn.position = pos
	btn.size = Vector2(70, 70)
	style_button(btn) 
	btn.pressed.connect(_on_open_journal)
	ui_layer.add_child(btn)
	book_icon = TextureRect.new()
	book_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	book_atlas = AtlasTexture.new()
	book_atlas.atlas = load("res://assets/objects.png") 
	book_atlas.region = Rect2(243, 0, 16, 20) 
	book_icon.texture = book_atlas
	book_icon.scale = Vector2(3.5, 3.5) 
	book_icon.position = Vector2(5, 0) 
	btn.add_child(book_icon)

func create_journal_ui():
	journal_panel = Panel.new()
	journal_panel.position = Vector2(240, 40) 
	journal_panel.size = Vector2(800, 640) 
	journal_panel.z_index = 100
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08, 0.98) 
	style.border_width_left = 6
	style.border_width_right = 6
	style.border_width_top = 6
	style.border_width_bottom = 6
	style.border_color = Color(0.6, 0.4, 0.1) 
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	journal_panel.add_theme_stylebox_override("panel", style)
	journal_panel.visible = false
	ui_layer.add_child(journal_panel)

	var title = Label.new()
	title.text = "Журнал Авантюриста"
	title.position = Vector2(0, 20)
	title.size = Vector2(800, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	if font_title: title.add_theme_font_override("font", font_title)
	journal_panel.add_child(title)

	var h_tabs = HBoxContainer.new()
	h_tabs.position = Vector2(115, 80) 
	h_tabs.size = Vector2(570, 40)
	h_tabs.add_theme_constant_override("separation", 15)
	journal_panel.add_child(h_tabs)

	btn_tab_bestiary = Button.new()
	btn_tab_bestiary.text = "Бестиарий"
	btn_tab_bestiary.custom_minimum_size = Vector2(180, 45) 
	btn_tab_bestiary.add_theme_font_size_override("font_size", 20)
	style_button(btn_tab_bestiary)
	btn_tab_bestiary.pressed.connect(func(): _switch_journal_tab("bestiary"))
	h_tabs.add_child(btn_tab_bestiary)

	btn_tab_materials = Button.new()
	btn_tab_materials.text = "Материалы"
	btn_tab_materials.custom_minimum_size = Vector2(180, 45)
	btn_tab_materials.add_theme_font_size_override("font_size", 20)
	style_button(btn_tab_materials)
	btn_tab_materials.pressed.connect(func(): _switch_journal_tab("materials"))
	h_tabs.add_child(btn_tab_materials)

	btn_tab_items = Button.new()
	btn_tab_items.text = "Предметы"
	btn_tab_items.custom_minimum_size = Vector2(180, 45)
	btn_tab_items.add_theme_font_size_override("font_size", 20)
	style_button(btn_tab_items)
	btn_tab_items.pressed.connect(func(): _switch_journal_tab("items"))
	h_tabs.add_child(btn_tab_items)

	journal_scroll = ScrollContainer.new()
	journal_scroll.position = Vector2(50, 140) 
	journal_scroll.size = Vector2(700, 450) 
	journal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	journal_panel.add_child(journal_scroll)

	journal_content = VBoxContainer.new()
	journal_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_content.add_theme_constant_override("separation", 15)
	journal_scroll.add_child(journal_content)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(740, 20) 
	close_btn.size = Vector2(40, 40)
	close_btn.add_theme_font_size_override("font_size", 24)
	style_button(close_btn)
	close_btn.pressed.connect(_on_close_journal)
	journal_panel.add_child(close_btn)

func _on_open_journal():
	journal_panel.visible = true
	_switch_journal_tab(current_journal_tab)

func _switch_journal_tab(tab_name):
	current_journal_tab = tab_name
	for child in journal_content.get_children():
		child.queue_free()
	btn_tab_bestiary.modulate = Color(0.7, 0.7, 0.7)
	btn_tab_materials.modulate = Color(0.7, 0.7, 0.7)
	btn_tab_items.modulate = Color(0.7, 0.7, 0.7)
	
	if tab_name == "bestiary":
		btn_tab_bestiary.modulate = Color(1.2, 1.2, 1.2) 
		_fill_bestiary()
	elif tab_name == "materials":
		btn_tab_materials.modulate = Color(1.2, 1.2, 1.2) 
		_fill_materials()
	else:
		btn_tab_items.modulate = Color(1.2, 1.2, 1.2)
		_fill_items()

func _fill_bestiary():
	if GameManager.discovered_enemies.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Вы пока никого не встретили."
		empty_label.add_theme_font_size_override("font_size", 22)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		journal_content.add_child(empty_label)
		return
	for enemy_id in GameManager.discovered_enemies:
		var data = GameManager.enemy_db[enemy_id]
		var entry_panel = Panel.new()
		entry_panel.custom_minimum_size = Vector2(660, 200) 
		var entry_style = StyleBoxFlat.new()
		entry_style.bg_color = Color(0.2, 0.15, 0.1)
		entry_style.corner_radius_top_left = 5
		entry_style.corner_radius_top_right = 5
		entry_style.corner_radius_bottom_left = 5
		entry_style.corner_radius_bottom_right = 5
		entry_style.border_width_left = 2
		entry_style.border_width_right = 2
		entry_style.border_width_top = 2
		entry_style.border_width_bottom = 2
		entry_style.border_color = Color(0.5, 0.3, 0.1)
		entry_panel.add_theme_stylebox_override("panel", entry_style)
		
		var sprite_rect = TextureRect.new()
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://assets/tileset.png")
		atlas.region = Rect2(data["x"], data["y"], 16, 16)
		sprite_rect.texture = atlas
		sprite_rect.scale = Vector2(3, 3) 
		sprite_rect.position = Vector2(20, 60) 
		entry_panel.add_child(sprite_rect)

		var drop_data = GameManager.item_db[data["drop"]]
		var drop_icon = TextureRect.new()
		var drop_atlas = AtlasTexture.new()
		drop_atlas.atlas = load("res://assets/tileset.png")
		drop_atlas.region = Rect2(drop_data["icon_x"], drop_data["icon_y"], 16, 16)
		drop_icon.texture = drop_atlas
		drop_icon.scale = Vector2(2.5, 2.5)
		drop_icon.position = Vector2(590, 60) 
		entry_panel.add_child(drop_icon)

		var text = Label.new()
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.text = "• " + data["name"] + "\n" + data["desc"] + "\nОпыт: " + str(data["xp"]) + "\nМатериал: " + drop_data["name"]
		text.position = Vector2(90, 15) 
		text.size = Vector2(480, 170) 
		text.add_theme_font_size_override("font_size", 22)
		text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		entry_panel.add_child(text)
		journal_content.add_child(entry_panel)

func _fill_materials():
	var material_counts = {}
	for item in GameManager.inventory:
		if item in GameManager.item_db: 
			if item in material_counts: material_counts[item] += 1
			else: material_counts[item] = 1
	if material_counts.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Вы пока не нашли материалов."
		empty_label.add_theme_font_size_override("font_size", 22)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		journal_content.add_child(empty_label)
		return
	for item_id in material_counts:
		var count = material_counts[item_id]
		var data = GameManager.item_db[item_id]
		var entry_panel = Panel.new()
		entry_panel.custom_minimum_size = Vector2(660, 80) 
		var entry_style = StyleBoxFlat.new()
		entry_style.bg_color = Color(0.2, 0.15, 0.1)
		entry_style.corner_radius_top_left = 5
		entry_style.corner_radius_top_right = 5
		entry_style.corner_radius_bottom_left = 5
		entry_style.corner_radius_bottom_right = 5
		entry_style.border_width_left = 2
		entry_style.border_width_right = 2
		entry_style.border_width_top = 2
		entry_style.border_width_bottom = 2
		entry_style.border_color = Color(0.5, 0.3, 0.1)
		entry_panel.add_theme_stylebox_override("panel", entry_style)
		var icon = TextureRect.new()
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://assets/tileset.png")
		atlas.region = Rect2(data["icon_x"], data["icon_y"], 16, 16) 
		icon.texture = atlas
		icon.scale = Vector2(3, 3)
		icon.position = Vector2(20, 15)
		entry_panel.add_child(icon)
		var text = Label.new()
		text.text = data["name"] + " (x" + str(count) + ")\n" + data["desc"]
		text.position = Vector2(90, 15) 
		text.add_theme_font_size_override("font_size", 22)
		text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		entry_panel.add_child(text)
		journal_content.add_child(entry_panel)

func _fill_items():
	var item_counts = {}
	for item in GameManager.inventory:
		if item not in GameManager.item_db:
			if item in item_counts: item_counts[item] += 1
			else: item_counts[item] = 1
	if item_counts.is_empty():
		var empty_label = Label.new()
		empty_label.text = "В сумке нет предметов."
		empty_label.add_theme_font_size_override("font_size", 22)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		journal_content.add_child(empty_label)
		return
	for item_id in item_counts:
		var count = item_counts[item_id]
		var entry_panel = Panel.new()
		entry_panel.custom_minimum_size = Vector2(660, 80) 
		var entry_style = StyleBoxFlat.new()
		entry_style.bg_color = Color(0.2, 0.15, 0.1)
		entry_style.corner_radius_top_left = 5
		entry_style.corner_radius_top_right = 5
		entry_style.corner_radius_bottom_left = 5
		entry_style.corner_radius_bottom_right = 5
		entry_style.border_width_left = 2
		entry_style.border_width_right = 2
		entry_style.border_width_top = 2
		entry_style.border_width_bottom = 2
		entry_style.border_color = Color(0.5, 0.3, 0.1)
		entry_panel.add_theme_stylebox_override("panel", entry_style)
		var icon = TextureRect.new()
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://assets/tileset.png")
		var item_data = {}
		if item_id == "health_potion":
			item_data = {"name": "Зелье лечения", "desc": "Восстанавливает 10 HP", "icon_x": 114, "icon_y": 145}
		else:
			item_data = {"name": item_id, "desc": "", "icon_x": 0, "icon_y": 0}
		atlas.region = Rect2(item_data["icon_x"], item_data["icon_y"], 16, 16) 
		icon.texture = atlas
		icon.scale = Vector2(3, 3)
		icon.position = Vector2(20, 15)
		entry_panel.add_child(icon)
		var text = Label.new()
		text.text = item_data["name"] + " (x" + str(count) + ")\n" + item_data["desc"]
		text.position = Vector2(90, 15) 
		text.add_theme_font_size_override("font_size", 22)
		text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		entry_panel.add_child(text)
		journal_content.add_child(entry_panel)

func _on_close_journal():
	journal_panel.visible = false

func create_inventory_ui():
	inv_panel = Panel.new()
	inv_panel.position = Vector2(440, 150)
	inv_panel.size = Vector2(400, 400)
	inv_panel.z_index = 100
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.05, 0.0) 
	style.border_width_left = 6
	style.border_width_right = 6
	style.border_width_top = 6
	style.border_width_bottom = 6
	style.border_color = Color(0.1, 0.0, 0.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	inv_panel.add_theme_stylebox_override("panel", style)
	inv_panel.visible = false
	ui_layer.add_child(inv_panel)
	
	var title = Label.new()
	title.text = "Инвентарь"
	title.position = Vector2(0, 20)
	title.size = Vector2(400, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	title.add_theme_color_override("font_outline_color", Color(0,0,0))
	title.add_theme_constant_override("outline_size", 4)
	if font_title: title.add_theme_font_override("font", font_title)
	inv_panel.add_child(title)
	
	inv_scroll = ScrollContainer.new()
	inv_scroll.position = Vector2(30, 80)
	inv_scroll.size = Vector2(340, 230)
	inv_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inv_panel.add_child(inv_scroll)
	inv_items_container = VBoxContainer.new()
	inv_items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_items_container.add_theme_constant_override("separation", 10)
	inv_scroll.add_child(inv_items_container)
	
	var close_btn = Button.new()
	close_btn.text = "Закрыть"
	close_btn.position = Vector2(125, 330)
	close_btn.size = Vector2(150, 50)
	close_btn.add_theme_font_size_override("font_size", 22)
	style_button(close_btn)
	close_btn.pressed.connect(func(): inv_panel.visible = false)
	inv_panel.add_child(close_btn)

func _on_open_inventory():
	inv_panel.visible = true
	for child in inv_items_container.get_children(): child.queue_free()
	var item_counts = {}
	for item in GameManager.inventory:
		if item in item_counts: item_counts[item] += 1
		else: item_counts[item] = 1
	if item_counts.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Инвентарь пуст."
		empty_label.add_theme_font_size_override("font_size", 22)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		inv_items_container.add_child(empty_label)
		return
	for item_id in item_counts:
		var count = item_counts[item_id]
		var card = Panel.new()
		card.custom_minimum_size = Vector2(310, 60) 
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.2, 0.15, 0.1)
		card_style.corner_radius_top_left = 5
		card_style.corner_radius_top_right = 5
		card_style.corner_radius_bottom_left = 5
		card_style.corner_radius_bottom_right = 5
		card.add_theme_stylebox_override("panel", card_style)
		inv_items_container.add_child(card)
		var row = HBoxContainer.new()
		row.position = Vector2(10, 10)
		row.size = Vector2(290, 40)
		row.add_theme_constant_override("separation", 15)
		card.add_child(row)
		var item_data = {}
		if item_id == "health_potion": item_data = {"name": "Зелье лечения", "icon_x": 114, "icon_y": 145}
		else: item_data = GameManager.item_db[item_id]
		var icon = TextureRect.new()
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://assets/tileset.png")
		atlas.region = Rect2(item_data["icon_x"], item_data["icon_y"], 16, 16)
		icon.texture = atlas
		icon.custom_minimum_size = Vector2(32, 32)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var text = Label.new()
		text.text = item_data["name"] + " x" + str(count)
		text.add_theme_font_size_override("font_size", 22)
		text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		row.add_child(text)

func create_shop_ui():
	shop_panel = Panel.new()
	shop_panel.position = Vector2(340, 50)
	shop_panel.size = Vector2(600, 620) 
	shop_panel.z_index = 100
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.05, 0.98) 
	style.border_width_left = 6
	style.border_width_right = 6
	style.border_width_top = 6
	style.border_width_bottom = 6
	style.border_color = Color(0.8, 0.5, 0.2) 
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	shop_panel.add_theme_stylebox_override("panel", style)
	shop_panel.visible = false
	ui_layer.add_child(shop_panel)
	
	var title = Label.new()
	title.text = "Лавка торговца"
	title.position = Vector2(0, 20)
	title.size = Vector2(600, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	title.add_theme_color_override("font_outline_color", Color(0,0,0))
	title.add_theme_constant_override("outline_size", 4)
	if font_title: title.add_theme_font_override("font", font_title)
	shop_panel.add_child(title)
	
	shop_gold_label = Label.new()
	shop_gold_label.position = Vector2(0, 70)
	shop_gold_label.size = Vector2(600, 30)
	shop_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_gold_label.add_theme_font_size_override("font_size", 24)
	shop_gold_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	shop_panel.add_child(shop_gold_label)
	
	var h_tabs = HBoxContainer.new()
	h_tabs.position = Vector2(150, 110)
	h_tabs.size = Vector2(300, 45)
	h_tabs.add_theme_constant_override("separation", 20)
	shop_panel.add_child(h_tabs)
	
	btn_shop_buy_tab = Button.new()
	btn_shop_buy_tab.text = "Купить"
	btn_shop_buy_tab.custom_minimum_size = Vector2(130, 45)
	btn_shop_buy_tab.add_theme_font_size_override("font_size", 20)
	style_button(btn_shop_buy_tab)
	btn_shop_buy_tab.pressed.connect(func(): _switch_shop_tab("buy"))
	h_tabs.add_child(btn_shop_buy_tab)
	
	btn_shop_sell_tab = Button.new()
	btn_shop_sell_tab.text = "Продать"
	btn_shop_sell_tab.custom_minimum_size = Vector2(130, 45)
	btn_shop_sell_tab.add_theme_font_size_override("font_size", 20)
	style_button(btn_shop_sell_tab)
	btn_shop_sell_tab.pressed.connect(func(): _switch_shop_tab("sell"))
	h_tabs.add_child(btn_shop_sell_tab)
	
	shop_scroll = ScrollContainer.new()
	shop_scroll.position = Vector2(50, 170)
	shop_scroll.size = Vector2(500, 350)
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_panel.add_child(shop_scroll)
	shop_content = VBoxContainer.new()
	shop_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_content.add_theme_constant_override("separation", 15)
	shop_scroll.add_child(shop_content)
	
	var btn_close = Button.new()
	btn_close.text = "Уйти"
	btn_close.position = Vector2(200, 540)
	btn_close.size = Vector2(200, 50)
	btn_close.add_theme_font_size_override("font_size", 22)
	style_button(btn_close)
	btn_close.pressed.connect(func(): shop_panel.visible = false)
	shop_panel.add_child(btn_close)

func _on_open_shop():
	shop_panel.visible = true
	_switch_shop_tab(current_shop_tab)

func _switch_shop_tab(tab_name):
	current_shop_tab = tab_name
	for child in shop_content.get_children(): child.queue_free()
	item_count_labels.clear() 
	if tab_name == "buy":
		btn_shop_buy_tab.modulate = Color(1.2, 1.2, 1.2)
		btn_shop_sell_tab.modulate = Color(0.7, 0.7, 0.7)
		_fill_shop_buy()
	else:
		btn_shop_buy_tab.modulate = Color(0.7, 0.7, 0.7)
		btn_shop_sell_tab.modulate = Color(1.2, 1.2, 1.2)
		_fill_shop_sell()
	update_shop_ui()

func _fill_shop_buy():
	for item in shop_inventory: create_shop_item_card(item)

func _fill_shop_sell():
	var sellable_items = {}
	for item in GameManager.inventory:
		if item != "health_potion": 
			if item in sellable_items: sellable_items[item] += 1
			else: sellable_items[item] = 1
	if sellable_items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "У вас нет трофеев на продажу."
		empty_label.add_theme_font_size_override("font_size", 22)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		shop_content.add_child(empty_label)
		return
	for item_id in sellable_items:
		var count = sellable_items[item_id]
		var data = GameManager.item_db[item_id]
		var card = Panel.new()
		card.custom_minimum_size = Vector2(460, 80)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.15, 0.1)
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.5, 0.3, 0.1)
		card.add_theme_stylebox_override("panel", style)
		shop_content.add_child(card)
		var icon = TextureRect.new()
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://assets/tileset.png")
		atlas.region = Rect2(data["icon_x"], data["icon_y"], 16, 16)
		icon.texture = atlas
		icon.scale = Vector2(2.5, 2.5)
		icon.position = Vector2(20, 20)
		card.add_child(icon)
		var text_label = Label.new()
		text_label.text = data["name"] + " (x" + str(count) + ")"
		text_label.position = Vector2(80, 25)
		text_label.size = Vector2(220, 30) 
		text_label.add_theme_font_size_override("font_size", 20)
		card.add_child(text_label)
		card.tooltip_text = data["desc"]
		text_label.tooltip_text = data["desc"]
		var btn_sell = Button.new()
		btn_sell.text = "Продать (" + str(data["sell_price"]) + ")"
		btn_sell.position = Vector2(310, 15) 
		btn_sell.size = Vector2(130, 50)
		btn_sell.add_theme_font_size_override("font_size", 16)
		style_button(btn_sell)
		btn_sell.pressed.connect(func(): _on_shop_sell_item(item_id))
		card.add_child(btn_sell)

func create_shop_item_card(item):
	var card = Panel.new()
	card.custom_minimum_size = Vector2(460, 80)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.3, 0.1)
	card.add_theme_stylebox_override("panel", style)
	shop_content.add_child(card)
	var icon = TextureRect.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = load("res://assets/tileset.png")
	atlas.region = Rect2(item["icon_x"], item["icon_y"], 16, 16)
	icon.texture = atlas
	icon.scale = Vector2(2.5, 2.5)
	icon.position = Vector2(20, 20)
	card.add_child(icon)
	var text_label = Label.new()
	text_label.text = item["name"]
	text_label.position = Vector2(80, 15)
	text_label.size = Vector2(220, 30)
	text_label.add_theme_font_size_override("font_size", 20)
	card.add_child(text_label)
	card.tooltip_text = item["desc"]
	text_label.tooltip_text = item["desc"]
	var count_label = Label.new()
	count_label.position = Vector2(80, 45)
	count_label.add_theme_font_size_override("font_size", 16)
	count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	card.add_child(count_label)
	if not item_count_labels.has(item["id"]): item_count_labels[item["id"]] = []
	item_count_labels[item["id"]].append(count_label)
	var btn_buy = Button.new()
	btn_buy.text = str(item["price"]) + " зол."
	btn_buy.position = Vector2(310, 15) 
	btn_buy.size = Vector2(130, 50)
	btn_buy.add_theme_font_size_override("font_size", 18)
	style_button(btn_buy)
	btn_buy.pressed.connect(func(): _on_shop_buy_item(item["id"], item["price"]))
	card.add_child(btn_buy)

func update_shop_ui():
	shop_gold_label.text = "Ваше золото: " + str(int(GameManager.gold))
	for item in shop_inventory:
		var item_id = item["id"]
		var count = 0
		for inv_item in GameManager.inventory:
			if inv_item == item_id: count += 1
		if item_count_labels.has(item_id):
			for label in item_count_labels[item_id]:
				if is_instance_valid(label): label.text = "В инвентаре: " + str(count) + " шт."

func _on_shop_buy_item(item_id, price):
	if GameManager.buy_item(item_id, price):
		update_shop_ui()
		update_info_ui()
	else: print("Не хватает золота!")

func _on_shop_sell_item(item_id):
	if GameManager.sell_item(item_id):
		_switch_shop_tab("sell") 
		update_info_ui()

func _on_go_to_expedition():
	GameManager.expedition_is_returning = false # СБРАСЫВАЕМ ФЛАГ ПРИ ВХОДЕ
	get_tree().change_scene_to_file("res://Expedition.tscn")

func create_pause_menu():
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0, 0, 0, 0.7)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.z_index = 200
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS 
	ui_layer.add_child(pause_overlay)

	pause_panel = Panel.new()
	pause_panel.position = Vector2(390, 160)
	pause_panel.size = Vector2(500, 400)
	pause_panel.z_index = 201
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.15, 0.1, 0.05, 0.98) 
	p_style.border_width_left = 6
	p_style.border_width_right = 6
	p_style.border_width_top = 6
	p_style.border_width_bottom = 6
	p_style.border_color = Color(0.8, 0.5, 0.2) 
	p_style.corner_radius_top_left = 15
	p_style.corner_radius_top_right = 15
	p_style.corner_radius_bottom_left = 15
	p_style.corner_radius_bottom_right = 15
	pause_panel.add_theme_stylebox_override("panel", p_style)
	pause_overlay.add_child(pause_panel)

	var p_title = Label.new()
	p_title.text = "ПАУЗА"
	p_title.position = Vector2(0, 30)
	p_title.size = Vector2(500, 50)
	p_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_title.add_theme_font_size_override("font_size", 40)
	p_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	if font_title: p_title.add_theme_font_override("font", font_title)
	pause_panel.add_child(p_title)

	var p_vbox = VBoxContainer.new()
	p_vbox.position = Vector2(100, 120)
	p_vbox.size = Vector2(300, 250)
	p_vbox.add_theme_constant_override("separation", 20)
	pause_panel.add_child(p_vbox)

	var btn_resume = Button.new()
	btn_resume.text = "Продолжить"
	btn_resume.custom_minimum_size = Vector2(300, 60)
	btn_resume.add_theme_font_size_override("font_size", 24)
	style_button(btn_resume)
	btn_resume.pressed.connect(_on_pause_resume)
	p_vbox.add_child(btn_resume)

	var btn_settings = Button.new()
	btn_settings.text = "Настройки"
	btn_settings.custom_minimum_size = Vector2(300, 60)
	btn_settings.add_theme_font_size_override("font_size", 24)
	style_button(btn_settings)
	btn_settings.pressed.connect(func(): print("Настройки в разработке"))
	p_vbox.add_child(btn_settings)

	var btn_exit = Button.new()
	btn_exit.text = "Выйти в меню"
	btn_exit.custom_minimum_size = Vector2(300, 60)
	btn_exit.add_theme_font_size_override("font_size", 24)
	style_button(btn_exit)
	btn_exit.pressed.connect(_on_pause_exit)
	p_vbox.add_child(btn_exit)

	confirm_panel = Panel.new()
	confirm_panel.position = Vector2(440, 200)
	confirm_panel.size = Vector2(400, 250)
	confirm_panel.z_index = 202
	confirm_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	confirm_panel.add_theme_stylebox_override("panel", p_style)
	confirm_panel.visible = false
	pause_overlay.add_child(confirm_panel)

	var c_title = Label.new()
	c_title.text = "Вы уверены?"
	c_title.position = Vector2(0, 30)
	c_title.size = Vector2(400, 40)
	c_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_title.add_theme_font_size_override("font_size", 28)
	c_title.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	if font_title: c_title.add_theme_font_override("font", font_title)
	confirm_panel.add_child(c_title)

	var c_hbox = HBoxContainer.new()
	c_hbox.position = Vector2(50, 120)
	c_hbox.size = Vector2(300, 60)
	c_hbox.add_theme_constant_override("separation", 20)
	confirm_panel.add_child(c_hbox)

	var btn_yes = Button.new()
	btn_yes.text = "Да, выйти"
	btn_yes.custom_minimum_size = Vector2(130, 60)
	btn_yes.add_theme_font_size_override("font_size", 20)
	style_button(btn_yes)
	btn_yes.pressed.connect(_on_confirm_exit_yes)
	c_hbox.add_child(btn_yes)

	var btn_no = Button.new()
	btn_no.text = "Отмена"
	btn_no.custom_minimum_size = Vector2(130, 60)
	btn_no.add_theme_font_size_override("font_size", 20)
	style_button(btn_no)
	btn_no.pressed.connect(_on_confirm_exit_no)
	c_hbox.add_child(btn_no)

func _on_pause_resume():
	pause_overlay.visible = false
	get_tree().paused = false

func _on_pause_exit():
	pause_panel.visible = false
	confirm_panel.visible = true

func _on_confirm_exit_yes():
	get_tree().paused = false
	GameManager.save_game()
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _on_confirm_exit_no():
	confirm_panel.visible = false
	pause_panel.visible = true
