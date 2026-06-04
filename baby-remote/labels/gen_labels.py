#!/usr/bin/env python3
"""Generate a 1:1 sticky-label faceplate for the baby-remote cap.

Orientation (confirmed against the physical cap):
  - USB-C cutout at the BOTTOM, on the right (Sleep/LED column side)
  - LED at the TOP-RIGHT
  - rows run Tummy(top) -> Breast(bottom); labels sit BELOW their buttons,
    facing down toward the cutout
  - columns: Breast on the LEFT (no left-right mirror)
  - "Baby Tracker" + baby face in the bottom blank band, above the USB

This is the first layout flipped TOP-BOTTOM (positions only; text stays upright).

Distances trace back to scad/dims.scad:
  grid (board-local):  cx = 16.5 + 17c , cy = 38.5 + 17r          (17 mm pitch)
  board -> cap (outer): px/py add wall + pcb_clear = 2.0 + 0.4 = 2.4
  cap outer footprint:  case_w x case_l = 88.8 x 110.8 mm
  button hole:          cover_hole = 7.8 mm (rounded square)
  LED window:           d = 10 mm at cell (3,3)  (no label)
  USB-C notch:          usbc_w = 16 mm centred at px(66)

Print at **100% (actual size, no scaling)**; verify with the 50 mm bar.
"""

# ── shared geometry (mirror of dims.scad) ─────────────────────────────
WALL, PCB_CLEAR = 2.0, 0.4
OFF = WALL + PCB_CLEAR                         # board -> cap origin offset = 2.4
CASE_W, CASE_L, CORNER_R = 88.8, 110.8, 4.0
HOLE = 7.8                                     # cover_hole (rounded square)
LED_D = 10.0
USB_W, USB_CX = 16.0, OFF + 66.0               # USB-edge notch (board x = 66), right side
HOLE_RX = 1.3
CAL_H = 22.0                                   # bottom strip for calibration bar / note
LABEL_OFF = 8.5                                # word sits this far BELOW its button (toward USB)
FONT      = "Arial Rounded MT Bold, Arial, sans-serif"
FONT_SIZE = 3.2                                # mm
PAGE_H    = CASE_L + CAL_H

# button labels by [row][col]; None = the LED cell (no label)
LABELS = [["Breast", "Bottle", "Solid",  "Sleep"],
          ["Pump L", "Pump R", "Bath",   "Meds"],
          ["Pee",    "Poop",   "Both",   "Change"],
          ["Tummy",  "Weight", "Note",   None]]

# ── coordinate helpers: model -> page (TOP-BOTTOM flip, X unchanged) ──
def bx(c):  return OFF + 16.5 + 17 * c           # Breast = left (no mirror)
def by(r):  return CASE_L - (OFF + 38.5 + 17 * r)  # row0 (Breast) bottom, row3 (Tummy) top


# ── header: "Baby Tracker" title + a baby face on the side ────────────
def baby_face(fx, fy, r):
    s = [f'<g fill="none" stroke="#000" stroke-width="0.45" '
         f'stroke-linecap="round" stroke-linejoin="round">']
    s.append(f'<circle cx="{fx}" cy="{fy}" r="{r}" fill="#fff"/>')          # head
    s.append(f'<circle cx="{fx-r}" cy="{fy}" r="{r*0.26:.2f}"/>')           # ear L
    s.append(f'<circle cx="{fx+r}" cy="{fy}" r="{r*0.26:.2f}"/>')           # ear R
    s.append(f'<path d="M {fx-1.4:.2f} {fy-r+0.3:.2f} q 1.4 -2.4 2.9 -0.7"/>')  # hair curl
    s.append(f'<circle cx="{fx-r*0.36:.2f}" cy="{fy-r*0.08:.2f}" r="0.75" fill="#000"/>')  # eye L
    s.append(f'<circle cx="{fx+r*0.36:.2f}" cy="{fy-r*0.08:.2f}" r="0.75" fill="#000"/>')  # eye R
    s.append(f'<path d="M {fx-r*0.42:.2f} {fy+r*0.32:.2f} '
             f'q {r*0.42:.2f} {r*0.5:.2f} {r*0.84:.2f} 0"/>')               # smile
    s.append('</g>')
    return "\n".join(s)

def header():
    # bottom blank band: between the Breast row labels and the USB notch
    fy = CASE_L - 16.0          # face centre (page y), down in the blank space
    fx, fr = 11.5, 6.5
    tcx = (fx + fr + CASE_W) / 2
    return (baby_face(fx, fy, fr) +
            f'\n<text x="{tcx:.1f}" y="{fy+2.4:.1f}" font-family="{FONT}" '
            f'font-size="7" font-weight="bold" text-anchor="middle" fill="#000">'
            f'Baby Tracker</text>')


def svg():
    el = [f'<svg xmlns="http://www.w3.org/2000/svg" '
          f'width="{CASE_W}mm" height="{PAGE_H}mm" viewBox="0 0 {CASE_W} {PAGE_H}">',
          '<rect x="0" y="0" width="100%" height="100%" fill="white"/>']

    # ── faceplate outline, USB notch, holes, crosshairs ──
    el.append('<g stroke="#000" fill="none" stroke-width="0.2">')
    el.append(f'<rect x="0" y="0" width="{CASE_W}" height="{CASE_L}" '
              f'rx="{CORNER_R}" ry="{CORNER_R}"/>')
    # USB-C notch on the BOTTOM edge (orientation aid)
    el.append(f'<rect x="{USB_CX-USB_W/2:.2f}" y="{CASE_L-3:.2f}" width="{USB_W}" '
              f'height="3.2" stroke="#888"/>')
    for r in range(4):
        for c in range(4):
            x, y = bx(c), by(r)
            if LABELS[r][c] is None:           # LED cell
                el.append(f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{LED_D/2}" '
                          f'stroke="#888" stroke-dasharray="0.8 0.8"/>')
            else:
                el.append(f'<rect x="{x-HOLE/2:.2f}" y="{y-HOLE/2:.2f}" '
                          f'width="{HOLE}" height="{HOLE}" rx="{HOLE_RX}" ry="{HOLE_RX}" '
                          f'stroke="#bbb" stroke-dasharray="0.6 0.6"/>')
            el.append(f'<line x1="{x-1.5:.2f}" y1="{y:.2f}" x2="{x+1.5:.2f}" y2="{y:.2f}" stroke="#ddd"/>')
            el.append(f'<line x1="{x:.2f}" y1="{y-1.5:.2f}" x2="{x:.2f}" y2="{y+1.5:.2f}" stroke="#ddd"/>')
    el.append('</g>')

    # ── labels (centred BELOW each button, facing the cutout) ──
    el.append(f'<g fill="#000" font-family="{FONT}" font-size="{FONT_SIZE}" '
              f'font-weight="bold" text-anchor="middle">')
    for r in range(4):
        for c in range(4):
            w = LABELS[r][c]
            if not w:
                continue
            el.append(f'<text x="{bx(c):.2f}" y="{by(r)+LABEL_OFF:.2f}" '
                      f'dominant-baseline="middle">{w}</text>')
    el.append('</g>')

    # ── header (title + baby face) in the bottom blank band ──
    el.append(header())

    # ── orientation note + 50 mm calibration bar (below the faceplate) ──
    yb = CASE_L + 8
    el.append('<g font-family="Arial, sans-serif" font-size="3" fill="#000">')
    el.append(f'<text x="2" y="{CASE_L+5:.1f}">USB at bottom · LED top-right · PRINT AT 100% (actual size, no scaling)</text>')
    el.append(f'<line x1="2" y1="{yb+4:.1f}" x2="52" y2="{yb+4:.1f}" stroke="#000" stroke-width="0.3"/>')
    el.append(f'<line x1="2" y1="{yb+2.5:.1f}" x2="2" y2="{yb+5.5:.1f}" stroke="#000" stroke-width="0.3"/>')
    el.append(f'<line x1="52" y1="{yb+2.5:.1f}" x2="52" y2="{yb+5.5:.1f}" stroke="#000" stroke-width="0.3"/>')
    el.append(f'<text x="54" y="{yb+5:.1f}" font-size="2.6">50 mm (measure to verify scale)</text>')
    el.append('</g>')

    el.append('</svg>')
    return "\n".join(el)


if __name__ == "__main__":
    import os
    here = os.path.dirname(os.path.abspath(__file__))
    s = svg()
    svg_path = os.path.join(here, "baby-remote-labels.svg")
    with open(svg_path, "w") as f:
        f.write(s)
    print("wrote", svg_path)
    try:
        import cairosvg
        pdf_path = os.path.join(here, "baby-remote-labels.pdf")
        cairosvg.svg2pdf(bytestring=s.encode(), write_to=pdf_path)
        print("wrote", pdf_path)
    except ImportError:
        print("NOTE: cairosvg not importable — SVG only (no PDF).")
