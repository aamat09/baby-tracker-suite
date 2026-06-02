# Baby Remote — fab package (JLCPCB)

`baby-remote-jlcpcb.zip` is the manufacturing package generated from
`baby-remote.kicad_pcb` (DRC-clean, 2-layer, Freerouting-routed).

Regenerate:
```bash
CLI=/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli
"$CLI" pcb export gerbers --no-protel-ext \
  --layers F.Cu,B.Cu,F.Mask,B.Mask,F.Silkscreen,B.Silkscreen,Edge.Cuts \
  -o fab/gerbers/ baby-remote.kicad_pcb
"$CLI" pcb export drill --format excellon --excellon-units mm -o fab/gerbers/ baby-remote.kicad_pcb
# zip FLAT — files at the archive root (JLCPCB does not read nested folders)
( cd fab/gerbers && zip ../baby-remote-jlcpcb.zip *.gbr *.gbrjob *.drl )
```

## JLCPCB order settings
Upload `baby-remote-jlcpcb.zip` at jlcpcb.com → it auto-detects:

| Setting | Value |
|---|---|
| Layers | **2** |
| Dimensions | **80 × 100 mm** |
| Thickness | 1.6 mm |
| Min hole | 0.4 mm (vias), 1.1 mm (THT switch legs) |
| Min track/spacing | 0.3 mm tracks — well above JLCPCB's 0.127 mm min |
| Surface finish | HASL (lead-free) is fine; ENIG if you want flatter pads |
| Copper | 1 oz |

**Price tier:** the board is 80 × **100 mm** — within JLCPCB's cheapest
"≤100×100 mm, 5 pcs" promo tier (trimmed 2 mm off the empty bottom margin to
land here; copper extends only to y≈95, so there was ~9 mm of slack). A 5-pc
pilot is rock-bottom price.

## Assembly
All parts are hand-solderable: 15× 6×6×5 mm THT tactile switches, the WS2812B
(SMD PLCC4), and the ESP32-C3 SuperMini (castellated, solder flat or on headers).
This package is **bare-board only** (no JLCPCB PCBA / no BOM+CPL) — populate it
yourself. The matrix is diodeless; rows F.Cu / cols B.Cu.
