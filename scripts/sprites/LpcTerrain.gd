class_name LpcTerrain
extends RefCounted
## LPC-Gelände für das Feld (Stufe 4): Kacheln aus den Blättern des
## LPC-Basissets (assets/lpc/terrain, Lanea Zimmerman und Daniel Armstrong,
## CC-BY-SA 3.0 / GPL 3.0) — dieselbe Hand wie die Figuren.
##
## Die Blätter haben 32-px-Kacheln. Im Feld gilt weiter TILE = 16 Welt-
## Einheiten; die Sprites werden deshalb auf 0.5 gezeichnet und die Kamera
## zoomt 4-fach. Ergebnis: ein Kunstpixel = zwei Bildschirmpixel, genau wie
## bei den Kampffiguren.
##
## Geländeblätter (grass, dirt, water) sind 3x6 Kacheln groß:
##   Zeile 0-1, Spalte 1-2   vier Innenecken (Ring mit Loch in der Mitte)
##   Zeile 2-4               3x3-Block: Außenecken, Kanten, Füllung in der Mitte
##   Zeile 5                 drei Füll-Varianten

const DIR := "res://assets/lpc/terrain/"
const T := 32     # Kachelgröße in den Blättern
const S := 0.5    # Maßstab im Feld (Welt-Einheiten je Blattpixel)

static var _sheets := {}
static var _cuts := {}

static func sheet(name: String) -> Texture2D:
	if not _sheets.has(name):
		var p := DIR + name + ".png"
		_sheets[name] = load(p) if ResourceLoader.exists(p) else null
	return _sheets[name]

## Sind die Blätter da? (Fehlen sie, fällt das Feld auf den alten Aufbau zurück.)
static func available() -> bool:
	return sheet("grass") != null and sheet("dirt") != null and sheet("water") != null

## Ausschnitt in Blattpixeln.
static func cut(name: String, x: int, y: int, w: int, h: int) -> Texture2D:
	var key := "%s_%d_%d_%d_%d" % [name, x, y, w, h]
	if _cuts.has(key):
		return _cuts[key]
	var sh := sheet(name)
	if sh == null:
		return null
	var at := AtlasTexture.new()
	at.atlas = sh
	at.region = Rect2(x, y, w, h)
	_cuts[key] = at
	return at

## Ganze Kachel (Spalte, Zeile).
static func tile(name: String, tx: int, ty: int) -> Texture2D:
	return cut(name, tx * T, ty * T, T, T)

## Füllkachel eines Geländes — meist die ruhige Mitte, ab und zu eine Variante.
static func fill(name: String, n: float) -> Texture2D:
	if n < 0.58:
		return tile(name, 1, 3)
	return tile(name, int(n * 97.0) % 3, 5)

## Viertelkachel-Übergänge: liefert vier 16x16-Ausschnitte (oben links, oben
## rechts, unten links, unten rechts). Die Argumente sagen, ob der jeweilige
## Nachbar dasselbe Gelände ist. Mit Viertelkacheln gehen auch ein Feld
## breite Wege — ein 3x3-Block allein kann obere und untere Kante nicht in
## derselben Kachel zeigen.
static func quarters(name: String, n: bool, e: bool, s: bool, w: bool,
		ne: bool, se: bool, sw: bool, nw: bool) -> Array:
	return [
		_quarter(name, 0, 0, n, w, nw, Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 3), Vector2i(2, 1)),
		_quarter(name, 1, 0, n, e, ne, Vector2i(2, 2), Vector2i(1, 2), Vector2i(2, 3), Vector2i(1, 1)),
		_quarter(name, 0, 1, s, w, sw, Vector2i(0, 4), Vector2i(1, 4), Vector2i(0, 3), Vector2i(2, 0)),
		_quarter(name, 1, 1, s, e, se, Vector2i(2, 4), Vector2i(1, 4), Vector2i(2, 3), Vector2i(1, 0)),
	]

## Ein Viertel: vert/horz = Nachbar senkrecht bzw. waagerecht vorhanden,
## diag = Diagonalnachbar vorhanden. Die vier Kacheln sind: Außenecke,
## waagerechte Kante (senkrechter Nachbar fehlt), senkrechte Kante
## (waagerechter Nachbar fehlt), Innenecke.
static func _quarter(name: String, qx: int, qy: int, vert: bool, horz: bool, diag: bool,
		corner: Vector2i, edge_h: Vector2i, edge_v: Vector2i, inner: Vector2i) -> Texture2D:
	var t := Vector2i(1, 3)
	if not vert and not horz:
		t = corner
	elif not vert:
		t = edge_h
	elif not horz:
		t = edge_v
	elif not diag:
		t = inner
	return cut(name, t.x * T + qx * 16, t.y * T + qy * 16, 16, 16)
