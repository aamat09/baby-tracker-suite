// Baby Tracker Remote Control — ESP32-C3 + LiPo + 15 Buttons
// 4 columns x 4 rows grid (last cell = RGB LED window)
//
// PLUNGER-IN-BARREL buttons (no fragile snaps):
//   - Each cell has a barrel (tube) molded into the case; the 6x6 tactile
//     switch sits at its base.
//   - button_plunger() is a downward-opening cup: its skirt slides inside the
//     barrel AROUND the switch (long guide without adding height), and its
//     closed top presses the switch.
//   - The plunger's shoulder is wider than the cover hole, so the COVER traps
//     it from above. No snap, nothing flexes — robust on any printer.
//   - The press surface is a nub poking up through the cover hole.
//
// Print guide:
//   - bottom_case(): body + barrels + switch locators, print face-down
//   - top_cover(): lid with nub holes, print face-up
//   - button_plunger(): print 15x, skirt-opening DOWN (nub up), no supports
//   - led_window(): print 1x in clear/translucent filament
//
// Assembly: seat + wire a switch in each barrel, drop the plungers in from
//   above (they rest on the switches), then mate the cover — the small holes
//   capture the plungers. Nothing to glue or snap.
//
// BOM:
//   - ESP32-C3 SuperMini (22x18mm, ~3mm thick)
//   - TP4056 USB-C charging board (26x17mm)
//   - 3.7V LiPo 500-800mAh (~48x30x5mm)
//   - 15x 6x6x5mm tactile push buttons
//   - 1x WS2812B RGB LED (for feedback)
//   - Wire, solder, hot glue

// ─── Parameters ───────────────────────────────────────────

// Button grid (btn_size is the cell pitch reference)
cols = 4;
rows = 4;
btn_size = 13;
btn_spacing = 4;

// Tactile switch (6x6x5)
sw_size = 6;
sw_h = 5;                // body+plunger height (resting), sits on bay floor
sw_clear = 0.6;          // locator clearance around the body

// Barrel (guide tube in the case) + plunger cup — ROUNDED-SQUARE so the skirt
// clears the square 6x6 switch body cleanly and keys the nub (no spin).
// Sizes given inner-out.
btn_r = 1.5;             // corner rounding for the square button features
skirt_in = sw_size + 1.0;                  // 7.0 — clears the 6mm switch body
skirt_wall = 1.4;
skirt_out = skirt_in + 2 * skirt_wall;     // 9.8 (shoulder = cover capture)
plunger_clear = 0.4;     // slide clearance
barrel_in = skirt_out + plunger_clear;     // 10.2 (skirt slides in here)
barrel_wall = 1.4;
barrel_out = barrel_in + 2 * barrel_wall;  // 13.0 (fits 17mm cell pitch)
skirt_len = 1.0;         // guide length (skirt overlaps the switch)
skirt_play = 0.4;        // extra room: shrinks only the sliding skirt (not the
                         // shoulder), so the plunger isn't a tight fit in the barrel
cap_t = 1.6;             // cup-top / shoulder thickness; also lands on switch
nub_proud = 1.5;         // press nub height above the cover
hole_clear = 0.6;        // cover-hole clearance around the nub
cover_hole = skirt_out - 2.0;         // 7.8 (< shoulder → cover captures cap)
nub_size = cover_hole - hole_clear;   // 7.2 (square press surface)

// Case
wall = 2.0;
corner_r = 4;
top_thick = 2.0;
bot_thick = 2.0;
// Cover underside lands cap_t above the switch top, so the shoulder rests
// against the cover when the switch spring pushes the plunger up.
bay_h = sw_h + cap_t;    // 6.6  → body height = bot_thick + bay_h + top_thick

// USB-C cutout
usbc_w = 10;
usbc_h = 4;

// Electronics strip reserved below the button grid (board + LiPo)
ebay_len = 22;
padding = 10;

// Derived
grid_w = cols * btn_size + (cols - 1) * btn_spacing;
grid_h = rows * btn_size + (rows - 1) * btn_spacing;
case_w = grid_w + 2 * padding;
case_l = grid_h + 2 * padding + ebay_len;
cover_under_z = bot_thick + bay_h;    // world z of cover underside

// ─── Helpers ──────────────────────────────────────────────

module rounded_box(w, l, h, r) {
    hull() {
        for (x = [r, w-r], y = [r, l-r])
            translate([x, y, 0])
                cylinder(h=h, r=r, $fn=32);
    }
}

module rounded_box_centered(w, l, h, r) {
    translate([-w/2, -l/2, 0])
        rounded_box(w, l, h, r);
}

// Button cell centres
function btn_x(c) = padding + c * (btn_size + btn_spacing) + btn_size/2;
function btn_y(r) = padding + ebay_len + r * (btn_size + btn_spacing) + btn_size/2;
function is_led_cell(r, c) = (r == 3 && c == 3);

// ─── Barrel (guide tube, part of the case) ────────────────
// Base at local z=0. Holds the switch at the bottom, guides the plunger skirt.

module barrel() {
    difference() {
        rounded_box_centered(barrel_out, barrel_out, bay_h, btn_r);
        // bore the plunger skirt slides in
        translate([0, 0, -0.1])
            rounded_box_centered(barrel_in, barrel_in, bay_h + 0.2, btn_r);
        // two wire/leg slots through the wall at the base
        for (m = [0, 1]) mirror([m, 0, 0])
            translate([barrel_in/2 - 0.5, -2, -0.1])
                cube([barrel_wall + 1, 4, 2.6]);
    }
    // 4 corner nubs locate the 6x6 switch on the floor (sides open for wires)
    loc = sw_size + sw_clear;
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * loc/2 + (sx < 0 ? -1.2 : 0),
                   sy * loc/2 + (sy < 0 ? -1.2 : 0), 0])
            cube([1.2, 1.2, 2.6]);
}

// ─── Bottom Case ──────────────────────────────────────────

module bottom_case() {
    difference() {
        rounded_box(case_w, case_l, bot_thick + bay_h, corner_r);
        translate([wall, wall, bot_thick])
            rounded_box(case_w - 2*wall, case_l - 2*wall, bay_h + 1, corner_r - wall);
        // USB-C port cutout (bottom edge, centered)
        translate([case_w/2 - usbc_w/2, -1, bot_thick + 1])
            cube([usbc_w, wall + 2, usbc_h]);
        // Power switch hole (side)
        translate([-1, 15, bot_thick + 1])
            cube([wall + 2, 6, 3.5]);
    }

    // Barrel + switch locator under each button cell
    for (r = [0:rows-1], c = [0:cols-1])
        if (!is_led_cell(r, c))
            translate([btn_x(c), btn_y(r), bot_thick])
                barrel();

    // ESP32-C3 / LiPo strip shelf at the front edge
    translate([wall + 2, wall + 2, bot_thick])
        cube([case_w - 2*wall - 4, ebay_len - 4, 1.5]);

    // Screw bosses in corners for the top cover
    for (x = [wall + 3, case_w - wall - 3], y = [wall + 3, case_l - wall - 3])
        translate([x, y, bot_thick])
            difference() {
                cylinder(d=6, h=bay_h, $fn=20);
                cylinder(d=2.2, h=bay_h + 0.1, $fn=16);
            }
}

// ─── Top Cover ────────────────────────────────────────────

module top_cover() {
    difference() {
        rounded_box(case_w, case_l, top_thick, corner_r);

        // Nub holes (rounded square) — smaller than the shoulder = capture
        for (r = [0:rows-1], c = [0:cols-1])
            if (!is_led_cell(r, c))
                translate([btn_x(c), btn_y(r), -1])
                    rounded_box_centered(cover_hole, cover_hole, top_thick + 2, btn_r);

        // LED window (row 3, col 3)
        translate([btn_x(3), btn_y(3), -1])
            cylinder(d=10, h=top_thick + 2, $fn=24);

        // Screw holes
        for (x = [wall + 3, case_w - wall - 3], y = [wall + 3, case_l - wall - 3])
            translate([x, y, -1])
                cylinder(d=2.5, h=top_thick + 2, $fn=16);

        // Label engravings (0.4mm deep, on the top surface)
        label_depth = 0.4;
        labels = [
            "Breast", "Bottle", "Solid", "Sleep",
            "Pump L", "Pump R", "Bath",  "Meds",
            "Pee",    "Poop",   "Both",  "Change",
            "Tummy",  "Weight", "Note"
        ];
        for (r = [0:rows-1], c = [0:cols-1]) {
            li = r * cols + c;
            if (!is_led_cell(r, c) && li < len(labels))
                translate([btn_x(c), btn_y(r) + btn_size/2 + 1.5, top_thick - label_depth])
                    linear_extrude(label_depth + 0.1)
                        text(labels[li], size=3, halign="center", valign="bottom",
                             font="Liberation Sans:style=Bold");
        }
    }
}

// ─── Button Plunger ───────────────────────────────────────
// Downward-opening cup. z=0 is the cover underside. Drops into the barrel
// from above; the cover then captures it. Print skirt-opening DOWN (nub up).

module button_plunger() {
    // Solid nub; shoulder bored to the SAME diameter as the skirt (no internal
    // step), open at the bottom so the plunger slides over the switch. Only the
    // top 1/4 of the shoulder stays solid — the disc the switch clicks.
    nub_top    = top_thick + nub_proud;
    sh_out     = skirt_out - skirt_play;     // 9.4 outer (shoulder + skirt), loose fit
    bore       = skirt_in;                    // 7.0 — uniform inner diameter, clears switch

    difference() {
        union() {
            // Shoulder / cup top region (wider than cover_hole = capture).
            translate([0, 0, -cap_t])
                rounded_box_centered(sh_out, sh_out, cap_t, btn_r);
            // Press nub.
            rounded_box_centered(nub_size, nub_size, nub_top, btn_r);
            // Guide skirt.
            translate([0, 0, -cap_t - skirt_len])
                rounded_box_centered(sh_out, sh_out, skirt_len, btn_r);
        }

        // Single uniform bore: open bottom up through the skirt and the bottom
        // 3/4 of the shoulder (top 1/4 left solid as the switch-press disc).
        translate([0, 0, -cap_t - skirt_len - 0.1])
            rounded_box_centered(bore, bore, skirt_len + 0.1 + cap_t * 3 / 4, btn_r);
    }
}

// ─── LED Window ───────────────────────────────────────────

module led_window() {
    cylinder(d=9.5, h=top_thick - 0.2, $fn=24);
}

// ─── Assembly Preview ─────────────────────────────────────

module assembly() {
    color("DimGray") bottom_case();
    color("SlateGray", 0.85) translate([0, 0, cover_under_z]) top_cover();

    btn_colors = [
        "#FF69B4", "#4A90D9", "#2d6a4f", "#7B68EE",  // Breast, Bottle, Solid, Sleep
        "#B19CD9", "#B19CD9", "#00CED1", "#DC3545",  // Pump L, Pump R, Bath, Meds
        "#FFD700", "#D2B48C", "#8B6914", "#BDB76B",  // Pee, Poop, Both, Change
        "#008080", "#808080", "#F5F5F5"               // Tummy, Weight, Note
    ];
    for (r = [0:rows-1], c = [0:cols-1]) {
        li = r * cols + c;
        if (!is_led_cell(r, c) && li < 15)
            translate([btn_x(c), btn_y(r), cover_under_z])
                color(btn_colors[li]) button_plunger();
    }

    // RGB LED indicator
    translate([btn_x(3), btn_y(3), cover_under_z])
        color("White", 0.5) led_window();
}

// ─── Render ───────────────────────────────────────────────
// Uncomment ONE at a time for STL export:

assembly();      // Full preview

// Standalone hollow plunger placed to the side for inspection (nub up, as printed)
translate([-30, case_l / 2, cap_t + skirt_len])
    color("Tomato") button_plunger();
// bottom_case();
// top_cover();
// button_plunger();
// led_window();
