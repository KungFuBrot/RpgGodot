# RpgGodot — Optik-Aufwertung und fordernde Bosskämpfe (Stufenplan)

## Stand

| Stufe | Status |
|---|---|
| 0 Fundament | fertig, live |
| 1 Fordernde Kämpfe | fertig, live — Messwerte unten |
| 2 Lebendigere Kampffiguren | fertig, live — Figuren-Shader (Trefferblitz, Kantenlicht, Zielumriss, Atmen für Einzelbild-Gegner), Angriffs-/Zauberposen laufen einmal sauber durch, Gegner-Aufstellung passt zur LPC-Größe |
| 3 Kampfkulissen | fertig, live — gemalte CC0-Ebenen (Luis Zuno/ansimuz) für Schlotwerk, Konzernturm, Hassfestung, per Shader auf die Arenafarben umgefärbt, echtes Parallax; Die Leere bleibt prozedural. Schalter: Titel → Settings → „Painted battle backdrops" |
| 4 Feld-Umgebungen | offen (dort auch Pixel-Snap, aus Stufe 0 verschoben) |
| 5 Leben in der Welt | offen |
| 6 Oberfläche und Übergänge | offen |
| 7 Abschluss | offen |

**Stufe 1, Abnahmemessung** (30 Bot-Läufe je Boss, erwartete Stufe):

| Boss | Stufe | taktisch | nur Angriff | Runden (Sieg) |
|---|---|---|---|---|
| Schlotbaron | 3 | 80 % | 0 % | 14 |
| Monopolfürst | 5 | 100 % | 13 % | 15 |
| Der Spalter | 8 | 90 % | 3 % | 17 |
| Die Stille | 10 | 100 % | 10 % | 15 |

Vorher fielen Boss 3 und 4 in 3–4 Runden, auch ohne jede Taktik. Die Kämpfe
dauern jetzt etwas länger als die geplanten 8–14 Runden; kürzer ging nur auf
Kosten der Regel „stures Angreifen verliert".

## Kontext

Das Spiel (`C:\Education\GitHub\RpgGodot`, Godot 4.7, Web-Export auf GitHub Pages) soll
optisch deutlich besser werden — Animationen, Umgebungen, Charaktere — und die Kämpfe,
vor allem die Bosse, sind zu leicht. Alles soll möglichst ohne Handarbeit des Nutzers
entstehen. Entscheidungen aus der Rückfrage:

- **Grafik:** LPC-Stil bleibt und wird veredelt (kein neuer Stilwechsel).
- **Assets:** weitere freie Assets (CC0 und CC-BY-SA) dürfen geladen und eingebunden werden.
- **Schwierigkeit:** fordernd, aber fair.

Befund aus der Analyse (die eigentlichen Ursachen):

| Bereich | Problem | Stelle |
|---|---|---|
| Feld-Figuren | LPC-Figuren (128-px-Zellen) werden auf 0,21 verkleinert → zerquetschte Pixel | `Field.gd:15,28` |
| Gelände | 16-px-Kenney/DTII-Kacheln neben LPC-Figuren (Stilbruch); Häuser = gestreckte Kachel; Bäume = 16×48-Säule | `SpriteFactoryLib.gd:395`, `Field.gd:452,484` |
| Tiefe | kein Y-Sort: Spieler läuft immer VOR Bäumen/Häusern | `Field.gd:882-896` |
| Animation | Bildzähler läuft nach rig3d-Länge statt LPC-Spaltenzahl → Zyklus springt; Gegner haben für hit/down/taunt kein eigenes Bild; viele Gegner sind Einzelbilder | `RigFactory.anim_frames`, `LpcMock.gd:168` |
| Kampfkulisse | flache Polygone, Kreis-Nebel, kein echtes Parallax, Kamera statisch | `BattleStage.gd:199-327` |
| UI | Godot-Standardschrift, flache Kästen, Text ohne Schreibmaschine/Porträt, Schwarzblende als Übergang | `Field.gd:1171`, `Main.gd:106-128` |
| Bosse | 1 Aktion pro Runde gegen 3 Helden; ~10–16 Schaden bei 42–72 LP; jede Heilung belebt wieder; keine Statuseffekte | `BattleEnemyActions.gd:8-124`, `GameState.gd:40-130` |

Projektregel (CLAUDE.md): sichtbare Stil-Änderungen nur nach In-Game-Vergleich und
Freigabe. Deshalb endet jede Stufe mit Vorher/Nachher-Bildern; die beiden großen Umbauten
(Stufe 3 und 4) laufen zuerst hinter einem Menüschalter wie `lpc_preview`.

## Ablauf jeder Stufe (gilt für alle)

1. Umsetzen, dann Prüfkette (siehe „Verifikation").
2. Vorher/Nachher-Montage an den Nutzer schicken (einzige Handarbeit: anschauen, Ja/Nein).
3. Commit mit deutscher Message (`Feature:`/`Fix:`), Web-Export. **Push (= öffentlicher
   Pages-Deploy) erst nach Freigabe der Bilder.**

Godot-Binary (CLAUDE.md ist hier veraltet):
`C:\Users\Kungf\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe`

---

## Stufe 0 — Fundament und Messlatte

- Projekt importieren (`--headless --editor --quit`; `.godot/` fehlt im frischen Klon).
- **Referenzbilder:** `SHOT`-Tour (`Main.gd:51-104`) um dungeon4 und Boss 4 erweitern, Lauf
  mit Fenster, Ablage in `shots/baseline/` (in `.gitignore`).
- **Vergleichswerkzeug:** kleines GDScript `tools/compare_shots.gd` (per `--script`), das
  zwei Bildordner zu Vorher/Nachher-Montagen zusammensetzt (kein Python/ImageMagick da).
- **Sofort-Fixes ohne Stilwirkung:**
  - Bildzähler an LPC-Spaltenzahl koppeln (`LpcMock` liefert Länge; `RigFactory.anim_frames`
    / `mon_frames` nur noch als Rückfall).
  - `GRADES`-Eintrag für dungeon4 ergänzen (`Field.gd:1130-1147`).
  - Pixel-Snap in `project.godot` einschalten (`rendering/2d/snap/*`), Kamera-Zittern prüfen.
- **CLAUDE.md aktualisieren:** Binary-Pfad, LPC ist Standard, Regel „keine neuen Assets" →
  „neue Assets nur unter `assets/<quelle>/` mit LICENSE + Eintrag im Credits-Bildschirm".

## Stufe 1 — Fordernde, faire Kämpfe

Daten in `scripts/GameState.gd`, Logik in `scripts/battle/BattleEnemyActions.gd`,
`BattleDamage.gd`, `BattleBossCine.gd`, Anzeige in `BattleUi.gd`. Bestehende
Inszenierungen (`_boss_aoe`, `_boss_ultimate`, `_boss_enrage`, `_ult_banner`) bleiben und
werden wiederverwendet.

- **Stellschrauben zentral:** neue Tabelle `BOSS_TUNING` (LP-/Angriffsfaktor, Aktionen pro
  Runde, Wut-Schwelle) und ein globaler Faktor für normale Gegner (leicht angehoben).
- **Aktionsökonomie:** Bosse handeln 2× pro Runde (Schleife in `Battle._run_battle`).
- **Angekündigte Großangriffe:** der Flächenangriff wird zweistufig — Zug N „lädt auf"
  (Banner + Aura), Zug N+1 schlägt ein. Ohne „Defend" tut er richtig weh → Verteidigen
  bekommt einen Zweck.
- **Statuseffekte** (kleines generisches System in `BattleBase`: Name, Dauer, Symbol über
  der Party-Leiste), je Boss thematisch:
  - Schlotbaron: **Gift** (Schaden pro Runde, durch Heilung entfernt).
  - Monopolfürst: **Steuer** (zieht MP ab) + **Goldschild**, das erst gebrochen werden muss.
  - Der Spalter: **Isoliert** (ein Held kann 2 Runden nicht geheilt werden); „Wall of Hate"
    erhöht seine Verteidigung, bis „Focus Pierce" sie bricht.
  - Die Stille: **Schweigen** (Fähigkeiten eines Helden 2 Züge versiegelt); ab 50 % LP
    ruft sie zwei Schemen herbei.
- **Wut-Phase** früher (50 % statt 40 %), Ultimates treffen härter (heute nur ~1× Angriff).
- **Fairness-Ausgleich:** Wiederbeleben nur noch mit neuem Shop-Item „Revive" bzw. mit
  halben LP statt durch jede Heilung (`_restore_if_revived`, `BattleUi.gd:418-421`);
  Boss-Niederlage setzt direkt vor den Boss zurück statt an den Dungeon-Anfang.
- **Automatisches Balancing (statt Probespielen):** neuer Hook `AUTOBATTLE=<boss>` neben
  `BOSSSHOT` (`Main.gd:35-50`, `Battle.gd:16-20`): ein Bot spielt den Kampf headless im
  Zeitraffer (`_hitstop` in `BattleFx.gd:643` darf `Engine.time_scale` dann nicht auf 1
  zurücksetzen) und gibt Sieg/Runden/Rest-LP aus. Zwei Bots, je 30 Läufe pro Boss auf
  erwartetem Level:
  - „taktisch" (verteidigt bei Ansage, heilt unter 40 %): Ziel **70–90 % Siege**, 8–14 Runden.
  - „nur Angriff": Ziel **unter 25 % Siege** — Beleg, dass Taktik nötig ist.
  - Werte in `BOSS_TUNING` nachziehen, bis beide Bänder für alle 4 Bosse stimmen.

## Stufe 2 — Lebendigere Figuren im Kampf

Stil unverändert, nur Bewegung und Wucht. Dateien: `scripts/Fx.gd`,
`scripts/battle/BattleFx.gd`, `BattleStage.gd`, `scripts/sprites/LpcMock.gd`.

- **Ein Figuren-Shader** `Fx.unit_material()` für alle Kämpfer (ersetzt das nachträgliche
  Material-Tauschen beim Dissolve, `BattleDamage.gd:57`): Atmen (Streckung ab Fußlinie),
  leichtes Schwanken oben, weißer Trefferblitz, farbiger Auswahl-Umriss, Rim-Licht in der
  Arenafarbe, Dissolve. Macht auch Einzelbild-Gegner lebendig.
- **Fehlende Gegnerposen erzeugen:** hit/down/taunt per Shader-Verformung + Tween statt
  starrem Idle-Bild (`_epose`, `BattleFx.gd:509`).
- **Timing:** eigene Bildraten je Animation statt Zufalls-Ticker 0,13–0,19 s
  (`BattleStage.gd:956-986`); Angriff mit Ausholen → Halte-Bild beim Treffer → Ausschwingen.
- **Wucht:** Hiebbögen/Smear, Nachbilder, Einschlag-Funken aus den Kenney-Partikeln,
  Kamera fährt kurz auf den Handelnden (`_punch_zoom` ausbauen), Schadenszahlen mit Sprung.
- Prüfung per `SPELLSHOT`-Lauf (alle Fähigkeiten automatisch).

## Stufe 3 — Kampfkulissen mit Tiefe  ⛔ Vergleich hinter Schalter

`BattleStage._build_scene` (199-327) bekommt je Thema eine echte Mehrebenen-Kulisse.

- **Quelle:** freie Pixel-Parallax-Hintergründe (bevorzugt CC0, z. B. Ansimuz-Sets von
  OpenGameArt/itch: Industrie → Schlotwerk, Stadt/Hochhaus → Konzernturm, Burg/Friedhof →
  Hassfestung; Die Leere bleibt prozedural). Lizenz jedes Sets vor dem Einbinden prüfen;
  Ablage `assets/backdrops/<thema>/` + LICENSE + Credits-Eintrag.
- **Einbau:** 4–5 Ebenen mit echtem Parallax (Kamera-Idle und `_punch_zoom` bewegen die
  Ebenen unterschiedlich stark), Bodenfläche mit Kontaktschatten, Vordergrund-Silhouetten.
  Vorhandene Fackeln, Lichtschächte, Nebel, Wetter bleiben als Ebenen darüber;
  `STAGE_LIFT`/Vignette neu abstimmen.
- **Schalter** `GameState.backdrop_preview` (Muster: `lpc_preview`, `GameState.gd:171-206`,
  `Title.gd:434,485`) → Vergleich alt/neu im echten Spiel, auch am Handy. Zuerst nur die
  Toxic-Arena; nach Freigabe die übrigen drei, dann Schalter und Altcode entfernen.

## Stufe 4 — Umgebungen im Feld  ⛔ Vergleich hinter Schalter

Größter sichtbarer Sprung. Dateien: `scripts/sprites/SpriteFactoryLib.gd`,
`scripts/Field.gd`, `scripts/MapData.gd` (Karten bleiben ASCII).

- **Maßstab:** Feld auf LPC-Raster umstellen — Kachel 32 px, Figuren 1:1 (64-px-LPC),
  Kamera-Zoom 2 (pixelgenau, ca. 15×8 Kacheln sichtbar). Beseitigt die zerquetschten
  Figuren. Alle Konstanten, die von `TILE = 16` abhängen, mitziehen.
- **Gelände aus LPC:** LPC-Terrain-Atlas (CC-BY-SA 3.0/GPL 3) nach `assets/lpc/terrain/`,
  Autorenliste in `assets/lpc/LICENSE.txt` + Credits. `tile_at`/`edge_overlay`/
  `TERRAIN_RANK` bleiben als Logik, wählen aber echte LPC-Übergangskacheln.
- **Objekte:** echte LPC-Bäume (Stamm + Krone), mehrteilige Häuser mit Dach, Zäune,
  Brunnen, Laternen; Dungeon-Wände/-Böden aus LPC-Innenräumen, je Thema eingefärbt.
- **Tiefe:** Y-Sort (Spieler läuft hinter Kronen/Dächern durch), weiche Schlagschatten.
- **Schalter** `terrain_preview`; zuerst nur die Stadt, nach Freigabe Weltkarte und die
  vier Dungeons, dann Altpfad (Kenney-Gelände, DTII-Böden) entfernen.

## Stufe 5 — Leben in der Welt

- **Bewegung:** Schrittbilder an die Laufstrecke koppeln (9-Bild-LPC-Zyklus, kein
  „Schlittern"), weiches Anlaufen/Abbremsen statt linearem Tween (`Field.gd:1063-1071`).
- **NPCs:** drehen sich zum Spieler, kleine Wege, Sprechblasen-Symbol.
- **Natur:** Wind-Shader für Kronen/Gras, Schmetterlinge/Vögel/Glühwürmchen, Kaminrauch,
  Lichtstrahlen im Wald, Uferschaum; Wetter je Karte (Regen, Asche, Goldstaub, Nebel).
- **Licht:** Tageszeit-Tönung je Karte, wärmere Laternen in den Dungeons.

## Stufe 6 — Oberfläche und Übergänge

- **Pixelschrift** (CC0/OFL) statt Godot-Standardschrift, einheitliches Theme für
  `Title.gd`, `Field.gd`, `BattleUi.gd`.
- **Rahmen:** 9-Patch-Fenster (CC0-UI-Pack) statt `StyleBoxFlat`.
- **Dialog:** Schreibmaschinen-Text, Porträt aus dem LPC-Kopf, Auf-/Zuklappen
  (`Field.gd:1125,1171-1181`).
- **Übergänge:** Kampfbeginn als Splitter-/Wirbel-Shader, Kartenwechsel als Iris-Blende
  (`Main.gd:106-128`); Titelbild mit den neuen Kulissen.

## Stufe 7 — Abschluss

- Web-Build im Browser prüfen (Compatibility-Renderer: kein Glow/HDR → Helligkeit, Shader).
- Leistung am Handy-Format messen; bei Bedarf Kacheln zu wenigen Texturen zusammenbacken.
- Aufräumen: ungenutzte Assets (`assets/lpc/monsters`, `people`, alte Rückfallpfade),
  Credits-Bildschirm vollständig, README/CLAUDE.md auf Stand.

## Reihenfolge und Abhängigkeiten

0 zuerst. Danach sind **1** (Kämpfe), **3** (Kulissen), **4** (Feld) und **6** (UI)
voneinander unabhängig; **2** und **1** teilen sich Kampf-Dateien (nacheinander), **5**
baut auf **4** auf, **7** zuletzt. Empfohlene Folge: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7.

## Verifikation

```powershell
$g = "…\Godot_v4.7-stable_win64_console.exe"
& $g --headless --editor --quit --path .      # Klassen-Cache / Import
& $g --headless --quit --path .               # kompiliert alle Skripte
$env:SPELLSHOT = "$PWD\shots\spell"; & $g --headless --path .   # Smoke: alle Fähigkeiten
$env:SHOT = "$PWD\shots\now"; & $g --path .   # Bildtour (mit Fenster)
& $g --headless --path . --script tools/compare_shots.gd   # Vorher/Nachher-Montagen
$env:AUTOBATTLE = "boss"; & $g --headless --path .   # Balancing-Lauf (ab Stufe 1)
& $g --headless --path . --export-release "Web"      # Web-Build nach web/
```

- Montagen selbst ansehen (Read-Tool) und an den Nutzer schicken.
- Web-Build lokal ausliefern und im eingebauten Browser gegenprüfen (Stufen 3, 4, 7).
- Stufe 1 gilt als fertig, wenn beide Bot-Bänder für alle vier Bosse erfüllt sind.
