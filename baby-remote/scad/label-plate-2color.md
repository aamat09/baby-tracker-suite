# Label plate — 2-color print guide

How to print `baby-remote-label-plate.stl` so the **raised button words + title
come out in a contrast color** against the plate, using a single-extruder printer
and one manual filament swap.

## Why it works

The plate is modeled in two height bands (see `baby-remote-label-plate.scad`):

| Band | Height (z) | What | Color |
|------|------------|------|-------|
| Base plate | `0 → 0.8 mm` (`plate_t`) | the thin faceplate | **color 1** |
| Raised letters | `0.8 → 1.4 mm` (`+ label_h 0.6`) | the words + "Baby Tracker" title | **color 2** |

So a single filament swap at **z = 0.8 mm** puts everything below in color 1 and
everything above (the letters) in color 2. Print **flat, letters up** (the STL is
already oriented this way) — no supports needed.

## Bambu Studio (manual swap)

1. Load `baby-remote-label-plate.stl` and slice.
2. Open **Preview** and use the **vertical layer slider** on the right edge.
3. Drag to the layer at **z ≈ 0.8 mm**. At 0.2 mm layer height that's the **start
   of layer 5** (layers 1–4 = the 0.8 mm base).
4. Click the **`+` / flag icon** on the slider at that layer → **Add color change**.
   On a single-extruder printer this inserts a **pause** (`M600`-style).
5. Print. At z = 0.8 mm the printer parks and pauses → **load the contrast
   filament, purge until the old color is gone, then Resume.** The 0.6 mm of
   letters print in the new color.

> Target it **by height (0.8 mm)**, not by layer number, so it still lands right if
> you change layer height (e.g. 0.16 mm → the base is 5 layers, swap before layer 6).

## Other slicers

- **PrusaSlicer / SuperSlicer / OrcaSlicer:** right-click the layer slider at
  z = 0.8 mm → **Add color change** (single extruder → pause + manual swap).
- **Cura:** *Extensions → Post Processing → Modify G-Code → Filament Change*, set
  it at the layer/height for z = 0.8 mm.

## No-babysitting alternative (AMS / multi-material)

If you have an AMS or multi-extruder setup, ask for the **split export**
(`…-plate-base.stl` + `…-plate-letters.stl`). Load both, assign a color per object,
and the slicer handles the change automatically — perfect registration since both
share the same origin.

## Assembly

Glue the finished plate onto the cap's outer face (it aligns 1:1 — shared
`dims.scad` grid). The button nubs poke through the square holes, the LED through
its hole, the USB through the top notch, and the **OLED window edge overlaps the
glass to trap the screen** (the cap has no snap-pins).
