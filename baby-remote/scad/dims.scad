// Shared dimensions for the baby-remote printed board + snap cap.
// SINGLE SOURCE OF TRUTH for the values BOTH parts must agree on. Edit the
// OUTLINE / GRID / LED / USB here and both baby-remote-pcb.scad and
// baby-remote-pcb-case.scad pick it up (they `include <dims.scad>`).
//
// Internal details stay in their own file: grooves / holes / C3 pocket / feet
// live in baby-remote-pcb.scad; walls / ledge / snap ridges / barrels live in
// baby-remote-pcb-case.scad. Only the shared interface lives here.

board_w = 84;     // board outline X (mm)
board_h = 106;    // board outline Y (mm)
board_t = 2.0;    // board thickness

// 4x4 button grid — cell centre, board-local mm. TOP (low Y) = USB/C3 edge.
function cx(c) = 16.5 + 17*c;
function cy(r) = 38.5 + 17*r;
function is_led(r,c) = (r==3 && c==3);   // cell (3,3) is the RGB LED, not a switch

c3_x = 66;        // ESP32-C3 SuperMini / USB-C port X (board-local), at the top edge

// ─── Shared case fit (cap + back cover BOTH use these) ────
// Three parts now share this frame: baby-remote-pcb-case.scad (cap),
// baby-remote-back-cover.scad (back cover), and the board. z = 0 at BOARD TOP.
pcb_clear = 0.4;  // gap per side around the board
wall      = 2.0;  // perimeter wall thickness (cap + cover, kept equal so faces are flush)
corner_r  = 4;    // outer corner radius

board_bot = -board_t;             // -2.0  board back (bottom) plane
inner_w   = board_w + 2*pcb_clear; // 84.8  cavity X
inner_l   = board_h + 2*pcb_clear; // 106.8 cavity Y
case_w    = inner_w + 2*wall;       // 88.8  outer X (shared by cap + cover)
case_l    = inner_l + 2*wall;       // 110.8 outer Y

// board-local (x,y) -> case (outer) coords
function px(x) = wall + pcb_clear + x;
function py(y) = wall + pcb_clear + y;

// USB-C opening (C3 dev-board port, overhangs the TOP short edge, y=0)
usbc_w = 11; usbc_h = 5;
usb_cx = px(c3_x);

// ─── Back cover + cap-to-cover joint ──────────────────────
// The board IS held by the cap (proven). The COVER closes the wire side and
// joins the cap via a FILAMENT-PIN HINGE on the LEFT long edge (x=0) and a
// SNAP on the RIGHT long edge (x=case_w). USB stays on the top short edge.
wire_clear = 5.0;   // clearance below the board back for wires/solder/pins
cover_fl_t = 2.0;   // back-cover floor thickness
// derived z planes (cover lives below the board):
cover_in_z  = board_bot - wire_clear;        // -5.0  cover floor inner (top) face
cover_bot_z = cover_in_z - cover_fl_t;       // -7.0  cover outer bottom
// cover walls rise from the floor up to the board-bottom plane to butt the cap:
cover_wall_h = board_bot - cover_in_z;       //  3.0  (wall above the floor, to z=board_bot)

// Standoff posts on the cover floor that push the board UP to the cap ledge when
// closed. Same groove-free zones the old feet used (board-local mm).
post_r = 2.5;
post_xy = [[4,5],[80,5],[4,53],[80,53],[4,101],[80,101]];

// Filament-pin hinge on the LEFT edge (axis along Y at the seam z=board_bot).
hinge_kn_r = 2.5;   // knuckle outer radius (protrudes -X beyond the wall)
hinge_bore = 1.9;   // pin bore for a snipped 1.75 mm filament length
hinge_n    = 5;     // knuckle count along the edge (even idx = CAP, odd = COVER)
hinge_gap  = 0.5;   // axial play between adjacent knuckles
hinge_z    = board_bot;                       // pin axis z (the cap/cover seam)
function hinge_y0(i) = i*case_l/hinge_n;      // knuckle i start (Y)
function hinge_y1(i) = (i+1)*case_l/hinge_n;  // knuckle i end (Y)

// One hinge knuckle: a bored cylinder lying along Y at the left-edge seam.
// SHARED so cap (even i) and cover (odd i) knuckles interlock exactly.
module hinge_knuckle(i){
    y0 = hinge_y0(i) + hinge_gap/2;
    y1 = hinge_y1(i) - hinge_gap/2;
    translate([0, y0, hinge_z]) rotate([-90,0,0])
        difference(){
            cylinder(h=y1-y0, r=hinge_kn_r, $fn=32);
            translate([0,0,-0.1]) cylinder(h=y1-y0+0.2, r=hinge_bore/2, $fn=20);
        }
}

// Shallow snaps on the RIGHT edge: a SHORT cap skirt that sits FLUSH against the
// cover's outer wall (a solid edge rib, no standoff gap), with a barb that clicks
// into a NOTCH POCKET in the cover wall near the seam. Press a skirt out to release.
clamp_w   = 8;     // engagement width (along Y)
skirt_th  = 2.0;   // cap skirt thickness (X, outboard rib)
skirt_len = 4.0;   // SHORT skirt drop below the seam (vs the full cover depth)
skirt_clr = 0.2;   // skirt inner face clearance to the cover outer wall
barb_d    = 1.4;   // barb reach inward (-X) into the cover notch
barb_z    = board_bot - 1.6;   // barb/notch centre z (near the top of the wall)
notch_d   = 1.7;   // notch pocket depth into the cover wall (< wall, stays closed)
notch_h   = 2.6;   // notch pocket height
clamp_ys  = [case_l*0.33, case_l*0.66];   // two snaps
