# Baby Remote — 3D-printed physical buttons for the baby tracker

A handheld 15-button remote so you can log a feed/diaper/sleep with one press
instead of unlocking a phone at 3am. An ESP32-C3 reads the buttons and publishes
each press over MQTT; Home Assistant / n8n pick it up and log the event.

> "She wanted physical buttons instead of the classic yaml." — and here we are.

## How it works

```
[15 tactile buttons] --GPIO--> ESP32-C3 --WiFi/MQTT--> broker --> Home Assistant / n8n --> PostgreSQL
                                  |
                                  +-- WS2812B LED flashes the button's colour as confirmation
```

Each button publishes to `baby/remote/event` with a small JSON payload
(`{"event_type":"feed","event_subtype":"breast"}`). The onboard RGB LED blinks
the event's colour so you get tactile *and* visual confirmation.

## Bill of materials

| Qty | Part | Notes |
|-----|------|-------|
| 1 | ESP32-C3 SuperMini | any C3 dev board with exposed GPIOs |
| 1 | TP4056 USB-C charging board | LiPo charge + protection |
| 1 | 3.7V LiPo, 500–800 mAh | ~48×30×5 mm fits the bay |
| 15 | 6×6×5 mm tactile push buttons | through-hole, 4-pin |
| 1 | WS2812B RGB LED | feedback indicator |
| — | hookup wire, solder | shared GND bus + 15 signal wires |

## Print

OpenSCAD source: [`scad/remote_case.scad`](scad/remote_case.scad). Exported STLs in `scad/`:

| File | Qty | Orientation |
|------|-----|-------------|
| `bottom_case.stl` | 1 | as-is (face down) |
| `top_cover.stl` | 1 | face up (labels up) |
| `button_plunger.stl` | **15** | nub up / skirt-opening down — no supports |
| `led_window.stl` | 1 | clear/translucent filament |

The buttons are a **plunger-in-barrel** design: each plunger drops into a barrel
molded into the case, rests on its tactile switch, and is captured by the cover —
no glue, no snap-fit, won't fall out or spin. Tune `plunger_clear` / `hole_clear`
in the SCAD if your printer runs tight/loose.

## Wiring

Every switch: one leg → its GPIO (`INPUT_PULLUP`, active-low), the other leg →
a shared **GND bus**. WS2812B data → **GPIO8**.

| Row | Buttons (GPIO) |
|-----|----------------|
| 0 | Breast `0`, Bottle `1`, Solid `2`, Sleep `3` |
| 1 | Pump L `4`, Pump R `5`, Bath `6`, Meds `7` |
| 2 | Pee `9`, Poop `10`, Both `18`, Change `19` |
| 3 | Tummy `20`, Weight `21`, Note `22` |

> **Note:** the firmware also samples battery voltage on an ADC pin. On the C3
> SuperMini the usable ADC pins overlap the button GPIOs — pick a free ADC-capable
> pin for the divider (or drop battery monitoring) so it doesn't clash with a button.

## Flash

```bash
cd esphome
cp secrets.yaml.example secrets.yaml   # fill in WiFi + MQTT
esphome run baby_remote.yaml
```

Firmware: [`esphome/baby_remote.yaml`](esphome/baby_remote.yaml). It connects to
WiFi + MQTT, defines a `binary_sensor` per button, and on press runs a script that
flashes the LED in the button's colour and publishes the event.

## Integrate

Point it at any MQTT broker Home Assistant or n8n listens on. The matching
HA config + n8n event-logger flow live one level up in
[`../baby-tracker/`](../baby-tracker/) (`ha/configuration_snippets.yaml`,
`n8n/baby_event_logger.json`). Subscribe to `baby/remote/event` and route each
`event_type`/`event_subtype` to your logger of choice.
