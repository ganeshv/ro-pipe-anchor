/* ========================================================
   RO Pipe Counter Conduit with Collet Grip  —  v2
   
   Two-part fitting to route a 6.5mm blue RO exhaust pipe
   through a kitchen counter and hold it securely.
   
   Part 1 — Counter conduit:
     Shaft sits in 15mm counter hole, flange lip on surface,
     threaded post above with internal compression taper.
   
   Part 2 — Collet cap:
     Screws onto post. Collet fingers hang from a solid top
     plate down into the tapered bore. Tightening drives
     fingers deeper into the taper, compressing onto pipe.
   
   Assembly:
     1. Thread blue pipe through Part 2 from the top
     2. Drop Part 1 shaft into counter hole (flange sits flush)
     3. Push blue pipe down through Part 1 until tip reaches
        PVC drain (~11mm below counter bottom)
     4. Screw Part 2 onto Part 1 — collet grips the pipe
   
   Printing (PLA):
     - Part 1: upright, flange at top. No supports needed.
     - Part 2: flip so flat cap top is on bed, fingers up.
     - 0.2mm layers, 3+ perimeters, 30%+ infill
     - Thread tolerance tunable via thread_tol
   ======================================================== */

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

// ===================== PARAMETERS =====================

// Blue RO exhaust pipe
pipe_od         = 6.5;      // measured outer diameter

// Counter
counter_thick   = 57;       // counter thickness

// Shaft (sits inside counter hole)
shaft_od        = 14;       // fits in 15mm hole
shaft_bore      = 8;        // blue pipe passes through easily

// Shaft collet (lower portion of shaft has fingers)
shaft_collet_frac = 0.6;    // fraction of shaft that's fingered (0.6 = 60%)
shaft_collet_n   = 6;       // number of fingers
shaft_slit_w     = 1.2;     // slit width
shaft_lead_in    = 4;       // tapered lead-in at bottom tip (mm)
shaft_lead_od    = 12.5;    // OD at very bottom of lead-in (narrows to enter)

// Flange / lip (rests on counter surface)
flange_od       = 26;       // wider than 15mm hole
flange_h        = 3;

// Thread (joins the two parts)
thread_d        = 20;       // nominal diameter
thread_pitch    = 2.5;      // coarse for PLA reliability
thread_tol      = 0.4;      // increase if thread too tight

// Threaded post (rises above flange)
post_h          = 18;

// Compression taper inside the post
taper_top_id    = 15;       // wide mouth at top of post
taper_bot_id    = 10;       // narrow at bottom — squeezes fingers
taper_h         = 14;       // most of the post depth is taper

// Collet fingers (part of cap, compress around pipe)
collet_n        = 6;        // number of fingers
collet_slit_w   = 1.2;      // slit width between fingers
collet_len      = 20;       // finger length (hangs into post)
collet_od       = 13.5;     // finger ring OD — must enter taper_top_id
collet_tip_od   = 11.5;     // finger tip OD — slightly > taper_bot_id for grip
collet_id       = pipe_od + 0.8;  // relaxed bore — pipe slides through

// Cap body
cap_od          = 26;
cap_wall        = 3;        // wall thickness of threaded ring
cap_thread_len  = 14;       // threaded engagement length
cap_top_h       = 4;        // solid top plate thickness
pipe_exit_d     = shaft_bore; // hole in cap top for pipe

// Cosmetic
$fn             = 72;

// ===================== RENDER MODE =====================
// "part1"     — counter conduit only
// "part2"     — cap only (print orientation)
// "part3"     — collet only (print orientation)
// "all"       — both parts side by side for printing
// "assembled" — cross-section showing how they mate

render_mode = "all";


// ===================== PART 1: COUNTER CONDUIT =====================

module part1_conduit() {
    shaft_collet_len = counter_thick * shaft_collet_frac;
    shaft_solid_len  = counter_thick - shaft_collet_len;

    difference() {
        union() {
            // Upper solid shaft section (connects to flange)
            up(shaft_collet_len)
                cyl(d=shaft_od, h=shaft_solid_len, anchor=BOTTOM);

            // Flange — sits on counter surface
            up(counter_thick)
                cyl(d=flange_od, h=flange_h, anchor=BOTTOM,
                    rounding2=0.8);

            // Threaded post above flange
            up(counter_thick + flange_h)
                threaded_rod(
                    d      = thread_d,
                    l      = post_h,
                    pitch  = thread_pitch,
                    anchor = BOTTOM
                );
        }

        // Bore through solid shaft + flange
        down(1)
            cyl(d=shaft_bore, h=counter_thick + flange_h + 2,
                anchor=BOTTOM);

        // Tapered bore inside the post (compression cone)
        up(counter_thick + flange_h + (post_h - taper_h))
            cyl(d1=taper_bot_id, d2=taper_top_id, h=taper_h,
                anchor=BOTTOM);

        // Straight bore below the taper
        up(counter_thick + flange_h - 1)
            cyl(d=taper_bot_id, h=post_h - taper_h + 2,
                anchor=BOTTOM);
    }

    // Shaft collet fingers — added outside difference() so
    // nothing cuts into them
    shaft_collet_fingers(shaft_collet_len);
}

module shaft_collet_fingers(collet_len) {
    difference() {
        union() {
            // Main finger cylinder at shaft OD
            up(shaft_lead_in)
                cyl(d=shaft_od, h=collet_len - shaft_lead_in,
                    anchor=BOTTOM);

            // Tapered lead-in at bottom
            cyl(d1=shaft_lead_od, d2=shaft_od,
                h=shaft_lead_in, anchor=BOTTOM,
                chamfer1=0.5);
        }

        // Bore for blue pipe
        down(1)
            cyl(d=shaft_bore, h=collet_len + 2, anchor=BOTTOM);

        // Slits to create fingers
        for (i = [0 : shaft_collet_n - 1]) {
            rot(i * 360 / shaft_collet_n)
                translate([0, -shaft_slit_w / 2, -1])
                    cube([shaft_od / 2 + 1, shaft_slit_w,
                          collet_len - 2]);  // stop 3mm from top (solid ring)
        }
    }
}


// ===================== PART 2: COLLET CAP =====================

module part2_cap() {
    $slop = thread_tol;

    cap_total_h = cap_top_h + cap_thread_len;

    // Cap body with female thread
    difference() {
        union() {
            // Solid outer cylinder for threaded section
            cyl(d=cap_od, h=cap_thread_len, anchor=BOTTOM,
                chamfer1=0.5);

            // Solid top plate
            up(cap_thread_len)
                cyl(d=cap_od, h=cap_top_h, anchor=BOTTOM,
                    rounding2=1);
        }

        // Cut female thread into the outer cylinder
        down(0.5)
            threaded_rod(
                d        = thread_d,
                l        = cap_thread_len + 1,
                pitch    = thread_pitch,
                internal = true,
                anchor   = BOTTOM
            );

        // Pipe hole through top plate
        up(cap_thread_len - 1)
            cyl(d=pipe_exit_d, h=cap_top_h + 2, anchor=BOTTOM);
    }

    /*
     * better make the collet a separate part instead of joined to the cap

    // Collet fingers — added AFTER difference so the thread
    // cut doesn't destroy them
    collet_start_z = cap_thread_len;
    up(collet_start_z - collet_len)
        collet_fingers();
    */
}


module collet_fingers() {
    difference() {
        // Tapered cylinder — wider at top (attachment), narrower at tips
        cyl(d1=collet_tip_od, d2=collet_od,
            h=collet_len, anchor=BOTTOM,
            chamfer1=0.5);

        // Bore for pipe
        down(1)
            cyl(d=collet_id, h=collet_len + 2, anchor=BOTTOM);

        // Slits creating individual fingers
        for (i = [0 : collet_n - 1]) {
            rot(i * 360 / collet_n)
                translate([0, -collet_slit_w / 2, -1])
                    cube([collet_od, collet_slit_w,
                          collet_len - 3]);  // slits stop 2mm from top (keeps ring)
        }
    }
}


// ===================== LAYOUT / RENDER =====================

if (render_mode == "part1") {
    part1_conduit();

} else if (render_mode == "part2") {
    // Print orientation: cap top face on bed, fingers up
    cap_total = cap_top_h + cap_thread_len;
    up(cap_total) xrot(180)
        part2_cap();

} else if (render_mode == "part3") {
    up(collet_len) xrot(180)
        collet_fingers();

} else if (render_mode == "all") {
    // Side by side for print plate
    part1_conduit();

    cap_total = cap_top_h + cap_thread_len;
    right(flange_od / 2 + cap_od / 2 + 12)
        up(cap_total) xrot(180)
            part2_cap();

    left(flange_od / 2 + 12)
        up(collet_len) xrot(180)
            collet_fingers();

} else if (render_mode == "assembled") {
    // Cross-section: cap screwed partway onto post
    post_base = counter_thick + flange_h;
    // Cap sits with its thread engaged on the post
    cap_total = cap_top_h + cap_thread_len;
    cap_z = post_base + post_h - cap_total + 2; // 2mm engagement gap

    difference() {
        union() {
            color("SteelBlue", 0.8)
                part1_conduit();

            color("Orange", 0.8)
                up(cap_z)
                    part2_cap();

            // Ghost blue pipe
            color("DodgerBlue", 0.3)
                translate([0, 0, -15])
                    cyl(d=pipe_od, h=counter_thick + 55,
                        anchor=BOTTOM);
        }
        // Cut front half for cross-section
        fwd(50) cube(100, center=true);
    }
}
