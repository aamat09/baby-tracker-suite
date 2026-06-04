// Baby Remote — SNAP-FIT CAP for the 3D-printed substrate (baby-remote-pcb.scad)
// THREE-part design (board + cap + back cover), for the 84 x 106 mm printed board:
//   - The populated board drops into this cap from below, top face up.
//   - The cap carries the walls, the hanging barrels, the plungers and labels.
//   - An internal LEDGE stops the board at z=0. The board is held against that
//     ledge by the back cover's standoff posts when closed (the old thin PCB-
//     retention snap ridges were removed — fragile + collided with the cover).
//   - BACK COVER (baby-remote-back-cover.scad) closes the wire side: joined by a
//     FILAMENT-PIN HINGE on the LEFT edge (interleaved knuckles, shared via
//     dims.scad) and SHORT SNAP CLAMPS on the RIGHT edge (cover_clamp skirts that
//     click under detent bumps near the seam). Cover posts push the board up to
//     the ledge when closed.
//   - USB-C notch in the top wall at the C3 port (board x = 66, top edge).
// Barrel/plunger/label geometry is the proven plunger-in-barrel design (carried
// over from the retired 3-part tray+cover); the perimeter = walls + internal
// ledge + hinge/cover-clamp. Print: cap TOP-FACE-DOWN (barrels up); plungers x15.

// ─── Board it wraps (shared via dims.scad) ────────────────
include <dims.scad>   // board_w/board_h/board_t, cx()/cy()/is_led(), c3_x — shared with the board

// ─── hinge pin-hole (tweak HERE, re-render just this part) ─
// Bore for the 1.75 mm filament pin. Proven value on cpapdash-push-c3 is 1.95.
// NOTE: this bore prints along Y = HORIZONTAL, so it bridges/sags; if the printed
// hole is too tight, ream with a 2 mm drill or switch to a teardrop bore — just
// raising this number barely helps once sag dominates.
hinge_bore = 2.0;

// ─── Fit / case (pcb_clear/wall/corner_r/case_*/px/py now in dims.scad) ───
top_thick=2.0;
ledge_w=1.2;          // perimeter shelf the board TOP rests against
sw_h=5;               // switch body height above the board top
cap_t=1.6;            // plunger cup-top (lands on the switch)

// ─── button labels (ENGRAVED) ────────────────────────────
// Letters are CUT INTO the top face (raised/embossed text was too mushy at this
// size). Strokes are widened a touch (label_widen) so the grooves read well
// without the glyphs creeping down into the button hole below.
label_depth = 0.5;    // how deep the letters cut into the top face (mm)
label_size  = 3.0;    // glyph size (mm)
label_widen = 0.15;   // offset() that fattens each stroke / groove per side (mm)
label_font  = "Arial Rounded MT Bold";   // friendly + prints clean; alts below
// alternatives (installed): "Avenir Next:style=Demi Bold", "Arial:style=Bold",
//   "Arial Narrow:style=Bold" (fits long words), "Arial Black"
label_dy    = 4.5;    // label offset above the button centre (Y)

// ─── Barrel + plunger (proven plunger-in-barrel geometry) ─
btn_r=1.5; sw_size=6;
skirt_in=sw_size+1.0; skirt_wall=1.4; skirt_out=skirt_in+2*skirt_wall;
plunger_clear=0.4; barrel_in=skirt_out+plunger_clear; barrel_wall=1.4;
barrel_out=barrel_in+2*barrel_wall;
skirt_len=1.0; skirt_play=0.4; nub_proud=2.5; hole_clear=0.5;  // nub_proud: how far the button stands above the face (was 1.5). 0.6→0.5: nub 0.1 larger, less wobble in the plate hole
cover_hole=skirt_out-2.0; nub_size=cover_hole-hole_clear;

// USB-C opening (usbc_w/usbc_h now in dims.scad)

// ─── z stack: z = 0 at the BOARD TOP face (board_bot now in dims.scad) ──
plate_under = sw_h + cap_t;             // 6.6  cap plate underside
plate_top   = plate_under + top_thick;  // 8.6  cap outer top
barrel_len  = plate_under - 0.4;        // 6.2  barrels hang to ~board top

// ─── Footprint (case_w/case_l, inner_*, px/py, usb_cx now in dims.scad) ──
function btnx(c)=px(cx(c));
function btny(r)=py(cy(r));

rows_n=4; cols_n=4;
labels=["Breast","Bottle","Solid","Sleep","Pump L","Pump R","Bath","Meds",
        "Pee","Poop","Both","Change","Tummy","Weight","Note"];

// ─── Helpers ──────────────────────────────────────────────
module rbox(w,l,h,r){ hull() for(x=[r,w-r],y=[r,l-r]) translate([x,y,0]) cylinder(h=h,r=r,$fn=32); }
module rbox_c(w,l,h,r){ translate([-w/2,-l/2,0]) rbox(w,l,h,r); }

// barrel hangs from the plate underside down toward the board top
module barrel_guide(){
    translate([0,0,plate_under-barrel_len])
    difference(){
        rbox_c(barrel_out,barrel_out,barrel_len,btn_r);
        translate([0,0,-0.1]) rbox_c(barrel_in,barrel_in,barrel_len+0.2,btn_r);
        for(m=[0,1]) mirror([m,0,0])
            translate([barrel_in/2-0.5,-2,-0.1]) cube([barrel_wall+1,4,2.6]);
    }
}

module button_plunger(){
    nub_top=top_thick+nub_proud; sh_out=skirt_out-skirt_play; bore=skirt_in;
    difference(){
        union(){
            translate([0,0,-cap_t]) rbox_c(sh_out,sh_out,cap_t,btn_r);
            rbox_c(nub_size,nub_size,nub_top,btn_r);
            translate([0,0,-cap_t-skirt_len]) rbox_c(sh_out,sh_out,skirt_len,btn_r);
        }
        translate([0,0,-cap_t-skirt_len-0.1])
            rbox_c(bore,bore,skirt_len+0.1+cap_t*3/4,btn_r);
    }
}
module led_window(){ cylinder(d=9.5,h=top_thick-0.2,$fn=24); }

// (Board-retention snap ridges removed: they were thin/fragile and collided with
//  the back cover. The board is now held against the ledge by the cover's standoff
//  posts when closed.)

// Cover snap clamp (RIGHT edge) — bareboards-style TAPERED TAB + ANCHOR + NOTCH.
// The tab hangs OUTSIDE the cover's right wall (flexes outward into open air, so it
// never rubs); thick at the root, thin at the tip; its notch captures the cover's
// outer-wall ridge when closed. Anchor block ties the tab into the cap wall.
module cover_clamp(yy){
    difference(){
        union(){
            // anchor block — volumetric tie into the cap wall, above the seam only
            translate([case_w - wall, yy - snap_w/2, board_bot])
                cube([wall + snap_tab_thick_root, snap_w, 2.5]);
            // tapered tab — outside the cover wall, hanging from the seam
            hull(){
                translate([case_w, yy - snap_w/2, board_bot - 0.01])
                    cube([snap_tab_thick_root, snap_w, 0.01]);
                translate([case_w, yy - snap_w/2, board_bot - snap_tab_drop])
                    cube([snap_tab_thick_tip, snap_w, 0.01]);
            }
        }
        // notch — captures the cover ridge when closed (oversized for tolerance)
        translate([case_w - 0.1, yy - snap_w/2 - 0.5, snap_ridge_zc - snap_notch_h/2])
            cube([snap_protrusion + 0.6, snap_w + 1, snap_notch_h]);
    }
}

// ─── Cap ──────────────────────────────────────────────────
module cap(){
  difference(){
    union(){
        difference(){
            union(){
                // outer shell: walls (board_bot -> plate_under) + plate on top
                translate([0,0,board_bot]) rbox(case_w,case_l, plate_top-board_bot, corner_r);
            }
            // LOWER cavity (board-sized, board_bot -> ledge at z=0)
            translate([wall,wall,board_bot-0.1])
                rbox(inner_w,inner_l, (0-board_bot)+0.1, max(0.5,corner_r-wall));
            // UPPER cavity (narrower -> leaves a ledge shelf at z=0; barrels live here)
            translate([wall+ledge_w,wall+ledge_w,0])
                rbox(inner_w-2*ledge_w,inner_l-2*ledge_w, (plate_under-0)+0.1, max(0.5,corner_r-wall-ledge_w));

            // button nub holes through the plate
            for(r=[0:rows_n-1],c=[0:cols_n-1]) if(!is_led(r,c))
                translate([btnx(c),btny(r),plate_under-0.1])
                    rbox_c(cover_hole,cover_hole, top_thick+0.2, btn_r);
            // LED window
            translate([btnx(3),btny(3),plate_under-0.1]) cylinder(d=10,h=top_thick+0.2,$fn=24);
            // (labels are ENGRAVED — cut in the outer difference below)
            // USB-C notch in the TOP wall (y-min edge) at the C3 port. Anchored at
            // board_bot and capped below the top plate so the taller (boot-clearing)
            // opening doesn't breach the top face.
            translate([usb_cx-usbc_w/2, -1, board_bot]) cube([usbc_w, wall+2, usbc_h]);

            // relieve the LEFT wall where the COVER's knuckles (odd i) pass through
            for(i=[0:hinge_n-1]) if(i%2==1) hinge_relief(i);
        }

        // hanging barrels (skip the LED cell)
        for(r=[0:rows_n-1],c=[0:cols_n-1]) if(!is_led(r,c))
            translate([btnx(c),btny(r),0]) barrel_guide();

        // ── back-cover joint ──
        // hinge knuckles on the LEFT edge — CAP half = EVEN indices (cover = odd)
        for(i=[0:hinge_n-1]) if(i%2==0) hinge_knuckle(i);
        // snap clamps on the RIGHT edge (short skirts, click under cover bumps)
        for(yy=clamp_ys) cover_clamp(yy);
    }
    // clear the pin hole through the wall (knuckle bore alone gets plugged)
    hinge_pin_channel();
    // ENGRAVED labels — cut into the top face; strokes widened via offset()
    for(r=[0:rows_n-1],c=[0:cols_n-1]){ li=r*cols_n+c;
        if(!is_led(r,c) && li<len(labels))
            translate([btnx(c),btny(r)+label_dy,plate_top-label_depth]) linear_extrude(label_depth+0.1)
                offset(delta=label_widen)
                    text(labels[li],size=label_size,halign="center",valign="bottom",font=label_font);
    }
  }
}

// ─── PCB stand-in (visual only) ───────────────────────────
module board_mock(){
    color("#1b5e20") translate([px(0),py(0),board_bot]) cube([board_w,board_h,board_t]);
    color("#222") for(r=[0:rows_n-1],c=[0:cols_n-1]) if(!is_led(r,c))
        translate([btnx(c)-sw_size/2,btny(r)-sw_size/2,0]) cube([sw_size,sw_size,sw_h]);
    color("#333") translate([usb_cx-9,py(2),0]) cube([18,22.5,3]);
}

// ─── Assembly preview ─────────────────────────────────────
module assembly(){
    color("SlateGray",0.55) cap();
    board_mock();
    btn_colors=["#FF69B4","#4A90D9","#2d6a4f","#7B68EE","#B19CD9","#B19CD9",
                "#00CED1","#DC3545","#FFD700","#D2B48C","#8B6914","#BDB76B",
                "#008080","#808080","#F5F5F5"];
    for(r=[0:rows_n-1],c=[0:cols_n-1]){ li=r*cols_n+c;
        if(!is_led(r,c) && li<15) translate([btnx(c),btny(r),sw_h]) color(btn_colors[li]) button_plunger();
    }
    translate([btnx(3),btny(3),plate_under]) color("White",0.5) led_window();
}

// ─── Render (uncomment ONE for STL export) ────────────────
assembly();
// cap();
// button_plunger();
// led_window();
