class_name Fx
## Gemeinsame HD-2D-Bildeffekte im Octopath-Stil: Tilt-Shift-Tiefenunschärfe
## als Screen-Space-Shader sowie weiche 2D-Punktlichter für Laternen,
## Fackeln und Kristalle. Alles prozedural, keine Assets.

# Blur-Stärke wächst quadratisch mit dem Abstand zum Fokusband — oben (fern)
# stärker als unten (nah), wie eine Miniatur-Diorama-Aufnahme.
const TILT_SHADER_CODE := "
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float top_blur = 3.0;
uniform float bottom_blur = 2.2;
uniform float focus_center = 0.5;
uniform float focus_width = 0.18;
uniform float desat : hint_range(0.0, 1.0) = 0.16;
uniform float contrast = 1.06;
uniform float grain = 0.02;

void fragment() {
	float d = abs(SCREEN_UV.y - focus_center) - focus_width;
	float t = clamp(d / 0.35, 0.0, 1.0);
	t *= t;
	float radius = t * (SCREEN_UV.y < focus_center ? top_blur : bottom_blur);
	vec2 px = SCREEN_PIXEL_SIZE * radius;
	const vec2 taps[12] = {
		vec2(-0.326, -0.406), vec2(-0.840, -0.074), vec2(-0.696, 0.457),
		vec2(-0.203, 0.621), vec2(0.962, -0.195), vec2(0.473, -0.480),
		vec2(0.519, 0.767), vec2(0.185, -0.893), vec2(0.507, 0.064),
		vec2(0.896, 0.412), vec2(-0.322, -0.933), vec2(-0.792, -0.598)
	};
	vec4 col = texture(screen_tex, SCREEN_UV);
	for (int i = 0; i < 12; i++) {
		col += texture(screen_tex, SCREEN_UV + taps[i] * px);
	}
	vec3 c = (col / 13.0).rgb;
	// Filmischer Grade im SELBEN Pass: der Kompatibilitäts-Renderer kopiert
	// den Screen nur einmal pro Layer — ein zweiter Screen-Shader würde die
	// Unschärfe wieder verwerfen. Also: Entsättigung, Kontrast, kühle
	// Schatten/warme Lichter und feines animiertes Filmkorn direkt hier.
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(lum), desat);
	c = (c - 0.5) * contrast + 0.5;
	c += (0.5 - lum) * vec3(-0.02, 0.0, 0.035);
	float g = fract(sin(dot(floor(SCREEN_UV * vec2(960.0, 540.0))
		+ vec2(TIME * 173.0, TIME * 311.0), vec2(127.1, 311.7))) * 43758.5453) - 0.5;
	c += g * grain;
	COLOR = vec4(c, 1.0);
}
"

static var _tilt_shader: Shader
static var _light_tex: ImageTexture

## Vollbild-Rechteck mit Tiefenunschärfe; als erstes Kind der UI-CanvasLayer
## einhängen, damit HUD und Textboxen scharf bleiben.
static func tilt_shift(top := 3.0, bottom := 2.2, center := 0.5, width := 0.18) -> ColorRect:
	if _tilt_shader == null:
		_tilt_shader = Shader.new()
		_tilt_shader.code = TILT_SHADER_CODE
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = _tilt_shader
	mat.set_shader_parameter("top_blur", top)
	mat.set_shader_parameter("bottom_blur", bottom)
	mat.set_shader_parameter("focus_center", center)
	mat.set_shader_parameter("focus_width", width)
	rect.material = mat
	return rect

# Wasser-Shimmer: helle Wellenlinien wandern in Weltkoordinaten über alle
# Wasserkacheln hinweg (nicht pro Kachel wiederholt), plus leichtes Wogen.
const WATER_SHADER_CODE := "
shader_type canvas_item;
varying vec2 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	// COLOR enthält hier bereits Textur * Modulate/Polygonfarbe — so funktioniert
	// das Material auch auf untexturierten, eingefärbten Polygonen (Flutwelle).
	vec4 col = COLOR;
	float w = sin(world_pos.x * 0.13 + TIME * 1.1)
			+ sin(world_pos.y * 0.19 - TIME * 0.8)
			+ sin((world_pos.x + world_pos.y) * 0.09 + TIME * 0.6);
	w /= 3.0;
	float crest = smoothstep(0.55, 1.0, w);
	float trough = smoothstep(0.55, 1.0, -w);
	col.rgb += crest * vec3(0.16, 0.20, 0.24) * col.a;
	col.rgb -= trough * vec3(0.05, 0.07, 0.09) * col.a;
	COLOR = col;
}
"

# Zerfall in Pixelblöcken (passend zur Pixel-Art): progress 0→1 löst den
# Körper auf, die Zerfallskante glüht kurz in edge_color.
const DISSOLVE_SHADER_CODE := "
shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.62, 0.25, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 col = COLOR;
	float n = hash(floor(UV * 22.0));
	float d = n - progress * 1.15;
	if (d < 0.0) {
		col.a = 0.0;
	} else if (d < 0.14 && col.a > 0.05) {
		col.rgb = edge_color.rgb * 1.6;
	}
	COLOR = col;
}
"

static var _dissolve_shader: Shader

## Pro sterbender Figur ein eigenes Material (progress wird pro Instanz getweent).
static func dissolve_material(edge := Color(1.0, 0.62, 0.25)) -> ShaderMaterial:
	if _dissolve_shader == null:
		_dissolve_shader = Shader.new()
		_dissolve_shader.code = DISSOLVE_SHADER_CODE
	var m := ShaderMaterial.new()
	m.shader = _dissolve_shader
	m.set_shader_parameter("progress", 0.0)
	m.set_shader_parameter("edge_color", edge)
	return m

# Radiale Screen-Stoßwelle mit chromatischer Aberration auf dem Ring.
const SHOCKWAVE_SHADER_CODE := "
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.0;
uniform float width = 0.09;
uniform float strength = 0.035;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = uv - center;
	d.x *= 1.777;
	float dist = length(d);
	float ring = 1.0 - smoothstep(0.0, width, abs(dist - radius));
	vec2 dir = normalize(d + vec2(0.00001));
	dir.x /= 1.777;
	vec2 off = dir * ring * strength * (1.0 - radius);
	vec3 col;
	col.r = texture(screen_tex, uv - off * 1.6).r;
	col.g = texture(screen_tex, uv - off).g;
	col.b = texture(screen_tex, uv - off * 0.4).b;
	COLOR = vec4(col, 1.0);
}
"

# Aufsteigendes Hitzeflimmern (UV-Wobble) für Feuer-Momente.
const HAZE_SHADER_CODE := "
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float strength = 0.004;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y * 70.0 + TIME * 9.0) * strength;
	uv.y += cos(uv.x * 55.0 + TIME * 6.0) * strength * 0.5;
	COLOR = texture(screen_tex, uv);
}
"

static var _shock_shader: Shader
static var _haze_shader: Shader

## Pro Stoßwelle ein eigenes Material (center/radius werden getweent).
static func shockwave_material() -> ShaderMaterial:
	if _shock_shader == null:
		_shock_shader = Shader.new()
		_shock_shader.code = SHOCKWAVE_SHADER_CODE
	var m := ShaderMaterial.new()
	m.shader = _shock_shader
	return m

static func heat_haze_material() -> ShaderMaterial:
	if _haze_shader == null:
		_haze_shader = Shader.new()
		_haze_shader.code = HAZE_SHADER_CODE
	var m := ShaderMaterial.new()
	m.shader = _haze_shader
	return m

static var _water_shader: Shader
static var _water_mat: ShaderMaterial

## Gemeinsames Wasser-Material (einmalig erzeugt) für alle Wasserkacheln.
static func water_material() -> ShaderMaterial:
	if _water_mat == null:
		_water_shader = Shader.new()
		_water_shader.code = WATER_SHADER_CODE
		_water_mat = ShaderMaterial.new()
		_water_mat.shader = _water_shader
	return _water_mat

## „Heiße" HDR-Farbe: RGB über 1.0 geboostet, damit echtes 2D-Bloom anspringt.
## Im Web (gl_compatibility, kein HDR-2D) bleibt die Farbe unverändert — die
## vorhandenen additiven Fake-Glows sind dort weiterhin der Look.
static func hot(c: Color, boost := 1.8) -> Color:
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return c
	return Color(c.r * boost, c.g * boost, c.b * boost, c.a)

## Echtes 2D-Bloom über WorldEnvironment (wirkt nur mit hdr_2d + Forward+;
## im Web still ignoriert). Einmal pro Szene als Kind einhängen.
static func glow_environment() -> WorldEnvironment:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.glow_hdr_threshold = 1.1
	env.glow_intensity = 0.5
	env.glow_bloom = 0.0  # >0 legt einen globalen Helligkeitsschleier über alles
	# Nur zwei enge Blur-Stufen — die weiten Standard-Stufen (3/5) waschen
	# sonst die ganze Szene in der Farbe der hellsten Lichtquelle aus.
	for i in range(1, 8):
		env.set("glow_levels/%d" % i, 0.0)
	env.set("glow_levels/1", 0.8)
	env.set("glow_levels/3", 0.5)
	var we := WorldEnvironment.new()
	we.environment = env
	return we

## Weiche radiale Falloff-Textur für PointLight2D (smoothstep, 128 px).
static func light_texture() -> Texture2D:
	if _light_tex != null:
		return _light_tex
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d := Vector2(x - 63.5, y - 63.5).length() / 64.0
			var v := clampf(1.0 - d, 0.0, 1.0)
			v = v * v * (3.0 - 2.0 * v)
			img.set_pixel(x, y, Color(1, 1, 1, v))
	_light_tex = ImageTexture.create_from_image(img)
	return _light_tex

## radius = Weltpixel bis zum Lichtrand.
static func point_light(color: Color, radius: float, energy := 1.0) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_texture()
	l.color = color
	l.energy = energy
	l.texture_scale = radius / 64.0
	l.blend_mode = Light2D.BLEND_MODE_ADD
	return l

## Unruhiges Fackelflackern. Erst aufrufen, wenn das Licht im Baum hängt.
static func flicker(l: PointLight2D, base_energy: float) -> void:
	var tw := l.create_tween().set_loops()
	tw.tween_property(l, "energy", base_energy * (0.78 + randf() * 0.12), 0.09 + randf() * 0.08)
	tw.tween_property(l, "energy", base_energy * (1.08 + randf() * 0.14), 0.11 + randf() * 0.09)
	tw.tween_property(l, "energy", base_energy * 0.92, 0.08 + randf() * 0.06)

## Ruhiges An- und Abschwellen, z. B. für Kristalle.
static func pulse(l: PointLight2D, base_energy: float, period := 1.6) -> void:
	var tw := l.create_tween().set_loops()
	tw.tween_property(l, "energy", base_energy * 1.25, period * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(l, "energy", base_energy * 0.8, period * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ---------- Figuren-Shader (Kampf) ----------
# Ein Material je Kämpfer. Alles bleibt im Pixelraster — nichts wird gestreckt
# oder weichgezeichnet:
#   flash        weißer Trefferblitz (funktioniert auch im Web, wo es kein
#                HDR-Überstrahlen gibt)
#   rim_col      Kantenlicht in der Arenafarbe an der dem Licht zugewandten
#                Seite — bindet die Figur in die Szene ein
#   outline_col  Umriss für die Zielauswahl
#   breathe      Atmen für Figuren mit nur EINEM Bild: der Oberkörper sinkt im
#                Takt um einen Kunstpixel ab (klassisches Zwei-Bild-Atmen)
# "texel" = Bildschirmpixel je Kunstpixel (LPC-Blätter liegen doppelt groß vor).
const UNIT_SHADER_CODE := "
shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 rim_col : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec2 rim_dir = vec2(-1.0, -1.0);
uniform vec4 outline_col : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float texel = 2.0;
uniform float breathe = 0.0;
uniform float rate = 0.4;
uniform float phase = 0.0;
uniform float split = 0.55;
varying float v_y;
varying vec4 v_col;

void vertex() {
	v_y = VERTEX.y < 0.0 ? 0.0 : 1.0;
	v_col = COLOR;
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * texel;
	vec2 uv = UV;
	if (breathe > 0.0 && v_y < split) {
		uv.y -= px.y * breathe * step(0.5, fract(TIME * rate + phase));
	}
	vec4 tex = texture(TEXTURE, uv);
	vec4 col = tex * v_col;
	if (rim_col.a > 0.0 && tex.a > 0.5) {
		float open = 1.0 - texture(TEXTURE, uv + rim_dir * px).a;
		col.rgb += rim_col.rgb * rim_col.a * open;
	}
	col.rgb = mix(col.rgb, flash_col.rgb, flash * step(0.05, tex.a));
	if (outline_col.a > 0.0 && tex.a < 0.1) {
		float n = texture(TEXTURE, uv + vec2(px.x, 0.0)).a
			+ texture(TEXTURE, uv - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, uv + vec2(0.0, px.y)).a
			+ texture(TEXTURE, uv - vec2(0.0, px.y)).a;
		if (n > 0.5) {
			col = outline_col;
		}
	}
	COLOR = col;
}
"

static var _unit_shader: Shader

static func unit_material(rim := Color(0, 0, 0, 0)) -> ShaderMaterial:
	if _unit_shader == null:
		_unit_shader = Shader.new()
		_unit_shader.code = UNIT_SHADER_CODE
	var m := ShaderMaterial.new()
	m.shader = _unit_shader
	m.set_shader_parameter("rim_col", rim)
	return m

# ---------- Kulissen-Shader (Kampf) ----------
# Färbt eine Hintergrund-Ebene auf die Farbleiter der Arena um (Helligkeit ->
# dunkel/mittel/hell), damit Ebenen aus verschiedenen Quellen wie aus einem
# Guss wirken. "keep" lässt einen Teil der Originalfarbe stehen, "depth"
# mischt ferne Ebenen in den Dunst ("fog").
const BACKDROP_SHADER_CODE := "
shader_type canvas_item;
uniform vec4 c_dark : source_color = vec4(0.02, 0.05, 0.03, 1.0);
uniform vec4 c_mid : source_color = vec4(0.1, 0.3, 0.15, 1.0);
uniform vec4 c_light : source_color = vec4(0.6, 1.0, 0.5, 1.0);
uniform vec4 fog : source_color = vec4(0.1, 0.2, 0.1, 1.0);
uniform float keep : hint_range(0.0, 1.0) = 0.3;
uniform float depth : hint_range(0.0, 1.0) = 0.0;
uniform float gain = 1.0;

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float l = dot(t.rgb, vec3(0.299, 0.587, 0.114));
	vec3 g = l < 0.5 ? mix(c_dark.rgb, c_mid.rgb, l * 2.0) : mix(c_mid.rgb, c_light.rgb, (l - 0.5) * 2.0);
	vec3 c = mix(g, t.rgb, keep) * gain;
	c = mix(c, fog.rgb, depth);
	COLOR = vec4(c, t.a);
}
"

static var _backdrop_shader: Shader

static func backdrop_material(dark: Color, mid: Color, light: Color, fog: Color,
		keep: float, depth: float, gain := 1.0) -> ShaderMaterial:
	if _backdrop_shader == null:
		_backdrop_shader = Shader.new()
		_backdrop_shader.code = BACKDROP_SHADER_CODE
	var m := ShaderMaterial.new()
	m.shader = _backdrop_shader
	m.set_shader_parameter("c_dark", dark)
	m.set_shader_parameter("c_mid", mid)
	m.set_shader_parameter("c_light", light)
	m.set_shader_parameter("fog", fog)
	m.set_shader_parameter("keep", keep)
	m.set_shader_parameter("depth", depth)
	m.set_shader_parameter("gain", gain)
	return m

# ---------- Wind in den Baumkronen (Feld) ----------
# Die Krone wiegt sich in ganzen Kunstpixeln: oben weiter als unten, jeder
# Baum leicht versetzt (Phase aus seiner Lage). Kein Strecken, kein Weichzeichnen.
const SWAY_SHADER_CODE := "
shader_type canvas_item;
uniform float texel = 1.0;
uniform float strength = 1.6;
uniform float speed = 1.1;
varying float v_y;
varying float v_phase;
varying vec4 v_col;

void vertex() {
	v_y = VERTEX.y > 0.5 ? 1.0 : 0.0;
	v_phase = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).x * 0.045;
	v_col = COLOR;
}

void fragment() {
	float lift = 1.0 - v_y;
	float wave = sin(TIME * speed + v_phase) + 0.35 * sin(TIME * speed * 2.7 + v_phase * 1.7);
	float shift = floor(wave * strength * lift + 0.5);
	vec2 uv = UV + vec2(shift * TEXTURE_PIXEL_SIZE.x * texel, 0.0);
	COLOR = texture(TEXTURE, uv) * v_col;
}
"

static var _sway_material: ShaderMaterial

## Ein gemeinsames Material für alle Kronen (die Phase kommt aus der Lage).
static func sway_material() -> ShaderMaterial:
	if _sway_material == null:
		var sh := Shader.new()
		sh.code = SWAY_SHADER_CODE
		_sway_material = ShaderMaterial.new()
		_sway_material.shader = sh
	return _sway_material

# ---------- Oberfläche (Stufe 6) ----------

static var _ui_font: Font
static var _panel_tex := {}

## Pixelschrift für die ganze Oberfläche (DotGothic16, SIL OFL 1.1) — die
## klassische JRPG-Textschrift; lateinische Zeichen sind gleich breit, die
## Symbole der Spieltexte (Sterne, Rauten, Pfeile) bringt sie selbst mit.
## Was ihr fehlt, kommt weiter aus der Standardschrift der Engine.
static func ui_font() -> Font:
	if _ui_font == null:
		var p := "res://assets/fonts/DotGothic16.ttf"
		if ResourceLoader.exists(p):
			var f: FontFile = load(p)
			# Ligaturen aus: die Verbindung "fi" dieser Schrift liest sich wie ein
			# anderer Buchstabe ("fire" sah aus wie "Are").
			var ts := TextServerManager.get_primary_interface()
			if ts != null:
				f.opentype_feature_overrides = {
					ts.name_to_tag("liga"): 0, ts.name_to_tag("clig"): 0,
					ts.name_to_tag("dlig"): 0, ts.name_to_tag("calt"): 0}
			var fb: Font = ThemeDB.fallback_font
			if fb != null and fb != f:
				f.fallbacks = [fb]
			_ui_font = f
	return _ui_font

## Einmal beim Start: Schrift und Fensterrahmen als Standard für alle
## Bedienelemente setzen — die Oberfläche entsteht überall per Code, so greift
## es ohne Änderung an jeder einzelnen Stelle.
static func install_ui_theme() -> void:
	var th := ThemeDB.get_default_theme()
	var f := ui_font()
	if th == null:
		return
	if f != null:
		var old: Font = th.default_font
		if old != null and old != f and f is FontFile:
			(f as FontFile).fallbacks = [old]
		th.default_font = f
	th.set_stylebox("panel", "PanelContainer", panel_style())

## Fensterrahmen im Pixel-Look: dunkles Feld, doppelte Goldkante, Ecknieten.
## Wird als 9-Patch gestreckt; "alpha" steuert die Deckkraft des Feldes.
static func panel_style(alpha := 0.94, margin := 14) -> StyleBoxTexture:
	var key := "%.2f" % alpha
	if not _panel_tex.has(key):
		var n := 48
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		var fill_top := Color(0.09, 0.10, 0.22, alpha)
		var fill_bot := Color(0.04, 0.04, 0.11, alpha)
		var edge_dark := Color(0.02, 0.02, 0.05, 1.0)
		var gold := Color(0.86, 0.74, 0.42, 1.0)
		var gold_dim := Color(0.45, 0.36, 0.18, 1.0)
		for y in n:
			for x in n:
				var d: int = mini(mini(x, y), mini(n - 1 - x, n - 1 - y))  # Abstand zum Rand
				var c := fill_top.lerp(fill_bot, float(y) / float(n - 1))
				if d < 2:
					c = edge_dark
				elif d < 4:
					c = gold
				elif d < 6:
					c = gold_dim
				img.set_pixel(x, y, c)
		# Ecknieten: helle Quadrate auf den vier Ecken, eine Spur Glanz oben links.
		for corner: Vector2i in [Vector2i(0, 0), Vector2i(n - 10, 0), Vector2i(0, n - 10), Vector2i(n - 10, n - 10)]:
			for y in 10:
				for x in 10:
					var edge: bool = x < 2 or y < 2 or x > 7 or y > 7
					var c2 := edge_dark if edge else gold
					if not edge and x < 4 and y < 4:
						c2 = Color(1.0, 0.95, 0.72, 1.0)
					elif not edge and (x > 5 or y > 5):
						c2 = gold_dim
					img.set_pixel(corner.x + x, corner.y + y, c2)
		_panel_tex[key] = ImageTexture.create_from_image(img)
	var sb := StyleBoxTexture.new()
	sb.texture = _panel_tex[key]
	sb.set_texture_margin_all(12)
	sb.set_content_margin_all(margin)
	return sb

# Blenden: 1 = Iris (Kreis schließt sich zur Mitte), 2 = Rautenraster, das
# diagonal über das Bild läuft. progress 0 = offen, 1 = ganz zu.
const WIPE_SHADER_CODE := "
shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int mode = 1;
uniform vec2 center = vec2(0.5, 0.5);

void fragment() {
	float a = 0.0;
	if (mode == 1) {
		vec2 d = (UV - center) * vec2(16.0 / 9.0, 1.0);
		// in groben Stufen, damit der Rand pixelig bleibt
		d = floor(d * 135.0) / 135.0;
		a = step((1.0 - progress) * 1.25, length(d));
	} else {
		vec2 grid = vec2(24.0, 13.5);
		vec2 cell = floor(UV * grid);
		vec2 f = fract(UV * grid) - 0.5;
		float delay = (cell.x + cell.y) / (grid.x + grid.y) * 0.6;
		float local = clamp((progress - delay) / 0.4, 0.0, 1.0);
		a = step(abs(f.x) + abs(f.y), local * 1.02);
	}
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
"

static var _wipe_shader: Shader

static func wipe_material(mode: int) -> ShaderMaterial:
	if _wipe_shader == null:
		_wipe_shader = Shader.new()
		_wipe_shader.code = WIPE_SHADER_CODE
	var m := ShaderMaterial.new()
	m.shader = _wipe_shader
	m.set_shader_parameter("mode", mode)
	m.set_shader_parameter("progress", 0.0)
	return m
