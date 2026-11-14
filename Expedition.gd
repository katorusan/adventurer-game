extends Control

# --- Мир ---
var world: Node2D
var camera: Camera2D
var player: Sprite2D
var player_light: PointLight2D

# --- Параметры генерации ---
var current_pos = Vector2(200, 0)
var current_dir = Vector2.RIGHT
var segment_length = 400.0
var floor_segments = []
var event_nodes = []
var waypoints = []
var last_turn = 0 

# --- Состояние ---
var is_running = false
var is_event_active = false
var current_event_type = ""
var current_event_node: Node2D
var speed = 300.0 
var spawn_timer = 4.0 

# --- UI ---
var ui_layer: CanvasLayer
var hp_label: Label
var gold_label: Label
var xp_label: Label

var event_panel: Panel
var event_label: Label
var btn_fight: Button
var btn_continue: Button

var pause_overlay: ColorRect
var pause_panel: Panel
var confirm_panel: Panel

var hp_atlas: AtlasTexture
var gold_atlas: AtlasTexture
var font_title = load("res://assets/fonts/Rubik-Regular.ttf")
var font_text = load("res://assets/fonts/Nunito-Regular.ttf")

var walk_time = 0.0

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var canvas_mod = CanvasModulate.new()
	canvas_mod.color = Color(0, 0, 0) 
	add_child(canvas_mod)

	world = Node2D.new()
	add_child(world)

	player = Sprite2D.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = load("res://assets/tileset.png")
	atlas.region = Rect2(16, 128, 16, 16)
	player.texture = atlas
	player.scale = Vector2(4.0, 4.0)
	player.z_index = 10
	world.add_child(player)

	player_light = PointLight2D.new()
	player_light.texture = _create_light_texture()
	player_light.texture_scale = 1.4 
	player_light.energy = 1.2        
	player_light.color = Color(1.0, 0.8, 0.5)
	player.add_child(player_light)

	var player_glow = PointLight2D.new()
	player_glow.texture = _create_light_texture()
	player_glow.texture_scale = 0.6
	player_glow.energy = 1.0
	player_glow.color = Color(1, 1, 1)
	player.add_child(player_glow)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	player.add_child(camera)
	camera.make_current()

	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	create_screen_vignette()
	create_wooden_hud()
	create_event_ui()
	create_pause_menu()

	if get_node_or_null("/root/SoundManager"):
		SoundManager.connect_ui_sounds(self)

	if GameManager.expedition_is_returning:
		player.position = GameManager.expedition_saved_pos
		current_pos = GameManager.expedition_saved_pos
		current_dir = GameManager.expedition_saved_dir
		GameManager.expedition_is_returning = false 
		generate_next_segment() 
	else:
		player.position = Vector2(200, 0)
		current_pos = Vector2(200, 0)
		current_dir = Vector2.RIGHT
		last_turn = 0
		for i in range(3):
			generate_next_segment()
		
	is_running = true
	spawn_timer = 3.0 

func _process(delta):
	if is_running and waypoints.size() > 0:
		walk_time += delta * 15.0
		player.offset.y = -8 + sin(walk_time) * 4.0
	else:
		player.offset.y = -8

	if get_tree().paused or not is_running: return

	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_event(current_pos)
		spawn_timer = randf_range(4.0, 7.0)

	if waypoints.size() > 0:
		var target = waypoints[0]
		player.position = player.position.move_toward(target, speed * delta)
		
		if player.position.distance_to(target) > 10:
			var dir = (target - player.position).normalized()
			if dir.x < -0.1:
				player.flip_h = true 
			elif dir.x > 0.1:
				player.flip_h = false 

		if player.position.distance_to(target) < 10:
			waypoints.pop_front()
			generate_next_segment()
	else:
		generate_next_segment()

	cleanup_old_chunks()
	check_events()

func generate_next_segment():
	var r = randf()
	var current_turn = 0
	
	if r < 0.5:
		current_turn = 0 
	elif r < 0.75:
		current_turn = -1 
	else:
		current_turn = 1 

	if current_turn == last_turn and current_turn != 0:
		current_turn = 0

	if current_turn == -1:
		current_dir = current_dir.rotated(-PI/2) 
	elif current_turn == 1:
		current_dir = current_dir.rotated(PI/2) 
	
	last_turn = current_turn 

	var start_pos = current_pos
	var next_pos = current_pos + current_dir * segment_length
	waypoints.append(next_pos)

	var corridor = Line2D.new()
	corridor.points = PackedVector2Array([start_pos, next_pos])
	corridor.width = 300.0
	corridor.default_color = Color(0.35, 0.3, 0.25) 
	corridor.joint_mode = Line2D.LINE_JOINT_ROUND
	corridor.begin_cap_mode = Line2D.LINE_CAP_ROUND
	corridor.end_cap_mode = Line2D.LINE_CAP_ROUND
	corridor.z_index = 0
	world.add_child(corridor)
	floor_segments.append(corridor)

	decorate_segment(start_pos, next_pos, current_dir)
	current_pos = next_pos

func decorate_segment(start_pos: Vector2, end_pos: Vector2, dir: Vector2):
	var perp = dir.rotated(PI/2)
	
	if randf() < 0.5:
		var torch_pos = start_pos + dir * randf_range(50, 300) + perp * randf_range(130, 150)
		if randf() < 0.5: torch_pos = start_pos + dir * randf_range(50, 300) - perp * randf_range(130, 150)
		
		var torch = Node2D.new()
		torch.position = torch_pos
		world.add_child(torch)
		
		var flame = Polygon2D.new()
		flame.polygon = PackedVector2Array([Vector2(0, -15), Vector2(10, 10), Vector2(-10, 10)])
		flame.color = Color(1.0, 0.5, 0.0)
		torch.add_child(flame)
		
		var t_light = PointLight2D.new()
		t_light.texture = _create_light_texture()
		t_light.texture_scale = 0.8
		t_light.energy = 1.5
		t_light.color = Color(1.0, 0.5, 0.0)
		torch.add_child(t_light)
		
		floor_segments.append(torch)

	if randf() < 0.7:
		var rock = Polygon2D.new()
		var rock_pos = start_pos + dir * randf_range(0, segment_length) + perp * randf_range(-80, 80)
		rock.polygon = PackedVector2Array([
			Vector2(-15, 10), Vector2(-5, -15), Vector2(15, -10), Vector2(20, 15), Vector2(0, 20)
		])
		rock.color = Color(0.2, 0.2, 0.22)
		rock.position = rock_pos
		rock.rotation = randf_range(0, TAU)
		rock.z_index = 1
		world.add_child(rock)
		floor_segments.append(rock)

	if randf() < 0.6:
		var crack = Line2D.new()
		var crack_pos = start_pos + dir * randf_range(0, segment_length)
		crack.points = PackedVector2Array([Vector2(-30, 20), Vector2(0, -10), Vector2(40, 10)])
		crack.width = 4
		crack.default_color = Color(0.15, 0.15, 0.15)
		crack.position = crack_pos
		crack.rotation = randf_range(0, TAU)
		crack.z_index = 0
		world.add_child(crack)
		floor_segments.append(crack)

func spawn_event(pos: Vector2):
	var event_node = Node2D.new()
	event_node.position = pos
	event_node.z_index = 5
	world.add_child(event_node)
	event_nodes.append(event_node)

	var r = randf() * 100.0
	var type = ""
	var enemy_id = -1
	
	if r < 35.0:
		type = "enemy"
		enemy_id = 0 
	elif r < 60.0:
		type = "enemy"
		enemy_id = 1 
	elif r < 75.0:
		type = "enemy"
		enemy_id = 2 
	elif r < 90.0:
		type = "chest"
	else:
		type = "merchant"

	if type == "enemy":
		var spr = Sprite2D.new()
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://assets/tileset.png")
		
		var data = GameManager.enemy_db[enemy_id]
		atlas.region = Rect2(data["x"], data["y"], 16, 16)
		spr.texture = atlas
		spr.scale = Vector2(4, 4)
		event_node.add_child(spr)
		
	elif type == "chest":
		var chest_body = ColorRect.new()
		chest_body.color = Color(0.4, 0.2, 0.1)
		chest_body.size = Vector2(50, 35)
		chest_body.position = Vector2(-25, -17.5)
		event_node.add_child(chest_body)

		var chest_lid = Polygon2D.new()
		chest_lid.polygon = PackedVector2Array([
			Vector2(-25, -17.5), Vector2(25, -17.5), Vector2(20, -30), Vector2(-20, -30)
		])
		chest_lid.color = Color(0.55, 0.3, 0.15)
		event_node.add_child(chest_lid)

		var lock = ColorRect.new()
		lock.color = Color(1.0, 0.8, 0.2)
		lock.size = Vector2(10, 15)
		lock.position = Vector2(-5, -10)
		event_node.add_child(lock)
		
	else:
		var merchant_body = Polygon2D.new()
		merchant_body.polygon = PackedVector2Array([Vector2(-20, 20), Vector2(20, 20), Vector2(10, -15), Vector2(-10, -15)])
		merchant_body.color = Color(0.3, 0.2, 0.4) 
		event_node.add_child(merchant_body)

		var face = ColorRect.new()
		face.color = Color(0.9, 0.7, 0.6)
		face.size = Vector2(16, 16)
		face.position = Vector2(-8, -25)
		event_node.add_child(face)

		var beard = Polygon2D.new()
		beard.polygon = PackedVector2Array([Vector2(-8, -10), Vector2(8, -10), Vector2(0, 5)])
		beard.color = Color(0.8, 0.8, 0.8) 
		event_node.add_child(beard)

		var hat = Polygon2D.new()
		hat.polygon = PackedVector2Array([Vector2(-18, -25), Vector2(18, -25), Vector2(0, -50)])
		hat.color = Color(0.5, 0.1, 0.6) 
		event_node.add_child(hat)

	event_node.set_meta("type", type)
	event_node.set_meta("enemy_id", enemy_id)
	event_node.set_meta("triggered", false)

func cleanup_old_chunks():
	for i in range(floor_segments.size() - 1, -1, -1):
		if is_instance_valid(floor_segments[i]):
			var dist = 0
			if floor_segments[i] is Line2D and floor_segments[i].points.size() > 1:
				dist = floor_segments[i].points[1].distance_to(player.position)
			else:
				dist = floor_segments[i].global_position.distance_to(player.position)
				
			if dist > 1500:
				floor_segments[i].queue_free()
				floor_segments.remove_at(i)
			
	for i in range(event_nodes.size() - 1, -1, -1):
		if is_instance_valid(event_nodes[i]): 
			if event_nodes[i].global_position.distance_to(player.position) > 1000:
				event_nodes[i].queue_free()
				event_nodes.remove_at(i)
		else:
			event_nodes.remove_at(i) 

func check_events():
	for event in event_nodes:
		if is_instance_valid(event) and not event.get_meta("triggered"): 
			if player.position.distance_to(event.global_position) < 80:
				event.set_meta("triggered", true)
				trigger_event(event)

func trigger_event(event_node: Node2D):
	is_running = false
	is_event_active = true
	current_event_type = event_node.get_meta("type")
	current_event_node = event_node
	
	btn_continue.disabled = false # Сбрасываем блокировку кнопки на всякий случай
	
	if current_event_type == "enemy":
		event_label.text = "Враг преградил путь!"
		btn_fight.text = "В бой!"
		btn_fight.visible = true
		btn_continue.text = "Сбежать (30%)"
		btn_continue.visible = true
		event_panel.visible = true
		
		var enemy_id = event_node.get_meta("enemy_id")
		GameManager.current_enemy_id = enemy_id
		GameManager.discover_enemy(enemy_id)
		
	elif current_event_type == "chest":
		event_label.text = "Вы нашли сундук!"
		btn_fight.text = "Открыть"
		btn_fight.visible = true
		btn_continue.text = "Пройти мимо"
		btn_continue.visible = true
		event_panel.visible = true
		
	elif current_event_type == "merchant":
		event_label.text = "Бродячий торговец"
		btn_fight.text = "Торговать"
		btn_fight.visible = true
		btn_continue.text = "Пройти мимо"
		btn_continue.visible = true
		event_panel.visible = true

# --- UI ---
func create_screen_vignette():
	var vignette = TextureRect.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))   
	grad.set_color(0.6, Color(0, 0, 0, 0)) 
	grad.set_color(1, Color(0, 0, 0, 1))   
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 512
	tex.height = 512
	vignette.texture = tex
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(vignette)

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

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(15, 15) 
	vbox.size = Vector2(290, 130) 
	vbox.add_theme_constant_override("separation", 10)
	hud.add_child(vbox)

	var h_info = HBoxContainer.new()
	h_info.add_theme_constant_override("separation", 20)
	
	var level_label = Label.new()
	level_label.text = "Ур. 1 Ранг F"
	level_label.add_theme_font_size_override("font_size", 18) 
	level_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) 
	level_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	level_label.add_theme_constant_override("outline_size", 4)
	h_info.add_child(level_label)
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

func create_event_ui():
	event_panel = Panel.new()
	event_panel.position = Vector2(390, 450)
	event_panel.size = Vector2(500, 150) 
	event_panel.z_index = 100
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.05, 0.95) 
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.8, 0.5, 0.2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	event_panel.add_theme_stylebox_override("panel", style)
	event_panel.visible = false
	ui_layer.add_child(event_panel)

	event_label = Label.new()
	event_label.position = Vector2(0, 20)
	event_label.size = Vector2(500, 40)
	event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_label.add_theme_font_size_override("font_size", 24)
	event_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	if font_title: event_label.add_theme_font_override("font", font_title)
	event_panel.add_child(event_label)

	var hbox = HBoxContainer.new()
	hbox.position = Vector2(100, 80) 
	hbox.size = Vector2(300, 50)
	hbox.add_theme_constant_override("separation", 20) 
	event_panel.add_child(hbox)

	btn_fight = Button.new()
	btn_fight.text = "В бой!"
	btn_fight.custom_minimum_size = Vector2(140, 50) 
	btn_fight.add_theme_font_size_override("font_size", 20)
	style_button(btn_fight) 
	btn_fight.pressed.connect(_on_fight_btn_pressed)
	hbox.add_child(btn_fight)

	btn_continue = Button.new()
	btn_continue.text = "Сбежать"
	btn_continue.custom_minimum_size = Vector2(140, 50)
	btn_continue.add_theme_font_size_override("font_size", 20)
	style_button(btn_continue) 
	btn_continue.pressed.connect(_on_continue_btn_pressed)
	hbox.add_child(btn_continue)

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

# --- ЛОГИКА КНОПОК ---
func _on_fight_btn_pressed():
	if get_node_or_null("/root/SoundManager"): SoundManager.play("click")
	
	if current_event_type == "enemy":
		GameManager.expedition_saved_pos = player.position
		GameManager.expedition_saved_dir = current_dir
		GameManager.expedition_is_returning = true
		get_tree().change_scene_to_file("res://battle_scene.tscn")
		
	elif current_event_type == "chest":
		var gold_found = randi_range(1, 3)
		GameManager.gold += gold_found
		update_info_ui()
		GameManager.save_game()
		print("Найдено золота: ", gold_found)
		_close_event()
		
	elif current_event_type == "merchant":
		print("Торговец пока в разработке (магазин откроется позже)")
		_close_event()

func _on_continue_btn_pressed():
	if get_node_or_null("/root/SoundManager"): SoundManager.play("click")
	
	if current_event_type == "enemy":
		# ШАНС ПОБЕГА 30%
		var escape_chance = randf()
		if escape_chance <= 0.3:
			print("Успешный побег!")
			_close_event()
		else:
			event_label.text = "Побег не удался!"
			btn_continue.disabled = true
			btn_continue.text = "Пойман!"
			await get_tree().create_timer(1.0).timeout
			_on_fight_btn_pressed()
	else:
		_close_event()

func _close_event():
	event_panel.visible = false
	if is_instance_valid(current_event_node):
		if current_event_node in event_nodes:
			event_nodes.erase(current_event_node)
		current_event_node.queue_free()
	is_event_active = false
	is_running = true
	spawn_timer = 2.0

# --- МЕНЮ ПАУЗЫ ---
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

	var btn_exit = Button.new()
	btn_exit.text = "Сбежать в город"
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
	btn_yes.text = "Да"
	btn_yes.custom_minimum_size = Vector2(130, 60)
	btn_yes.add_theme_font_size_override("font_size", 20)
	style_button(btn_yes)
	btn_yes.pressed.connect(_on_confirm_exit_yes)
	c_hbox.add_child(btn_yes)

	var btn_no = Button.new()
	btn_no.text = "Нет"
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
	get_tree().change_scene_to_file("res://Town.tscn")

func _on_confirm_exit_no():
	confirm_panel.visible = false
	pause_panel.visible = true

# --- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ СВЕТА ---
func _create_light_texture() -> Texture2D:
	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))     
	grad.set_color(0.5, Color(1, 1, 1, 0.8)) 
	grad.set_color(1, Color(1, 1, 1, 0))     
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 512
	tex.height = 512
	return tex
