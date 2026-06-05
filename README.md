# Baby Tracker Suite

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-%23FFDD00.svg?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/aamat09)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![ESPHome](https://img.shields.io/badge/ESPHome-firmware-blue.svg?logo=esphome)](https://esphome.io/)
![status](https://img.shields.io/badge/status-active-brightgreen)

A baby care tracking system built on Home Assistant, n8n, PostgreSQL, and ESP32. Born out of a contraction tracker built for labor, evolved into a full newborn care dashboard once my son arrived plus a ~$10 3D-printed physical remote for those 3am diaper-change logs.

<p align="center">
  <img src="assets/dashboard.png" alt="Home Assistant baby tracker dashboard — summary stats and one-tap event buttons" width="340">
</p>

## Features

- **One-tap logging** of feeds, diapers, sleep, baths, medicine, tummy time, weight, pumping, and notes. 17 event types across 8 categories
- **Multi-channel fan-out** on every press: PostgreSQL, both phones, Echo Show, and Discord via a single n8n webhook
- **Live HA dashboard** with daily stats (feeds/diapers today, sleep total, last feed/diaper) polled every 30s
- **3D-printed physical remote** ESP32-C3 + a 15-button 4x4 matrix + WS2812 feedback LED, MQTT over WiFi
- **Reproducible PCB**  fully-routed 2-layer KiCad board *and* a 3D-printed copper-tape groove board, both generated from script
- **2-hour pump reminders** with independent per-side timers
- **Retired contraction tracker**  the labor-day origin story, Ring panic button + on-demand Ollama labor-stage AI assessment

## The Story

When my wife went into labor, we needed a way to log contractions without fumbling with phone apps. We paired a Ring Alarm Panic Button (Z-Wave) to our home automation stack where one press logged the contraction, timestamped it in PostgreSQL, notified both phones, posted to Discord, and announced it on the Echo Show. It worked beautifully for 700+ contractions over two weeks.

When we got to the hospital, the Ring button was back home. So we added intensity-coded buttons (Mild/Moderate/Strong/Intense) to the HA dashboard with color coding, stats (average gap, frequency), and an on-demand AI assessment powered by Ollama that would estimate the labor stage.

My son was born the next day. The contraction tracker was retired the same day and replaced with a baby tracker covering feeds, diapers, sleep, baths, medicine, tummy time, weight, pumping, and notes.

Keeping the same low-friction (high-WAF) style, we then built a 3D-printed physical remote with labeled buttons so nobody has to unlock a phone to log a diaper change at 3am.

## Architecture

```
Physical Button / HA App / Siri Shortcut
        |
        v
   n8n Webhook (POST /webhook/baby-event)
        |
   +----+----+----+----+
   |    |    |    |    |
   v    v    v    v    v
  DB  Phone Phone Echo Discord
  PG   you   ptnr Show
        |
        v
   n8n Log API (GET /webhook/baby-log)
        |
        v
   HA REST Sensor (polls every 30s)
        |
        v
   HA Dashboard (stats + journal + buttons)
```

## Components

### Contraction Tracker (retired)

The original. Ring Panic Button press -> Z-Wave JS UI -> Python bridge -> MQTT + n8n webhook -> full pipeline.

| File | Description |
|------|-------------|
| `contraction-tracker/zwave_panic_mqtt.py` | Python bridge: Z-Wave WebSocket -> MQTT + webhook |
| `contraction-tracker/n8n/contraction_tracker.json` | Main workflow: webhook -> Discord, DB, notifications |
| `contraction-tracker/n8n/contraction_note_logger.json` | MQTT-triggered note logger |
| `contraction-tracker/n8n/contraction_log_api.json` | GET API: returns entries + 2-hour stats |
| `contraction-tracker/n8n/contraction_ai_assessment.json` | On-demand Ollama AI labor stage assessment |
| `contraction-tracker/ha/dashboard.json` | HA Lovelace dashboard (intensity buttons, journal, AI) |
| `contraction-tracker/ha/configuration_snippets.yaml` | HA config: rest_command, input_text, REST sensor |

Features added during labor:
- 4 color-coded intensity buttons (Mild/Moderate/Strong/Intense)
- Real-time stats: contraction count, average gap, average intensity (last 2 hours)
- On-demand AI assessment via Ollama (gpt-oss model) with timestamp
- Press feedback: haptic vibration + button scale animation
- iPhone home screen shortcut via Apple Shortcuts deep link

### Baby Tracker (active)

Full newborn care tracker. 17 event types across 8 categories.

| File | Description |
|------|-------------|
| `baby-tracker/n8n/baby_event_logger.json` | Main workflow: webhook -> DB + phone notifications |
| `baby-tracker/n8n/baby_note_logger.json` | MQTT-triggered note logger |
| `baby-tracker/n8n/baby_log_api.json` | GET API: returns entries + daily stats |
| `baby-tracker/n8n/pump_reminder.json` | 2-hour pump reminder (independent timers per pump) |
| `baby-tracker/ha/dashboard.json` | HA Lovelace dashboard |
| `baby-tracker/ha/configuration_snippets.yaml` | HA config snippets |

Event types:
- **Feed:** breast, bottle, solid
- **Pump:** left, right (with 2h reminder)
- **Diaper:** pee, poop, both, change
- **Other:** sleep (toggle), bath, medicine, tummy_time, weight
- **Notes:** regular, special (star-prefixed)

Stats tracked: last feed time/type, last diaper time/type, feeds today, diapers today, sleep total today, baths/medicines/tummy times/pumps today.

### Baby Tracker App — Home Assistant add-on (separate repo)

A **single-container Home Assistant app** that bundles everything above with
**no n8n and no external database**: an Ingress web UI (the colorful button
dashboard), local SQLite storage, the same stats/journal, pump reminders, and
native HA entities via MQTT discovery — and it still listens to the ESP32
remote. It lives in its own installable repo:

➡️ **[hms-homelab/hms-baby-tracker](https://github.com/hms-homelab/hms-baby-tracker)**
(FastAPI + SQLite; add the repo URL under Settings → Add-ons/Apps → Repositories).

<p align="center">
  <img src="assets/addon/ingress-ui.png" alt="Baby Tracker add-on Ingress web UI — summary stats, color-coded button grid, notes and journal" width="48%">
  <img src="assets/addon/addon-info.png" alt="Baby Tracker add-on running in Home Assistant — Info page with Ingress, start-on-boot and resource usage" width="48%">
</p>
<p align="center"><em>The add-on's Ingress web UI (left) and its Home Assistant app page (right) — runs as a native HA add-on, no n8n or external DB.</em></p>

The n8n + PostgreSQL path in this repo remains as the advanced/legacy backend;
the app is the portable, one-click way to run the whole thing.

### Baby Remote (in progress)

3D-printed physical remote control with ESP32-C3, 15 tactile buttons, RGB LED feedback, and LiPo battery.


> **🎛️ Want one without building it?** The remote is made in small batches —
> **[join the device waitlist →](https://www.shmaestro.com/waitlist)**.

| File | Description |
|------|-------------|
| `baby-remote/kicad/` | 2-layer PCB (DRC-clean, Freerouting-routed) — the manufactured board |
| `baby-remote/kicad/fab/baby-remote-jlcpcb.zip` | Gerbers + drill, ready to upload to JLCPCB |
| `baby-remote/scad/baby-remote-pcb.scad` | OpenSCAD 3D-printed PCB substrate (grooved board = device back; bottom feet) |
| `baby-remote/scad/baby-remote-pcb-case.scad` | OpenSCAD snap-fit cap (walls + ledge + barrels + labels); board snaps in |
| `baby-remote/scad/button_plunger.stl` | Button plunger (print 15×) |
| `baby-remote/scad/led_window.stl` | LED window (print 1× in clear filament) |
| `baby-remote/esphome/baby_remote.yaml` | ESPHome firmware: matrix -> MQTT -> n8n / the app |

See [Hardware](#hardware) for the button layout, matrix wiring, PCB, and BOM.

### Database

| File | Description |
|------|-------------|
| `db/schema.sql` | PostgreSQL schema for both tables |

Both tables live in the `maestro_hub` database on PostgreSQL 17 at homelab.local.

## Hardware

The **Baby Remote** is a 3D-printed, battery-powered ESP32-C3 keypad. 15 tactile
switches on a diodeless **4x4 scan matrix** (16th cell is the LED window), each
press published over MQTT to the same n8n webhook the app and Siri use.

Button layout (4x4 grid, last cell = RGB LED):
```
 Breast  | Bottle  |  Solid  |  Sleep
 Pump L  | Pump R  |  Bath   |  Meds
  Pee    |  Poop   |  Both   | Change
 Tummy   | Weight  |  Note   |  [LED]
```

Matrix -> GPIO (firmware `baby-remote/esphome/baby_remote.yaml` == PCB):

| Signal | GPIO | Net |
|---|---|---|
| Rows (drive) | GPIO0, GPIO1, GPIO3, GPIO4 | `ROW0..3` |
| Columns (sense) | GPIO5, GPIO6, GPIO7, GPIO10 | `COL0..3` |
| WS2812B LED | GPIO8 | `LED_DIN` |

PCB -- two interchangeable designs, both script-generated and reproducible:
- **KiCad** (`baby-remote/kicad/`)  fully-routed **2-layer** board (rows on
  F.Cu, columns on B.Cu), DRC clean (0 violations / 0 unconnected / 0 parity),
  Freerouting-routed, JLCPCB-ready. Regenerate with `gen_schematic.py` ->
  `pcbgen.py`; route via Specctra DSN/SES.
- **OpenSCAD groove board** (`baby-remote/scad/baby-remote-pcb.scad`)  3D-printed
  substrate with copper-tape/tinned-wire grooves; rows on the top face, columns
  on the bottom, switch legs bridging faces (crossing-free).

BOM (~$10):

| Part | Qty |
|---|---|
| ESP32-C3 SuperMini | 1 |
| TP4056 USB-C LiPo charger | 1 |
| 3.7V LiPo 500mAh | 1 |
| 6x6x5mm tactile switches | 15 |
| WS2812B RGB LED | 1 |
| Slide switch (power) | 1 |

## Infrastructure

- **Home Assistant:** KVM/VM at homeassistant.local (dashboards, scripts, REST sensors)
- **n8n:** Native at homelab.local:5678 (workflow automation, webhooks)
- **PostgreSQL 17:** Native at homelab.local:5432 (data storage)
- **EMQX:** Native at homelab.local:1883 (MQTT broker)
- **Ollama:** ollama.local:11434 (AI assessment, RTX 3050)
- **ESPHome:** For ESP32 device firmware

## Install as a Home Assistant App

The fastest path — no n8n, no PostgreSQL, no manual scripts:

1. **Settings → Add-ons → Add-on Store** (shown as **Apps** on HA 2026.2+) →
   ⋮ → **Repositories** → add `https://github.com/hms-homelab/hms-baby-tracker`.
2. Install **Baby Tracker**, then **Start** it.
3. Open the **Web UI** (Ingress) — the button dashboard is right there.
4. *(optional)* In the app's **Configuration** tab set `notify_targets`
   (e.g. `mobile_app_your_phone`) to get press + pump-reminder notifications,
   and adjust `timezone` / `pump_hours`.

It auto-connects to the HA Mosquitto broker, so the **ESP32 remote keeps
working** (publishes to `baby/remote/event`) and native HA sensors/buttons
appear automatically via MQTT discovery. Data lives in the add-on's `/data`
(SQLite). Full reference:
[hms-baby-tracker DOCS](https://github.com/hms-homelab/hms-baby-tracker/blob/main/baby_tracker/DOCS.md).

## Quick Start (advanced / legacy n8n backend)

### 1. Database

```bash
psql -d maestro_hub -f db/schema.sql
```

### 2. n8n + Home Assistant

```bash
# Import the n8n workflows (n8n UI or API)
#   baby-tracker/n8n/*.json
# Add the HA snippets to configuration.yaml
#   baby-tracker/ha/configuration_snippets.yaml
# Import the dashboard into HA storage (.storage/lovelace.<name>)
#   baby-tracker/ha/dashboard.json
# Create the HA scripts referenced by the dashboard (rest_command + input_text,
#   see baby-tracker/ha/configuration_snippets.yaml)
```

### 3. Flash the remote

```bash
esphome run baby-remote/esphome/baby_remote.yaml
```

### 4. Build the remote

Print the case parts (`baby-remote/scad/*.stl`), fabricate the PCB
(KiCad Gerbers or the OpenSCAD groove board), and assemble.

## Related Projects

Part of the [Smart Home Maestro](https://github.com/hms-homelab) homelab:
- [hms-cpap](https://github.com/hms-homelab/hms-cpap) multi platform service for realtime visualization of sleep based data on cpap. 
- [hms-claude-mem](https://github.com/hms-homelab/hms-claude-mem) -- semantic memory MCP server (Redis vectorsets + Ollama)
- [hms-mm](https://github.com/hms-homelab/hms-mm) -- dual ESP32-C3 WiFi SD-card bridge
- [hms-scale-esp](https://github.com/hms-homelab/hms-scale-esp) -- ESP32-C3 BLE scale gateway

## License

MIT License -- see [LICENSE](LICENSE) for details.

## Support

If this project is useful to you, consider buying me a coffee!

[![Buy Me A Coffee](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/aamat09)
