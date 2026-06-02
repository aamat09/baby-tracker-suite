// Baby Tracker Remote Control — ESP32-C3 + 15 Buttons (PCB-carrier, v1)
// 4 cols x 4 rows grid (last cell = RGB LED window).
//
// v1 = USB-POWERED (no LiPo / no power switch — reserved for v2).
// This enclosure is a CARRIER for the manufactured KiCad PCB
// (baby-remote/kicad/, 80 x 100 mm), NOT a hand-wired build:
//   - The PCB holds all 15 tactile switches at the 17 mm grid, the C3, the LED.
//   - The board drops onto a perimeter LEDGE; the cover CLAMPS it (snap-fit
//     clips) — no PCB mounting holes required, order the board as-is.
//   - PLUNGER-IN-BARREL buttons kept: the barrels now hang from the COVER and
//     surround each board-mounted switch; plungers are captured by the cover
//     holes and rest on the switches. (The switch body + barrel both guide.)
//   - USB-C opening is at the C3 SuperMini's own port (board-x 66, top edge).
//
// Print guide:
//   - bottom_case(): PCB tray, print face-down
//   - top_cover(): lid + hanging barrels — print TOP-FACE-DOWN (barrels point up)
//   - button_plunger(): print 15x, skirt-opening DOWN (nub up), no supports
//   - led_window(): print 1x in clear/translucent filament
//
// Assembly: solder/populate the PCB → drop it into the tray (rests on ledge) →
//   insert the 15 plungers into the cover barrels from below → snap the cover
//   on (its barrels seat over the switches, plungers land on them).

// ─── PCB (manufactured KiCad board) ───────────────────────
// KiCad edge-cuts: x in [2,82], y in [2,102] -> 80 x 100 mm. Grid (board mm):
//   cx = 16.5 + 17*c , cy = 38.5 + 17*r ; C3/USB at (66, top edge); LED cell 3,3.
pcb_w = 80;
pcb_l = 100;          // trimmed 2mm off the bottom -> fits JLCPCB 100x100 tier
pcb_t = 1.6;
pcb_clear = 0.4;          // fit clearance per side

// ─── Case ─────────────────────────────────────────────────
wall = 2.0;
corner_r = 4;
top_thick = 2.0;
bot_thick = 2.0;
ledge = 1.2;              // perimeter shelf the PCB rests on
standoff_h = 3.0;         // gap under the PCB for THT switch/C3 legs

// ─── Tactile switch (6x6x5, board-mounted) ────────────────
sw_size = 6;
sw_h = 5;                 // switch body height above the PCB

// ─── Barrel + plunger (proven mechanism, unchanged sizing) ─
btn_r = 1.5;
skirt_in   = sw_size + 1.0;                 // 7.0  clears the 6mm switch body
skirt_wall = 1.4;
skirt_out  = skirt_in + 2 * skirt_wall;     // 9.8  (shoulder = cover capture)
plunger_clear = 0.4;
barrel_in  = skirt_out + plunger_clear;     // 10.2 (skirt slides in here)
barrel_wall = 1.4;
barrel_out = barrel_in + 2 * barrel_wall;   // 13.0 (fits the 17mm cell pitch)
skirt_len  = 1.0;
skirt_play = 0.4;
cap_t      = 1.6;         // cup-top / shoulder; lands on the switch
nub_proud  = 1.5;
hole_clear = 0.6;
cover_hole = skirt_out - 2.0;        // 7.8 (< shoulder -> cover captures cap)
nub_size   = cover_hole - hole_clear;// 7.2

// USB-C opening (C3 SuperMini dev-board port)
usbc_w = 11;
usbc_h = 5;

// ─── Derived geometry ─────────────────────────────────────
inner_w = pcb_w + 2 * pcb_clear;     // 80.8
inner_l = pcb_l + 2 * pcb_clear;     // 102.8
case_w  = inner_w + 2 * wall;        // 84.8
case_l  = inner_l + 2 * wall;        // 106.8

pcb_bot_z   = bot_thick + standoff_h;        // 5.0
pcb_top_z   = pcb_bot_z + pcb_t;             // 6.6
sw_top_z    = pcb_top_z + sw_h;              // 11.6
cover_under_z = sw_top_z + cap_t;            // 13.2  (cover underside)
barrel_len  = cover_under_z - (pcb_top_z + 0.4);  // 6.2  (hang to ~PCB top)

// board mm -> case mm (board KiCad corner (2,2) sits at (wall+clear, wall+clear))
function cxc(kx) = wall + pcb_clear + (kx - 2);
function cyc(ky) = wall + pcb_clear + (ky - 2);
function btn_x(c) = cxc(16.5 + 17 * c);
function btn_y(r) = cyc(38.5 + 17 * r);
function is_led_cell(r, c) = (r == 3 && c == 3);
usb_cx = cxc(66);                    // USB at board x = 66

// ─── Helpers ──────────────────────────────────────────────
module rounded_box(w, l, h, r) {
    hull() for (x = [r, w-r], y = [r, l-r])
        translate([x, y, 0]) cylinder(h=h, r=r, $fn=32);
}
module rounded_box_centered(w, l, h, r) {
    translate([-w/2, -l/2, 0]) rounded_box(w, l, h, r);
}

// ─── Bottom Case (PCB tray) ───────────────────────────────
module bottom_case() {
    difference() {
        rounded_box(case_w, case_l, cover_under_z, corner_r);

        // Cavity ABOVE the ledge — PCB + components drop in from the top.
        translate([wall, wall, pcb_bot_z])
            rounded_box(inner_w, inner_l, cover_under_z, max(0.5, corner_r - wall));

        // Leg cavity BELOW the ledge (inset by `ledge` so the PCB rests on it).
        translate([wall + ledge, wall + ledge, bot_thick])
            rounded_box(inner_w - 2*ledge, inner_l - 2*ledge,
                        standoff_h + 0.1, max(0.5, corner_r - wall - ledge));

        // USB-C opening at the C3 port (top edge = y-min), at PCB height.
        translate([usb_cx - usbc_w/2, -1, pcb_top_z - 0.6])
            cube([usbc_w, wall + 2, usbc_h]);
    }

    // Snap lugs on the inner walls (catch the cover skirt). Small ramps.
    for (sx = [0, 1]) mirror([sx, 0, 0]) translate([sx ? -case_w : 0, 0, 0])
        for (yy = [case_l*0.3, case_l*0.7])
            translate([wall, yy, cover_under_z - 2.2])
                rotate([0, -90, 0]) cylinder(h=0.8, r=0.9, $fn=12);
}

// ─── Top Cover (lid + hanging barrels) ────────────────────
// One barrel per switch cell hangs below the plate (local z<0) to surround the
// board-mounted switch and guide its plunger. Print TOP-FACE-DOWN.
module barrel_guide() {
    translate([0, 0, -barrel_len])
        difference() {
            rounded_box_centered(barrel_out, barrel_out, barrel_len, btn_r);
            translate([0, 0, -0.1])
                rounded_box_centered(barrel_in, barrel_in, barrel_len + 0.2, btn_r);
            // two wire/leg relief slots at the base
            for (m = [0, 1]) mirror([m, 0, 0])
                translate([barrel_in/2 - 0.5, -2, -0.1])
                    cube([barrel_wall + 1, 4, 2.6]);
        }
}

module top_cover() {
    union() {
        difference() {
            rounded_box(case_w, case_l, top_thick, corner_r);

            // Nub holes (rounded square, smaller than the shoulder = capture).
            for (r = [0:rows_n-1], c = [0:cols_n-1])
                if (!is_led_cell(r, c))
                    translate([btn_x(c), btn_y(r), -1])
                        rounded_box_centered(cover_hole, cover_hole, top_thick + 2, btn_r);

            // LED window (cell 3,3).
            translate([btn_x(3), btn_y(3), -1])
                cylinder(d=10, h=top_thick + 2, $fn=24);

            // Engraved labels (0.4 mm).
            for (r = [0:rows_n-1], c = [0:cols_n-1]) {
                li = r * cols_n + c;
                if (!is_led_cell(r, c) && li < len(labels))
                    translate([btn_x(c), btn_y(r) + 4.5, top_thick - 0.4])
                        linear_extrude(0.5)
                            text(labels[li], size=3, halign="center", valign="bottom",
                                 font="Liberation Sans:style=Bold");
            }
        }

        // Hanging barrels (skip the LED cell).
        for (r = [0:rows_n-1], c = [0:cols_n-1])
            if (!is_led_cell(r, c))
                translate([btn_x(c), btn_y(r), 0]) barrel_guide();

        // Perimeter skirt that drops into the tray (snap-fit against the lugs).
        difference() {
            translate([wall - 0.4, wall - 0.4, -3.0])
                rounded_box(inner_w + 0.8, inner_l + 0.8, 3.0, max(0.5, corner_r - wall));
            translate([wall + 0.8, wall + 0.8, -3.1])
                rounded_box(inner_w - 1.6, inner_l - 1.6, 3.2, max(0.5, corner_r - wall - 1.2));
        }
    }
}

rows_n = 4;
cols_n = 4;
labels = [
    "Breast", "Bottle", "Solid", "Sleep",
    "Pump L", "Pump R", "Bath",  "Meds",
    "Pee",    "Poop",   "Both",  "Change",
    "Tummy",  "Weight", "Note"
];

// ─── Button Plunger (unchanged) ───────────────────────────
module button_plunger() {
    nub_top = top_thick + nub_proud;
    sh_out  = skirt_out - skirt_play;     // 9.4 outer, loose fit
    bore    = skirt_in;                    // 7.0 uniform inner, clears switch
    difference() {
        union() {
            translate([0, 0, -cap_t])
                rounded_box_centered(sh_out, sh_out, cap_t, btn_r);
            rounded_box_centered(nub_size, nub_size, nub_top, btn_r);
            translate([0, 0, -cap_t - skirt_len])
                rounded_box_centered(sh_out, sh_out, skirt_len, btn_r);
        }
        translate([0, 0, -cap_t - skirt_len - 0.1])
            rounded_box_centered(bore, bore, skirt_len + 0.1 + cap_t * 3 / 4, btn_r);
    }
}

// ─── LED Window ───────────────────────────────────────────
module led_window() {
    cylinder(d=9.5, h=top_thick - 0.2, $fn=24);
}

// ─── PCB stand-in (visual only) ───────────────────────────
module pcb_mock() {
    color("#1b5e20")
        translate([wall + pcb_clear, wall + pcb_clear, pcb_bot_z])
            cube([pcb_w, pcb_l, pcb_t]);
    // switches
    color("#222")
        for (r = [0:rows_n-1], c = [0:cols_n-1]) if (!is_led_cell(r, c))
            translate([btn_x(c) - sw_size/2, btn_y(r) - sw_size/2, pcb_top_z])
                cube([sw_size, sw_size, sw_h]);
    // C3 module (top-right, USB to the top edge)
    color("#333")
        translate([cxc(66) - 9, cyc(2) , pcb_top_z]) cube([18, 22.5, 3]);
}

// ─── Assembly Preview ─────────────────────────────────────
module assembly() {
    color("DimGray") bottom_case();
    pcb_mock();
    color("SlateGray", 0.85) translate([0, 0, cover_under_z]) top_cover();

    btn_colors = [
        "#FF69B4", "#4A90D9", "#2d6a4f", "#7B68EE",
        "#B19CD9", "#B19CD9", "#00CED1", "#DC3545",
        "#FFD700", "#D2B48C", "#8B6914", "#BDB76B",
        "#008080", "#808080", "#F5F5F5"
    ];
    for (r = [0:rows_n-1], c = [0:cols_n-1]) {
        li = r * cols_n + c;
        if (!is_led_cell(r, c) && li < 15)
            translate([btn_x(c), btn_y(r), cover_under_z])
                color(btn_colors[li]) button_plunger();
    }
    translate([btn_x(3), btn_y(3), cover_under_z]) color("White", 0.5) led_window();
}

// ─── Render (uncomment ONE for STL export) ────────────────
assembly();
// bottom_case();
// top_cover();
// button_plunger();
// led_window();
