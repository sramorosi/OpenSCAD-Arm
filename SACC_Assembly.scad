// Robot Arm Assembly
//  Started on 3/24/2020 by SrAmo
//  last modified October 13 2021 by SrAmo

use <force_lib.scad>
use <Robot_Arm_Parts_lib.scad>
use <Pulley-GT2_2.scad>
use <gears_involute.scad>
include <SACC-26-Configuration.scad>

// Draw the Robot Arm Assembly
display_assy = true;
// Section cut at X = 0?
clip_yz = true;
// Section cut at Z = 0?
clip_xy = false;
// Draw Final shoulder
display_shoulder = false;
// Draw Final AB arm
display_ABarm = false;
// Draw Final BC arm
display_BCarm = false;
// Draw Final Claw 
display_claw= false;
// Draw Final Claw Attachment
display_claw_shooter= false;
// Is the shooter curved or linear?
curved_shooter=false;
// Draw Final Forks (option to claw)
display_fork= false;
// BC Arm Pulley at A
display_B_drive_pulley_at_A= false;
// BC Arm Pulley at B
display_B_drive_pulley_at_B= false;
// Draw Final End (C) Horn
display_C_horn= false;

if (display_assy) {
    difference () {
        draw_assy(A_angle=90,B_angle=-20,C_angle=-20);
        if (clip_yz) // x = xcp cut 
            translate ([0,-lenAB*2,-lenAB*2]) cube (lenAB*4,center=false);
        if (clip_xy) // z = 0 cut 
            translate ([-lenAB*2,-lenAB*2,0]) cube (lenAB*4,center=false);
        }
    }

if (display_ABarm) final_AB_arm ();
if (display_BCarm) final_BC_arm ();
if (display_shoulder)  shoulder_assy ();
if (display_B_drive_pulley_at_A) B_drive_at_A_Pulley ();
if (display_B_drive_pulley_at_B) B_Drive_at_B_Pulley ();
if (display_C_horn) final_C_horn ();
if (display_claw_shooter)  {
    color ("purple") claw_shooter(curved=curved_shooter);
}
if (display_claw)  final_claw();
if (display_fork)  final_fork();
    
module torsion_spring_spacer() {
    translate([0,0,9271K619_t/2]) 
        spacer(d=9271K619_ID*0.9,t=9271K619_t,d_pin=hole_M6*1.03);
}
*torsion_spring_spacer();

module end_effector_assy() {
    color("SpringGreen") final_C_horn (); 
    color("green") final_claw();
    //color ("purple") claw_shooter(curved=curved_shooter);
    color ("red",.5) translate([claw_servo_x,claw_height/2-svo_flange_d,0]) 
        rotate([0,90,-90]) servo_body();
}
module zip_tie_AB (x = 50,y=5) {
    // holes are parallel to the Y axis
    zip_hole_d = hole_M3;
    rotate([90,0,0]) {
        translate ([x,-y,0]) 
            cylinder(h=100,d=zip_hole_d,center=true,$fn=16);
        translate ([x,y,0]) 
            cylinder(h=100,d=zip_hole_d,center=true,$fn=16);
    }
}

module AB_offset_link (length=50,w=15,offset=7,d_pin=5,t=2) {
    // Create a Link on xy plane along the X axis 
    // First joint is at [0,0], Second joint is at [length,0]
    // link width is w (y dimension), constant along length of part
    // Method of making a dog leg link, using law of sines:
    c_ang=135;
    a_ang = law_sines_angle (C=length,a=offset,c_ang=c_ang);
    b_ang = 180 - a_ang-c_ang;
    L1 = law_sines_length (C=length,c_ang=c_ang,b_ang=b_ang);
    echo(a_ang=a_ang,b_ang=b_ang,L1=L1);
    rotate([0,0,a_ang]) {
        
        // collection of operations for the first leg
        difference () {
            union() {
                simple_link (l=L1,w=w,t=w,d=0,cored=w*.75); 
                // add the servo horn pad
                rotate([0,0,-90]) translate([0,widthAB*.25,widthAB-a_svo_boss/2])
                    rounded_cube(size=[widthAB,widthAB*1.5,a_svo_boss],r=widthAB/2,center=true);
            }
            // remove the servo horn shape
            translate([0,0,widthAB-a_svo_boss/2]) servo_horn ();
        }
        // collection of operations for the second leg
        translate([L1,0,0]) rotate([0,0,c_ang-180]) 
            simple_link (l=offset,w=w,t=w,d=0,cored=0); 
    }
}

module final_AB_arm () {
    $fa=$preview ? 6 : 1; // minimum angle fragment

    difference () {
        AB_offset_link (length=lenAB,w=widthAB,offset=widthAB/2.25,d_pin=pinSize,t=wall_t,$fn=48);
            
        // remove the A hole and donut
        cylinder(h=4*widthAB,d=M6_bearing_od,center=true);
        
        translate([0,0,widthAB/2])
            filled_donut(t=widthAB*.55,d=widthAB*1.4,r=widthAB*.2);
        translate([0,0,14]) rotate([0,0,100])
            torsion_spring (deflection_angle=9271K619_angle,OD=9271K619_OD,wire_d=9271K619_wd,leg_len=9271K619_len,coils=9271K619_coils,LH=9271K619_LH);
        
        // remove the B hole and end donut
        translate([lenAB,0,widthAB/2]) {
            cylinder(h=4*widthAB,d=pinSize,center=true);
            filled_donut(t=widthAB*.75,d=widthAB*1.5,r=widthAB*.1);
        }
   }
}
module final_BC_arm () {
    $fa=$preview ? 6 : 1; // minimum angle fragment
    
    hex_h = AB_pulley_t;  // height offset for hex

    difference () {
        union () {
            hollow_offset_link(length=lenBC,d_pin=pinSize,w=widthBC,t=widthBC,offset=widthBC/2.5,ang=45,wall=wall_t,$fn=48); 
            // union HEX for pulley
            translate ([ 0,0,-hex_h+Qtr_bearing_flange_t])
                hex (size=22.86,l=hex_h);
            
            // boss for servo
            translate([lenBC,0,-1])
                rotate([0,0,-45])
                    translate([-10,0,0])
                    rounded_cube(size=[svo_screw_l+5,svo_w+5,5],r=7,center=true);
        }
        // c-bore for bearing
        cylinder(h=3*widthBC,d=Qtr_bearing_od,center=true);
            
        // subtract A servo interface
        translate([lenBC,0,svo_flange_d-3.5])
            rotate([0,0,-45])
                servo_body (vis=false);

    }    
   translate([0,0,wall_t]) Bearing_Flanged (t=Qtr_bearing_t,flange_t=Qtr_bearing_flange_t,od=Qtr_bearing_od,id=hole_qtr_inch,flange_od=Qtr_bearing_flange_od);
   translate([0,0,-AB_pulley_t+Qtr_bearing_flange_t]) rotate([180,0,0]) Bearing_Flanged (t=Qtr_bearing_t,flange_t=Qtr_bearing_flange_t,od=Qtr_bearing_od,id=hole_qtr_inch,flange_od=Qtr_bearing_flange_od);
   translate([0,0,wBC_inside+2*wall_t]) Bearing_Flanged (t=Qtr_bearing_t,flange_t=Qtr_bearing_flange_t,od=Qtr_bearing_od,id=hole_qtr_inch,flange_od=Qtr_bearing_flange_od);
}

module B_Drive_at_B_Pulley () {
    color ("green") difference () {
       pulley_gt2_2 ( teeth = AB_pulley_teeth , pulley_t_ht = AB_pulley_t);
        // add hex bore
       hex (size=22.94,l=AB_pulley_t+.5);
    }
}
module plastic_screw() {
    translate([0,0,20/2])cylinder(h=21,d=2.8,center=true);
    translate([0,0,-1.1]) cylinder(h=2,d=7,center=true);
}

module B_drive_at_A_Pulley () {
    // This pulley is on the outside of the AB arm at A
    // PRINT THIS IN TWO PARTS
    $fn=$preview ? 64 : 128; // minimum angle fragment
    
    pulley_OD = tooth_spacing (AB_pulley_teeth,2,0.254) +2;
    
    difference () {
        union () {
            // PART A
            pulley_gt2_2(teeth=AB_pulley_teeth,pulley_t_ht=AB_pulley_t ,motor_shaft=hole_qtr_inch);
            translate([0,0,13]) 
                cylinder(h=6,d=pulley_OD,center=true); // big boss A side
            
            // PART B
            translate([0,0,-3]) 
                cylinder(h=6,d=pulley_OD,center=true); // big boss B side
            translate([0,0,-AB_boss_t/2]) 
                rotate([0,0,-10]) 
                    rotate_extrude(angle=60,convexity = 10)
                        translate([20, 0, 0]) 
                            square([15,AB_boss_t],center=true);

            }
        // remove the servo horn shape
        rotate([0,0,20]) translate([0,0,-AB_boss_t-1]) servo_horn();
        // remove the spring
        translate([0,0,-3]) rotate([0,0,-90+45]) // ADJUSTMENT ANGLE
            torsion_spring (deflection_angle=9271K619_angle,OD=9271K619_OD,wire_d=9271K619_wd*1.05,leg_len=9271K619_len,coils=9271K619_coils,LH=9271K619_LH,inverse=true);
        translate([-30,-50,10]) cube([40,40,20],center=false);
        translate([-50,-11,10]) cube([40,40,20],center=false);
        translate([0,0,11.5]) cube([21,21,3],center=true);
        // remove the A hole!
        cylinder(h=10*AB_boss_t,d=M6_bearing_od,center=true);
        // remove the screw holes that hold the two parts together
        rotate([0,0,70]) translate([16,0,-4]) plastic_screw();
        rotate([0,0,160]) translate([16,0,-4]) plastic_screw();
        rotate([0,0,250]) translate([16,0,-4]) plastic_screw();
        rotate([0,0,330]) translate([16,0,-4]) plastic_screw();

        // remove the outside bearing flange cylinder
        *translate([0,0,-AB_pulley_t])
            cylinder(h=AB_pulley_t,d=Qtr_bearing_flange_od+.5,center=false);
    }
   translate([0,0,-6]) rotate([180,0,0]) Bearing_Flanged (t=M6_bearing_t,flange_t=M6_bearing_flange_t,od=M6_bearing_od,id=hole_M6,flange_od=M6_bearing_flange_od);
   translate([0,0,AB_pulley_t+6]) Bearing_Flanged (t=M6_bearing_t,flange_t=M6_bearing_flange_t,od=M6_bearing_od,id=hole_M6,flange_od=M6_bearing_flange_od);
}

module final_C_horn(){
    // Pulley at joint C
    // This is the arm end-effector interface
    // center is 0,0,0 on xy plane, length is +x
    // The belt can be slipped over the pulley
    // The interface is a standard width
    $fa=$preview ? 3 : 1; // minimum angle fragment
    $fs=0.05; // minimum size of fragment (default is 2)

    offx = 5;
    t_at_C=wBC_inside-2*Qtr_bearing_flange_t-offx; // thickness at C
    
    difference () {
        union () { 
            translate([0,0,offx/2]) cylinder (t_at_C,d=30,center=true);
            ear();
            mirror ([0,0,1]) ear() ;// make a mirror copy
        }
        // remove bore bearing
        cylinder(2*t_at_C,d=Qtr_bearing_od,center=true);
        translate([0,0,-6]) cylinder(h=10,d=Qtr_bearing_flange_od+4,center=true);
        
        // remove the servo horn
        translate([0,0,-t_at_C/2-.01]) servo_horn();
        
        // remove End attach pin
        translate ([End_pin_x,End_pin_y,0])
            cylinder(2*t_at_C,d=hole_qtr_inch,center=true);
    }
    //translate([0,0,-t_at_C/2+10]) rotate([180,0,0]) bearing_flng_qtr ();
    //translate([0,0,t_at_C/2+offx/2]) bearing_flng_qtr ();
    module ear () {
        End_angle = atan2(End_pin_y,End_pin_x);
        translate ([End_pin_x,End_pin_y,End_w/2+End_w/4]) 
            cube([hole_qtr_inch*3,hole_qtr_inch*3,End_w/2],center=true);
        translate ([0,-hole_qtr_inch*2,End_w/2]) 
            rotate([0,0,End_angle])
            cube([End_x,hole_qtr_inch*4,End_w/2],center=false);
    }
}
module final_fork (t_forks=1.3,l_fork=2,d_fork=0.2) {
    // Fork that attaches to End Effector
    // center is 0,0,0 on xy plane, length is +x
    // t_end is the end effector inteface thickness
    $fa=$preview ? 6 : 1; // minimum angle fragment

    difference () {
        union () { 
            // interface center
            translate ([End_x-End_pin_x,-End_pin_y,-End_w/2])
                cube([End_pin_x,End_pin_y,End_w],center=false);
            right_fork();
            // make a mirror copy
            mirror ([0,0,1]) right_fork();
        }
        // remove attach pin
        translate ([End_pin_x,-End_pin_y/2,0])
            cylinder(2,d=hole_qtr_inch,center=true);
        // remove cylinder to clear pulley
        cylinder(End_w*2,d=1.1*end_pulley_d,center=true);
    }
    module right_fork() {
        // interface back
        translate ([End_x,-End_pin_y,0]) {
            cube([0.2,End_pin_y,t_forks/2],center=false);
            rotate ([-90,0,0]) 
                translate ([d_fork/2,t_forks/2,End_pin_y])
                    cylinder(2*End_pin_y,d=d_fork,center=true);
        }
        // forks 
        translate([End_x+l_fork/2,-End_pin_y+d_fork/2,t_forks/2-d_fork/2])
            rotate([0,90,-5])
                fork(l_fork,d_fork);
}
}
module final_claw(){
    // DRAW THE COMPLIANT CLAW
    servo_plate_t = 8;
    back_plate_w = claw_width - 4*claw_radius;
    $fa=$preview ? 6 : 1; // minimum angle fragment
    union () {
        difference () {
            union () { 
                // interface center
                translate ([End_pin_x,End_pin_y,0])
                    cube([hole_qtr_inch*3,hole_qtr_inch*3,End_w],center=true);
                // interface top
                translate ([End_x+claw_radius,claw_height/2-servo_plate_t,-back_plate_w/2+5]) 
                    cube([50,servo_plate_t,back_plate_w+10],center=false);
            }
            // remove attach pin
            translate ([End_pin_x,End_pin_y,0])
                cylinder(2*End_w,d=hole_qtr_inch,center=true,$fn=32);

            // remove the servo interface
            translate([claw_servo_x,claw_height/2-svo_flange_d,0]) rotate([0,90,-90]) servo_body(vis=false,$fn=32);
                        
        }
    }
    translate([End_x,-claw_height/2,0]) rotate([0,-90,-90])     
    compliant_claw2 (len=claw_length,width=claw_width,t1=1.73,t2=claw_height,r=claw_radius,pre_angle=15);
}
module claw_shooter (curved=true) {
    union () { 
        // top plate attachment
        translate ([End_x+1.8,.7,-.8]) 
            rotate([0,0,-15])
                difference () {
                    cube([.12,1,1.6],center=false);
                    translate([0,.5,.4]) 
                        rotate([0,90,0]) 
                            cylinder(h=1,d=hole_M3_inch,center=true,$fn=16);
                    translate([0,.5,1.2]) 
                        rotate([0,90,0]) 
                            cylinder(h=1,d=hole_M3_inch,center=true,$fn=16);
                }
                if (curved) {
                    translate ([3.25,-4.41,0]) rotate([0,0,55]) 
                    rotate_extrude(angle=35,$fn=156) 
                    polygon([[6,.8],[6.08,.8],[6.08,-.8],[6,-.8],[6,.8]]);
                } else {
                    translate([5.,1.6,0])
                    cube([3.5,.08,1.6],center=true);
                }
    }
}
module pair_shoulder_screw_holes(h=20) {
    $fn=32;
    translate([0,h_guss/4,0]) cylinder(h=h,d=hole_no6_screw,center=true);
    translate([0,-h_guss/4,0]) cylinder(h=h,d=hole_no6_screw,center=true);
}
//pair_shoulder_screw_holes();
module shoulder_servo_lug() {
    difference () {
        lug (r=x_guss,w=shoulder_w/1.3,h=shoulder_z_top+12,t=shoulder_svo_lug_t);    
        translate([0,shoulder_z_top,svo_flange_d])
            rotate([0,0,90])
                servo_body (vis=false);
        translate([x_guss+t_guss/2,h_guss/2,0]) pair_shoulder_screw_holes();
        translate([-(x_guss+t_guss/2),h_guss/2,0]) pair_shoulder_screw_holes();
    }
}
//shoulder_servo_lug();
module shoulder_lug() {
    $fn=64;
    difference() {
        lug (r=x_guss,w=x_guss*2,h=shoulder_z_top,t=shoulder_svo_lug_t);
        translate([0,h_guss/2,shoulder_svo_lug_t/2]) 
            rotate([0,90,0]) pair_shoulder_screw_holes(h=x_guss*3);
        translate([0,shoulder_z_top,0]) cylinder(h=shoulder_l*2,d=hole_M6,center=true);
   }
}
//shoulder_lug();

module shoulder_assy () {
    // shoulder of the arm
    // XY = HORIZON
    $fn=$preview ? 64 : 128; // minimum number of fragements

    difference () {
        union () {
            // shoulder plate
            translate([0,shoulder_l/2-shoulder_svo_lug_t,-shoulder_z_top - shoulder_t/2])
                rounded_cube(size=[shoulder_w,shoulder_l,shoulder_t],r=hole_qtr_inch,center=true);
            translate([0,shoulder_y_shift,-shoulder_z_top - shoulder_t - 5])
                cylinder(h=10,d=60,center=true);

            // A Servo support (lug)
            color("yellow") translate([0,shoulder_y_A-shoulder_svo_lug_t,-shoulder_z_top])
                rotate([90,0,180]) 
                    shoulder_servo_lug();    
            // First lug
            color("lime") translate([0,shoulder_y_1,-shoulder_z_top])
                rotate([90,0,0]) 
                    shoulder_lug();    
            // Second lug
            color("turquoise") translate([0,shoulder_y_2,-shoulder_z_top])
                rotate([90,0,0]) 
                    shoulder_lug();
            // Third lug
            *color("fuchsia") translate([0,shoulder_y_3,-shoulder_z_top])
                rotate([90,0,0]) 
                    shoulder_lug();
            // B Servo support (lug)
            color("blueviolet") translate([0,shoulder_y_B,-shoulder_z_top])
                rotate([90,0,0]) 
                    shoulder_servo_lug();    
               //*/     
            
            // shoulder gussets
            color("blue") translate([x_guss,shoulder_y_A,-shoulder_z_top])
                cube([t_guss,shoulder_y_B-shoulder_y_A-shoulder_svo_lug_t,h_guss],center=false);
            color("blue") translate([-x_guss-t_guss,shoulder_y_A,-shoulder_z_top])
                cube([t_guss,shoulder_y_B-shoulder_y_A-shoulder_svo_lug_t,h_guss],center=false);
            *color("skyblue") translate([-x_guss,y1,-shoulder_z_top])
                cube([2*x_guss,extra_lug_y-y1+shoulder_svo_lug_t,h_guss],center=false);
                
        }
        // subtract the wire hole
        translate([0,shoulder_y_shift,-shoulder_z_top])
                cylinder(h=shoulder_t*5,d=15,center=true);
        
        // subtract the 4 shoulder mounting bolt holes
        translate([x_b,y_b+shoulder_y_shift,-shoulder_z_top])
                cylinder(h=shoulder_t*3,d=hole_M5,center=true);
        translate([x_b,-y_b+shoulder_y_shift,-shoulder_z_top])
                cylinder(h=shoulder_t*3,d=hole_M5,center=true);
        translate([-x_b,-y_b+shoulder_y_shift,-shoulder_z_top])
                cylinder(h=shoulder_t*3,d=hole_M5,center=true);
        translate([-x_b,y_b+shoulder_y_shift,-shoulder_z_top])
                cylinder(h=shoulder_t*3,d=hole_M5,center=true);
        
        // subtract the 4 gear mounting screw holes
        translate([0,y_g+shoulder_y_shift,-shoulder_z_top-10])
                cylinder(h=shoulder_t*4,d=hole_no6_screw,center=true);
        translate([x_g,shoulder_y_shift,-shoulder_z_top-10])
                cylinder(h=shoulder_t*4,d=hole_no6_screw,center=true);
        translate([-x_g,shoulder_y_shift,-shoulder_z_top-10])
                cylinder(h=shoulder_t*4,d=hole_no6_screw,center=true);
        translate([0,-y_g+shoulder_y_shift,-shoulder_z_top-10])
                cylinder(h=shoulder_t*4,d=hole_no6_screw,center=true);
        
        // screw holes long ways in gussets
        translate([x_guss+t_guss/2,h_guss/2,-shoulder_z_top + h_guss/2]) 
            rotate([90,0,0]) pair_shoulder_screw_holes(h=shoulder_l*2);
        translate([-(x_guss+t_guss/2),h_guss/2,-shoulder_z_top + h_guss/2]) 
            rotate([90,0,0]) pair_shoulder_screw_holes(h=shoulder_l*2);
        // screw holes perpendicular to gussets
        translate([0,shoulder_y_1-shoulder_svo_lug_t/2,-shoulder_z_top + h_guss/2]) 
            rotate([90,0,90]) pair_shoulder_screw_holes(h=x_guss*4);
        translate([0,shoulder_y_2-shoulder_svo_lug_t/2,-shoulder_z_top + h_guss/2]) 
            rotate([90,0,90]) pair_shoulder_screw_holes(h=x_guss*4);
        *translate([0,shoulder_y_3-shoulder_svo_lug_t/2,-shoulder_z_top + h_guss/2]) 
            rotate([90,0,90]) pair_shoulder_screw_holes(h=x_guss*4);

    }
}
module base_assy() {
    // parameters for the 4 shoulder attach bolts to the bearing
    hole_space = 77;
    x_b = hole_space/2;
    y_b = hole_space/2;

    difference() {
        cylinder(h=base_t,d=130,center=true);
        //rounded_cube(size=[130,130,base_t],r=hole_qtr_inch,center=true);
        cylinder(h=shoulder_t*5,d=94,center=true);
        // subtract the 4 bearing mounting bolt holes
        translate([x_b,y_b,0])
                cylinder(h=base_t*3,d=hole_M5,center=true);
        translate([x_b,-y_b,0])
                cylinder(h=base_t*3,d=hole_M5,center=true);
        translate([-x_b,-y_b,0])
                cylinder(h=base_t*3,d=hole_M5,center=true);
        translate([-x_b,y_b,0])
                cylinder(h=base_t*3,d=hole_M5,center=true);
    }
}

module draw_assy (A_angle=0,B_angle=0,C_angle=0) {
    // XZ = HORIZON
    // calculate b and c positions from angles
    b=[lenAB*cos(A_angle),lenAB*sin(A_angle),0];  // B location
    c = [(cos(A_angle)*lenAB+cos(B_angle)*lenBC),(sin(A_angle)*lenAB+sin(B_angle)*lenBC),0];
    // lower arm vector
    vecAB=[b[0]/lenAB,b[1]/lenAB,b[2]/lenAB];
    
    translate([0,0,12]) {     // fix the UGLYNESS of where is Y center   
        // draw the upper and lower arms
        rotate([0,0,A_angle]) {
            // Draw the AB link
            color("plum",1) 
                translate ([0,0,-widthAB/2]) {
                    final_AB_arm ();
           translate([0,0,0]) rotate([180,0,0]) Bearing_Flanged (t=M6_bearing_t,flange_t=M6_bearing_flange_t,od=M6_bearing_od,id=hole_M6,flange_od=M6_bearing_flange_od);
           translate([0,0,wAB_inside]) rotate([180,0,0]) Bearing_Flanged (t=M6_bearing_t,flange_t=M6_bearing_flange_t,od=M6_bearing_od,id=hole_M6,flange_od=M6_bearing_flange_od);
                }
            
            // Draw the BC link
            translate([lenAB,0,-widthBC/2-wall_t-Qtr_bearing_flange_t]) {
                rotate([0,0,B_angle-A_angle]) final_BC_arm ();
                rotate ([180,0,0]) B_Drive_at_B_Pulley ();
            }
        }
        // Draw the end effector
        translate([c[0],c[1],c[2]-wall_t-Qtr_bearing_flange_t]) 
            rotate ([0,0,C_angle])  end_effector_assy();
        
        // Draw the B drive pulley at A
        yb=-41; //-(center_t/2+3*shoulder_svo_lug_t+AB_pulley_t*1.6);
        echo(yb=yb);
        color("navy",1)  
            rotate([0,0,(B_angle)]) 
                translate([0,0,yb+4.5]) B_drive_at_A_Pulley ();
        
        // C Servo
        color ("red",.5) 
            translate([c[0],c[1],c[2]-widthBC/2+1.5]) {
                rotate([0,0,-45]) servo_body();
                rotate([0,0,C_angle])
                    servo_horn();
            }
                
        // B drive belt (displayed with shoulder assembly)
        color("blue") 
            pt_pt_belt([0,0,-widthAB/1.3],[b[0],b[1],-widthAB/1.3],d=6,r_pulley=AB_pulley_d/2,round=false);
        // Draw springs
            
        // torsion spring at A
        translate([0,0,-center_t]) {
            torsion_spring (deflection_angle=9271K619_angle,OD=9271K619_OD,wire_d=9271K619_wd,leg_len=9271K619_len,coils=9271K619_coils,LH=9271K619_LH);
            torsion_spring_spacer();
        }
            
        translate([0,0,yb+2]) {
            torsion_spring (deflection_angle=9271K619_angle,OD=9271K619_OD,wire_d=9271K619_wd,leg_len=9271K619_len,coils=9271K619_coils,LH=9271K619_LH);
            torsion_spring_spacer();
        }
    }
    // shoulder    adjust z translation as required
    translate([0,0,shoulder_y_shift]) { 
        color("green",.5) rotate([-90,0,0]) shoulder_assy (); 
        // A Servo
        color ("red",.5) rotate([0,180,-90])
            translate([0,0,shoulder_y_A+shoulder_svo_lug_t/2]) {
                servo_body();
                rotate([0,0,90-A_angle])
                    servo_horn();
            }
        // B Servo
        color ("red",.5) rotate([0,0,90])
            translate([0,0,-shoulder_y_B+svo_flange_d]) {
                servo_body();
                rotate([0,0,B_angle-60])
                    servo_horn();
            }
        }
    // sholder servo
    translate([0,-1.42*shoulder_z_top,0]) rotate([90,0,0]) 64T_32P_Actobotics();
    color ("red",.5) translate([-34,base_z_top-8,0]) rotate([-90,0,0])
                servo_body();
        
    // Base
    translate([0,base_z_top,0]) rotate([90,0,0]) base_assy();

} 
