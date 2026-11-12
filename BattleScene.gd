extends Node2D

var board_node: Node2D
var player: Sprite2D
var enemy: Sprite2D
var cells_array = []

var obstacles_array = [] 

var ui_label: Label
var ui_panel: Panel
var player_hp_bar: ProgressBar
var enemy_hp_bar: ProgressBar
var potion_button: Button 

var end_panel: Panel
var end_title: Label
var end_subtitle: Label
var end_button: Button
var is_win = false

var player_cell_index = 30  
var enemy_cell_index = 49  

var player_hp = 0 
var enemy_hp = 0 
var enemy_damage = 0
var enemy_range = 1
var enemy_max_ap = 1
var enemy_is_ranged = false 
var reward_xp = 0
var drop_item_id = ""

var player_ap = 2
var max_ap = 2
var player_attack_range = 1 

var is_player_turn = true
var game_over = false

var tileset_path = "res://assets/tileset.png" 
var cut_size = 16 

var hero_x = 16 
var hero_y = 128
var enemy_x = 0
var enemy_y = 144 

var cols = 10
var rows = 8
var radius = 45.0 
var squash = 0.65 

var pause_overlay: ColorRect
var pause_panel: Panel
var confirm_panel: Panel

func _ready():
	player_hp = GameManager.player_hp
	
	var current = GameManager.enemy_db[GameManager.current_enemy_id]
	enemy_hp = current["hp"]
	enemy_damage = current["dmg"]
	enemy_range = current["atk_range"]
	enemy_max_ap = current["ap"]
	enemy_is_ranged = current["is_ranged"] 
	reward_xp = current["xp"]
	drop_item_id = current["drop"]
	enemy_x = current["x"]
	enemy_y = current["y"]
	
	obstacles_array.clear()
	var num_obstacles = randi_range(6, 10)
	var attempts = 0
	while obstacles_array.size() < num_obstacles and attempts < 100:
		attempts += 1
		var rand_idx = randi() % (cols * rows)
		
		if rand_idx != player_cell_index and rand_idx != enemy_cell_index and rand_idx not in obstacles_array:
			obstacles_array.append(rand_idx)
			if get_neighbors(enemy_cell_index).size() == 0:
				obstacles_array.pop_back() 
			if get_neighbors(player_cell_index).size() == 0:
				obstacles_array.pop_back()

	var bg_dark = ColorRect.new()
	bg_dark.color = Color(0.35, 0.45, 0.3) 
	bg_dark.size = Vector2(1920, 1080) 
	bg_dark.z_index = -20 
	add_child(bg_dark)

	draw_background_decor(bg_dark)

	var arena_bg = Polygon2D.new()
	var arena_pts = PackedVector2Array()
	for i in range(40):
		var angle = (i / 40.0) * TAU
		arena_pts.append(Vector2(cos(angle) * 800, sin(angle) * 500) + Vector2(960, 540))
	arena_bg.polygon = arena_pts
	arena_bg.color = Color(0.6, 0.75, 0.4) 
	bg_dark.add_child(arena_bg)

	board_node = Node2D.new()
	board_node.position = Vector2(622, 228) 
	add_child(board_node)

	for r in range(rows):
		for q in range(cols):
			var i = r * cols + q
			var cell = Polygon2D.new()
			
			var points = PackedVector2Array()
			for angle in range(0, 360, 60):
				var rad = deg_to_rad(angle)
				var x = (radius - 2) * cos(rad)
				var y = (radius - 2) * sin(rad)
				points.append(Vector2(x, y * squash))
				
			cell.polygon = points
			
			if i in obstacles_array:
				cell.color = Color(0.2, 0.15, 0.1) 
			else:
				cell.color = Color(0.5, 0.7, 0.4) 
			
			var pos_x = 1.5 * radius * q
			var pos_y = (sqrt(3) * radius * r + (q % 2) * (sqrt(3) * radius / 2)) * squash
			
			cell.position = Vector2(pos_x, pos_y)
			board_node.add_child(cell)
			cells_array.append(cell)
			
			if i in obstacles_array:
				draw_rock(cell.position)

	player = Sprite2D.new()
	setup_sprite_from_tileset(player, tileset_path, hero_x, hero_y, cut_size)
	player.offset = Vector2(0, -8) 
	player.z_index = 1 
	player.flip_h = false 
	add_child(player)
	add_shadow(player)

	enemy = Sprite2D.new()
	setup_sprite_from_tileset(enemy, tileset_path, enemy_x, enemy_y, cut_size)
	enemy.offset = Vector2(0, -8) 
	enemy.z_index = 1
	enemy.flip_h = true 
	add_child(enemy)
	add_shadow(enemy)

	player_hp_bar = create_hp_bar(GameManager.max_hp)
	add_child(player_hp_bar)

	enemy_hp_bar = create_hp_bar(enemy_hp)
	add_child(enemy_hp_bar)

	ui_panel = Panel.new()
	ui_panel.position = Vector2(660, 950) 
	ui_panel.size = Vector2(600, 60) 
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.2, 0.1) 
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.15, 0.05, 0.0) 
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	ui_panel.add_theme_stylebox_override("panel", style)
	add_child(ui_panel)

	ui_label = Label.new()
	ui_label.position = Vector2(0, 15) 
	ui_label.size = Vector2(600, 30)
	ui_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_label.add_theme_font_size_override("font_size", 24)
	ui_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	ui_label.add_theme_color_override("font_outline_color", Color(0,0,0))
	ui_label.add_theme_constant_override("outline_size", 4)
	ui_panel.add_child(ui_label)

	potion_button = Button.new()
	potion_button.text = "Выпить зелье"
	potion_button.position = Vector2(430, 950)
	potion_button.size = Vector2(200, 60)
	potion_button.add_theme_font_size_override("font_size", 22)
	potion_button.add_theme_color_override("font_outline_color", Color(0,0,0))
	potion_button.add_theme_constant_override("outline_size", 4)
	style_button(potion_button)
	potion_button.pressed.connect(_on_potion_pressed)
	add_child(potion_button)

	create_end_screen()
	create_pause_menu()
	update_positions_instant()
	update_ui()
	
	SoundManager.connect_ui_sounds(self)

func draw_rock(pos: Vector2):
	var rock = Polygon2D.new()
	rock.polygon = PackedVector2Array([
		Vector2(-20, 10), Vector2(-10, -15), Vector2(15, -20), 
		Vector2(25, 0), Vector2(15, 15), Vector2(-5, 20)
	])
	rock.color = Color(0.4, 0.4, 0.45) 
	rock.position = pos
	rock.z_index = 0
	board_node.add_child(rock)

func add_shadow(node: Node2D):
	var shadow = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(8): 
		var angle = (i / 8.0) * TAU
		pts.append(Vector2(cos(angle) * 10, sin(angle) * 5)) 
	shadow.polygon = pts
	shadow.color = Color(0, 0, 0, 0.3) 
	shadow.position = Vector2(0, 2) 
	shadow.z_index = -1
	node.add_child(shadow)

func draw_background_decor(bg_node: Control):
	for i in range(30):
		var tree = Polygon2D.new()
		var tx = randf_range(0, 1920)
		var ty = randf_range(0, 1080)
		
		if Vector2(tx, ty).distance_to(Vector2(960, 540)) < 600:
			continue
			
		tree.polygon = PackedVector2Array([
			Vector2(tx, ty), 
			Vector2(tx + 40, ty - 80), 
			Vector2(tx + 80, ty)
		])
		tree.color = Color(0.25, 0.35, 0.25) 
		bg_node.add_child(tree)

func _on_potion_pressed():
	if not is_player_turn or game_over: return
	
	if player_ap > 0:
		if GameManager.use_item("health_potion"):
			player_hp = GameManager.player_hp
			player_ap -= 1
			SoundManager.play("potion")
			update_ui()
			if player_ap == 0:
				end_player_turn()

func create_end_screen():
	end_panel = Panel.new()
	end_panel.position = Vector2(660, 300)
	end_panel.size = Vector2(600, 300)
	end_panel.z_index = 100 
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.05, 0.0) 
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.1, 0.0, 0.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	end_panel.add_theme_stylebox_override("panel", style)
	end_panel.visible = false
	add_child(end_panel)

	for i in range(4):
		var plank = ColorRect.new()
		plank.color = Color(0.45, 0.3, 0.15) if i % 2 == 0 else Color(0.4, 0.25, 0.1)
		plank.position = Vector2(6, 6 + i * 71) 
		plank.size = Vector2(588, 68)
		end_panel.add_child(plank)

	for pos in [Vector2(12, 12), Vector2(580, 12), Vector2(12, 280), Vector2(580, 280)]:
		var nail = ColorRect.new()
		nail.color = Color(0.15, 0.15, 0.15)
		nail.position = pos
		nail.size = Vector2(8, 8)
		end_panel.add_child(nail)

	end_title = Label.new()
	end_title.position = Vector2(0, 30)
	end_title.size = Vector2(600, 50)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_font_size_override("font_size", 54)
	end_title.add_theme_color_override("font_outline_color", Color(0,0,0))
	end_title.add_theme_constant_override("outline_size", 6)
	end_title.add_theme_font_override("font", load("res://assets/fonts/Rubik-Regular.ttf"))
	end_panel.add_child(end_title)

	end_subtitle = Label.new()
	end_subtitle.position = Vector2(40, 100) 
	end_subtitle.size = Vector2(520, 80) 
	end_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART 
	end_subtitle.add_theme_font_size_override("font_size", 24)
	end_subtitle.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	end_subtitle.add_theme_color_override("font_outline_color", Color(0,0,0))
	end_subtitle.add_theme_constant_override("outline_size", 4)
	end_panel.add_child(end_subtitle)

	end_button = Button.new()
	end_button.position = Vector2(200, 200)
	end_button.size = Vector2(200, 60)
	end_button.add_theme_font_size_override("font_size", 24)
	end_button.add_theme_color_override("font_outline_color", Color(0,0,0))
	end_button.add_theme_constant_override("outline_size", 4)
	style_button(end_button)
	end_button.pressed.connect(_on_end_button_pressed)
	end_panel.add_child(end_button)

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

func setup_sprite_from_tileset(sprite_node, path, x, y, size):
	var tex = load(path)
	if tex != null:
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(x, y, size, size) 
		sprite_node.texture = atlas
		
		var target_size = 50.0 
		var new_scale = target_size / size
		sprite_node.scale = Vector2(new_scale, new_scale)

func create_hp_bar(max_hp):
	var bar = ProgressBar.new()
	bar.max_value = max_hp
	bar.value = max_hp
	bar.show_percentage = false
	bar.size = Vector2(80, 14)
	bar.z_index = 2 
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1)
	bg_style.corner_radius_top_left = 7
	bg_style.corner_radius_top_right = 7
	bg_style.corner_radius_bottom_left = 7
	bg_style.corner_radius_bottom_right = 7
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0, 0, 0)
	bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.2)
	fill_style.corner_radius_top_left = 7
	fill_style.corner_radius_top_right = 7
	fill_style.corner_radius_bottom_left = 7
	fill_style.corner_radius_bottom_right = 7
	fill_style.border_width_left = 2
	fill_style.border_width_right = 2
	fill_style.border_width_top = 2
	fill_style.border_width_bottom = 2
	fill_style.border_color = Color(0, 0, 0)
	bar.add_theme_stylebox_override("fill", fill_style)
	
	return bar

func offset_to_cube(index):
	var q = index % cols
	var r = int(index / cols)
	var x = q
	var z = r - (q - (q & 1)) / 2
	var y = -x - z
	return Vector3(x, y, z)

func hex_distance(index_a, index_b):
	var a = offset_to_cube(index_a)
	var b = offset_to_cube(index_b)
	return int(max(abs(a.x - b.x), max(abs(a.y - b.y), abs(a.z - b.z))))

func get_neighbors(index):
	var q = index % cols
	var r = int(index / cols)
	var neighbors = []
	var dirs = []
	
	if q % 2 == 0: 
		dirs = [[1, 0], [1, -1], [-1, 0], [-1, -1], [0, -1], [0, 1]]
	else: 
		dirs = [[1, 0], [1, 1], [-1, 0], [-1, 1], [0, -1], [0, 1]]

	for d in dirs:
		var nq = q + d[0]
		var nr = r + d[1]
		if nq >= 0 and nq < cols and nr >= 0 and nr < rows:
			var next_idx = nr * cols + nq
			if next_idx not in obstacles_array:
				neighbors.append(next_idx)
	return neighbors

func find_path(start_idx, target_idx):
	var queue = [[start_idx]]
	var visited = [start_idx]

	while queue.size() > 0:
		var path = queue.pop_front()
		var current = path[-1]

		if current == target_idx:
			return path

		for neighbor in get_neighbors(current):
			if neighbor not in visited:
				visited.append(neighbor)
				var new_path = path.duplicate()
				new_path.append(neighbor)
				queue.append(new_path)

	return []

func shake_node(node: Node2D):
	var original_pos = node.position
	for i in range(4):
		var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8)) 
		node.position = original_pos + offset
		await get_tree().create_timer(0.03).timeout
	node.position = original_pos

func shoot_projectile(start_pos: Vector2, end_pos: Vector2):
	var ball = Polygon2D.new()
	var pts = PackedVector2Array()
	for a in range(0, 360, 10):
		pts.append(Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 10) 
	
	ball.polygon = pts
	ball.color = Color(1.0, 0.2, 0.2) 
	ball.z_index = 5 
	ball.position = start_pos
	add_child(ball)
	
	SoundManager.play("shoot")
	
	var tween = create_tween()
	tween.tween_property(ball, "position", end_pos, 0.3)
	await tween.finished
	
	ball.queue_free() 

func update_ui():
	if is_instance_valid(player_hp_bar): player_hp_bar.value = player_hp
	if is_instance_valid(enemy_hp_bar): enemy_hp_bar.value = enemy_hp
	
	ui_label.text = "Очки действия: " + str(player_ap) + " / " + str(max_ap)
	
	var potion_count = 0
	for item in GameManager.inventory:
		if item == "health_potion":
			potion_count += 1
			
	potion_button.disabled = potion_count == 0 or player_ap == 0
	if potion_count > 0:
		potion_button.text = "Выпить зелье (x" + str(potion_count) + ") (1 ОД)"
	else:
		potion_button.text = "Нет зелий"
		
	highlight_cells()

func highlight_cells():
	for i in range(cells_array.size()):
		if i in obstacles_array:
			cells_array[i].color = Color(0.2, 0.15, 0.1)
		else:
			cells_array[i].color = Color(0.5, 0.7, 0.4)
		
	if game_over: return

	if player_ap > 0:
		var neighbors = get_neighbors(player_cell_index)
		for n in neighbors:
			if n != enemy_cell_index:
				cells_array[n].color = Color(0.6, 0.85, 1.0) 

	if hex_distance(player_cell_index, enemy_cell_index) <= enemy_range and player_ap > 0:
		enemy.modulate = Color(1.0, 0.8, 0.0) 
	else:
		enemy.modulate = Color(1.0, 1.0, 1.0) 

func update_positions_instant():
	player.position = board_node.position + cells_array[player_cell_index].position
	enemy.position = board_node.position + cells_array[enemy_cell_index].position
	
	if is_instance_valid(player_hp_bar):
		player_hp_bar.position = player.position + Vector2(-40, -62) 
	if is_instance_valid(enemy_hp_bar):
		enemy_hp_bar.position = enemy.position + Vector2(-40, -62)

func move_sprite_smooth(sprite_node, hp_bar, target_cell_index):
	var target_pos = board_node.position + cells_array[target_cell_index].position
	var start_pos = sprite_node.position
	
	if start_pos == target_pos: return 
	
	if target_pos.x < start_pos.x:
		sprite_node.flip_h = true 
	elif target_pos.x > start_pos.x:
		sprite_node.flip_h = false 
	
	var direction = sign(target_pos.x - start_pos.x)
	if direction == 0: direction = 1 
	
	var tween = create_tween()
	tween.tween_property(sprite_node, "rotation_degrees", 20.0 * direction, 0.1)
	tween.parallel().tween_property(sprite_node, "position", target_pos, 0.2)
	tween.parallel().tween_property(hp_bar, "position", target_pos + Vector2(-40, -62), 0.2)
	tween.tween_property(sprite_node, "rotation_degrees", 0.0, 0.1)
	
	await tween.finished

func _input(event):
	if not is_player_turn or game_over:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in range(cells_array.size()):
			var cell = cells_array[i]
			
			var local_click = event.position - board_node.position - cell.position
			if Geometry2D.is_point_in_polygon(local_click, cell.polygon):
				
				if i in obstacles_array:
					return
				
				if i == enemy_cell_index:
					if hex_distance(player_cell_index, enemy_cell_index) <= player_attack_range and player_ap > 0:
						is_player_turn = false 
						
						if enemy.position.x < player.position.x:
							player.flip_h = true
						else:
							player.flip_h = false

						var original_pos = player.position
						var dir = (enemy.position - player.position).normalized()
						var attack_pos = original_pos + (dir * 25) 
						
						var tween = create_tween()
						tween.tween_property(player, "position", attack_pos, 0.1)
						tween.tween_property(player, "position", original_pos, 0.1)
						await tween.finished
						
						enemy_hp -= 3 # ВЕРНУЛИ ФИКСИРОВАННЫЙ УРОН
						player_ap -= 1
						
						SoundManager.play("hit")
						await shake_node(enemy)
						
						if enemy_hp <= 0:
							enemy.queue_free()
							enemy_hp_bar.queue_free()
							GameManager.add_rewards(reward_xp, drop_item_id) 
							update_ui()
							is_win = true
							var loot_name = GameManager.item_db[drop_item_id]["name"]
							
							show_end_screen("ПОБЕДА!", "Вы получили " + str(reward_xp) + " опыта.\nТрофей: " + loot_name)
							return
							
						update_ui()
						if player_ap == 0:
							end_player_turn()
						else:
							is_player_turn = true 
				
				elif i != player_cell_index and hex_distance(player_cell_index, i) == 1 and player_ap > 0:
					is_player_turn = false 
					player_cell_index = i
					player_ap -= 1
					await move_sprite_smooth(player, player_hp_bar, player_cell_index)
					update_ui()
					
					if player_ap == 0:
						end_player_turn()
					else:
						is_player_turn = true

func end_player_turn():
	is_player_turn = false
	for i in range(cells_array.size()):
		if i in obstacles_array:
			cells_array[i].color = Color(0.2, 0.15, 0.1)
		else:
			cells_array[i].color = Color(0.5, 0.7, 0.4)
			
	await get_tree().create_timer(0.5).timeout
	enemy_turn()

func enemy_turn():
	if game_over: return
	
	var temp_enemy_ap = enemy_max_ap
	
	while temp_enemy_ap > 0 and not game_over:
		var current_dist = hex_distance(player_cell_index, enemy_cell_index)
		
		if current_dist <= enemy_range:
			if player.position.x < enemy.position.x:
				enemy.flip_h = true
			else:
				enemy.flip_h = false
				
			if enemy_is_ranged:
				await shoot_projectile(enemy.position, player.position)
			else:
				var original_pos = enemy.position
				var dir = (player.position - enemy.position).normalized()
				var attack_pos = original_pos + (dir * 25)
				
				var tween = create_tween()
				tween.tween_property(enemy, "position", attack_pos, 0.1)
				tween.tween_property(enemy, "position", original_pos, 0.1)
				await tween.finished
				SoundManager.play("hit")
				
			player_hp -= enemy_damage
			GameManager.player_hp = player_hp 
			GameManager.save_game()
			
			update_ui() 
			
			await shake_node(player)
			temp_enemy_ap -= 1
			
			if player_hp <= 0:
				player.queue_free()
				player_hp_bar.queue_free()
				GameManager.player_hp = GameManager.max_hp 
				GameManager.save_game() 
				is_win = false
				show_end_screen("ПОРАЖЕНИЕ...", "Вы потеряли сознание. Но добрые жители города вылечили вас.")
				return
				
			await get_tree().create_timer(0.4).timeout 
		else:
			var path = find_path(enemy_cell_index, player_cell_index)
			
			if path.size() > 1: 
				enemy_cell_index = path[1] 
				await move_sprite_smooth(enemy, enemy_hp_bar, enemy_cell_index)
				temp_enemy_ap -= 1
				await get_tree().create_timer(0.2).timeout
			else:
				temp_enemy_ap = 0 
		
	is_player_turn = true
	player_ap = max_ap
	update_ui()

func show_end_screen(title_text, subtitle_text):
	game_over = true
	ui_panel.visible = false 
	potion_button.visible = false 
	
	for i in range(cells_array.size()):
		if i in obstacles_array:
			cells_array[i].color = Color(0.2, 0.15, 0.1)
		else:
			cells_array[i].color = Color(0.5, 0.7, 0.4)

	end_title.text = title_text
	end_subtitle.text = subtitle_text
	
	if is_win:
		SoundManager.play("win")
		end_title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3)) 
		end_button.text = "Продолжить путь"
	else:
		SoundManager.play("lose")
		end_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3)) 
		end_button.text = "Вернуться в город"
		
	end_panel.visible = true

func _on_end_button_pressed():
	GameManager.save_game()
	if is_win:
		get_tree().change_scene_to_file("res://Expedition.tscn") 
	else:
		get_tree().change_scene_to_file("res://Town.tscn")

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
		if game_over: return
		
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
