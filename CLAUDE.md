# RpgGodot — Mini-JRPG (Godot 4)

Rundenbasiertes Mini-JRPG im Stil von FF VI / Octopath. Läuft als Web-Export auf
GitHub Pages. Aufbau, Karten, Effekte und UI entstehen per Code — es gibt nur
eine Szene (`Main.tscn`), keine Editor-Ressourcen. Figuren kommen aus
LPC-Blättern (`assets/lpc/`), Kacheln und Partikel aus DTII und Kenney.

**Laufender Umbau:** Optik-Aufwertung und fordernde Bosse in Stufen 0–7, siehe
`docs/optik-und-bosse-plan.md` (Stand der Stufen steht dort ganz oben).

## Konventionen

- **Spielertexte: Englisch.** Code-Kommentare: Deutsch. Beides beibehalten.
- Typisiertes GDScript (`:=`, `->`), Tabs, LF-Zeilenenden.
- Keine neuen Szenen anlegen. Neue Assets nur aus freien Quellen (CC0,
  CC-BY-SA) unter `assets/<quelle>/` mit eigener `LICENSE.txt` und Eintrag im
  Credits-Bildschirm (`Title.gd`); bei CC-BY-SA jede*n Autor*in namentlich.
- ACHTUNG Grafikstil: Stil-Umbauten nur nach In-Game-Mock und Freigabe
  (mehrere Anläufe wurden abgelehnt, siehe `docs/ki-grafikstil-plan.md`).
  Der LPC-Figurenstil ist freigegeben und bleibt; große Umbauten laufen zuerst
  hinter einem Menüschalter (Muster: `GameState.lpc_preview`).

## Dateikarte — gezielt lesen statt alles laden

| Datei | Inhalt |
|---|---|
| `scripts/Main.gd` | Root: Szenenwechsel Feld/Kampf/Intro/Ende, Input-Map, Fades |
| `scripts/GameState.gd` | **Daten:** Party, Fähigkeiten, Items, ENEMIES (inkl. Boss-Dialoge), XP/Level |
| `scripts/MapData.gd` | **Daten:** Karten (ASCII), Portale, NPC-Dialoge |
| `scripts/Field.gd` | Erkundung: Karte, Bewegung, NPC/Shop, Zufallskämpfe |
| `scripts/Intro.gd` / `Ending.gd` | Story-Texte Anfang/Abspann |
| `scripts/Title.gd` | Titelbild, Menü, Einstellungen |
| `scripts/AudioManager.gd` | Prozeduraler Chiptune-Synth + Junkala-Tracks |
| `scripts/Fx.gd` | Shader: Tilt-Shift, Wasser, Dissolve, Stoßwelle |
| `scripts/TouchControls.gd` | Bildschirm-Pad für Mobile |

### Battle-Vererbungskette (`scripts/battle/` + `scripts/Battle.gd`)

Der Kampf ist eine lineare Kette — **eine Klasse darf nur Methoden von sich
selbst oder ihren Vorfahren (weiter oben) aufrufen**, nie nach unten:

| # | Klasse | Inhalt |
|---|---|---|
| 1 | `BattleBase` | Zustand, Konstanten, `_say`, Kleinst-Helfer |
| 2 | `BattleFx` | Generische Effekte: Partikel, Beben, Hit-Stop, Kamera, `_sprint`, Banner |
| 3 | `BattleStage` | Arena-Aufbau, Ambiente, Idle-Animationen |
| 4 | `BattleUi` | Party-/Bossleiste, Menüs, Zielwahl, Input |
| 5 | `BattleBossCine` | Boss-Auftritt, Wut-Phase, Boss-Tod |
| 6 | `BattleDamage` | `_damage_hero` / `_damage_enemy` |
| 7 | `BattleHeroActions` | Helen- & Janosch-Skills |
| 8 | `BattleRaxActions` | Wally: MG, Laser, Raketen, Nuke, Orbital |
| 9 | `BattleSummons` | Ifrit, Leviathan, Bahamut |
| 10 | `BattleEnemyActions` | Gegnerzüge, Boss-AoE/-Ultimates |
| 11 | `Battle` | `_ready`, Rundenschleife, Fähigkeiten-Menü, Sieg/Niederlage, Showcases |

Neue geteilte Helfer gehören nach `BattleFx` (visuell) bzw. `BattleBase` (Zustand).

### Figuren im Kampf

- Jede Kampffigur trägt `Fx.unit_material()` (Meta `unit_mat`): weißer
  Trefferblitz (`_unit_flash`), Kantenlicht in der Arenafarbe, Zielumriss
  (`_set_outline`), Atmen für Gegner mit nur einem Bild. Beim Tod ersetzt der
  Dissolve-Shader das Material.
- `_pose` / `_epose` spielen Schlag-, Zauber-, Treffer- und Angriffsposen
  EINMAL von vorn durch (`POSE_ONCE`, `lock`); der Leerlauf-Ticker hält sich
  solange heraus. Schleifenposen (block, aim, run, cheer) taktet der Ticker.
- Nur schwebende Gegner (`BattleStage.FLOATERS`) und Bosse wippen noch;
  alle anderen stehen (`bob_amp` 0).

### Oberfläche

- `Fx.install_ui_theme()` (Aufruf in `Main._ready`) setzt die Pixelschrift
  DotGothic16 (`assets/fonts`, SIL OFL) und den Fensterrahmen
  `Fx.panel_style()` als Standard für alle Bedienelemente. Lateinische Zeichen
  sind gleich breit — Breiten deshalb in Zeichen rechnen (Schriftgröße / 2 px
  je Zeichen). Ligaturen sind abgeschaltet.
- Dialog im Feld: Schreibmaschine (`dialog_typing`), Porträt aus dem Feldbild
  (`_set_dialog_portrait`). Erste Bestätigung zeigt den Satz ganz, die zweite
  blättert.
- Blenden: `Main._wipe(kind, closing, dur)` — 1 Iris (Kartenwechsel),
  2 Rautenraster (Kampf); `_fade` bleibt für Titel/Intro/Abspann.
- Prüfbilder: `MENUSHOT` (Fähigkeiten-Menü), `CREDITSHOT=1` zusammen mit
  `SHOT` (Credits-Tafel).

### Kampfkulissen (`BattleStage.BACKDROPS`)

Je Arena-Thema eine Liste gemalter Ebenen aus `assets/backdrops/` (CC0, Luis
Zuno). `_build_backdrop` kachelt sie über die Bildbreite,
`Fx.backdrop_material` färbt sie per Farbleiter auf das Thema um (`keep`,
`depth`, `gain` je Ebene), `_process` führt sie als Parallax der Kamera
nach. Abschaltbar über `GameState.backdrop_preview` (dann die alte
Polygon-Kulisse); „void" hat keine Ebenen und bleibt prozedural. Bilder immer
mit `--rendering-method gl_compatibility` beurteilen — so sieht es im Web aus
(deutlich heller als Forward+ am Desktop).

### Boss-Mechanik und Schwierigkeit

- Stellschrauben stehen zentral in `GameState.BOSS_TUNING` / `MOB_TUNING`
  (Faktoren auf die Grundwerte in `ENEMIES`). Nie von Hand raten — mit dem
  Bot nachmessen (`AUTOBATTLE`, siehe Befehle).
- Bosse handeln 2× pro Runde (`Battle._run_battle`). `_boss_plan` in
  `BattleEnemyActions` entscheidet: Großangriffe (Flächenangriff, Ultimates)
  werden mit der LETZTEN Aktion einer Runde aufgeladen und mit der ERSTEN der
  nächsten entfesselt — die Helden haben immer eine Runde zum Verteidigen.
- Signaturzüge (`_boss_signature`): Gift (Schlotbaron), MP-Steuer +
  Goldschild in der Wut (Monopolfürst), Mauer des Hasses + Isolation (Spalter),
  Schweigen + zwei Schemen ab 50 % (Die Stille).
- Helden-Status in `h["status"]` (`_add_status`, `_tick_status`,
  `_cure_poison` in `BattleUi`). „Defend" dämpft auf 35 % und gibt MP zurück.
- Gefallene holt nur das Item „Revive" zurück. Nach einer Niederlage geht es
  mit dem Stand von vor dem Kampf weiter (`GameState.snapshot`/`restore`).

### SpriteFactory-Kette (`scripts/sprites/` + `scripts/SpriteFactory.gd`)

`SpriteFactoryLib` (Asset-Loader, Kacheln, Gelände-Übergänge, Pixel-Helfer) →
`SpriteFactoryChars` (Figuren-Einstiege) → `SpriteFactory` (Beschwörungen,
Gegner, Props). Alle Aufrufe von außen laufen über `SpriteFactory.*`
(statische Vererbung).

### Figuren: LPC ist Standard (`scripts/sprites/LpcMock.gd`)

Alle Helden, Dorfbewohner, 13 Monster und 4 Bosse werden aus LPC-Blättern
geschnitten (`assets/lpc/heroes`, `assets/lpc/enemies`; Zelle 128 px = LPC 64 px
doppelt). `SpriteFactoryChars.field_char` / `hero_battle_frame` und
`SpriteFactory.enemy_frame` fragen zuerst `LpcMock`; nur bei abgeschaltetem
Menüschalter oder fehlendem Blatt greift `RigFactory`. Die Bildzahl je Pose
liefern `LpcMock.hero_frames` / `monster_anim_frames` (erreichbar über
`RigFactory.anim_frames` / `mon_frames`). Gegner haben nur Leerlauf-, Angriffs-
und (Bosse) Brüll-Blätter; Treffer und Sturz sind Verformung per Tween.
Beschwörungen sind prozedural (`SpriteFactory.gd`).

**Alles Folgende zu `proto/` und `RigFactory` beschreibt nur noch den Rückfall.**

### 3D-zu-Pixel-Pipeline (`scripts/proto/`) — Rückfall ohne LPC

Seit dem Stilwechsel werden Figuren **nicht mehr gezeichnet**, sondern als
3D-Gelenkskelett modelliert, orthografisch sehr klein und ohne Kantenglättung
gerendert und als Sprite-Streifen nach `assets/rig3d/` gebacken (Verfahren von
Motion Twin / Dead Cells). `RigFactory` lädt die Streifen und schneidet die
Einzelbilder heraus; fehlt ein Streifen, fällt die Figur automatisch auf die
alte 2D-Zeichnung zurück.

| Datei | Inhalt |
|---|---|
| `proto/Rig3D.gd` | Bauformen (Humanoid parametriert, Blob, Vierbeiner, Spinne) + Animationstabellen als Gelenkwinkel |
| `proto/Figures3D.gd` | Bauplan jeder Spielfigur, Leinwandgrößen, Kameragrößen |
| `proto/Proto3D.gd` | Backvorgang: SubViewport, Dreipunktlicht, Farbstufen, Kontur |

**Neu backen** (Godot NICHT headless starten — headless hat kein Rendergerät):
```powershell
$env:PROTO3D = "$PWD\assets\rig3d"; godot --path .
```
Danach `--headless --editor --quit`, damit die neuen PNGs importiert werden.

Kein Skinning: jeder Körperteil ist ein starres Mesh an einem Gelenk-Node.
Leinwandgrößen (Held 32x56, Monster 52x52, Boss 112x128) sind identisch zum
alten 2D-Rig — deshalb blieb die gesamte Kampf- und Feldaufstellung unberührt.

**`scripts/sprites/RigFactory.gd` steht daneben, nicht in der Kette.** Dort
werden ALLE Kampffiguren gezeichnet — Helden, 13 Monster, 4 Bosse, Dorf-NPCs:
Körperteil-Karte → Schattierung je Glied über dessen eigene Ausdehnung →
farbige Kontur. Eine Lichtrichtung (oben links), eine Tonwertleiter, ein
Maßstab (`BATTLE_SCALE = 2.0`); die Größe steckt in der Leinwand
(Held 32x56, Monster 52x52, Boss 112x128), nicht in der Vergrößerung — nur so
ist ein Pixel bei allen Figuren gleich groß. `SpriteFactoryChars.field_char` /
`hero_battle_frame` und `SpriteFactory.enemy_frame` reichen nur noch dorthin
durch. DTII liefert seither ausschließlich Kacheln und Requisiten.

Der Posen-Bestand steht: Helden idle/walk/run/attack/attack2/cast/aim/block/
hit/down/cheer (im Feld zusätzlich `_up`/`_down` als Blickrichtung), Kreaturen
idle/attack/hit/down/taunt, Bosse zusätzlich roar. Der Kampf setzt sie über
`_pose` (Helden) bzw. `_epose` (Gegner); `_sprint` schaltet auf "run".

### LPC-Gelände im Feld (`scripts/sprites/LpcTerrain.gd`, `Field._build_tiles_lpc`)

Standard seit Stufe 4 (`GameState.terrain_preview`, abschaltbar im Titelmenü;
für Prüfläufe schaltet env `CLASSIC_LOOK=1` Gelände und Kulissen ab).
`TILE` bleibt 16 Welt-Einheiten; LPC-Kacheln (32 px) werden auf 0.5
gezeichnet, die Kamera zoomt 4-fach, Figuren stehen auf 0.25 — überall sind
zwei Bildschirmpixel ein Kunstpixel. Übergänge (Weg, Wasser) setzt
`LpcTerrain.quarters` aus Viertelkacheln zusammen. Figuren, Bäume und Häuser
liegen auf z 5 und werden nach y sortiert (`y_sort_enabled`); Kronen vor der
Heldin werden durchscheinend (`_lpc_fade_canopies`). Dungeons nutzen
Burgboden/-mauern, je Thema eingefärbt (`LPC_TINT`). Portal-Symbole und
Story-Requisiten sind noch alte 16-px-Grafik (`LPC_KEEP_OBJECTS`).

Alles Folgende beschreibt den alten Aufbau (Schalter aus).

### Gelände-Übergänge (`SpriteFactoryLib.edge_overlay`)

Karten werden nicht mehr aus Vollkacheln gestapelt: `TERRAIN_RANK` legt fest,
welches Gelände in die Kachel des niedrigeren hineingreift (Fels > Weg > Gras >
Wasser). Die Kante bleibt pixelscharf, mäandert aber über tieffrequentes
Rauschen; am Saum liegt Kontaktschatten bzw. Ufersaum. Bäume, Häuser, Wände und
Portalsymbole sind Objekte AUF dem Gelände (`Field.OBJECT_CHARS`), damit der
Untergrund durchläuft.

## Befehle

Godot-Binary (winget, unten kurz `godot`):
`%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe`
Nach frischem Klon zuerst `--headless --editor --quit`, sonst fehlt `.godot/`.

```powershell
# Skript-/Klassencheck (nach Umbauten immer ausführen):
godot --headless --editor --quit --path .   # Klassen-Cache neu aufbauen
godot --headless --quit --path .            # Spielstart kompiliert alle Skripte

# Runtime-Smoke-Test: spielt alle Kampf-Fähigkeiten automatisch durch
# (headless schlagen nur die save_png-Screenshots fehl — das ist ok):
$env:SPELLSHOT = "$env:TEMP\shots"; godot --headless --path .

# Balancing: Bot spielt jeden Boss im Zeitraffer und druckt Siegquote/Runden.
# Ziel: "smart" 70-90 % Siege, "naive" (nur Angriff) unter 25 %.
# Optional: AUTORUNS=30, AUTOBOT=smart|naive, AUTOLEVEL=-1, AUTOLOG=1 (Protokoll),
# AUTOTUNE="hp=1.6,atk=1.2" (Werte probeweise überschreiben).
$env:AUTOBATTLE = "all"; godot --headless --path .

# Bildtour MIT Fenster (headless kann den Viewport nicht speichern):
# Titel, Intro, alle Karten, Arenen und Bosse -> shots/now/
# (gl_compatibility = derselbe Renderer wie im Web-Build)
$env:SHOT = "$PWD\shots\now"; godot --rendering-method gl_compatibility --path .
# Vorher/Nachher-Montagen gegen shots/baseline/ + Anteil geänderter Pixel:
godot --headless --path . --script tools/compare_shots.gd

# Web-Export (Ziel web/, wird per GitHub Action auf GitHub Pages ausgeliefert):
godot --headless --path . --export-release "Web"
```

## Sitzungsende-Workflow

1. Headless-Check (siehe oben) — muss fehlerfrei sein.
2. Web-Build exportieren.
3. Committen (deutsche Commit-Messages, Muster: `Fix:`/`Feature:`/`Web-Build: … exportiert`).
4. Pushen auf `master` löst den öffentlichen Pages-Deploy aus — bei sichtbaren
   Änderungen erst nach Freigabe der Vorher/Nachher-Bilder.

## Nicht lesen / nicht anfassen

- `web/*` (generierte Binaries — nur per Export erzeugen, nie editieren)
- `.godot/` (Cache), `assets/dtii`, `assets/kenney` (CC0-Packs, fertig)
- `shots/` (Screenshot-Ablage der Debug-Touren, nicht im Repo)
