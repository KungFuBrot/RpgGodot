extends Node
## Wurzelknoten: wechselt zwischen Feld (Stadt/Weltkarte/Dungeon) und Kampf,
## inkl. Überblendungen. Feldposition wird beim Kampfstart gemerkt.

var current_screen: Node = null
var fade_rect: ColorRect
var touch: TouchControls

# Merker, um nach einem Kampf an dieselbe Stelle zurückzukehren.
var field_return := {"map": "town", "spawn": "start", "pos": Vector2i(-1, -1)}
var last_battle_was_final_boss := false
var battle_snapshot := {}  # Stand vor dem Kampf — nach einer Niederlage geht es von dort weiter

func _ready() -> void:
	GameState.main = self
	_setup_input()
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade_rect)
	# Bildschirm-Steuerung für Geräte ohne Tastatur (Web/Touch); bleibt über
	# allen Szenen bestehen und speist die Input-Actions ein.
	touch = TouchControls.new()
	add_child(touch)
	if OS.get_environment("PROTO3D") != "":
		# Prototyp: 3D-Figur zu Pixel-Art backen (nicht headless starten).
		var proto := Proto3D.new()
		add_child(proto)
		await proto.run(OS.get_environment("PROTO3D"))
		get_tree().quit()
		return
	if OS.get_environment("AUTOBATTLE") != "":
		_auto_series()
		return
	if OS.get_environment("SPELLSHOT") != "":
		goto_map("town", "start")
		await get_tree().create_timer(0.5).timeout
		start_battle(["schlammschleim", "qualmgeist", "muellgnom"], "dungeon", Vector2i(4, 10))
	elif OS.get_environment("BOSSSHOT") != "":
		# Boss-Showcase: env BOSSKEY wählt boss/boss2/boss3 (Standard: boss).
		goto_map("town", "start")
		await get_tree().create_timer(0.5).timeout
		var bid := OS.get_environment("BOSSKEY")
		if bid == "":
			bid = "boss"
		var bmap: String = {"boss": "dungeon", "boss2": "dungeon2", "boss3": "dungeon3",
			"boss4": "dungeon4"}[bid]
		start_battle([bid], bmap, Vector2i(4, 10))
	else:
		show_title()
		if OS.get_environment("SHOT") != "":
			_shot_tour()

## Temporärer Debug-Rundgang: Screenshots von Feld und Bosskampf (env SHOT=Zielordner).
func _shot_tour() -> void:
	await get_tree().create_timer(2.0).timeout
	_snap("title")
	_show_intro()
	await get_tree().create_timer(2.6).timeout
	_snap("intro")
	goto_map("town", "start")
	await get_tree().create_timer(2.0).timeout
	_snap("town")
	goto_map("world", "from_town")
	await get_tree().create_timer(2.0).timeout
	_snap("world")
	goto_map("dungeon", "entrance")
	await get_tree().create_timer(2.0).timeout
	_snap("dungeon")
	goto_map("dungeon2", "entrance")
	await get_tree().create_timer(2.0).timeout
	_snap("dungeon2")
	goto_map("dungeon3", "entrance")
	await get_tree().create_timer(2.0).timeout
	_snap("dungeon3")
	goto_map("dungeon4", "entrance")
	await get_tree().create_timer(2.0).timeout
	_snap("dungeon4")
	# Berührungs-Test: neben den Boss stellen und hineinlaufen — muss den Kampf starten.
	goto_map("dungeon", "", Vector2i(17, 10))
	await get_tree().create_timer(1.5).timeout
	_snap("boss_before_touch")
	(current_screen as Field)._try_step(Vector2i(1, 0))
	await get_tree().create_timer(7.0).timeout
	_snap("battle1")
	await get_tree().create_timer(3.0).timeout
	_snap("battle2")
	start_battle(["schlammschleim", "qualmgeist", "muellgnom"], "dungeon", Vector2i(4, 10))
	await get_tree().create_timer(2.5).timeout
	_snap("battle_toxic")
	start_battle(["gierschlund", "zinshund", "paragraphengeist"], "dungeon2", Vector2i(4, 10))
	await get_tree().create_timer(2.5).timeout
	_snap("battle_gold")
	start_battle(["hetzer", "schlaeger", "hassprediger"], "dungeon3", Vector2i(4, 10))
	await get_tree().create_timer(2.5).timeout
	_snap("battle_hate")
	start_battle(["boss2"], "dungeon2", Vector2i(4, 10))
	await get_tree().create_timer(7.0).timeout
	_snap("battle_boss2")
	start_battle(["boss3"], "dungeon3", Vector2i(4, 10))
	await get_tree().create_timer(7.0).timeout
	_snap("battle_boss3")
	start_battle(["hohlgaenger", "grauschemen", "namenlose"], "dungeon4", Vector2i(4, 10))
	await get_tree().create_timer(2.5).timeout
	_snap("battle_void")
	start_battle(["boss4"], "dungeon4", Vector2i(4, 10))
	await get_tree().create_timer(7.0).timeout
	_snap("battle_boss4")
	get_tree().quit()

func _snap(shot_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("SHOT") + "/" + shot_name + ".png")

func goto_map(map_id: String, spawn_id: String, exact_pos := Vector2i(-1, -1)) -> void:
	await _fade(1.0, 0.25)
	_clear_screen()
	var field := Field.new()
	field.map_id = map_id
	field.spawn_id = spawn_id
	field.exact_pos = exact_pos
	add_child(field)
	current_screen = field
	AudioManager.play_music(map_id)
	await _fade(0.0, 0.35)

func start_battle(enemy_ids: Array, from_map: String, pos: Vector2i) -> void:
	field_return = {"map": from_map, "spawn": "", "pos": pos}
	battle_snapshot = GameState.snapshot()
	last_battle_was_final_boss = enemy_ids.has("boss4")
	AudioManager.play_sfx("encounter")
	# Kurzes Aufblitzen als Kampf-Übergang.
	for i in 2:
		fade_rect.color = Color.WHITE
		await _fade(0.8, 0.07)
		await _fade(0.0, 0.07)
	fade_rect.color = Color.BLACK
	await _fade(1.0, 0.25)
	_clear_screen()
	var battle := Battle.new()
	battle.enemy_ids = enemy_ids
	battle.arena_theme = {"dungeon": "toxic", "dungeon2": "gold",
		"dungeon3": "hate", "dungeon4": "void"}.get(from_map, "toxic")
	battle.finished.connect(_on_battle_finished)
	add_child(battle)
	current_screen = battle
	# Boss-Kämpfe bringen ihre eigene Musik mit.
	var song := "battle"
	for id in enemy_ids:
		song = GameState.ENEMIES[id].get("song", song)
	AudioManager.play_music(song)
	await _fade(0.0, 0.35)

func _on_battle_finished(victory: bool) -> void:
	if not victory:
		# Niederlage: zurück an die Stelle vor dem Kampf, mit dem Stand von
		# davor (Items kommen zurück, alle stehen mit mindestens halben LP/MP
		# wieder auf). Früher hieß das: Stufe 1 und ab in die Stadt.
		GameState.restore(battle_snapshot)
		goto_map(field_return["map"], "", field_return["pos"])
	elif last_battle_was_final_boss and GameState.boss4_defeated:
		_show_ending()
	else:
		goto_map(field_return["map"], "", field_return["pos"])

## Der Boss ist gefallen — das Spiel endet mit dem Abspann.
func _show_ending() -> void:
	await _fade(1.0, 0.6)
	_clear_screen()
	var ending := Ending.new()
	ending.restart.connect(_on_ending_restart)
	add_child(ending)
	current_screen = ending
	await _fade(0.0, 0.8)

func _on_ending_restart() -> void:
	show_title()

## Blendet den Titelbildschirm ein (Spielstart und nach dem Abspann).
func show_title() -> void:
	await _fade(1.0, 0.25)
	_clear_screen()
	var title := Title.new()
	title.start_game.connect(_on_title_start)
	add_child(title)
	current_screen = title
	AudioManager.play_music("title")
	await _fade(0.0, 0.5)

func _on_title_start() -> void:
	GameState.reset_all()
	_show_intro()

## Erzähl-Auftakt: der Anfang der Geschichte, danach beginnt das Spiel.
func _show_intro() -> void:
	await _fade(1.0, 0.3)
	_clear_screen()
	var intro := Intro.new()
	intro.done.connect(_on_intro_done)
	add_child(intro)
	current_screen = intro
	await _fade(0.0, 0.6)

func _on_intro_done() -> void:
	goto_map("town", "start")

func _clear_screen() -> void:
	if is_instance_valid(current_screen):
		current_screen.queue_free()
	current_screen = null

func _fade(target_alpha: float, dur: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", target_alpha, dur)
	await tw.finished

func _setup_input() -> void:
	var bindings := {
		"move_up": [KEY_UP, KEY_W],
		"move_down": [KEY_DOWN, KEY_S],
		"move_left": [KEY_LEFT, KEY_A],
		"move_right": [KEY_RIGHT, KEY_D],
		"confirm": [KEY_Z, KEY_ENTER, KEY_SPACE],
		"cancel": [KEY_X, KEY_ESCAPE],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

## ---------- Balancing-Lauf (env AUTOBATTLE) ----------
## Lässt einen Bot die Bosskämpfe im Zeitraffer durchspielen und druckt je
## Boss und Bot Siegquote und Rundenzahl. Läuft headless:
##   AUTOBATTLE=all|boss|boss2|boss3|boss4   welche Bosse
##   AUTOBOT=smart|naive                     nur ein Bot (Standard: beide)
##   AUTORUNS=20                             Läufe je Boss und Bot
##   AUTOLEVEL=-1                            Stufe relativ zur erwarteten
##   AUTOSPEED=40                            Zeitraffer-Faktor
func _auto_series() -> void:
	var which := OS.get_environment("AUTOBATTLE")
	var ids: Array = ["boss", "boss2", "boss3", "boss4"] if which == "all" else [which]
	var bots: Array = ["smart", "naive"]
	if OS.get_environment("AUTOBOT") != "":
		bots = [OS.get_environment("AUTOBOT")]
	var runs := maxi(int(OS.get_environment("AUTORUNS")), 1) if OS.get_environment("AUTORUNS") != "" else 20
	var delta := int(OS.get_environment("AUTOLEVEL"))
	var speed := float(OS.get_environment("AUTOSPEED")) if OS.get_environment("AUTOSPEED") != "" else 40.0
	Engine.time_scale = speed
	for pair: String in OS.get_environment("AUTOTUNE").split(",", false):
		var kv := pair.split("=")
		if kv.size() == 2:
			GameState.tuning_override[kv[0].strip_edges()] = float(kv[1])
	for id: String in ids:
		for bot: String in bots:
			var wins := 0
			var rounds_all := 0
			var rounds_win := 0
			var stuck := 0
			var standing := 0
			var boss_left := 0.0
			for r in runs:
				GameState.sim_setup(id, delta)
				var res: Dictionary = await _auto_one(id, bot)
				rounds_all += int(res["rounds"])
				boss_left += float(res["boss_left"])
				if res["stuck"]:
					stuck += 1
				elif res["win"]:
					wins += 1
					rounds_win += int(res["rounds"])
					standing += int(res["standing"])
			var lvl: int = int(GameState.SIM_SETUP[id]["level"]) + delta
			print("AUTOBATTLE %-5s %-5s L%-2d  wins %2d/%-2d (%3.0f%%)  boss-hp-left %3.0f%%  rounds avg %4.1f  win-rounds %4.1f  standing %3.1f  stuck %d" % [
				id, bot, lvl, wins, runs, 100.0 * wins / runs, 100.0 * boss_left / runs,
				float(rounds_all) / runs,
				float(rounds_win) / maxi(wins, 1),
				float(standing) / maxi(wins, 1), stuck])
	Engine.time_scale = 1.0
	get_tree().quit()

## Ein einzelner Bot-Kampf. "stuck" meldet einen Kampf, der nicht zu Ende kam.
func _auto_one(id: String, bot: String) -> Dictionary:
	_clear_screen()
	await get_tree().process_frame
	var battle := Battle.new()
	battle.enemy_ids = [id]
	battle.arena_theme = {"boss": "toxic", "boss2": "gold", "boss3": "hate", "boss4": "void"}.get(id, "toxic")
	battle.auto_mode = bot
	var outcome := {"done": false, "win": false}
	battle.finished.connect(func(v: bool):
		outcome["done"] = true
		outcome["win"] = v)
	add_child(battle)
	current_screen = battle
	var started := Time.get_ticks_msec()
	while not outcome["done"] and Time.get_ticks_msec() - started < 120000:
		await get_tree().process_frame
	var standing := 0
	for m in GameState.party:
		if m["hp"] > 0:
			standing += 1
	var left := 0.0
	for e in battle.enemies:
		if e["is_boss"]:
			left = clampf(float(e["hp"]) / float(e["max_hp"]), 0.0, 1.0)
	return {"win": outcome["win"], "rounds": battle.round_no, "standing": standing,
		"stuck": not outcome["done"], "boss_left": left}
