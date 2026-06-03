// Baby Remote — BACK COVER (closes the exposed wire side of the board)
// Third part of the enclosure (board + cap + this cover). It snaps to the cap:
//   - FILAMENT-PIN HINGE on the LEFT long edge (x=0): interleaved knuckles on
//     cap + cover, joined by a snipped length of 1.75 mm filament as the pin.
//   - CANTILEVER SNAPS on the RIGHT long edge (x=case_w): the cap's clamps hang
//     down into windows in this cover's right wall and click home.
//   - The cover floor sits 3 mm below the board back (wire_clear); STANDOFF POSTS
//     rise to the board bottom and push it up against the cap's internal ledge.
//   - USB-C stays on the TOP short edge (handled by the cap); a shallow relief in
//     the cover's top wall keeps the connector clear.
// All shared geometry comes from dims.scad (single source of truth for cap+cover).
// Print FLOOR-DOWN (knuckles/clamps-window up). z = 0 at the BOARD TOP face, so
// the whole cover lives at NEGATIVE z (board_bot down to cover_bot_z).

include <dims.scad>

// ─── helpers ──────────────────────────────────────────────
module rbox(w,l,h,r){ hull() for(x=[r,w-r],y=[r,l-r]) translate([x,y,0]) cylinder(h=h,r=r,$fn=32); }
// hinge_knuckle(i) is shared from dims.scad; cover renders the ODD indices.

// ─── back cover body ──────────────────────────────────────
module back_cover(){
    union(){
        difference(){
            // outer block: floor + perimeter walls (cover_bot_z up to board_bot)
            translate([0,0,cover_bot_z]) rbox(case_w, case_l, board_bot-cover_bot_z, corner_r);
            // hollow out the inside above the floor (leaves floor + walls)
            translate([wall, wall, cover_in_z])
                rbox(inner_w, inner_l, (board_bot-cover_in_z)+0.1, max(0.5,corner_r-wall));
            // RIGHT-wall NOTCH POCKETS (the cap skirt barbs click into these)
            for(yy=clamp_ys)
                translate([case_w-notch_d, yy-(clamp_w+0.8)/2, barb_z-notch_h/2])
                    cube([notch_d+0.1, clamp_w+0.8, notch_h]);
            // USB-C relief in the TOP wall (belt-and-braces; connector clears anyway)
            translate([usb_cx-usbc_w/2, -0.1, board_bot-1.0])
                cube([usbc_w, wall+0.2, 1.2]);
        }

        // standoff posts: push the board up to the cap ledge when closed
        for(p=post_xy)
            translate([px(p[0]), py(p[1]), cover_in_z])
                cylinder(h=cover_wall_h, r=post_r, $fn=24);

        // hinge knuckles — COVER half = ODD indices (cap takes the even ones)
        for(i=[0:hinge_n-1]) if(i%2==1) hinge_knuckle(i);
    }
}

// ─── render (this file = the back cover by itself, ready to export) ──
back_cover();
