# baby-remote — Changelog

Per-component scheme `YYYY.ver.patch`. Components: `esphome/` (FW), `scad/` (3D
print), `kicad/` (PCB). Each has its own `VERSION` file.

## 2026.3.0 — 2026-06-10

### Firmware (esphome) → 2026.3.0
- **Wireless updates (OTA):** added an `ota:` block (esphome platform, password
  in `secrets.yaml`). After this build's USB flash, future updates go over WiFi.
  No HA API — the remote stays MQTT/n8n-only.
- **Sleep is now a single/double tap:** one Sleep key sends an explicit
  `sleep/start` on a single tap and `sleep/end` on a double tap (two presses
  <1s apart) via `on_multi_click`, instead of a `toggle` the backend had to
  resolve.
- **Press feedback on the OLED:** each button press now flashes the chosen
  action (e.g. "Breast", "Sleep start") on the screen for ~4s, then the display
  falls back to the schedule (last feed / last pump / next pump). Appears
  instantly via `component.update`.
- **Pump reminder banner:** when the pump-due alert hits the broker
  (`baby/remote/alert` rising edge) the OLED pops a "Pump reminder / pump due
  now" banner for ~4s (in addition to the existing ambient LED pulse). The
  banner is **suppressed on the first (retained) alert after boot/reconnect**,
  so only a genuine due-cycle pops it.

## 2026.2.1 — 2026-06-06

OLED test-fit refinements + a new glue-on label plate.

### 3D print (scad) → 2026.2.1
- **Thinner button engraving** on the cap: `label_widen` 0.15 → 0.05 (0.15 printed mushy).
- **OLED from the test fit:** window short axis 14.05 → **15**; mounting-hole spacing back to
  **19.07 × 14.05** (the spacing that physically fit — squaring it to 19.07 was wrong); pin/hole
  Ø 3.5 → **2.0**.
- **Snap-pins dropped from the cap** — the real holes (19.07 × 14.05) fall *inside* the
  24.92 × 15 window, so pins had no plate to hang from. The screen drops into the window/pocket
  and is held by the new label plate.
- **NEW glue-on label plate** (`baby-remote-label-plate.scad`): a very thin (0.8 mm) faceplate
  with RAISED button words + "Baby Tracker" title and through-holes for the buttons, LED, USB
  and OLED. The OLED window slightly overlaps the glass to trap the screen. Built as a 2-colour
  print — swap filament at **z = 0.8 mm** for contrast-coloured letters. No border frame.

### Firmware (esphome) — unchanged (stays 2026.2.0)
### PCB (kicad) — unchanged (stays 2026.1.0)

## 2026.2.0 — 2026-06-05

**0.96" I2C OLED added to the remote** — a dumb 3-row status screen on the cap,
fed over MQTT by n8n (last feed / last pump / pump reminder). Verified end-to-end
on hardware (`ac:eb:e6:56:60:3c`).

### Firmware (esphome) → 2026.2.0
- **This build targets the OLED unit.** `ROW0`/`ROW1` moved off `GPIO0`/`GPIO1` to
  **`GPIO21`/`GPIO20`** (C3 UART0 pins, free because the logger is on
  `USB_SERIAL_JTAG`), which frees **`GPIO0` (I2C SDA) / `GPIO1` (I2C SCL)** for the
  SSD1306 128×64 @ `0x3C`. Wiring: GND→GND, VDD→3V3, SCK→GPIO1, SDA→GPIO0.
- **Dumb 3-row display:** subscribes to `baby/remote/display` (`{l1,l2,l3}`, retained)
  and renders the rows under a "Baby Remote" title; falls back to IP/RSSI before any
  data arrives.
- **Reminder alert:** `baby/remote/alert` (`"1"`/`"0"`, retained) pulses the WS2812
  amber every 6 s and shows a `!` by the title while active.
- Fabbed (non-OLED) PCBs: revert `ROW0`/`ROW1` to `GPIO0`/`GPIO1` and delete the
  `i2c`/`font`/`display`/`globals`/`interval` blocks (documented in the yaml header).

### 3D print (scad) → 2026.2.0
- **Cap now carries the 0.96" OLED** in the top band (left of the C3, clears it by
  ~3.7 mm), glass flush through the front: window **24.92 × 14.05 mm**, mounted by
  **4 slotted snap-pins** (19.07 mm spacing, Ø3.5) the module clicks onto from the
  open back. Holes sit *outside* the window so the pins + the mid-board header hide
  under the bezel. All parametric behind `oled_enable`.
- **Sticker labels** (`labels/`): added the OLED window square to the faceplate and
  moved "Baby Tracker" + the baby face to the top band.

### Backend (n8n)
- New **Baby Remote Display** workflow (`baby-tracker/n8n/baby_remote_display.json`):
  every-minute schedule → query last feed/pump from Postgres → publish the 3 rows +
  the pump-due alert (reuses the existing Postgres + MQTT credentials).

### PCB (kicad) — unchanged (stays 2026.1.0)

## 2026.1.1 — 2026-06-03

### Firmware (esphome) → 2026.1.1
- **Active pin map is now the fabricated JLCPCB PCB**: rows `GPIO0, GPIO1, GPIO3,
  GPIO4` (matches the PCB, back-engraving, KiCad and SCAD). The hand-soldered
  prototype's `GPIO21/GPIO20` row remap is documented in the header as the
  alternative to use only when flashing that one board.
- **WiFi fix:** `output_power: 8.5dB` — caps TX power so the SuperMini's PCB chip
  antenna stops overdriving and association succeeds (was stuck in an auth→init
  loop). Same root cause as cpapdash-push-c3's `esp_wifi_set_max_tx_power(44)`.
- **LED driver** → `esp32_rmt_led_strip` (the esp-idf-native WS2812 driver;
  `neopixelbus` is arduino-only).
- **Logger** pinned to `hardware_uart: USB_SERIAL_JTAG` (log over the C3 native USB).
- Verified end-to-end: all 15 buttons publish to MQTT `baby/remote/event`; n8n
  "Baby Event Logger" now also subscribes to that topic, so presses reach Andy's
  tracker too.

### 3D print (scad) → 2026.1.1
- **USB-C cutout** enlarged 11×5 → **16×9 mm** to clear the cable's rubber overmold.
- **Hinge bore** 1.9 → **2.2 mm** so a 1.75 mm filament pin fits after print shrinkage.
- **Removed the fragile PCB-retention snap ridges** from the cap — they were thin,
  broke easily, and collided with the back cover. The board is now held against the
  cap ledge by the back cover's standoff posts.
- **Hinge wall-relief**: each part's left wall is relieved at the *other* part's
  knuckle positions so the interleaved knuckles no longer collide with the opposite
  wall (verified: cap ∩ cover has no real volume overlap).
- **Lid→back snap rebuilt** as the proven `push-c3-enclosure-bareboards` pattern:
  a ridge on the cover's outer wall + a TAPERED tab (thick root → thin tip, 7 mm
  drop) on the cap with an anchor block and capture notch. Flexes outward into open
  air (no more rubbing), strong at the notch.
- **Button plunger nub** +0.1 mm (`hole_clear` 0.6 → 0.5) — less wobble in the plate hole.
- Regenerated all individual STLs (cap, board, back cover, plunger, LED window).

### PCB (kicad) — unchanged (stays 2026.1.0)
