// Baby Remote — 3D-printed PCB substrate (copper-tape / tinned-wire grooves)
// Technique from cpapdash-push-c3/kicad/v1/3d-pcb, but TWO faces:
//   ROWS = grooves on TOP face, COLS = grooves on BOTTOM face. Tactile switches
//   are through-hole, so their legs bridge faces -> the 4x4 matrix is
//   CROSSING-FREE. Row escapes run in the RIGHT MARGIN and hop to the bottom
//   (via through-holes) to dodge other rows. Cols run UP the bottom face.
// Frame matches remote_case.scad: cell centre = (16.5+17c, 38.5+17r).
// TOP = USB/C3 edge (low Y).  Rows GPIO0/1/3/4 · Cols GPIO5/6/7/10 · LED GPIO8.

board_w=84; board_h=106; board_t=2.0;
groove_d=0.8; row_w=1.5; col_w=1.5; leg_d=1.1; pad_d=1.6; pad_depth=1.0;

function cx(c)=16.5+17*c;
function cy(r)=38.5+17*r;
legdx=3.25; legdy=2.25;

// LiPo keep-out (top-left of the bay) — ~48x30 cell sits here, no grooves/pads.
lipo_x0=3; lipo_y0=4; lipo_w=48; lipo_h=30;
function lipo_clear() = true;

// C3 SuperMini — top-RIGHT of the bay, beside the LiPo. Long axis vertical so
// the USB-C short end sits flush at the TOP board edge (y=0) for the enclosure
// cutout. Right-edge pads catch row escapes (short); left-edge pads catch cols.
c3_len=22.5; c3_wid=18;
c3x=66; c3y=2+c3_len/2; pitch=2.54;   // USB end ~y=2 (top edge)
usb_w=9; usb_h=3.4;                    // USB-C cutout at the top edge
RX=c3x+7.62;   // right edge pads (rows)
LX=c3x-7.62;   // left edge pads (cols)
function pady(i)=c3y-1.5*pitch+i*pitch;   // 4 stacked pads, i=0..3

// ---- helpers ----
module gr(x1,y1,x2,y2,w,top){dx=x2-x1;dy=y2-y1;L=sqrt(dx*dx+dy*dy);a=atan2(dy,dx);
    z=top?board_t-groove_d:-0.01;
    translate([x1,y1,z])rotate([0,0,a])translate([0,-w/2,0])cube([L,w,groove_d+0.02]);}
module rowg(x1,y1,x2,y2){gr(x1,y1,x2,y2,row_w,true);}
module colg(x1,y1,x2,y2){gr(x1,y1,x2,y2,col_w,false);}
module hole(x,y,d=leg_d){translate([x,y,-0.01])cylinder(h=board_t+0.02,d=d,$fn=20);}
module padT(x,y){translate([x,y,board_t-pad_depth])cylinder(h=pad_depth+0.01,d=pad_d,$fn=20);}
module padB(x,y){translate([x,y,-0.01])cylinder(h=pad_depth+0.01,d=pad_d,$fn=20);}
// engraved label on the BACK (bottom) face, x-mirrored so it reads from below
module blabel(x,y,s,sz=1.4){
    translate([x,y,-0.01]) mirror([1,0,0])
        linear_extrude(0.4) text(s,size=sz,halign="center",valign="center",font="Liberation Mono");
}

difference(){
    cube([board_w,board_h,board_t]);

    // switch legs (15 switches, skip (3,3)=LED)
    for(r=[0:3],c=[0:3]) if(!(r==3&&c==3))
        for(sx=[-legdx,legdx],sy=[-legdy,legdy]) hole(cx(c)+sx,cy(r)+sy);

    // ROWS: 2-layer fan into the C3 right pads, right of the module.
    //   TOP bus over the legs -> tap (via) -> BOTTOM vertical up to the pad row
    //   -> via -> TOP horizontal into the pad. Verticals (bottom) and
    //   horizontals (top) are on different faces, so the fan never crosses.
    for(r=[0:3]){
        y=cy(r)-legdy; cmax=(r==3)?2:3; lane=74+2*r; py=pady(r);
        rowg(cx(0)-legdx,y,lane,y);   // TOP bus over top legs, out to the tap
        hole(lane,y);                  // via TOP -> BOTTOM
        colg(lane,y,lane,py);          // BOTTOM vertical up to the pad row
        hole(lane,py);                 // via BOTTOM -> TOP
        rowg(lane,py,RX,py);           // TOP horizontal into the right pad
        padT(RX,py);
    }

    // COLS (bottom): bus under bottom legs -> straight up to the C3 left pad.
    for(c=[0:3]){
        x=cx(c); rmax=(c==3)?2:3; py=pady(c);
        colg(x,cy(rmax)+legdy,x,cy(0)+legdy); // column bus
        colg(x,cy(0)+legdy,x,py);             // up toward the bay
        colg(x,py,LX,py);                     // into the C3 left pad row
        hole(LX,py); padT(LX,py);
    }

    // LED (WS2812) pads at cell (3,3) — DIN/+5V/GND fan next pass
    padT(cx(3)-2.5,cy(3)); padT(cx(3),cy(3)); padT(cx(3)+2.5,cy(3));

    // ===== BACK-FACE pin labels (engraved, mirrored) =====
    // C3 SuperMini: GPIO per pad. Left edge = columns, right edge = rows.
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

// silk function labels (top)
LBL=[["Breast","Bottle","Solid","Sleep"],["PumpL","PumpR","Bath","Meds"],
     ["Pee","Poop","Both","Change"],["Tummy","Weight","Note","LED"]];
color("gray") for(r=[0:3],c=[0:3])
    translate([cx(c)-4,cy(r)-7.6,board_t]) linear_extrude(0.3)
        text(LBL[r][c],size=2,font="Liberation Mono");

// ===== floorplan markers (visual only, not the board) =====
color([0.25,0.35,0.8,0.45]) translate([lipo_x0,lipo_y0,board_t])
    cube([lipo_w,lipo_h,5]);                                  // LiPo cell
color([0.95,0.95,0.95]) translate([lipo_x0,lipo_y0,board_t+5.2])
    linear_extrude(0.1) text("LiPo",size=6);
color([0.1,0.55,0.15,0.55]) translate([c3x-c3_wid/2,c3y-c3_len/2,board_t])
    cube([c3_wid,c3_len,1.6]);                                // C3 module
color([0.6,0.6,0.6]) translate([c3x-usb_w/2,-2,board_t])
    cube([usb_w,3,usb_h]);                                    // USB-C at TOP edge
