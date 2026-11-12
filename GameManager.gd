extends Node

var gold = 0
var xp = 0
var player_hp = 15
var max_hp = 15
var current_enemy_id = 0 

var inventory = [] 

var item_db = {
	"slime_goo": {"name": "Слизь", "sell_price": 3, "icon_x": 0, "icon_y": 144, "desc": "Липкий комок. Торговцы используют её для алхимии."},
	"bat_wing": {"name": "Крыло мыши", "sell_price": 6, "icon_x": 0, "icon_y": 160, "desc": "Тонкое и прочное. Подходит для зелий."},
	"ectoplasm": {"name": "Эктоплазма", "sell_price": 10, "icon_x": 16, "icon_y": 160, "desc": "Призрачная субстанция. Очень ценится магами."}
}

var enemy_db = {
	0: {"name": "Слайм", "hp": 6, "dmg": 1, "xp": 1, "drop": "slime_goo", "x": 0, "y": 144, "atk_range": 1, "ap": 1, "is_ranged": false, "desc": "Липкий и медлительный. Самый легкий противник для новичка."},
	1: {"name": "Летучая мышь", "hp": 10, "dmg": 1, "xp": 3, "drop": "bat_wing", "x": 0, "y": 160, "atk_range": 3, "ap": 1, "is_ranged": true, "desc": "Быстрая и назойливая. Плюется сгустками магии с расстояния трех клеток."},
	2: {"name": "Призрак", "hp": 15, "dmg": 2, "xp": 6, "drop": "ectoplasm", "x": 16, "y": 160, "atk_range": 1, "ap": 2, "is_ranged": false, "desc": "Блуждает по лесу. Имеет 2 очка действия. Его прикосновение леденит кровь."}
}

var discovered_enemies = []
var save_path = "user://savegame.json"

func _ready():
	load_game()

func save_game():
	var save_data = {
		"gold": gold,
		"xp": xp,
		"player_hp": player_hp,
		"max_hp": max_hp,
		"discovered_enemies": discovered_enemies,
		"inventory": inventory
	}
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func load_game():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var json = JSON.parse_string(file.get_as_text())
		file.close()
		if json:
			gold = int(json.get("gold", 0))
			xp = int(json.get("xp", 0))
			player_hp = int(json.get("player_hp", 15))
			max_hp = int(json.get("max_hp", 15))
			
			var loaded_enemies = json.get("discovered_enemies", [])
			discovered_enemies.clear()
			for e in loaded_enemies:
				discovered_enemies.append(int(e))
				
			inventory.clear()
			for item in json.get("inventory", []):
				inventory.append(item)

# НОВАЯ ФУНКЦИЯ: Сброс прогресса для новой игры
func reset_game():
	gold = 0
	xp = 0
	player_hp = 15
	max_hp = 15
	inventory.clear()
	discovered_enemies.clear()
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	save_game() # Сохраняем пустое состояние

func add_rewards(xp_amount, drop_item_id):
	xp += xp_amount
	if drop_item_id != "":
		inventory.append(drop_item_id)
	save_game() 

func discover_enemy(id):
	if id not in discovered_enemies:
		discovered_enemies.append(id)
		save_game() 

func buy_item(item_id, price):
	if gold >= price:
		gold -= price
		inventory.append(item_id)
		save_game()
		return true
	return false

func sell_item(item_id):
	if item_id in inventory:
		inventory.erase(item_id)
		gold += item_db[item_id]["sell_price"]
		save_game()
		return true
	return false

func use_item(item_id):
	if item_id in inventory:
		inventory.erase(item_id)
		if item_id == "health_potion":
			player_hp = min(player_hp + 10, max_hp) 
		save_game()
		return true
	return false
