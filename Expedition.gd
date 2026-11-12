extends Control

var bg_scroll_node: Node2D
var player_sprite: Sprite2D
var bg_tween: Tween
var bounce_tween: Tween
var sway_tween: Tween

var event_panel: Panel
var event_label: Label
var btn_continue: Button
var btn_fight: Button
var btn_town: Button

var hp_label: Label
var gold_label: Label
var xp_label: Label
var hp_atlas: AtlasTexture
var gold_atlas: AtlasTexture

var pause_overlay: ColorRect
var pause_panel: Panel
var confirm_panel: Panel

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	bg_scroll_node = Node2D.new()
	add_child(bg_scroll_node)

	var grad = Gradient.new()
	grad.set_color(0, Color(0.4, 0.6, 0.8))
	grad.set_color(1, Color(0.2, 0.3, 0.4))
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0, 1)
	grad_tex.fill_to = Vector2(0, 0)

	var sky = TextureRect.new()
	sky.texture = grad_tex
	sky.size = Vector2(3840, 720)
	bg_scroll_node.add_child(sky)

	for i in range(20):
		var cloud = Polygon2D.new()
		var cx = randf_range(0, 3840)
		var cy = randf_range(50, 400)
		cloud.polygon = PackedVector2Array([
			Vector2(cx, cy), Vector2(cx + 60, cy - 30), Vector2(cx + 120, cy), 
			Vector2(cx + 90, cy + 30), Vector2(cx + 30, cy + 30)
		])
		cloud.color = Color(0.9, 0.9, 0.9, 0.6) 
		bg_scroll_node.add_child(cloud)

	var ground = ColorRect.new()
	ground.color = Color(0.2, 0.35, 0.2)
	ground.position = Vector2(0, 720)
	ground.size = Vector2(3840, 360)
	bg_scroll_node.add_child(ground)

	var path = ColorRect.new()
	path.color = Color(0.45, 0.4, 0.3)
	path.position = Vector2(0, 750)
	path.size = Vector2(3840, 150)
	bg_scroll_node.add_child(path)

	for i in range(50):
		var tx = i * 80 + randf_range(-20, 20)
		var ty = 700
		var size = randf_range(80, 180)
		draw_bg_tree(tx, ty, size)

	for i in range(80):
		var bx = randf_range(0, 3840)
		var by = randf_range(720, 850)
		draw_bush(bx, by)

	create_wooden_hud()

	btn_town = Button.new()
	btn_town.text = "В город"
	btn_town.position = Vector2(1600, 950)
	btn_town.size = Vector2(200, 60)
	btn_town.add_theme_font_size_override("font_size", 22)
	btn_town.add_theme_color_override("font_outline_color", Color(0,0,0))
	btn_town.add_theme_constant_override("outline_size", 4)
	btn_town.z_index = 10
	style_button(btn_town)
	btn_town.pressed.connect(_on_return_to_town)
	add_child(btn_town)

	player_sprite = Sprite2D.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = load("res://assets/tileset.png")
	atlas.region = Rect2(16, 128, 16, 16)
	player_sprite.texture = atlas
	player_sprite.scale = Vector2(6.0, 6.0) 
	player_sprite.position = Vector2(960, 750)
	player_sprite.z_index = 5
	add_child(player_sprite)

	create_event_ui()
	create_pause_menu() 
	start_walking_sequence()
	
	SoundManager.connect_ui_sounds(self)

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
	level_label.text = "Ур. 1"
	level_label.add_theme_font_size_override("font_size", 20) 
	level_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) 
	level_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	level_label.add_theme_constant_override("outline_size", 4)
	h_info.add_child(level_label)

	var rank_label = Label.new()
	rank_label.text = "Ранг F"
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

func create_stat_label() -> Label:
	var lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl

func update_info_ui():
	hp_label.text = str(int(GameManager.player_hp)) + "/" + str(int(GameManager.max_hp))
	gold_label.text = str(int(GameManager.gold))
	xp_label.text = str(int(GameManager.xp))

func draw_bg_tree(x, y, size):
	var tree = Polygon2D.new()
	tree.polygon = PackedVector2Array([
		Vector2(x, y), 
		Vector2(x + size/2, y - size), 
		Vector2(x + size, y)
	])
	tree.color = Color(0.1, 0.25, 0.1) 
	bg_scroll_node.add_child(tree)
	
	var tree2 = Polygon2D.new()
	tree2.polygon = PackedVector2Array([
		Vector2(x + size*0.1, y - size*0.3), 
		Vector2(x + size/2, y - size*1.2), 
		Vector2(x + size*0.9, y - size*0.3)
	])
	tree2.color = Color(0.15, 0.35, 0.15) 
	bg_scroll_node.add_child(tree2)

	var tree3 = Polygon2D.new()
	tree3.polygon = PackedVector2Array([
		Vector2(x + size*0.2, y - size*0.6), 
		Vector2(x + size/2, y - size*1.4), 
		Vector2(x + size*0.8, y - size*0.6)
	])
	tree3.color = Color(0.2, 0.45, 0.2) 
	bg_scroll_node.add_child(tree3)
	
	var trunk = ColorRect.new()
	trunk.color = Color(0.2, 0.1, 0.05)
	trunk.position = Vector2(x + size/2 - 8, y)
	trunk.size = Vector2(16, 30)
	bg_scroll_node.add_child(trunk)

func draw_bush(x, y):
	var bush = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(3):
		var offset = Vector2(randf_range(-20, 20), randf_range(-15, 15))
		for a in range(0, 360, 45):
			pts.append(offset + Vector2(cos(deg_to_rad(a)) * randf_range(15, 30), sin(deg_to_rad(a)) * randf_range(15, 25)))
	bush.polygon = pts
	bush.position = Vector2(x, y)
	bush.color = Color(0.1, 0.3, 0.1) 
	bg_scroll_node.add_child(bush)

func create_event_ui():
	event_panel = Panel.new()
	event_panel.position = Vector2(660, 300)
	event_panel.size = Vector2(600, 300) 
	event_panel.z_index = 100
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
	event_panel.add_theme_stylebox_override("panel", style)
	event_panel.visible = false
	add_child(event_panel)

	for i in range(4):
		var plank = ColorRect.new()
		plank.color = Color(0.45, 0.3, 0.15) if i % 2 == 0 else Color(0.4, 0.25, 0.1)
		plank.position = Vector2(6, 6 + i * 72) 
		plank.size = Vector2(588, 72)
		event_panel.add_child(plank)

	for pos in [Vector2(12, 12), Vector2(580, 12), Vector2(12, 280), Vector2(580, 280)]:
		var nail = ColorRect.new()
		nail.color = Color(0.15, 0.15, 0.15)
		nail.position = pos
		nail.size = Vector2(8, 8)
		event_panel.add_child(nail)

	event_label = Label.new()
	event_label.position = Vector2(0, 40)
	event_label.size = Vector2(600, 40)
	event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_label.add_theme_font_size_override("font_size", 28)
	event_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	event_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	event_label.add_theme_constant_override("outline_size", 4)
	event_label.add_theme_font_override("font", load("res://assets/fonts/Rubik-Regular.ttf"))
	event_panel.add_child(event_label)

	var hbox = HBoxContainer.new()
	hbox.position = Vector2(100, 160) 
	hbox.size = Vector2(400, 60)
	hbox.add_theme_constant_override("separation", 20) 
	event_panel.add_child(hbox)

	btn_fight = Button.new()
	btn_fight.text = "В бой!"
	btn_fight.custom_minimum_size = Vector2(180, 60) 
	btn_fight.add_theme_font_size_override("font_size", 22)
	btn_fight.add_theme_color_override("font_outline_color", Color(0,0,0))
	btn_fight.add_theme_constant_override("outline_size", 4)
	style_button(btn_fight) 
	btn_fight.pressed.connect(_on_find_enemy)
	hbox.add_child(btn_fight)

	btn_continue = Button.new()
	btn_continue.text = "Сбежать (30%)"
	btn_continue.custom_minimum_size = Vector2(180, 60)
	btn_continue.add_theme_font_size_override("font_size", 20)
	btn_continue.add_theme_color_override("font_outline_color", Color(0,0,0))
	btn_continue.add_theme_constant_override("outline_size", 4)
	style_button(btn_continue) 
	btn_continue.pressed.connect(_on_continue_journey)
	hbox.add_child(btn_continue)

func start_walking_sequence():
	btn_continue.disabled = false
	btn_continue.text = "Сбежать (30%)"
	btn_fight.disabled = false
	
	bg_scroll_node.position = Vector2(0, 0)
	player_sprite.position = Vector2(960, 750)
	player_sprite.rotation_degrees = 0
	event_panel.visible = false
	
	bg_tween = create_tween()
	bg_tween.tween_property(bg_scroll_node, "position:x", -1920, 7.0)
	
	bounce_tween = create_tween()
	bounce_tween.set_loops()
	bounce_tween.tween_property(player_sprite, "position:y", 730.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property(player_sprite, "position:y", 750.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	sway_tween = create_tween()
	sway_tween.set_loops()
	sway_tween.tween_property(player_sprite, "position:x", 964.0, 0.4).set_trans(Tween.TRANS_SINE)
	sway_tween.parallel().tween_property(player_sprite, "rotation_degrees", 2.0, 0.4)
	sway_tween.tween_property(player_sprite, "position:x", 956.0, 0.4).set_trans(Tween.TRANS_SINE)
	sway_tween.parallel().tween_property(player_sprite, "rotation_degrees", -2.0, 0.4)
	
	await get_tree().create_timer(7.0).timeout
	
	bg_tween.kill()
	bounce_tween.kill()
	sway_tween.kill()
	player_sprite.position = Vector2(960, 750)
	player_sprite.rotation_degrees = 0
	
	var keys = GameManager.enemy_db.keys()
	var random_id = keys.pick_random()
	GameManager.current_enemy_id = random_id
	GameManager.discover_enemy(random_id)
	
	event_label.text = "Вы наткнулись на: " + GameManager.enemy_db[random_id]["name"] + "!"
	event_panel.visible = true

func _on_find_enemy():
	get_tree().change_scene_to_file("res://battle_scene.tscn")

func _on_continue_journey():
	var escape_chance = randf()
	if escape_chance <= 0.3: 
		start_walking_sequence()
	else:
		event_label.text = "Враг преградил вам путь!"
		btn_continue.disabled = true
		btn_continue.text = "Побег не удался!"
		await get_tree().create_timer(1.5).timeout
		_on_find_enemy()

func _on_return_to_town():
	get_tree().change_scene_to_file("res://Town.tscn")

func style_button(btn):
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.2, 0.15, 0.1)
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.8, 0.5, 0.2) 
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.35, 0.2, 0.1)
	hover.border_width_left = 2
	hover.border_width_right = 2
	hover.border_width_top = 2
	hover.border_width_bottom = 2
	hover.border_color = Color(1.0, 0.7, 0.3)
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("hover", hover)
	
	var disabled = StyleBoxFlat.new()
	disabled.bg_color = Color(0.15, 0.15, 0.15)
	disabled.border_width_left = 2
	disabled.border_width_right = 2
	disabled.border_width_top = 2
	disabled.border_width_bottom = 2
	disabled.border_color = Color(0.3, 0.3, 0.3)
	disabled.corner_radius_top_left = 8
	disabled.corner_radius_top_right = 8
	disabled.corner_radius_bottom_left = 8
	disabled.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("disabled", disabled)

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
