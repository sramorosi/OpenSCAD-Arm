// Input Arm Assembly
//  Design for Human Input Arm that drives Robot Arm
//  last modified January 2022 by SrAmo
include <InputArm-Configuration.scad>
use <force_lib.scad>
use <Robot_Arm_Parts_lib.scad>
//use <Pulley-GT2_2.scad>

// Draw the Input Arm Assembly
display_assy = false;
// Section cut Assy at X = 0?
clip_yz = false;
// Section cut Assy at Z = 0?
clip_xy = false;

// number of fragments for display, ==> DISPLAY PERFORMANCE
donut_fragments = 16; // recommend 16 for Preview,  48 for Render

if (display_assy) {
    difference () {
        draw_assy(120,60,0,full=true);
        if (clip_yz) // x = xcp cut 
            translate ([-200,-100,-100]) cube (200,center=false);
        if (clip_xy) // z = 0 cut 
            translate ([-100,-100,-200]) cube (200,center=false);
        }
    }
    
module end_effector_assy() {
    translate([0,0,armt/2]) rotate([-90,0,90]) final_hand();
    translate([39,-4,10]) 
        rotate([90,90,180]) final_finger();
    }
module wire_path(length=30){
    cylinder(h=length*2,d=wire_hole_dia,center=true);
    translate([0,wire_hole_dia/1.9,0])
        cube([wire_dia,wire_hole_dia,length*2.2],center=true);
}
module single_offset_link (length=50,w=15,offset=7,d_pin=5,pot_short=false) {
    // Create a Link on xy plane along the X axis 
    // First joint is at [0,-offset], Second joint is at [length,0]
    // link width is w (y dimension), constant along length of part
    // offset is the distance down from the x axis
    bend_ang = 45; // the angle of the bend
    long_leg = length-offset;
    short_leg = sqrt(2*offset*offset);
    echo(long_leg=long_leg,short_leg=short_leg);
    wire_hole_offset = offset+wire_hole_dia; // wire  hole offset
    difference () {
        union () {
            // Draw the main link
            dog_leg2 (d1=long_leg,ang=bend_ang,d2=short_leg,w=w,t=w);
            // pot bracket
            if(pot_short) { // short = AB arm
                translate([0,-offset,0]) 
                    rotate([0,0,bend_ang]) 
                        translate([w/3,0,w/1.2]) 
                            cube([w,w,w/1.2],center=true);
                } else { // BC arm
                    translate([length-w/3,0,w/1.2]) cube([w,w,w/1.2],center=true);
                }
            };
            // remove wire holes (same for both)
            //   diagonal hole 1
            translate([length/4,widthAB-wire_hole_offset,1]) 
                rotate ([0,30,0]) 
                    translate([0,0,length/4]) 
                        wire_path(length/4.2);
            //   diagonal hole 1
            translate([length/1.3,widthAB-wire_hole_offset,1]) 
                rotate ([0,-60,0]) 
                    translate([0,0,length/3.5]) 
                        wire_path(length/4.5);
            if(pot_short) {  // potentiometer on short end, AB arm
                // remove long wire hole
                translate([length/3.3,widthAB-wire_hole_offset,1.5]) 
                    rotate ([0,87,0]) 
                        wire_path(length/2);
                // remove either side of lug on long end
                translate([length-w*0.7,-w/1.1,pot_lug_t/2])
                    cube([1.4*w,2.2*w,w],center=false); 
                translate([length-w*0.7,-w/1.1,-w-pot_lug_t/2])
                    cube([1.4*w,2.2*w,w],center=false); 
                // remove clevis on short end
                translate([0,-offset,0]) {
                    rotate([0,0,bend_ang]) 
                        cube([1.4*w,2.2*w,pot_lug_t+clevis_gap],center=true);
                   cylinder(h=2*w,d=d_pin,center=true);
                }
                // remove the potentiometer interfaces
                translate([0,-offset,widthAB/2+1]) 
                    rotate([180,0,180-45]) 
                           P090S_pot(negative=true);
                translate([length,0,widthAB/2]) 
                    rotate([180,0,90]) 
                        P090S_pot(negative=true);
                // donut holes on long end for wires
                translate([length,0,pot_lug_t/2.5]) 
                    rotate_extrude(convexity = 10, $fn = donut_fragments) {
                        translate([widthAB/1.3, 0, 0]) 
                            circle(d=wire_hole_dia*1.3, $fn = donut_fragments);
                        translate([widthAB/1.8, 0, 0]) 
                            circle(d=wire_hole_dia*1.3, $fn = donut_fragments);
                    }
            } else { // potentiometer on long end, BC arm
                // remove long wire hole
                translate([length/3.3,widthAB-wire_hole_offset,1.5]) 
                    rotate ([0,90,0]) 
                        wire_path(length/2);
                // remove either side of lug on short end
                translate([0,-offset,0]) rotate([0,0,bend_ang]) {
                translate([-w*0.7,-w/1.1,pot_lug_t/2])
                    cube([1.4*w,2.2*w,w],center=false); 
                translate([-w*0.7,-w/1.1,-w-pot_lug_t/2])
                    cube([1.4*w,2.2*w,w],center=false); 
                }
                // remove clevis on short end
                translate([length,0,0]) {
                        cube([1.4*w,2.2*w,pot_lug_t+clevis_gap],center=true);
                   cylinder(h=2*w,d=d_pin,center=true);
                }
                // remove the potentiometer interfaces
                translate([0,-offset,-widthAB/2]) 
                    rotate([0,0,135]) 
                           P090S_pot(negative=true);
                translate([length,0,widthAB/2+1]) 
                    rotate([180,0,-90]) 
                        P090S_pot(negative=true);
                // donut holes on short end for wires
                translate([0,-offset,pot_lug_t/2.5]) 
                    rotate_extrude(convexity = 10, $fn = donut_fragments) {
                        translate([widthAB/1.3, 0, 0]) 
                            circle(d=wire_hole_dia*1.3, $fn = donut_fragments);
                        translate([widthAB/1.8, 0, 0]) 
                            circle(d=wire_hole_dia*1.3, $fn = donut_fragments);
                    }
            }
    }
}
module final_AB_arm(length=10,offset=2){
    // Create a Link on xy plane along the X axis 
    // First joint is at [0,-offset], Second joint is at [length,0]
//    $fa=$preview ? 6 : 1; // minimum angle fragment
//    $fs=0.01; // minimum size of fragment (default is 2)
    hook_ang=atan2(offset,length); // hook angle
    echo("AB",length=length,hook_ang=hook_ang,offset=offset);
    rotate([0,180,hook_ang]) 
        translate([0,offset,0])  
            //single_offset_link
            single_offset_link(length=length,w=widthAB,offset=offset,d_pin=pot_shaft_dia,pot_short=true,$fn=donut_fragments); 
}
module final_BC_arm(length=10,offset=2){
    // Create a Link on xy plane along the X axis 
    // First joint is at [0,-offset], Second joint is at [length,0]
//    $fa=$preview ? 6 : 1; // minimum angle fragment
//    $fs=0.01; // minimum size of fragment (default is 2)
    hook_ang=atan2(offset,length); // hook angle
    echo("BC",length=length,hook_ang=hook_ang,offset=offset);
    rotate([0,0,-hook_ang]) 
        translate([0,offset,0])  
            //single_offset_link 
            single_offset_link(length=length,w=widthAB,offset=offset,d_pin=pot_shaft_dia,pot_short=false,$fn=donut_fragments); 
}
module finger_ring(length=20,height=10,inside_dia=16) {
   // Finger Ring
   finger_width =6;
   lug (r=(inside_dia+4)/2,w=height,h=length,t=finger_width,d=inside_dia);
}
module final_hand(length=14){
    // Claw that attaches to End Effector
//    $fa=$preview ? 6 : 1; // minimum angle fragment
//    $fs=0.05; // minimum size of fragment (default is 2)
    difference () {
        union () {  
            // LUG
            translate ([0,pot_lug_t/2,-length]) rotate([90,0,0]) 
                lug (r=widthAB/2,w=armt,h=length,t=pot_lug_t,d=.1);
            
            // CLEVIS
             translate ([armt/2,0,-length+1]) rotate([-90,0,90]) 
                lug (r=widthAB/2,w=widthAB,h=length,t=armt,d=.1);
            // pot bracket
            translate([length,0,-length*1.6]) cube([10,widthAB,widthAB],center=true); 
            // ADD the finger loop
            translate([-armt/2,5,-length]) 
                rotate([-55,0,0])
                rotate([0,90,0]) finger_ring(30,height=10,inside_dia=20);
            };
        // clevis remove slot
        translate([0,0,-length*2]) 
           cube([pot_lug_t+clevis_gap,length*2,length+4],center=true); 
        // remove lug end Potentiometer
        translate([0,-pot_lug_t,0]) 
               rotate([90,0,180]) P090S_pot(negative=true);
        // remove clevis end Potentiometer
        translate([armt/2,0,-length*2+1]) 
            rotate([90,0,-90]) P090S_pot(negative=true);
        // pin remove 
        translate([0,0,-2*length+1])
           rotate([0,-90,0]) cylinder(h=armt,d=pot_shaft_dia,center=false); 
        // remove donut hole for wire
        rotate([90,0,0]) rotate_extrude(convexity = 10, $fn = donut_fragments) 
            translate([widthAB/1.8, pot_lug_t/2, 0]) circle(d=wire_hole_dia*1.8, $fn = donut_fragments);
        } 
}
module final_finger() {
    y_offset = 10;
    union() {
        difference() {
            lug (r=widthAB/2,w=10,h=y_offset,t=pot_lug_t,d=.1);
            // remove lug end Potentiometer
            translate([0,y_offset,pot_lug_t*1.5]) 
                rotate([0,180,0]) 
                    P090S_pot(negative=true);
        }
        translate([0,0,0])rotate([0,0,180]) 
            finger_ring(length=2*y_offset,height=10,inside_dia=20);
    }
}
module pot_joint(pot=true) {
    // If pot = true then model the side that holds the pot
    dbody = 26;
    zbody = 13;
    dlug = 18;
    difference () {
       // lug
        union() {
            if (pot) {
                translate([0,0,-zbody/2+1]) washer(d=dbody,t=zbody+2,d_pin=2,$fn=fascets);
                translate([0,0,2.4]) washer(d=dbody-10,t=5,d_pin=1,$fn=fascets);
                translate([0,0,5+4+8]) washer(d=dbody,t=8,d_pin=1,$fn=fascets);
            } else {
                translate([0,0,5+4]) washer(d=dlug,t=8,d_pin=1,$fn=fascets);
            }
        }
        // remove potentiometer interfaces
        P090S_pot(negative=true);
    }
}
*pot_joint();
*translate([30,0,0]) {
    pot_joint(pot=false);
    color("red",1) P090S_pot(negative=false);
}
fascets = 140;
base_t = 6;
A_joint_z_shift = 11;

module input_arm_base () {
    // Base of the input arm
//    $fa=$preview ? 6 : 1; // minimum angle fragment
//    $fs=$preview ? 0.05 : 0.03; // minimum size of fragment (default is 2)

    base_w = 60;
    base_l = 30;
    base_z_top = 10;
    base_x_shift = 14; // was 14
    base_lug_y_shift = 4;
    
    // parameters for the 4 attach bolts
    x_b = base_w/2-5;
    y_b = base_l/2-5;
    translate([-5,0,A_joint_z_shift+base_t/2]) rotate([0,90,0]) pot_joint();

    //translate([base_x_shift,0,-base_z_top- base_t/2])
    //    rounded_cube(size=[base_w,base_l,base_t],r=2,center=true);
    difference() {
        cylinder(h=base_t,d=base_w,center=true,$fn=fascets);
        // remove potentiometer interfaces
        translate([0,0,-7]) P090S_pot(negative=true);
        
        rotate([0,0,90]) Rotation_Pattern(number=2,radius=base_w/4,total_angle=360)
                cylinder(h=base_t*3,d=12,center=true,$fn=fascets);
    }
}
ss = 0.98;
*input_arm_base ();
*pot_joint(pot=false);

difference () {
    union() {
        input_arm_base ();
        translate([-4.8,0,A_joint_z_shift+base_t/2]) rotate([0,90,0]) scale([ss,ss,ss]) color("blue") pot_joint(pot=false);
        translate([-5,0,A_joint_z_shift+base_t/2]) rotate([0,90,0]) scale([ss,ss,ss]) color("red",1) P090S_pot(negative=false);
        translate([0,0,-9]) rotate([0,0,0]) scale([ss,ss,ss]) color("yellow",1) P090S_pot(negative=false);
    }
    translate([-50,0,-50]) cube([100,100,100],center=false);
}
*translate([0,1,40]) rotate([0,90,90]) ruler(100);

module knob () {
    $fn=$preview ? 16 : fascets; // minimum angle fragment
    difference () {
        translate([0,0,12]) cylinder(h=6,d=20);
        translate([0,0,3]) P090S_pot(negative=true);
    }
}

module turntable_base () {
    // Base of the input arm
    $fn=$preview ? 16 : fascets; // minimum angle fragment

    base_w = 40;
    base_l = 30;
    base_t = 3;
    base_z_top = 15;
    base_x_shift = 0;
    base_lug_y_shift = 4;
    
    blob_h = 18;
    
    // parameters for the 4 attach bolts
    x_b = base_w/2-5;
    y_b = base_l/2-5;

    difference () {
        union () {
            rotate([90,0,0]) translate([base_x_shift,0,-base_z_top- base_t/2])
                rounded_cube(size=[base_w,base_l,base_t],r=2,center=true);
            cylinder(h=blob_h,d=widthAB,center=true);
            translate([0,widthAB/2,0]) // lug support
                cube([widthAB,widthAB,blob_h],center=true);
        }
        // clevis remove
        *translate([0,0,-5])
            cube([1.4*widthAB,1.3*widthAB,pot_lug_t+clevis_gap],center=true); 
        // remove the potentiometer interfaces
        //cylinder(h=widthAB*3,d=pot_shaft_dia,center=true); 
        translate([0,0,3]) P090S_pot(negative=true);
        
        // subtract the 4 base mounting bolt holes
        rotate([90,0,0]) {
        translate([x_b+base_x_shift,y_b,-base_z_top])
                cylinder(h=base_t*3,d=4,center=true);
        translate([x_b+base_x_shift,-y_b,-base_z_top])
                cylinder(h=base_t*3,d=4,center=true);
        translate([-x_b+base_x_shift,-y_b,-base_z_top])
                cylinder(h=base_t*3,d=4,center=true);
        translate([-x_b+base_x_shift,y_b,-base_z_top])
                cylinder(h=base_t*3,d=4,center=true);
        }
    }
}
*turntable_base();
*color("red",1) translate([0,0,3]) P090S_pot(negative=false);
*color("blue") knob();

module draw_assy (A_angle=0,B_angle=0,C_angle=0,full=true) {
    // calculate b and c positions from angles
    b=[lenAB*cos(A_angle),lenAB*sin(A_angle),0];  // B location
    c = [(cos(A_angle)*lenAB+cos(B_angle)*lenBC),(sin(A_angle)*lenAB+sin(B_angle)*lenBC),-pot_lug_t-2];
    // lower arm vector
    vecAB=[b[0]/lenAB,b[1]/lenAB,b[2]/lenAB];
    
    link_offset=widthAB/2.1;
    // draw the upper and lower arms
    rotate([0,0,A_angle]) {
        // Draw the AB link
        color("plum",1) 
            translate ([lenAB,0,0])
                final_AB_arm(length=lenAB,offset=widthAB/2.1);
        // Draw the BC link
        
            translate([lenAB,0,0]) 
                rotate([0,0,B_angle-A_angle]) {
                    color("lightblue",1) final_BC_arm(length=lenBC,offset=widthAB/2.1);
                    translate([0,0,-widthAB/2-1])
                        rotate([0,0,52])
                            color("red",1) P090S_pot(negative=false);

                }
    }
    // Draw the end effector
    translate([c[0],c[1],c[2]]) 
        rotate ([0,0,C_angle]) end_effector_assy();

    // BASE    
    color("green") translate([0,0,-pot_lug_t/2]) 
        rotate([-90,180,0]) input_arm_base();
    color("blue") translate([0,0,16]) 
        rotate([-90,180,0]) turntable_base();
    translate([0,0,-widthAB/2-1])
        rotate([0,0,180])
            color("red",1) P090S_pot(negative=false);
} 
