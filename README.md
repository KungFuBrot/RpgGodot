# Fable RPG (Godot)

> Hobbyprojekt. **Im Browser spielen:** https://kungfubrot.github.io/RpgGodot/

Ein Mini-JRPG im Stil von *Final Fantasy VI / Octopath Traveler*, gebaut mit **Godot 4**.
Aufbau, Karten, Effekte, Oberfläche und ein Teil der Musik entstehen per Code; Figuren,
Gelände und Kampfkulissen stammen aus freien Grafiksets (siehe Credits).

## Ausführen

### 1. Godot installieren (einmalig)

Benötigt wird **Godot 4.3 oder neuer** (Standard-Version, kein .NET nötig). Unter Windows:

```powershell
winget install GodotEngine.GodotEngine
```

### 2. Spiel starten

```powershell
godot --path RpgGodot
```

Oder im Editor `RpgGodot/project.godot` importieren und **F5** drücken.

## Steuerung

| Taste | Aktion |
|---|---|
| Pfeiltasten / WASD | Bewegen bzw. Menü-Auswahl |
| Z / Enter / Leertaste | Bestätigen, Ansprechen, Kaufen |
| X / Escape | Abbrechen, zurück |

Auf Geräten ohne Tastatur erscheint ein Bildschirm-Pad.

## Inhalt

- **Lindenhain** — das Dorf: Ältester Theobald, Pia und Händlerin Greta (Potion, Ether,
  Elixir, Revive).
- **Weltkarte** — verbindet das Dorf mit vier Dungeons.
- **Drei Plagen, in beliebiger Reihenfolge:** Schlotwerk (Smokestack Baron),
  Konzernturm (Monopoly Prince), Hassfestung (The Divider). Jeder Sieg stärkt die Gruppe
  und löst Fähigkeiten-Siegel; die noch offenen Dungeons wachsen mit.
- **Die Leere** — öffnet sich nach allen drei Plagen (The Silence).
- **Drei Helden:** Helen (Schwertkämpferin), Janosch (Magier, Heilung, Beschwörungen),
  Finni (Kampfroboter, Reparatur, schwere Waffen).

### Kämpfe

Rundenbasiert: Attack, Ability, Defend, Item, Flee. Die Bosse verlangen Taktik:

- Sie handeln zweimal pro Runde und **kündigen Großangriffe eine Runde vorher an** —
  wer dann nicht verteidigt, steckt den vollen Schlag ein.
- **Defend** dämpft Treffer stark und gibt etwas MP zurück.
- Jeder Boss hat einen eigenen Kniff: Gift, MP-Steuer und Goldschild, Mauer des Hasses
  und Isolation, Schweigen und Verstärkung.
- Gefallene holt nur ein **Revive** zurück. Nach einer Niederlage geht es mit dem Stand
  von vor dem Kampf weiter.

## Einstellungen (Titelmenü → Settings)

Bildschirm-Pad, Debug-Modus (alles freigeschaltet) und drei Grafik-Schalter, mit denen
sich der frühere Look zum Vergleich zurückholen lässt: LPC-Figuren, gemalte Kampfkulissen,
LPC-Gelände.

## Für Entwickler

Architektur, Konventionen und Prüfbefehle stehen in [CLAUDE.md](CLAUDE.md), der Verlauf
des Grafik- und Balancing-Umbaus in [docs/optik-und-bosse-plan.md](docs/optik-und-bosse-plan.md).

## Credits

Vollständig im Spiel (Titelmenü → Credits) und in den `LICENSE.txt` der Asset-Ordner.

- Figuren, Gelände, Häuser: Liberated Pixel Cup (Stephen Challener, Charles Sanchez,
  Lanea Zimmerman, Daniel Armstrong u. a.), CC-BY-SA 3.0 / GPL 3.0
- Kampfkulissen: Luis Zuno (ansimuz), CC0
- Kacheln, Requisiten, Partikel: 0x72 (Dungeon Tileset II) und Kenney, CC0
- Musik: Juhani Junkala (JRPG Music Packs), CC0; Klänge: Kenney, artisticdude, CC0
- Schrift: DotGothic16 (Fontworks Inc.), SIL OFL 1.1
