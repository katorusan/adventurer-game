extends Node

var sound_bank = {}

func _ready():
	# Генерируем наши синтезированные звуки при запуске
	sound_bank["click"] = _generate_tone(800.0, 0.05, 0.4)    # Клик
	sound_bank["hit"] = _generate_noise(0.1, 0.5)             # Удар мечом
	sound_bank["shoot"] = _generate_sweep(800.0, 200.0, 0.15, 0.4) # Выстрел
	sound_bank["potion"] = _generate_arpeggio([400.0, 600.0, 800.0], 0.08, 0.3) # Зелье
	sound_bank["win"] = _generate_arpeggio([440.0, 554.0, 659.0, 880.0], 0.1, 0.4) # Победа
	sound_bank["lose"] = _generate_sweep(400.0, 100.0, 0.5, 0.4) # Поражение

# Функция для проигрывания звука
func play(sound_name: String):
	if sound_bank.has(sound_name):
		var player = AudioStreamPlayer.new()
		player.stream = sound_bank[sound_name]
		add_child(player)
		player.play()
		# Удаляем плеер, когда звук закончится
		player.finished.connect(player.queue_free)

# --- АВТОМАТИЧЕСКОЕ ПОДКЛЮЧЕНИЕ К КНОПКАМ ---
func connect_ui_sounds(node: Node):
	if node is Button:
		node.pressed.connect(func(): play("click"))
	for child in node.get_children():
		connect_ui_sounds(child)

# --- ГЕНЕРАТОРЫ ЗВУКА (Встроенные в Godot) ---
func _generate_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var mix_rate = 44100
	var frames = int(mix_rate * duration)
	var data = PackedByteArray()
	for i in range(frames):
		var time = float(i) / mix_rate
		var val = sin(time * freq * TAU)
		var fade = 1.0 - (float(i) / frames)
		var int_val = int(val * volume * fade * 32767.0)
		data.append(int_val & 0xFF)
		data.append((int_val >> 8) & 0xFF)
	return _create_wav(data, mix_rate)

func _generate_noise(duration: float, volume: float) -> AudioStreamWAV:
	var mix_rate = 44100
	var frames = int(mix_rate * duration)
	var data = PackedByteArray()
	for i in range(frames):
		var val = randf_range(-1.0, 1.0)
		var fade = 1.0 - (float(i) / frames)
		var int_val = int(val * volume * fade * 32767.0)
		data.append(int_val & 0xFF)
		data.append((int_val >> 8) & 0xFF)
	return _create_wav(data, mix_rate)

func _generate_sweep(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var mix_rate = 44100
	var frames = int(mix_rate * duration)
	var data = PackedByteArray()
	var current_phase = 0.0
	for i in range(frames):
		var time = float(i) / frames
		var freq = lerp(start_freq, end_freq, time)
		current_phase += (freq * TAU) / mix_rate
		var fade = 1.0 - time
		var int_val = int(sin(current_phase) * volume * fade * 32767.0)
		data.append(int_val & 0xFF)
		data.append((int_val >> 8) & 0xFF)
	return _create_wav(data, mix_rate)

func _generate_arpeggio(freqs: Array, note_duration: float, volume: float) -> AudioStreamWAV:
	var mix_rate = 44100
	var total_frames = int(mix_rate * note_duration * freqs.size())
	var data = PackedByteArray()
	var frame_index = 0
	for f in freqs:
		var frames = int(mix_rate * note_duration)
		for i in range(frames):
			var time = float(i) / mix_rate
			var val = sin(time * f * TAU)
			var fade = 1.0 - (float(i) / frames)
			var int_val = int(val * volume * fade * 32767.0)
			data.append(int_val & 0xFF)
			data.append((int_val >> 8) & 0xFF)
	return _create_wav(data, mix_rate)

func _create_wav(data: PackedByteArray, mix_rate: int) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav
