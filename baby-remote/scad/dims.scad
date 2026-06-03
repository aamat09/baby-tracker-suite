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
