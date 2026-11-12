extends Control

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

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.2, 0.3, 0.2))
	gradient.set_color(1, Color(0.1, 0.15, 0.1)) 
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = gradient
	grad_tex.fill_from = Vector2(0, 1)
	grad_tex.fill_to = Vector2(0, 0)
	
	var bg = TextureRect.new()
	bg.texture = grad_tex
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var inner_ground = Polygon2D.new()
	inner_ground.color = Color(0.65, 0.6, 0.5)
	var inner_points = PackedVector2Array()
	for i in range(60):
		var angle = (i / 60.0) * TAU
		inner_points.append(Vector2(cos(angle) * 680, sin(angle) * 480) + Vector2(960, 540))
	inner_ground.polygon = inner_points
	add_child(inner_ground)

	var outer_wall = Line2D.new()
	outer_wall.points = inner_points
	outer_wall.closed = true
	outer_wall.width = 40
	outer_wall.default_color = Color(0.3, 0.3, 0.3)
	add_child(outer_wall)

	var roads = [
		[Vector2(960, 540), Vector2(960, 100)],
		[Vector2(960, 540), Vector2(960, 980)],
		[Vector2(960, 540), Vector2(400, 540)],
		[Vector2(960, 540), Vector2(1520, 540)]
	]
	for r in roads:
		var road = Line2D.new()
		road.points = PackedVector2Array(r)
		road.width = 80
		road.default_color = Color(0.55, 0.45, 0.35)
		add_child(road)

	var plaza = Polygon2D.new()
	plaza.color = Color(0.6, 0.55, 0.45)
	var plaza_points = PackedVector2Array()
	for i in range(40):
		var angle = (i / 40.0) * TAU
		plaza_points.append(Vector2(cos(angle) * 200, sin(angle) * 150) + Vector2(960, 540))
	plaza.polygon = plaza_points
	add_child(plaza)

	var fountain_base = Polygon2D.new()
	fountain_base.color = Color(0.45, 0.45, 0.45)
	var f_points = PackedVector2Array()
	for i in range(30):
		var angle = (i / 30.0) * TAU
		f_points.append(Vector2(cos(angle) * 50, sin(angle) * 40) + Vector2(960, 540))
	fountain_base.polygon = f_points
	add_child(fountain_base)

	var fountain_water = Polygon2D.new()
	fountain_water.color = Color(0.3, 0.6, 0.8)
	var w_points = PackedVector2Array()
	for i in range(30):
		var angle = (i / 30.0) * TAU
		w_points.append(Vector2(cos(angle) * 35, sin(angle) * 25) + Vector2(960, 540))
	fountain_water.polygon = w_points
	add_child(fountain_water)

	draw_house(550, 250, 120, 90, Color(0.5, 0.4, 0.35), Color(0.3, 0.3, 0.3), "Кузнец") 
	draw_house(1200, 250, 110, 80, Color(0.8, 0.7, 0.6), Color(0.6, 0.2, 0.2), "Лавка")
	draw_house(520, 720, 150, 110, Color(0.7, 0.6, 0.5), Color(0.2, 0.3, 0.6), "Гильдия")
	draw_house(1250, 720, 130, 100, Color(0.85, 0.75, 0.65), Color(0.5, 0.2, 0.1), "Таверна")
	draw_house(750, 350, 70, 60, Color(0.8, 0.7, 0.6), Color(0.4, 0.2, 0.2))
	draw_house(1050, 380, 80, 65, Color(0.8, 0.7, 0.6), Color(0.6, 0.3, 0.3))
	draw_house(750, 680, 75, 60, Color(0.8, 0.7, 0.6), Color(0.3, 0.4, 0.3))
	draw_house(1050, 680, 70, 55, Color(0.8, 0.7, 0.6), Color(0.5, 0.3, 0.2))
	draw_house(850, 250, 60, 50, Color(0.8, 0.7, 0.6), Color(0.4, 0.2, 0.2))

	draw_tree(350, 300)
	draw_tree(380, 350)
	draw_tree(1600, 300)
	draw_tree(1550, 350)
	draw_tree(350, 800)
	draw_tree(1600, 800)
	draw_tree(800, 150)
	draw_tree(1100, 150)
	draw_tree(800, 950)
	draw_tree(1100, 950)

	for i in range(5):
		var fence = ColorRect.new()
		fence.color = Color(0.3, 0.2, 0.1)
		fence.position = Vector2(400 + i*40, 600)
		fence.size = Vector2(10, 40)
		add_child(fence)
		
		var fence_horiz = ColorRect.new()
		fence_horiz.color = Color(0.25, 0.15, 0.05)
		fence_horiz.position = Vector2(400, 610)
		fence_horiz.size = Vector2(200, 6)
		add_child(fence_horiz)

	create_wooden_hud()
	
	create_forest_button(Vector2(1700, 500))
	create_shop_button(Vector2(1205, 220)) 
	create_inventory_button(Vector2(20, 180)) 
	create_journal_button(Vector2(20, 280))
	
	create_journal_ui()
	create_shop_ui()
	create_inventory_ui()
	create_pause_menu()
	
	SoundManager.connect_ui_sounds(self)

func draw_house(x, y, w, h, wall_color, roof_color, sign_name = ""):
	var shadow = ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.position = Vector2(x + 15, y + 15)
	shadow.size = Vector2(w, h)
	add_child(shadow)

	var body = ColorRect.new()
	body.color = wall_color
	body.position = Vector2(x, y)
	body.size = Vector2(w, h)
	add_child(body)
	
	for i in range(1, int(h/20)):
		var log_line = ColorRect.new()
		log_line.color = Color(0, 0, 0, 0.1)
		log_line.position = Vector2(x, y + i*20)
		log_line.size = Vector2(w, 2)
		add_child(log_line)

	var roof = Polygon2D.new()
	roof.polygon = PackedVector2Array([
		Vector2(x - 10, y), 
		Vector2(x + w / 2, y - h * 0.8), 
		Vector2(x + w + 10, y)
	])
	roof.color = roof_color
	add_child(roof)
	
	var win1 = ColorRect.new()
	win1.color = Color(1.0, 0.9, 0.4)
	win1.position = Vector2(x + w * 0.15, y + h * 0.3)
	win1.size = Vector2(w * 0.25, h * 0.25)
	add_child(win1)
	
	var win2 = ColorRect.new()
	win2.color = Color(1.0, 0.9, 0.4)
	win2.position = Vector2(x + w * 0.6, y + h * 0.3)
	win2.size = Vector2(w * 0.25, h * 0.25)
	add_child(win2)
	
	var door = ColorRect.new()
	door.color = Color(0.2, 0.1, 0.05)
	door.position = Vector2(x + w * 0.35, y + h * 0.6)
	door.size = Vector2(w * 0.3, h * 0.4)
	add_child(door)
	
	if sign_name != "":
		var sign_label = Label.new()
		sign_label.text = sign_name
		sign_label.position = Vector2(x, y - h * 0.6)
		sign_label.size = Vector2(w, 30)
		sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign_label.add_theme_font_size_override("font_size", 18)
		sign_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
		sign_label.add_theme_color_override("font_outline_color", Color(0,0,0))
		sign_label.add_theme_constant_override("outline_size", 4)
		sign_label.add_theme_font_override("font", load("res://assets/fonts/Rubik-Regular.ttf"))
		add_child(sign_label)

func draw_tree(x, y):
	var tree = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(20):
		var angle = (i / 20.0) * TAU
		pts.append(Vector2(cos(angle) * 45, sin(angle) * 45) + Vector2(x, y))
	tree.polygon = pts
	tree.color = Color(0.15, 0.4, 0.15)
	add_child(tree)

func add_outline(poly: Polygon2D, width: float = 4.0):
	var line = Line2D.new()
	line.points = poly.polygon
	line.closed = true
	line.width = width
	line.default_color = Color(0, 0, 0)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	poly.get_parent().add_child(line)
	poly.get_parent().move_child(line, poly.get_index())

func create_wooden_hud():
	var hud = Panel.new()
	hud.position = Vector2(20, 20)
	hud.size = Vector2(300, 150) 
	hud.z_index = 10
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.2, 0.1) 
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.15, 0.05, 0.0) 
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	hud.add_theme_stylebox_override("panel", style)
	add_child(hud)

	for i in range(4):
		var plank = ColorRect.new()
		plank.color = Color(0.45, 0.3, 0.15) if i % 2 == 0 else Color(0.4, 0.25, 0.1)
		plank.position = Vector2(3, 3 + i * 36) 
		plank.size = Vector2(294, 36)
		hud.add_child(plank)

	for pos in [Vector2(6, 6), Vector2(290, 6), Vector2(6, 140), Vector2(290, 140)]:
		var nail = ColorRect.new()
		nail.color = Color(0.2, 0.2, 0.2)
		nail.position = pos
		nail.size = Vector2(4, 4)
		hud.add_child(nail)

	var circle = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(30):
		var angle = (i / 30.0) * TAU
		pts.append(Vector2(cos(angle) * 55, sin(angle) * 55) + Vector2(70, 75)) 
	circle.polygon = pts
	circle.color = Color(0.25, 0.15, 0.05) 
	hud.add_child(circle)
	
	var circle_border = Line2D.new()
	circle_border.points = pts
	circle_border.closed = true
	circle_border.width = 4
	circle_border.default_color = Color(0.15, 0.05, 0.0)
	hud.add_child(circle_border)

	var avatar = TextureRect.new()
	var avatar_atlas = AtlasTexture.new()
	avatar_atlas.atlas = load("res://assets/tileset.png")
	avatar_atlas.region = Rect2(16, 128, 16, 16) 
	avatar.texture = avatar_atlas
	avatar.scale = Vector2(5.5, 5.5) 
	avatar.position = Vector2(26, 31) 
	hud.add_child(avatar)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(145, 10) 
	vbox.size = Vector2(140, 130)
	vbox.add_theme_constant_override("separation", 6)
	hud.add_child(vbox)

	var h_info = HBoxContainer.new()
	h_info.add_theme_constant_override("separation", 10)
	
	var level_label = Label.new()
	level_label.text = "Ур. 1" # СТАТИЧНЫЙ УРОВЕНЬ
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) 
	level_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	level_label.add_theme_constant_override("outline_size", 4)
	h_info.add_child(level_label)

	var rank_label = Label.new()
	rank_label.text = "Ранг F" # СТАТИЧНЫЙ РАНГ
	rank_label.add_theme_font_size_override("font_size", 20)
	rank_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9)) 
	rank_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	rank_label.add_theme_constant_override("outline_size", 4)
	h_info.add_child(rank_label)
	
	vbox.add_child(h_info)

	var line = ColorRect.new()
	line.color = Color(0.2, 0.1, 0.05)
	line.custom_minimum_size = Vector2(140, 2)
	vbox.add_child(line)

	var h_hp = HBoxContainer.new()
	h_hp.add_theme_constant_override("separation", 8)
	var icon_hp = create_animated_icon("hp", 1, 50)
	h_hp.add_child(icon_hp)
	hp_label = create_stat_label()
	h_hp.add_child(hp_label)
	vbox.add_child(h_hp)

	var h_gold = HBoxContainer.new()
	h_gold.add_theme_constant_override("separation", 8)
	var icon_gold = create_animated_icon("gold", 1, 65)
	h_gold.add_child(icon_gold)
	gold_label = create_stat_label()
	h_gold.add_child(gold_label)
	vbox.add_child(h_gold)

	var h_xp = HBoxContainer.new()
	h_xp.add_theme_constant_override("separation", 8)
	var icon_xp = create_static_icon("res://assets/tileset.png", Rect2(114, 161, 16, 16))
	h_xp.add_child(icon_xp)
	xp_label = create_stat_label()
	h_xp.add_child(xp_label)
	vbox.add_child(h_xp)

	update_info_ui()
	animate_icons_loop()

func create_stat_label() -> Label:
	var lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl

func create_forest_button(pos: Vector2):
	var btn = Button.new()
	btn.position = pos
	btn.size = Vector2(100, 100)
	btn.z_index = 10
	btn.tooltip_text = "Выйти в лес"
	style_button(btn)
	btn.pressed.connect(_on_go_to_expedition)
	add_child(btn)

	var tree = Polygon2D.new()
	tree.polygon = PackedVector2Array([Vector2(50, 10), Vector2(90, 60), Vector2(10, 60)])
	tree.color = Color(0.1, 0.5, 0.1)
	btn.add_child(tree)
	add_outline(tree, 4.0)
	
	var tree2 = Polygon2D.new()
	tree2.polygon = PackedVector2Array([Vector2(50, 25), Vector2(75, 80), Vector2(25, 80)])
	tree2.color = Color(0.1, 0.6, 0.1)
	btn.add_child(tree2)
	add_outline(tree2, 4.0)

	var trunk = ColorRect.new()
	trunk.color = Color(0.4, 0.2, 0.1)
	trunk.position = Vector2(45, 75)
	trunk.size = Vector2(10, 15)
	trunk.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	btn.add_child(trunk)

func create_shop_button(pos: Vector2):
	var btn = Button.new()
	btn.position = pos
	btn.size = Vector2(100, 100)
	btn.z_index = 10
	btn.tooltip_text = "Лавка торговца"
	style_button(btn)
	btn.pressed.connect(_on_open_shop)
	add_child(btn)

	var coin = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(20):
		var angle = (i / 20.0) * TAU
		pts.append(Vector2(cos(angle) * 30, sin(angle) * 30) + Vector2(50, 50))
	coin.polygon = pts
	coin.color = Color(1.0, 0.8, 0.2)
	btn.add_child(coin)
	add_outline(coin, 3.0)

func create_animated_icon(type: String, start_x: int, start_y: int) -> TextureRect:
	var icon = TextureRect.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = load("res://assets/objects.png")
	atlas.region = Rect2(start_x, start_y, 13, 13)
	icon.texture = atlas
	icon.custom_minimum_size = Vector2(22, 22) 
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
	icon.custom_minimum_size = Vector2(22, 22)
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
	xp_label.text = str(int(GameManager.xp)) # Просто опыт, без "х/у"

func style_button(btn):
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.2, 0.15, 0.1, 0.9) 
	normal.border_width_left = 3
	normal.border_width_right = 3
	normal.border_width_top = 3
	normal.border_width_bottom = 3
	normal.border_color = Color(0.8, 0.5, 0.2) 
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.35, 0.2, 0.1, 0.95)
	hover.border_width_left = 3
	hover.border_width_right = 3
	hover.border_width_top = 3
	hover.border_width_bottom = 3
	hover.border_color = Color(1.0, 0.7, 0.3)
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("hover", hover)
	
	var disabled = StyleBoxFlat.new()
	disabled.bg_color = Color(0.15, 0.15, 0.15)
	disabled.border_width_left = 3
	disabled.border_width_right = 3
	disabled.border_width_top = 3
	disabled.border_width_bottom = 3
	disabled.border_color = Color(0.3, 0.3, 0.3)
	disabled.corner_radius_top_left = 8
	disabled.corner_radius_top_right = 8
	disabled.corner_radius_bottom_left = 8
	disabled.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("disabled", disabled)

func create_inventory_button(pos: Vector2):
	var btn = Button.new()
	btn.position = pos
	btn.size = Vector2(80, 80)
	btn.z_index = 10
	btn.tooltip_text = "Инвентарь"
	style_button(btn)
	btn.pressed.connect(_on_open_inventory)
	add_child(btn)
	var bag = Polygon2D.new()
	bag.polygon = PackedVector2Array([Vector2(25, 25), Vector2(55, 25), Vector2(65, 60), Vector2(50, 75), Vector2(30, 75), Vector2(15, 60)])
	bag.color = Color(0.8, 0.2, 0.15) 
	btn.add_child(bag)
	add_outline(bag, 4.0)
	var cinch = ColorRect.new()
	cinch.color = Color(0.3, 0.15, 0.1) 
	cinch.position = Vector2(25, 20)
	cinch.size = Vector2(30, 8)
	cinch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(cinch)
	var symbol = Polygon2D.new()
	symbol.polygon = PackedVector2Array([Vector2(40, 40), Vector2(48, 50), Vector2(40, 60), Vector2(32, 50)])
	symbol.color = Color(1.0, 0.8, 0.2)
	btn.add_child(symbol)
	add_outline(symbol, 2.0)

func create_journal_button(pos: Vector2):
	var btn = Button.new()
	btn.position = pos
	btn.size = Vector2(80, 80)
	btn.z_index = 10
	btn.tooltip_text = "Журнал"
	style_button(btn) 
	btn.pressed.connect(_on_open_journal)
	add_child(btn)
	book_icon = TextureRect.new()
	book_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	book_atlas = AtlasTexture.new()
	book_atlas.atlas = load("res://assets/objects.png") 
	book_atlas.region = Rect2(243, 0, 16, 20) 
	book_icon.texture = book_atlas
	book_icon.scale = Vector2(4, 4) 
	book_icon.position = Vector2(8, 0) 
	btn.add_child(book_icon)

func create_journal_ui():
	journal_panel = Panel.new()
	journal_panel.position = Vector2(560, 140) 
	journal_panel.size = Vector2(800, 800) 
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
	add_child(journal_panel)

	var title = Label.new()
	title.text = "Журнал Авантюриста"
	title.position = Vector2(0, 20)
	title.size = Vector2(800, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	title.add_theme_font_override("font", load("res://assets/fonts/Rubik-Regular.ttf"))
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
	journal_scroll.size = Vector2(700, 570) 
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
	await animate_book(true)
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
		empty_label.text = "Вы пока никого не встретили. Отправляйтесь в лес!"
		empty_label.add_theme_font_size_override("font_size", 22)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		journal_content.add_child(empty_label)
		return
	for enemy_id in GameManager.discovered_enemies:
		var data = GameManager.enemy_db[enemy_id]
		var entry_panel = Panel.new()
		entry_panel.custom_minimum_size = Vector2(660, 190)
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
		sprite_rect.position = Vector2(20, 55) 
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
		text.size = Vector2(480, 160) 
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
		entry_panel.custom_minimum_size = Vector2(660, 90) 
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
		icon.position = Vector2(20, 20)
		entry_panel.add_child(icon)
		var text = Label.new()
		text.text = data["name"] + " (x" + str(count) + ")\n" + data["desc"]
		text.position = Vector2(90, 20) 
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
		entry_panel.custom_minimum_size = Vector2(660, 90) 
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
		icon.position = Vector2(20, 20)
		entry_panel.add_child(icon)
		var text = Label.new()
		text.text = item_data["name"] + " (x" + str(count) + ")\n" + item_data["desc"]
		text.position = Vector2(90, 20) 
		text.add_theme_font_size_override("font_size", 22)
		text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		entry_panel.add_child(text)
		journal_content.add_child(entry_panel)

func _on_close_journal():
	journal_panel.visible = false
	await animate_book(false)

func animate_book(open: bool):
	if open:
		book_atlas.region = Rect2(259, 0, 16, 20)
		await get_tree().create_timer(0.08).timeout
		book_atlas.region = Rect2(275, 0, 16, 20)
		await get_tree().create_timer(0.08).timeout
		book_atlas.region = Rect2(288, 0, 16, 20)
		await get_tree().create_timer(0.08).timeout
		book_atlas.region = Rect2(304, 0, 16, 20)
	else:
		book_atlas.region = Rect2(288, 0, 16, 20)
		await get_tree().create_timer(0.08).timeout
		book_atlas.region = Rect2(275, 0, 16, 20)
		await get_tree().create_timer(0.08).timeout
		book_atlas.region = Rect2(259, 0, 16, 20)
		await get_tree().create_timer(0.08).timeout
		book_atlas.region = Rect2(243, 0, 16, 20)

func create_inventory_ui():
	inv_panel = Panel.new()
	inv_panel.position = Vector2(760, 250)
	inv_panel.size = Vector2(400, 500)
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
	add_child(inv_panel)
	for i in range(6):
		var plank = ColorRect.new()
		plank.color = Color(0.45, 0.3, 0.15) if i % 2 == 0 else Color(0.4, 0.25, 0.1)
		plank.position = Vector2(6, 6 + i * 81) 
		plank.size = Vector2(388, 81)
		inv_panel.add_child(plank)
	for pos in [Vector2(12, 12), Vector2(380, 12), Vector2(12, 480), Vector2(380, 480)]:
		var nail = ColorRect.new()
		nail.color = Color(0.15, 0.15, 0.15)
		nail.position = pos
		nail.size = Vector2(8, 8)
		inv_panel.add_child(nail)
	var title = Label.new()
	title.text = "Инвентарь"
	title.position = Vector2(0, 20)
	title.size = Vector2(400, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	title.add_theme_color_override("font_outline_color", Color(0,0,0))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_font_override("font", load("res://assets/fonts/Rubik-Regular.ttf"))
	inv_panel.add_child(title)
	inv_scroll = ScrollContainer.new()
	inv_scroll.position = Vector2(30, 80)
	inv_scroll.size = Vector2(340, 320)
	inv_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inv_panel.add_child(inv_scroll)
	inv_items_container = VBoxContainer.new()
	inv_items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inv_items_container.add_theme_constant_override("separation", 10)
	inv_scroll.add_child(inv_items_container)
	var close_btn = Button.new()
	close_btn.text = "Закрыть"
	close_btn.position = Vector2(125, 420)
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
		card.custom_minimum_size = Vector2(310, 70) 
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.2, 0.15, 0.1)
		card_style.corner_radius_top_left = 5
		card_style.corner_radius_top_right = 5
		card_style.corner_radius_bottom_left = 5
		card_style.corner_radius_bottom_right = 5
		card_style.border_width_left = 2
		card_style.border_width_right = 2
		card_style.border_width_top = 2
		card_style.border_width_bottom = 2
		card_style.border_color = Color(0.5, 0.3, 0.1)
		card.add_theme_stylebox_override("panel", card_style)
		inv_items_container.add_child(card)
		var row = HBoxContainer.new()
		row.position = Vector2(10, 15)
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
	shop_panel.position = Vector2(660, 200)
	shop_panel.size = Vector2(600, 680) 
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
	add_child(shop_panel)
	var title = Label.new()
	title.text = "Лавка торговца"
	title.position = Vector2(0, 20)
	title.size = Vector2(600, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	title.add_theme_color_override("font_outline_color", Color(0,0,0))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_font_override("font", load("res://assets/fonts/Rubik-Regular.ttf"))
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
	shop_scroll.size = Vector2(500, 380)
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_panel.add_child(shop_scroll)
	shop_content = VBoxContainer.new()
	shop_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_content.add_theme_constant_override("separation", 15)
	shop_scroll.add_child(shop_content)
	var btn_close = Button.new()
	btn_close.text = "Уйти"
	btn_close.position = Vector2(200, 580)
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
		card.custom_minimum_size = Vector2(460, 90)
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
		icon.position = Vector2(20, 25)
		card.add_child(icon)
		var text_label = Label.new()
		text_label.text = data["name"] + " (x" + str(count) + ")"
		text_label.position = Vector2(80, 30)
		text_label.size = Vector2(220, 30) 
		text_label.add_theme_font_size_override("font_size", 22)
		card.add_child(text_label)
		card.tooltip_text = data["desc"]
		text_label.tooltip_text = data["desc"]
		var btn_sell = Button.new()
		btn_sell.text = "Продать (" + str(data["sell_price"]) + ")"
		btn_sell.position = Vector2(310, 20) 
		btn_sell.size = Vector2(130, 50)
		btn_sell.add_theme_font_size_override("font_size", 18)
		style_button(btn_sell)
		btn_sell.pressed.connect(func(): _on_shop_sell_item(item_id))
		card.add_child(btn_sell)

func create_shop_item_card(item):
	var card = Panel.new()
	card.custom_minimum_size = Vector2(460, 90)
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
	icon.position = Vector2(20, 25)
	card.add_child(icon)
	var text_label = Label.new()
	text_label.text = item["name"]
	text_label.position = Vector2(80, 20)
	text_label.size = Vector2(220, 30)
	text_label.add_theme_font_size_override("font_size", 22)
	card.add_child(text_label)
	card.tooltip_text = item["desc"]
	text_label.tooltip_text = item["desc"]
	var count_label = Label.new()
	count_label.position = Vector2(80, 50)
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	card.add_child(count_label)
	if not item_count_labels.has(item["id"]): item_count_labels[item["id"]] = []
	item_count_labels[item["id"]].append(count_label)
	var btn_buy = Button.new()
	btn_buy.text = str(item["price"]) + " зол."
	btn_buy.position = Vector2(310, 20) 
	btn_buy.size = Vector2(130, 50)
	btn_buy.add_theme_font_size_override("font_size", 20)
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
	get_tree().change_scene_to_file("res://Expedition.tscn")

func create_pause_menu():
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0, 0, 0, 0.7)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.z_index = 200
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS 
	add_child(pause_overlay)

	pause_panel = Panel.new()
	pause_panel.position = Vector2(710, 340)
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
	p_title.add_theme_font_override("font", load("res://assets/fonts/Rubik-Regular.ttf"))
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
	confirm_panel.position = Vector2(760, 390)
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
	c_title.add_theme_font_override("font", load("res://assets/fonts/Rubik-Regular.ttf"))
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

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if pause_overlay.visible:
			_on_pause_resume()
		else:
			pause_overlay.visible = true
			pause_panel.visible = true
			confirm_panel.visible = false
			get_tree().paused = true

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
