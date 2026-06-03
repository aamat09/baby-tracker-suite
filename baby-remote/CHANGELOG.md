# baby-remote — Changelog

Per-component scheme `YYYY.ver.patch`. Components: `esphome/` (FW), `scad/` (3D
print), `kicad/` (PCB). Each has its own `VERSION` file.

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
