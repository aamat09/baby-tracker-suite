// Baby Remote — GLUE-ON LABEL PLATE (very thin faceplate)
// A thin plate that glues on the cap's outer face: RAISED button words + the
// "Baby Tracker" title, with through-holes for the button nubs, the LED and the
// USB notch, and an OLED window whose edge slightly overlaps the glass so it TRAPS
// the screen (the cap has no snap-pins). No border frame, no connecting lines —
// a solid thin backing, so no letter can float.
// 2-COLOUR PRINT: print the plate, then swap to a contrast filament at z = plate_t
// so the raised letters come out in a second colour. Aligns to the cap via dims.scad.

include <dims.scad>   // case_w/case_l/corner_r, cx()/cy()/is_led(), px()/py(), usb_cx, usbc_w, wall

// ── plate ─────────────────────────────────────────────────
plate_t    = 0.8;     // very thin base plate
label_h    = 0.6;     // raised letter / title height
label_size = 3.0;
title_size = 4.0;
label_font = "Arial Rounded MT Bold";
label_dy   = 4.5;     // label offset above the button (matches the cap)

// ── cutouts ───────────────────────────────────────────────
hole_slack = 0.3;     // per-side clearance on the button-nub holes
trap_lip   = 0.8;     // OLED window edge overlaps the glass by this (traps the screen)

// ── shared grid (mirror of the cap) ───────────────────────
function btnx(c)=px(cx(c));
function btny(r)=py(cy(r));
cover_hole = 7.8 + 2*hole_slack;   // button-nub clearance hole
btn_r = 1.5;
rows_n = 4; cols_n = 4;
labels = ["Breast","Bottle","Solid","Sleep","Pump L","Pump R","Bath","Meds",
          "Pee","Poop","Both","Change","Tummy","Weight","Note"];

// ── OLED window (slightly smaller than the glass -> traps the screen) ──
oled_cx = 42; oled_cy = 18; oled_glass_w = 24.92; oled_glass_h = 15.0;
oled_win_w = oled_glass_w - 2*trap_lip;   // 23.32 (still clears the 21.7 lit area)
oled_win_h = oled_glass_h - 2*trap_lip;   // 13.40

module rbox(w,l,h,r){ hull() for(x=[r,w-r],y=[r,l-r]) translate([x,y,0]) cylinder(h=h,r=r,$fn=32); }
module rbox_c(w,l,h,r){ translate([-w/2,-l/2,0]) rbox(w,l,h,r); }

module label_plate(){
  difference(){
    union(){
      // thin base plate
      rbox(case_w, case_l, plate_t, corner_r);

      // raised button words
      for(r=[0:rows_n-1], c=[0:cols_n-1]){ li = r*cols_n + c;
        if(!is_led(r,c) && li < len(labels))
          translate([btnx(c), btny(r)+label_dy, plate_t])
            linear_extrude(label_h)
              text(labels[li], size=label_size, halign="center", valign="bottom", font=label_font);
      }

      // raised "Baby Tracker" title (far band, clear of the Tummy row)
      ty = (btny(3)+label_dy+label_size + (case_l-3)) / 2;
      translate([case_w/2, ty, plate_t])
        linear_extrude(label_h)
          text("Baby Tracker", size=title_size, halign="center", valign="center", font=label_font);
    }

    // ── cutouts ──
    // button-nub holes
    for(r=[0:rows_n-1], c=[0:cols_n-1]) if(!is_led(r,c))
      translate([btnx(c), btny(r), -0.1]) rbox_c(cover_hole, cover_hole, plate_t+0.2, btn_r);
    // LED hole
    translate([btnx(3), btny(3), -0.1]) cylinder(d=10.4, h=plate_t+0.2, $fn=24);
    // OLED window (edge overlaps the glass -> traps the screen)
    translate([oled_cx-oled_win_w/2, oled_cy-oled_win_h/2, -0.1])
      cube([oled_win_w, oled_win_h, plate_t+0.2]);
    // USB-C notch (top edge)
    translate([usb_cx-usbc_w/2, -0.1, -0.1]) cube([usbc_w, wall+0.4, plate_t+0.2]);
  }
}

label_plate();
