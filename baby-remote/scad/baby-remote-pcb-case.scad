// Baby Remote — SNAP-FIT CAP for the 3D-printed substrate (baby-remote-pcb.scad)
// TWO-part design (board + cap), for the 84 x 106 mm printed board:
//   - The populated board snaps UP into this cap from below.
//   - The cap carries the walls, the hanging barrels, the plungers and labels.
//   - An internal LEDGE stops the board (top face up); SNAP RIDGES on the inner
//     walls catch the board's bottom edge and hold it against the ledge.
//   - The board IS the back of the device: its feet lift the exposed wire side
//     off the surface (a snap-on back cover is a v2).
//   - USB-C notch in the top wall at the C3 port (board x = 66, top edge).
// Barrel/plunger/label geometry is the proven plunger-in-barrel design (carried
// over from the retired 3-part tray+cover); only the perimeter is new (walls +
// internal ledge + snap ridges). Print: cap TOP-FACE-DOWN (barrels up); plungers x15.

// ─── Board it wraps (shared via dims.scad) ────────────────
include <dims.scad>   // board_w/board_h/board_t, cx()/cy()/is_led(), c3_x — shared with the board

// ─── Fit / case ───────────────────────────────────────────
pcb_clear=0.4; wall=2.0; corner_r=4; top_thick=2.0;
ledge_w=1.2;          // perimeter shelf the board TOP rests against
sw_h=5;               // switch body height above the board top
cap_t=1.6;            // plunger cup-top (lands on the switch)

// ─── Barrel + plunger (proven plunger-in-barrel geometry) ─
btn_r=1.5; sw_size=6;
skirt_in=sw_size+1.0; skirt_wall=1.4; skirt_out=skirt_in+2*skirt_wall;
plunger_clear=0.4; barrel_in=skirt_out+plunger_clear; barrel_wall=1.4;
barrel_out=barrel_in+2*barrel_wall;
skirt_len=1.0; skirt_play=0.4; nub_proud=1.5; hole_clear=0.6;
cover_hole=skirt_out-2.0; nub_size=cover_hole-hole_clear;

// USB-C opening (C3 dev-board port)
usbc_w=11; usbc_h=5;

// ─── z stack: z = 0 at the BOARD TOP face ─────────────────
plate_under = sw_h + cap_t;             // 6.6  cap plate underside
plate_top   = plate_under + top_thick;  // 8.6  cap outer top
board_bot   = -board_t;                 // -2.0 board back plane
barrel_len  = plate_under - 0.4;        // 6.2  barrels hang to ~board top

// ─── Footprint ────────────────────────────────────────────
inner_w = board_w + 2*pcb_clear;        // 84.8
inner_l = board_h + 2*pcb_clear;        // 106.8
case_w  = inner_w + 2*wall;             // 88.8
case_l  = inner_l + 2*wall;             // 110.8

// board-local -> case coords
function px(x)=wall+pcb_clear+x;
function py(y)=wall+pcb_clear+y;
function btnx(c)=px(cx(c));
function btny(r)=py(cy(r));
usb_cx=px(c3_x);

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

// half-round snap ridge (catches the board bottom edge; top at board_bot)
module snap_ridge_x(len=8){ translate([0,0,board_bot-0.9]) rotate([0,90,0]) cylinder(h=len,r=0.9,center=true,$fn=20); }
module snap_ridge_y(len=8){ translate([0,0,board_bot-0.9]) rotate([90,0,0]) cylinder(h=len,r=0.9,center=true,$fn=20); }

// ─── Cap ──────────────────────────────────────────────────
module cap(){
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
            // engraved labels (0.4 mm into the top face)
            for(r=[0:rows_n-1],c=[0:cols_n-1]){ li=r*cols_n+c;
                if(!is_led(r,c) && li<len(labels))
                    translate([btnx(c),btny(r)+4.5,plate_top-0.4]) linear_extrude(0.5)
                        text(labels[li],size=3,halign="center",valign="bottom",font="Liberation Sans:style=Bold");
            }
            // USB-C notch in the TOP wall (y-min edge) at the C3 port
            translate([usb_cx-usbc_w/2,-1,-0.6]) cube([usbc_w, wall+2, usbc_h+0.6]);
        }

        // hanging barrels (skip the LED cell)
        for(r=[0:rows_n-1],c=[0:cols_n-1]) if(!is_led(r,c))
            translate([btnx(c),btny(r),0]) barrel_guide();

        // snap ridges on the inner walls (catch the board bottom edge)
        for(yy=[case_l*0.30,case_l*0.70]){
            translate([wall, yy, 0])           snap_ridge_y();   // left wall
            translate([case_w-wall, yy, 0])    snap_ridge_y();   // right wall
        }
        translate([case_w*0.5, wall, 0])         snap_ridge_x();  // top wall
        translate([case_w*0.5, case_l-wall, 0])  snap_ridge_x();  // bottom wall
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
