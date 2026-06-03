# CLAUDE.md — baby-tracker-suite

Baby care tracking system (Home Assistant + n8n + PostgreSQL + ESP32) plus a
3D-printed physical remote. See `README.md` for the story/architecture.

## baby-remote (the 15-button physical remote)

ESP32-C3 SuperMini reads a **4×4 button matrix** and publishes each press over
MQTT (`baby/remote/event`) for HA/n8n to log. WS2812 LED = press feedback.

### Board orientation — shared vocabulary (use these terms)
- **TOP = the USB-C / ESP32-C3 edge.** The connector edge is the orientation
  reference. **FRONT = the component/silk side = the button face.**
- In the **KiCad PCB**, +Y is **down**, so: the C3 + USB sit at **low Y (top)**,
  the keypad is **below** them. **Row 0 (Breast/Bottle/Solid/Sleep) is nearest
  the USB**; **row 3 (Tummy/Weight/Note) is the bottom edge**. **Columns 0→3 run
  left→right** (−X→+X).
- So when we talk routing: **"up/top" = toward USB (lower Y)**, **"down/bottom" =
  far keypad edge (higher Y)**, **"left/right" = −X/+X**. "This rail goes over
  that one" is read in that frame.

### Matrix → GPIO (firmware `esphome/baby_remote.yaml` == PCB)
- **Rows** GPIO0,1,3,4 → `ROW0..3` → **F.Cu horizontal rails**
- **Cols** GPIO5,6,7,10 → `COL0..3` → **B.Cu vertical rails**
- **WS2812 LED** DIN → GPIO8 (`LED_DIN`); VDD→+5V, VSS→GND
- Unused/NC: GPIO2,9,20,21
- Switch ↔ function (Value field, matches the row/col→event map):
  `SW1`=Breast(r0c0) `SW2`=Bottle `SW3`=Solid `SW4`=Sleep ·
  `SW5`=PumpL(r1c0) `SW6`=PumpR `SW7`=Bath `SW8`=Meds ·
  `SW9`=Pee(r2c0) `SW10`=Poop `SW11`=Both `SW12`=Change ·
  `SW13`=Tummy(r3c0) `SW14`=Weight `SW15`=Note · LED at (r3c3).

### KiCad project (`baby-remote/kicad/`)
- Reuses the cpapdash-push-c3 SuperMini symbol+footprint lib (copied in).
- Reproducible generators (run KiCad's bundled python for `pcbnew`):
  `gen_schematic.py` (schematic, writes `symbols.json` ref→UUID) →
  `pcbgen.py` (places footprints at the SCAD button grid: `btn_x=16.5+17c`,
  `btn_y=38.5+17r`, matrix nets, Edge.Cuts) → `route.py` (routing + GND pour).
- Footprints placed at the **17 mm enclosure grid** (matches `scad/baby-remote-pcb.scad` + `scad/baby-remote-pcb-case.scad`).
- Validate: `kicad-cli sch erc` (4 benign module-power notes) and
  `kicad-cli pcb drc --schematic-parity` (parity = 0).
- KiCad lock/report/backups are gitignored.

## Versioning
Per-component `VERSION` files, scheme **YYYY.ver.patch** (currently `2026.1.0`).
Never bump/tag without asking the user (their standing rule).

## Don't commit
Real `secrets.yaml` (use `*.example`), `.venv/`, KiCad `*.lck`/`*.kicad_prl`/
`*-backups/`, `.DS_Store`. HA/n8n exports are redacted (placeholders, no tokens).
