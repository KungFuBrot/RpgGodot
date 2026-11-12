class_name LpcMock
extends RefCounted
## LPC-Figuren (siehe docs/lpc-umstellung-plan.md) — seit der Freigabe der
## Standard: alle Helden, Dorfbewohner, 13 Monster und 4 Bosse kommen von hier.
## Abschaltbar ueber den Menuepunkt "Art preview (LPC)" (`GameState.lpc_preview`);
## dann greift der alte Weg ueber RigFactory. Der Klassenname ist ein Ueberbleibsel
## aus der Mock-Phase.
##
## LPC-Blattaufbau: Zeilen sind Blickrichtungen (0 hoch, 1 links, 2 runter,
## 3 rechts), Spalten die Einzelbilder. Wir nehmen Zeile 1 (links), weil die
## Gegner links stehen — dieselbe Blickrichtung wie beim bisherigen Rig.

const DIR := "res://assets/lpc/"
## Heldenraster. LPC zeichnet auf 64x64; die Blaetter liegen doppelt so gross
## im Projekt, weil das Rig seine Figuren ebenfalls doppelt aufloest (Held
## 32x56 x BAKE 2) und der Kampf danach nicht mehr skaliert.
const CELL := 128

## Blatt, Spaltenzahl und ob die Bildfolge laeuft oder auf dem letzten Bild haelt.
## Helden-Blaetter, aus den Generator-Ebenen zusammengesetzt und umgefaerbt
## (Werkzeug siehe docs/lpc-umstellung-plan.md): Koerper, Beine, Oberteil, KOPF
## (eigene Ebene!) und Haare. Dateien liegen als heroes/<id>_<anim>.png.
##
## "cols" = Spalten des Blattes, "row" = Zeile im LPC-Raster
## (0 hoch, 1 links, 2 runter, 3 rechts). WICHTIG: Die Kampfszene spiegelt jede
## Heldenfigur (`s.flip_h = true` in BattleStage, Erbe der DTII-Zeit). Wir
## nehmen deshalb die RECHTS-Zeile — gespiegelt blickt sie nach links, also zu
## den Gegnern. Mit Zeile 1 schauten alle vom Feind weg.
## "hurt" hat nur EINE Zeile, deshalb row 0. "hold" haelt ein festes Bild,
## -1 laesst die Folge laufen.
const ROW := 3
const HERO_ANIM := {
	"idle":    {"sheet": "idle", "cols": 2, "row": ROW, "hold": -1},
	"walk":    {"sheet": "walk", "cols": 9, "row": ROW, "hold": -1},
	"run":     {"sheet": "run", "cols": 8, "row": ROW, "hold": -1},
	"attack":  {"sheet": "slash", "cols": 6, "row": ROW, "hold": -1},
	"attack2": {"sheet": "thrust", "cols": 8, "row": ROW, "hold": -1},
	# Dritter Schwung — wer kein eigenes Blatt dafuer hat, stoesst eben nochmal.
	"attack3": {"sheet": "thrust", "cols": 8, "row": ROW, "hold": -1},
	"cast":    {"sheet": "spellcast", "cols": 7, "row": ROW, "hold": -1},
	# Gehaltene Zauberpose: Arme oben, ohne Schleife — fuer das Ritual, in dem
	# die Haende einmal steigen und erst am Ende wieder sinken.
	"cast_hold": {"sheet": "spellcast", "cols": 7, "row": ROW, "hold": 5},
	"aim":     {"sheet": "spellcast", "cols": 7, "row": ROW, "hold": 4},
	"block":   {"sheet": "combat_idle", "cols": 2, "row": ROW, "hold": -1},
	# Echter Jubel statt gehaltener Zauberpose: Arme hoch, drei Bilder.
	"cheer":   {"sheet": "emote", "cols": 3, "row": ROW, "hold": -1},
	"hit":     {"sheet": "hurt", "cols": 6, "row": 0, "hold": -1},
	"down":    {"sheet": "hurt", "cols": 6, "row": 0, "hold": 5},
}

## Abweichungen je Figur. Helen fuehrt ein Langschwert: ihre beiden Schwuenge
## liegen auf DOPPELT so grossen Blaettern (Zelle 256 statt 128), weil die
## Klinge weit ueber die Figur hinausreicht. Die Figur bleibt dabei in der
## Zellmitte, springt beim Posenwechsel also nicht.
## Wally holt zum Angriff eine Armbrust hervor — im Stand traegt er keine.
const HERO_OVERRIDE := {
	"serena": {
		"attack":  {"sheet": "slash", "cols": 6, "row": ROW, "hold": -1, "cell": 256},
		"attack2": {"sheet": "halfslash", "cols": 6, "row": ROW, "hold": -1, "cell": 256},
		# Rueckhand — der dritte Schwung, damit die Schlagfolge sich nicht
		# wiederholt (13 Bilder, das laengste Blatt).
		"attack3": {"sheet": "backslash", "cols": 13, "row": ROW, "hold": -1, "cell": 256},
		# Helen ist Kaempferin, keine Zauberin: fuer Vorbereitung und Deckung
		# die Kampfhaltung MIT Schwert statt der Zauberpose — auf dem
		# Zauberblatt gibt es keine Waffenebene, dort fehlte die Klinge.
		"cast":  {"sheet": "combat_idle", "cols": 2, "row": ROW, "hold": -1},
		"aim":   {"sheet": "combat_idle", "cols": 2, "row": ROW, "hold": 1},
		"block": {"sheet": "combat_idle", "cols": 2, "row": ROW, "hold": 0},
	},
	"rax": {
		# Echte Schussfolge statt gehaltener Pose: anlegen, feuern, nachladen.
		"attack":  {"sheet": "shoot", "cols": 13, "row": ROW, "hold": -1},
		"attack2": {"sheet": "shoot", "cols": 13, "row": ROW, "hold": -1},
		"aim":     {"sheet": "shoot", "cols": 13, "row": ROW, "hold": 8},
	},
}

## Welche unserer Helden ein LPC-Blatt haben. Wally hat im LPC keine Entsprechung
## (es gibt dort keinen Roboter) — er ist aus Plattenpanzer, Schulterstuecken und
## geschlossenem Helm gebaut, alles auf kaltes Metall umgefaerbt, auch die Haut.
const HERO_FILES := {"serena": "serena", "milo": "milo", "rax": "rax"}

## Zusaetzlich fuers Feld: die drei Dorfbewohner (nur Stehen und Gehen).
const FIELD_FILES := {
	"serena": "serena", "milo": "milo", "rax": "rax",
	"npc_elder": "npc_elder", "npc_kid": "npc_kid", "npc_shop": "npc_shop",
}

## Feld-Blickrichtungen auf LPC-Zeilen. Das Feld spiegelt die Seitenansicht
## selbst (Field setzt flip_h bei facing.x < 0), also liefern wir die
## Rechts-Zeile; "up" ist der Ruecken, "down" das Gesicht.
const FIELD_ROW := {"side": 3, "up": 0, "down": 2}

## Gegner: fertig gebackene Streifen in enemies/<id>.png, ein Bild neben dem
## anderen. Die Zellbreite ergibt sich aus Breite/Bilderzahl, die Hoehe ist die
## Bildhoehe — deshalb genuegt hier die Bilderzahl. Wer nur ein Bild hat, kommt
## aus dem Kampfblatt (unbewegte Seitenansicht); die Bewegung macht dort wie
## gehabt die Verformung in BattleFx.
const ENEMY_FRAMES := {
	"schlammschleim": 3, "qualmgeist": 3, "muellgnom": 3, "gierschlund": 3,
	"paragraphengeist": 1, "zinshund": 1, "hetzer": 4, "wutgeist": 3,
	"schlaeger": 1, "hassprediger": 1, "hohlgaenger": 1, "grauschemen": 3,
	"namenlose": 1,
	"boss": 8, "boss2": 4, "boss3": 5, "boss4": 4,
}

static var _cache := {}
static var _sheets := {}
static var _env := -1

## Ist die Vorschau eingeschaltet? Entweder per Umgebungsvariable (Screenshot-
## Laeufe am Rechner) oder ueber den Menuepunkt — Letzteres ist der einzige Weg
## im Web-Export, wo es keine Umgebungsvariablen gibt. Der Menue-Schalter wird
## bei JEDEM Aufruf gelesen, damit er sofort wirkt; nur die Umgebungsvariable
## wird gemerkt.
static func active() -> bool:
	if _env < 0:
		_env = 1 if OS.get_environment("LPCMOCK") != "" else 0
	return _env == 1 or GameState.lpc_preview

static func _sheet(file: String) -> Texture2D:
	if _sheets.has(file):
		return _sheets[file]
	var p := DIR + file
	var t: Texture2D = load(p) if ResourceLoader.exists(p) else null
	_sheets[file] = t
	return t

static func _cut(file: String, x: int, y: int, w: int, h: int) -> Texture2D:
	var key := "%s_%d_%d_%d_%d" % [file, x, y, w, h]
	if _cache.has(key):
		return _cache[key]
	var sheet := _sheet(file)
	if sheet == null:
		return null
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(x, y, w, h)
	_cache[key] = at
	return at

## Held*in im Kampf. Gibt null zurueck, wenn Figur oder Pose (noch) nicht
## abgebildet sind — dann faellt der Aufrufer auf das bisherige Rig zurueck.
static func hero(id: String, frame: int, anim: String) -> Texture2D:
	var f: String = HERO_FILES.get(id, "")
	if f == "":
		return null
	var over: Dictionary = HERO_OVERRIDE.get(id, {})
	var d: Dictionary = over.get(anim, HERO_ANIM.get(anim, {}))
	if d.is_empty():
		return null
	var cols: int = d["cols"]
	var hold: int = d["hold"]
	var cell: int = int(d.get("cell", CELL))
	var col: int = frame % cols if hold < 0 else mini(hold, cols - 1)
	return _cut("heroes/%s_%s.png" % [f, d["sheet"]], col * cell, int(d["row"]) * cell, cell, cell)

## Gegner im Kampf. Die Bosse bringen mehr als Atmen mit — ihre Blaetter haben
## mehrere Zeilen, aus denen Angriff und Aufbaeumen gebacken sind (enemies/
## <id>_attack.png bzw. _roar.png). Fuer alles andere (Treffer, Zusammenbruch)
## und fuer die normalen Gegner bleibt es bei der Verformung in BattleFx.
static func monster(id: String, frame: int, anim := "idle") -> Texture2D:
	if not ENEMY_FRAMES.has(id):
		return null
	var file := "enemies/%s.png" % id
	if anim == "attack" or anim == "roar":
		var extra := "enemies/%s_%s.png" % [id, anim]
		if _sheet(extra) != null:
			file = extra
	var sheet := _sheet(file)
	if sheet == null:
		return null
	# Die Zellbreite steckt im LEERLAUF-Blatt (Breite / Bilderzahl). Die
	# Zusatzblaetter nutzen dieselbe Zelle, koennen aber mehr oder weniger
	# Bilder haben — deshalb ihre Anzahl daraus ableiten statt zu raten.
	var idle_sheet := _sheet("enemies/%s.png" % id)
	if idle_sheet == null:
		return null
	var w: int = maxi(int(idle_sheet.get_width() / maxi(int(ENEMY_FRAMES[id]), 1)), 1)
	var h: int = sheet.get_height()
	var n: int = maxi(int(round(float(sheet.get_width()) / float(w))), 1)
	return _cut(file, (frame % n) * w, 0, w, h)

## Bilderzahl des Streifens (0, wenn der Gegner nicht umgestellt ist).
static func monster_frames(id: String) -> int:
	return int(ENEMY_FRAMES.get(id, 0))

## Bilderzahl einer Heldenpose, wie `hero` sie tatsaechlich durchlaeuft
## (0 = Figur oder Pose nicht abgebildet). Gehaltene Posen zaehlen als ein Bild.
## Der Kampf taktet danach — frueher lief der Zaehler nach der Laenge der
## rig3d-Streifen (z. B. 22 beim Gehen) und sprang deshalb mitten im
## 9-Bilder-Zyklus zurueck.
static func hero_frames(id: String, anim: String) -> int:
	if not HERO_FILES.has(id):
		return 0
	var over: Dictionary = HERO_OVERRIDE.get(id, {})
	var d: Dictionary = over.get(anim, HERO_ANIM.get(anim, {}))
	if d.is_empty():
		return 0
	return 1 if int(d["hold"]) >= 0 else int(d["cols"])

## Bilderzahl einer Gegner-Animation: Angriff und Aufbaeumen haben eigene
## Blaetter, alles andere laeuft auf dem Leerlauf-Streifen.
static func monster_anim_frames(id: String, anim: String) -> int:
	if not ENEMY_FRAMES.has(id):
		return 0
	var idle_sheet := _sheet("enemies/%s.png" % id)
	if idle_sheet == null:
		return 0
	var n_idle: int = maxi(int(ENEMY_FRAMES[id]), 1)
	if anim == "attack" or anim == "roar":
		var extra := _sheet("enemies/%s_%s.png" % [id, anim])
		if extra != null:
			var w: int = maxi(int(idle_sheet.get_width() / n_idle), 1)
			return maxi(int(round(float(extra.get_width()) / float(w))), 1)
	return n_idle

## Figur auf der Karte. dir: "side" | "up" | "down".
static func field(id: String, walking: bool, frame: int, dir: String) -> Texture2D:
	var f: String = FIELD_FILES.get(id, "")
	if f == "":
		return null
	var sheet := "walk" if walking else "idle"
	var cols := 9 if walking else 2
	var row: int = int(FIELD_ROW.get(dir, 3))
	return _cut("heroes/%s_%s.png" % [f, sheet], (frame % cols) * CELL, row * CELL, CELL, CELL)
