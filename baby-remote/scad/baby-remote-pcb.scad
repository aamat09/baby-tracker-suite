// Baby Remote — 3D-printed PCB substrate (copper-tape / tinned-wire grooves)
// Technique from cpapdash-push-c3/kicad/v1/3d-pcb, but TWO faces:
//   ROWS = grooves on TOP face, COLS = grooves on BOTTOM face. Tactile switches
//   are through-hole, so their legs bridge faces -> the 4x4 matrix is
//   CROSSING-FREE. Row escapes run in the RIGHT MARGIN and hop to the bottom
//   (via through-holes) to dodge other rows. Cols run UP the bottom face.
// Frame shared with baby-remote-pcb-case.scad: cell centre = (16.5+17c, 38.5+17r).
// TOP = USB/C3 edge (low Y).  Rows GPIO0/1/3/4 · Cols GPIO5/6/7/10 · LED GPIO8.
//
// v1 = USB-POWERED. No LiPo (reserved for v2). The ESP32-C3 SuperMini is a
// through-hole DEV BOARD: its two 8-pin headers solder into the C3 footprint
// (16 holes) below; the USB-C connector overhangs the TOP board edge.
// EVERY pad is a real THROUGH-HOLE (pin/leg pokes through, solder on the back).

include <dims.scad>   // board_w/board_h/board_t, cx()/cy()/is_led(), c3_x — shared with the cap

groove_d=0.8; row_w=1.5; col_w=1.5; leg_d=1.6; pad_d=1.6;  // leg/pin/pad holes all 1.6 (snug for wires)

// Back stand-off (v1 = exposed back; snap-on back cover = v2)
foot_h=1.2; foot_r=2.5;  // bottom feet lift the wire-grooved back off the surface

legdx=3.25; legdy=2.25;

// C3 SuperMini — top-RIGHT of the bay. Long axis vertical so the USB-C short
// end sits flush at the TOP board edge (y=0). Two 8-pin headers @2.54 pitch,
// rows 0.6" (15.24 mm) apart. Right-edge pads catch row escapes; left-edge cols.
c3_len=22.5; c3_wid=18;
c3x=c3_x; c3y=2+c3_len/2; pitch=2.54;   // c3_x from dims.scad; USB end ~y=2 (top edge)
c3_pins=8; c3_pin_d=1.6;
c3_seat=1.2;   // recess depth: module body drops in & sits LOW (~flush w/ top)
c3_clear=0.4;  // pocket fit clearance per side
usb_w=9.5;     // USB-C connector cutout width at the top board edge
RX=c3x+7.62;   // right edge pads (rows)
LX=c3x-7.62;   // left edge pads (cols)
function pady(i)=c3y-1.5*pitch+i*pitch;        // 4 routed pads, i=0..3 (middle 4)
function c3_pady(i)=c3y+(i-(c3_pins-1)/2)*pitch;// full 8-pin header, i=0..7

// ---- helpers ----
module gr(x1,y1,x2,y2,w,top){dx=x2-x1;dy=y2-y1;L=sqrt(dx*dx+dy*dy);a=atan2(dy,dx);
    z=top?board_t-groove_d:-0.01;
    translate([x1,y1,z])rotate([0,0,a])translate([0,-w/2,0])cube([L,w,groove_d+0.02]);}
module rowg(x1,y1,x2,y2){gr(x1,y1,x2,y2,row_w,true);}
module colg(x1,y1,x2,y2){gr(x1,y1,x2,y2,col_w,false);}
module hole(x,y,d=leg_d){translate([x,y,-0.01])cylinder(h=board_t+0.02,d=d,$fn=20);}
// C3 SuperMini footprint: a recessed POCKET the module body drops into (so it
// sits low, ~flush with the board top) + 16 through-holes (2 rows x 8) for the
// header pins through the pocket floor + a USB-C notch cut through the top edge
// so the connector overhangs. Subtracted from the board below.
module c3_footprint(){
    // header pin through-holes (pins poke through the pocket floor)
    for(i=[0:c3_pins-1]){ hole(LX,c3_pady(i),c3_pin_d); hole(RX,c3_pady(i),c3_pin_d); }
    // recessed seating pocket (depth c3_seat from the top face)
    translate([c3x-c3_wid/2-c3_clear, c3y-c3_len/2-c3_clear, board_t-c3_seat])
        cube([c3_wid+2*c3_clear, c3_len+2*c3_clear, c3_seat+0.1]);
    // USB-C cutout: slot through the TOP board edge into the pocket front
    translate([c3x-usb_w/2, -1, -0.01])
        cube([usb_w, (c3y-c3_len/2)+1+1.0, board_t+0.02]);
}
// engraved label on the BACK (bottom) face, x-mirrored so it reads from below
module blabel(x,y,s,sz=1.4){
    translate([x,y,-0.01]) mirror([1,0,0])
        linear_extrude(0.4) text(s,size=sz,halign="center",valign="center",font="Liberation Mono");
}
// bottom stand-off foot (lifts the grooved back off the surface)
module foot(x,y){ translate([x,y,-foot_h]) cylinder(h=foot_h+0.01, r=foot_r, $fn=24); }

difference(){
    cube([board_w,board_h,board_t]);

    // switch legs (15 switches, skip (3,3)=LED)
    for(r=[0:3],c=[0:3]) if(!(r==3&&c==3))
        for(sx=[-legdx,legdx],sy=[-legdy,legdy]) hole(cx(c)+sx,cy(r)+sy);

    // ----- C3 SuperMini footprint (full 16-pin header + outline) -----
    c3_footprint();

    // ROWS: 2-layer fan into the C3 right pads, right of the module.
    //   TOP bus over the legs -> tap (via) -> BOTTOM vertical up to the pad row
    //   -> via -> TOP horizontal into the pad. Verticals (bottom) and
    //   horizontals (top) are on different faces, so the fan never crosses.
    //   The C3 right-header hole at (RX,py) IS the pad (no blind recess).
    for(r=[0:3]){
        y=cy(r)-legdy; cmax=(r==3)?2:3; lane=76+2*r; py=pady(r);  // lanes right of pocket wall
        rowg(cx(0)-legdx,y,lane,y);   // TOP bus over top legs, out to the tap
        hole(lane,y);                  // via TOP -> BOTTOM
        colg(lane,y,lane,py);          // BOTTOM vertical up to the pad row
        hole(lane,py);                 // via BOTTOM -> TOP
        rowg(lane,py,RX,py);           // TOP horizontal into the right header hole
    }

    // COLS (bottom): bus under bottom legs -> straight up to the C3 left pad.
    //   The C3 left-header hole at (LX,py) IS the pad.
    for(c=[0:3]){
        x=cx(c); rmax=(c==3)?2:3; py=pady(c);
        colg(x,cy(rmax)+legdy,x,cy(0)+legdy); // column bus
        colg(x,cy(0)+legdy,x,py);             // up toward the bay
        colg(x,py,LX,py);                     // into the C3 left header hole
    }

    // LED (WS2812) pads at cell (3,3) — DIN/+5V/GND, through-holes (fan next pass)
    hole(cx(3)-2.5,cy(3),pad_d); hole(cx(3),cy(3),pad_d); hole(cx(3)+2.5,cy(3),pad_d);

    // ===== BACK-FACE pin labels (engraved, mirrored) =====
    // C3 SuperMini: GPIO per routed pad. Left edge = columns, right edge = rows.
    COLG=["G5","G6","G7","G10"];   // COL0..3
    ROWG=["G0","G1","G3","G4"];    // ROW0..3
    for(i=[0:3]) blabel(LX-3.6, pady(i), COLG[i]);
    for(i=[0:3]) blabel(RX+3.6, pady(i), ROWG[i]);
    // switches: R by the top (row) legs, C by the bottom (col) legs
    for(r=[0:3],c=[0:3]) if(!(r==3&&c==3)){
        blabel(cx(c)-legdx-2, cy(r)-legdy, "R");
        blabel(cx(c)-legdx-2, cy(r)+legdy, "C");
    }
    // LED pins
    blabel(cx(3)-2.5, cy(3)-3, "DIN");
    blabel(cx(3),     cy(3)-3, "5V");
    blabel(cx(3)+2.5, cy(3)-3, "GND");
}

// ===== bottom feet: raise the wire-grooved back off the surface =====
// placed in groove-free zones (corners + long-edge mids, clear of lanes/pocket)
for(p=[[4,5],[80,5],[4,53],[80,53],[4,101],[80,101]]) foot(p[0],p[1]);

// silk function labels (top)
LBL=[["Breast","Bottle","Solid","Sleep"],["PumpL","PumpR","Bath","Meds"],
     ["Pee","Poop","Both","Change"],["Tummy","Weight","Note","LED"]];
color("gray") for(r=[0:3],c=[0:3])
    translate([cx(c)-4,cy(r)-7.6,board_t]) linear_extrude(0.3)
        text(LBL[r][c],size=2,font="Liberation Mono");
// C3 silk
color("gray") translate([c3x-3,c3y-1,board_t]) linear_extrude(0.3)
    text("C3",size=2.4,halign="center",font="Liberation Mono");
