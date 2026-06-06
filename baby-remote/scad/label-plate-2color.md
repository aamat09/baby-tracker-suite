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

1. **Add a second filament first** (this is the step everyone misses — without it
   the color-change `+` does nothing, because there's no other color to switch to).
   In **Prepare**, click the small **`+`** next to the filament list → you now have
   Filament 1 + Filament 2. Set Filament 2 to your letter color.
2. Load `baby-remote-label-plate.stl` and **Slice**.
3. Switch to the **Preview** tab (the color-change `+` only works in Preview, **not**
   Prepare — the other reason "nothing happens").
4. On the **vertical layer slider** (right edge), drag to **z ≈ 0.8 mm**. At 0.2 mm
   layer height that's the **start of layer 5** (layers 1–4 = the 0.8 mm base).
5. Click the **`+`** on the slider at that layer → it inserts a **color change to
   Filament 2** (a flag/diamond marker appears on the slider).
6. Print.
   - **AMS lite (A1 mini):** assign Filament 2 to a slot → it swaps automatically.
   - **Single spool, no AMS:** the change becomes a **pause** → at z = 0.8 mm load
     the contrast filament, purge until the old color is gone, then **Resume**.

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
