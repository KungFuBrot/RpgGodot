extends SceneTree
## Vorher/Nachher-Montagen aus zwei Screenshot-Ordnern (SHOT-Tour).
## Aufruf:
##   godot --headless --path . --script tools/compare_shots.gd -- [vorher] [nachher] [ziel]
## Ohne Angaben: shots/baseline, shots/now, shots/compare.
## Links steht das alte Bild, rechts das neue; dazwischen ein heller Trennstreifen.
## Zusätzlich meldet das Skript je Bild den Anteil geänderter Pixel — so fällt
## auf, wenn eine Stufe Szenen verändert, die sie gar nicht anfassen sollte.

const GAP := 6

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var before_dir: String = args[0] if args.size() > 0 else "shots/baseline"
	var after_dir: String = args[1] if args.size() > 1 else "shots/now"
	var out_dir: String = args[2] if args.size() > 2 else "shots/compare"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var names := []
	for f in DirAccess.get_files_at(before_dir):
		if f.ends_with(".png") and FileAccess.file_exists(after_dir + "/" + f):
			names.append(f)
	names.sort()
	if names.is_empty():
		push_error("Keine gemeinsamen PNGs in %s und %s" % [before_dir, after_dir])
		quit(1)
		return
	for f in names:
		var a := Image.load_from_file(before_dir + "/" + f)
		var b := Image.load_from_file(after_dir + "/" + f)
		if a == null or b == null:
			continue
		a.convert(Image.FORMAT_RGBA8)
		b.convert(Image.FORMAT_RGBA8)
		var w := a.get_width()
		var h := maxi(a.get_height(), b.get_height())
		var out := Image.create(w + GAP + b.get_width(), h, false, Image.FORMAT_RGBA8)
		out.fill(Color(1.0, 0.85, 0.3))
		out.blit_rect(a, Rect2i(0, 0, w, a.get_height()), Vector2i(0, 0))
		out.blit_rect(b, Rect2i(0, 0, b.get_width(), b.get_height()), Vector2i(w + GAP, 0))
		out.save_png(out_dir + "/" + f)
		print("%-24s geaendert: %5.1f %%" % [f, _changed_share(a, b) * 100.0])
	print("Montagen: %s (%d Bilder)" % [out_dir, names.size()])
	quit(0)

## Anteil der Pixel, die sich sichtbar unterscheiden (Raster 2 px, Schwelle
## gegen Rauschen aus Partikeln und Filmkorn).
func _changed_share(a: Image, b: Image) -> float:
	if a.get_size() != b.get_size():
		return 1.0
	var diff := 0
	var total := 0
	for y in range(0, a.get_height(), 2):
		for x in range(0, a.get_width(), 2):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			total += 1
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.18:
				diff += 1
	return float(diff) / float(maxi(total, 1))
