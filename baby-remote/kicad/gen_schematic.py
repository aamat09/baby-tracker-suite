#!/usr/bin/env python3
"""Generate baby-remote.kicad_sch: ESP32-C3 SuperMini + 4x4 button matrix.

Wiring (matches baby_remote.yaml matrix_keypad):
  Rows: GPIO0,1,3,4 -> ROW0..3 ; Cols: GPIO5,6,7,10 -> COL0..3 ; LED: GPIO8.
Connectivity is by net LABELS on pin endpoints (no wires); KiCad joins pins
that share a label name. Placement is snapped to the 1.27mm grid; unused
GPIOs get no-connect flags and power nets get PWR_FLAGs (clean ERC).
"""
import re, uuid, os

KICAD_SYM = "/Applications/KiCad/KiCad.app/Contents/SharedSupport/symbols"
HERE = os.path.dirname(os.path.abspath(__file__))
GRID = 1.27
def snap(v): return round(v / GRID) * GRID
def uid(): return str(uuid.uuid4())

def extract_symbol(lib_path, name):
    s = open(lib_path).read()
    i = s.find(f'(symbol "{name}"')
    if i < 0: raise SystemExit(f"symbol {name} not found in {lib_path}")
    depth = 0
    for j in range(i, len(s)):
        if s[j] == '(': depth += 1
        elif s[j] == ')':
            depth -= 1
            if depth == 0: return s[i:j+1]
    raise SystemExit("unbalanced")

def pins(block):
    out = []
    for m in re.finditer(
        r'\(pin\s+\S+\s+\S+\s+\(at\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\)'
        r'.*?\(name\s+"([^"]+)".*?\(number\s+"([^"]+)"', block, re.S):
        x, y, a, nm, num = m.groups()
        out.append((nm, num, float(x), float(y), float(a)))
    return out

c3_block  = extract_symbol(f"{HERE}/ESP32-C3_SUPERMINI.kicad_sym", "ESP32-C3_SUPERMINI")
sw_block  = extract_symbol(f"{KICAD_SYM}/Switch.kicad_sym", "SW_Push")
led_block = extract_symbol(f"{KICAD_SYM}/LED.kicad_sym", "WS2812B")

c3_pins, sw_pins, led_pins = pins(c3_block), pins(sw_block), pins(led_block)

c3_libid  = "ESP32-C3-SuperMini:ESP32-C3_SUPERMINI"
sw_libid  = "Switch:SW_Push"
led_libid = "LED:WS2812B"
c3_block_p  = c3_block.replace('(symbol "ESP32-C3_SUPERMINI"', f'(symbol "{c3_libid}"', 1)
sw_block_p  = sw_block.replace('(symbol "SW_Push"', f'(symbol "{sw_libid}"', 1)
led_block_p = led_block.replace('(symbol "WS2812B"', f'(symbol "{led_libid}"', 1)

ROOT = uid()
parts, labels, ncs, SYMS = [], [], [], {}

def place_label(net, x, y, ang=0):
    labels.append(f'  (label "{net}" (at {x:.2f} {y:.2f} {ang}) '
                  f'(effects (font (size 1.27 1.27)) (justify left bottom)) (uuid "{uid()}"))')

def no_connect(x, y):
    ncs.append(f'  (no_connect (at {x:.2f} {y:.2f}) (uuid "{uid()}"))')

def place_symbol(libid, ref, val, x, y, pinlist, footprint=""):
    x, y = snap(x), snap(y)
    sym_uuid = uid(); SYMS[ref] = sym_uuid
    pin_uuids = "\n".join(f'    (pin "{num}" (uuid "{uid()}"))' for (_, num, *_) in pinlist)
    fp = (f'    (property "Footprint" "{footprint}" (at {x} {y} 0) '
          f'(effects (font (size 1.27 1.27)) hide))') if footprint else ""
    parts.append(f'''  (symbol (lib_id "{libid}") (at {x} {y} 0) (unit 1)
    (exclude_from_sim no) (in_bom yes) (on_board yes) (dnp no)
    (uuid "{sym_uuid}")
    (property "Reference" "{ref}" (at {x+2} {y-2} 0) (effects (font (size 1.27 1.27)) (justify left)))
    (property "Value" "{val}" (at {x+2} {y+2} 0) (effects (font (size 1.27 1.27)) (justify left)))
{fp}
{pin_uuids}
    (instances (project "baby-remote" (path "/{ROOT}" (reference "{ref}") (unit 1))))
  )''')
    return {nm: (x + px, y - py) for (nm, num, px, py, pa) in pinlist}, \
           {num: (x + px, y - py) for (nm, num, px, py, pa) in pinlist}

# ---- C3 module ----
c3_byname, _ = place_symbol(c3_libid, "U1", "ESP32-C3 SuperMini", 180.34, 109.22, c3_pins,
                            "ESP32-C3-SuperMini:MODULE_ESP32-C3_SUPERMINI")
gpio_net = {"GPIO0":"ROW0","GPIO1":"ROW1","GPIO3":"ROW2","GPIO4":"ROW3",
            "GPIO5":"COL0","GPIO6":"COL1","GPIO7":"COL2","GPIO10":"COL3",
            "GPIO8":"LED_DIN","3V3":"+3V3","5V":"+5V","GND":"GND"}
for nm, (px, py) in c3_byname.items():
    if nm in gpio_net:
        place_label(gpio_net[nm], px, py)
    elif nm in ("GPIO2", "GPIO9", "GPIO20", "GPIO21"):
        no_connect(px, py)


# ---- 4x4 switch matrix (skip (3,3) = LED window -> WS2812) ----
LABELS = [["Breast","Bottle","Solid","Sleep"],
          ["PumpL","PumpR","Bath","Meds"],
          ["Pee","Poop","Both","Change"],
          ["Tummy","Weight","Note","LED"]]
x0, y0, dx, dy = 60.96, 60.96, 30.48, 25.40
n = 1
for r in range(4):
    for c in range(4):
        sx, sy = x0 + c*dx, y0 + r*dy
        if r == 3 and c == 3:
            _, byn = place_symbol(led_libid, "LED1", "WS2812B", sx, sy, led_pins,
                                  "LED_SMD:LED_WS2812B_PLCC4_5.0x5.0mm_P3.2mm")
            if "1" in byn: place_label("+5V",     *byn["1"])
            if "3" in byn: place_label("GND",     *byn["3"])
            if "4" in byn: place_label("LED_DIN", *byn["4"])
            if "2" in byn: no_connect(*byn["2"])
            continue
        _, byn = place_symbol(sw_libid, f"SW{n}", LABELS[r][c], sx, sy, sw_pins, "Button_Switch_THT:SW_PUSH_6mm_H13mm")
        if "1" in byn: place_label(f"ROW{r}", *byn["1"])
        if "2" in byn: place_label(f"COL{c}", *byn["2"])
        n += 1

sch = f'''(kicad_sch
  (version 20250114)
  (generator "baby_remote_gen")
  (generator_version "9.0")
  (uuid "{ROOT}")
  (paper "A4")
  (title_block (title "Baby Remote — 4x4 button matrix") (rev "2026.1.0") (company "Smart Home Maestro"))
  (lib_symbols
{c3_block_p}
{sw_block_p}
{led_block_p}
  )
{chr(10).join(parts)}
{chr(10).join(labels)}
{chr(10).join(ncs)}
  (sheet_instances
    (path "/" (page "1"))
  )
)
'''
open(f"{HERE}/baby-remote.kicad_sch", "w").write(sch)
import json
json.dump({"root": ROOT, "refs": SYMS}, open(f"{HERE}/symbols.json","w"))
print(f"wrote: {len(parts)} symbols, {len(labels)} labels, {len(ncs)} no-connects")
