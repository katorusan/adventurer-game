extends Control

var d_hero: Sprite2D
var d_bat: Sprite2D
var diorama_node: Node2D

# Безопасная загрузка шрифтов (если файла нет - игра не вылетит)
var font_title = load("res://assets/fonts/Rubik-Regular.ttf")
var font_text = load("res://assets/fonts/Nunito-Regular.ttf")

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 1. ФОН
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.15, 0.2, 0.3))
	gradient.set_color(1, Color(0.6, 0.45, 0.4))
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = gradient
	grad_tex.fill_from = Vector2(0, 1)
	grad_tex.fill_to = Vector2(0, 0)
	
	var bg = TextureRect.new()
	bg.texture = grad_tex
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 2. ОБЛАКА
	for i in range(15):
		var cloud = Polygon2D.new()
		cloud.polygon = PackedVector2Array([
			Vector2(-120, 0), Vector2(0, -30), Vector2(120, 0), 
			Vector2(60, 40), Vector2(-60, 40)
		])
		cloud.color = Color(0.9, 0.9, 0.95, 0.25)
		var start_x = randf_range(-300, 2200)
		var start_y = randf_range(50, 500)
		cloud.position = Vector2(start_x, start_y)
		add_child(cloud)
		var speed = randf_range(80.0, 150.0)
		var tween = create_tween()
		tween.tween_property(cloud, "position:x", 2200.0, (2200.0 - start_x) / speed)
		tween.tween_callback(func(): 
			cloud.position.x = -300.0
			cloud.position.y = randf_range(50, 500)
			var loop = create_tween().set_loops()
			loop.tween_property(cloud, "position:x", 2200.0, 2500.0 / speed)
			loop.tween_callback(func(): 
				cloud.position.x = -300.0 
				cloud.position.y = randf_range(50, 500)
			)
		)

	# 3. ЗЕМЛЯ И ХОЛМЫ
	var ground = ColorRect.new()
	ground.color = Color(0.2, 0.25, 0.15)
	ground.position = Vector2(0, 750)
	ground.size = Vector2(1920, 330)
	add_child(ground)

	for i in range(5):
		var hill = Polygon2D.new()
		var hx = i * 400
		hill.polygon = PackedVector2Array([
			Vector2(hx, 800), 
			Vector2(hx + 200, 600 + randf_range(-50, 50)), 
			Vector2(hx + 400, 800)
		])
		hill.color = Color(0.15, 0.2, 0.1)
		add_child(hill)

	# 4. ДЕРЕВЬЯ
	for i in range(15):
		var tx = i * 140 + randf_range(-30, 30)
		var ty = 780
		var size = randf_range(150, 250)
		draw_bg_tree(tx, ty, size, i)

	# 5. ДИОРАМА
	create_battle_diorama()

	# 6. МЕНЮ
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 40) 
	center_container.add_child(main_vbox)

	var title = Label.new()
	title.text = "Авантюрист: Путь к рангу S"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title.add_theme_constant_override("shadow_offset_x", 6)
	title.add_theme_constant_override("shadow_offset_y", 6)
	if font_title: title.add_theme_font_override("font", font_title)
	main_vbox.add_child(title)

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(450, 380)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.05, 0.95) 
	style.border_width_left = 6
	style.border_width_right = 6
	style.border_width_top = 6
	style.border_width_bottom = 6
	style.border_color = Color(0.8, 0.55, 0.2)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	panel.add_theme_stylebox_override("panel", style)
	main_vbox.add_child(panel)

	for i in range(5):
		var plank = ColorRect.new()
		plank.color = Color(0.2, 0.15, 0.1, 0.3) if i % 2 == 0 else Color(0.1, 0.05, 0.0, 0.3)
		plank.position = Vector2(10, 10 + i * 72) 
		plank.size = Vector2(430, 72)
		panel.add_child(plank)

	var panel_center = CenterContainer.new()
	panel_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(panel_center)

	var vbox_buttons = VBoxContainer.new()
	vbox_buttons.add_theme_constant_override("separation", 20)
	panel_center.add_child(vbox_buttons)

	var has_save = FileAccess.file_exists(GameManager.save_path)

	if has_save:
		var btn_continue = create_button("Продолжить")
		btn_continue.pressed.connect(_on_continue_pressed)
		vbox_buttons.add_child(btn_continue)

	var btn_new = create_button("Новая игра")
	btn_new.pressed.connect(_on_new_game_pressed)
	vbox_buttons.add_child(btn_new)

	var btn_settings = create_button("Настройки")
	btn_settings.pressed.connect(_on_settings_pressed)
	vbox_buttons.add_child(btn_settings)

	var btn_quit = create_button("Выход")
	btn_quit.pressed.connect(_on_quit_pressed)
	vbox_buttons.add_child(btn_quit)

	# Подключаем звуки, если скрипт SoundManager существует
	if get_node_or_null("/root/SoundManager"):
		SoundManager.connect_ui_sounds(self)

func draw_bg_tree(x, y, size, index):
	var tree_base = Node2D.new()
	tree_base.position = Vector2(x + size/2, y)
	add_child(tree_base)

	var tree = Polygon2D.new()
	tree.polygon = PackedVector2Array([
		Vector2(-size/2, 0), 
		Vector2(0, -size), 
		Vector2(size/2, 0)
	])
	tree.color = Color(0.1, 0.18, 0.1) 
	tree_base.add_child(tree)
	
	var tree2 = Polygon2D.new()
	tree2.polygon = PackedVector2Array([
		Vector2(-size*0.4, -size*0.3), 
		Vector2(0, -size*1.2), 
		Vector2(size*0.4, -size*0.3)
	])
	tree2.color = Color(0.12, 0.22, 0.12) 
	tree_base.add_child(tree2)
	
	var delay = index * 0.12 
	var start_timer = create_tween()
	start_timer.tween_interval(delay)
	start_timer.tween_callback(func():
		var sway_tween = create_tween().set_loops()
		sway_tween.tween_property(tree_base, "rotation_degrees", 3.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sway_tween.tween_property(tree_base, "rotation_degrees", 0.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	)

func create_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 60)
	btn.add_theme_font_size_override("font_size", 26)
	if font_text: btn.add_theme_font_override("font", font_text)
	
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.25, 0.15, 0.1, 0.9) 
	normal.border_width_left = 3
	normal.border_width_right = 3
	normal.border_width_top = 3
	normal.border_width_bottom = 3
	normal.border_color = Color(0.7, 0.45, 0.15) 
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
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
	btn.add_theme_stylebox_override("hover", hover)
	
	return btn

func create_battle_diorama():
	diorama_node = Node2D.new()
	diorama_node.position = Vector2(350, 850)
	diorama_node.z_index = 5
	add_child(diorama_node)

	var ground_patch = Polygon2D.new()
	var g_pts = PackedVector2Array()
	for i in range(20):
		var angle = (i / 20.0) * TAU
		g_pts.append(Vector2(cos(angle) * 160, sin(angle) * 25))
	ground_patch.polygon = g_pts
	ground_patch.color = Color(0.15, 0.2, 0.1)
	diorama_node.add_child(ground_patch)

	d_hero = Sprite2D.new()
	var atlas_h = AtlasTexture.new()
	atlas_h.atlas = load("res://assets/tileset.png")
	atlas_h.region = Rect2(16, 128, 16, 16)
	d_hero.texture = atlas_h
	d_hero.scale = Vector2(6.0, 6.0) 
	d_hero.position = Vector2(-60, -30)
	diorama_node.add_child(d_hero)
	add_small_shadow(d_hero)

	d_bat = Sprite2D.new()
	var atlas_b = AtlasTexture.new()
	atlas_b.atlas = load("res://assets/tileset.png")
	atlas_b.region = Rect2(0, 160, 16, 16)
	d_bat.texture = atlas_b
	d_bat.scale = Vector2(5.0, 5.0) 
	d_bat.position = Vector2(80, -110)
	d_bat.flip_h = true
	diorama_node.add_child(d_bat)
	add_small_shadow(d_bat)

	_run_battle_animation()

func add_small_shadow(node: Node2D):
	var shadow = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		pts.append(Vector2(cos(angle) * 10, sin(angle) * 3))
	shadow.polygon = pts
	shadow.color = Color(0, 0, 0, 0.4)
	shadow.position = Vector2(0, 10)
	shadow.z_index = -1
	node.add_child(shadow)

func _run_battle_animation():
	while true:
		await get_tree().create_timer(0.8).timeout
		
		var orig_pos = d_hero.position
		var attack_pos = orig_pos + Vector2(45, 0)
		var t1 = create_tween()
		t1.tween_property(d_hero, "position", attack_pos, 0.08)
		t1.tween_property(d_hero, "position", orig_pos, 0.12)
		await t1.finished
		
		if get_node_or_null("/root/SoundManager"): SoundManager.play("hit")
		
		await get_tree().create_timer(0.2).timeout
		
		var proj = Polygon2D.new()
		var p_pts = PackedVector2Array()
		for i in range(8):
			var angle = (i / 8.0) * TAU
			p_pts.append(Vector2(cos(angle) * 8, sin(angle) * 8))
		proj.polygon = p_pts
		proj.color = Color(1.0, 0.2, 0.2)
		proj.position = d_bat.position
		diorama_node.add_child(proj)
		
		if get_node_or_null("/root/SoundManager"): SoundManager.play("shoot")
		
		var t2 = create_tween()
		t2.tween_property(proj, "position", d_hero.position, 0.2)
		await t2.finished
		proj.queue_free()
		
		d_hero.modulate = Color(1.0, 0.4, 0.4)
		await get_tree().create_timer(0.1).timeout
		d_hero.modulate = Color(1.0, 1.0, 1.0)
		
		var bat_orig_y = d_bat.position.y
		var t3 = create_tween()
		t3.tween_property(d_bat, "position:y", bat_orig_y - 15, 0.15)
		t3.tween_property(d_bat, "position:y", bat_orig_y, 0.15)
		await t3.finished

func _on_continue_pressed():
	get_tree().change_scene_to_file("res://Town.tscn")

func _on_new_game_pressed():
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://Town.tscn")

func _on_settings_pressed():
	print("Настройки пока в разработке!")

func _on_quit_pressed():
	get_tree().quit()
