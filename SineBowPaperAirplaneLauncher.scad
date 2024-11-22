// Sine-Bow Paper Airplane Launcher, by SrAmo 2024
// This new and original Paper Airplane Launcher design is called a Sine-bow because
// it operates like a cross-bow and each undeformed bow shape is a sine wave.
// With the Sine-box I have been able to launch a variety of paper airplanes, 
//   with the accuracy and distance of an average human thrower!
// No rubber bands are required.  The Sine-bow is a very compliant structure.
// However, do Not leave the launcher in the cocked position for a long period 
// of time (i.e. more than a few minutes).  The plastic will creep and take a new 
// set, reducing the effectiveness of the launcher.
//
// The Sine-bow needs a 5mm diameter tube, about 300 mm long. 
//    The tube is the slide for the bow and keeps the bow stable.
// Attach trigger to Sine-bow with two #4 diameter x ½ inch length min. screws.
//    Preferably button head (countersunk should work) plastic or wood screws.
//
// Designed for PETG filament.  PETG WORKS BETTER THAN PLA!!
//     PETG has greater strength than PLA
//     PETG is more flexible than PLA
//   PETG sticks to the printer bed better, thus no brim required!
include <NEW_LDB_Indexes.scad>
use <NEW_LDB_Modules.scad>
use <../MAKE3-Arm/openSCAD-code/Robot_Arm_Parts_lib.scad>

// MATERIAL PROPERTIES:
MATERIAL = "PETG";
//MATERIAL = "PLA";
// Modulus of Elasticity (PSI)  This represents Stiffness.
E_PLA_NSMM = 2344;  // Modulus of Elasticity (NEWTONS PER mm^2), PLA
E_PETG_NSMM = 2068;  // Modulus of Elasticity (NEWTONS PER mm^2), PETG

// ~Stress level at which the material will fail
FAILURE_STRESS_PLA_METRIC = 45;  //~Stress level when PLA will fail (NEWTONS per mm^2)
FAILURE_STRESS_PETG_METRIC = 60; //~Stress level when PETG will fail(NEWTONS per mm^2)
// This could be tensile failure, compression failure, bending, etc.

DENSITY_PLA_METRIC = 0.0012318;  // material density (gram per mm^3)
DENSITY_PETG_METRIC = 0.0012733;  // material density (gram per mm^3)

// Units
UNITS = "METRIC, LENGTH = MM, FORCE = NEWTONS";

TITLE = str("SINE-BOW 11-11-24 ",MATERIAL); // UPDATE DATE BEFORE EXPORTING
echo(TITLE);

echo(str("UNITS ARE ",UNITS,", MATERIAL IS ",MATERIAL));

L_FLEX=220; // mm, of flex beam
Y_SINE = 15; // mm, initial offset of beam sine wave
Z_BEAM=20.0;  // mm, z height of beam (3d printing z-direction) WAS 15
NumberBeams = 49;  // was 30, better to be odd number
LN = L_FLEX/NumberBeams;

// individual beam thickness, minimum, mm
T_MIN =(MATERIAL=="PETG") ? 1.2 : (MATERIAL=="PLA") ? 1.02 : 0;  

// Power for end thickening depends on material
POWER_UP = (MATERIAL=="PETG") ? 1.02 : (MATERIAL=="PLA") ? 1.03 : 0;  

BEAM_SPACE = 20; // mm, space between two beams

// Support blocks on the ends of the beams
Rfillet = 8.0; // mm
END_T = 17;

// Sliding Tube hole size
D_TUBE = 5.1; // mm

// Tube support "square" size
W_SQR = 1.7*D_TUBE; // mm

V_LEN = 100; // mm, Length of V launcher
V_W = 3; // mm, width of V launcher
Z_LAUNCH = 45; // mm, z height of launcher portion
Z_VEE = 44; // mm, z height of vee in launcher

function OneFlexBeam() =
    let (pts=[for (i=[0:NumberBeams]) [L_FLEX*(i/NumberBeams),Y_SINE*sin(360*(i/NumberBeams)-90) + Y_SINE] ])
    let (BEAM = BEAM_FROM_NODES(nodes=pts,TBEAMS=T_MIN,TENDS=1.7,w=Z_BEAM,THICKEN_ENDS=true,T_MID=true,TUP=POWER_UP,S=12))
    BEAM;
*echo(OneFlexBeam());
*MAKE_BEAM_UNDEFORMED(BEAM=OneFlexBeam(),THK=T_MIN);
    
module ANALYSIS() {
    NB=25;  // half the full beam
    
    pts=[for (i=[0:NB]) [L_FLEX/2*(i/NB),Y_SINE*sin(180*(i/NB)-90) + Y_SINE] ];
    BEAM = BEAM_FROM_NODES(nodes=pts,TBEAMS=T_MIN,TENDS=1.7,w=Z_BEAM,THICKEN_ENDS=true,T_MID=false,TUP=POWER_UP,S=12);
    
    // Model the beam straight & short, to see thickness variation
    TESTpts=[[0,0],[20,0]]; 
    pts_ADD = addPoints(TESTpts,LN*20/(L_FLEX/2));  // add points at 0.5 spacing
    //draw_points(pts_ADD,dia=1);
    BEAM_VIS = BEAM_FROM_NODES(nodes=pts_ADD,TBEAMS=T_MIN,TENDS=1.7,w=Z_BEAM,THICKEN_ENDS=true,T_MID=false,TUP=POWER_UP,S=12);
    // move down and scale the Y up, to see the thickness variation
    translate([0,-10,0]) scale([1,10,1]) MAKE_BEAM_UNDEFORMED(BEAM_VIS,THK=1);
    
    // Applied load, Newtons?  2 spring in series and 2 in parrallel
    frx = (MATERIAL=="PETG") ? -7.55 : (MATERIAL=="PLA") ? -6.9 : 0;  
    echo("APPLIED LOADS = ",frx=frx);
    
    LOADS1 = concat([for (i=[1:NB]) [0,0,0]],[[frx,0,0]]);

    FS = (MATERIAL=="PETG") ? FAILURE_STRESS_PETG_METRIC : 
    (MATERIAL=="PLA") ? FAILURE_STRESS_PLA_METRIC: 0;
    
    MODULUS = (MATERIAL=="PETG") ? E_PETG_NSMM : 
    (MATERIAL=="PLA") ? E_PLA_NSMM : 0; 
    
    DO_ANALYSIS(LDB=BEAM,EXT_LOADS=LOADS1,fscale=0.1,Display_steps=true, echoLDB=false, displayLoads=true, Failure_Stress=FS, E=MODULUS, density=DENSITY_PETG_METRIC,pinned=true,FixFy=false,steps=20);
}
*ANALYSIS();
// PETG = STEP=20,load scale=1,σ MAX=41.8965,σ MIN=-44.9787,MIN MS=0.306916,MAX MS=36.3158,ENERGY=15.1716"
// "Final Starting Fixed Loads [Fx,Fy,M]=[[7.49971, 0.870009, -315.822]]"
// "NODES: X MAX=45.5021, X MIN=0", "NODES: Y MAX=88.8306, Y MIN=0"

// PLA STEP=20,load scale=1,σ MAX=43.5716,σ MIN=-46.0749,MIN MS=-0.0360458,MAX MS=15.8643,ENERGY=11.414"
// "Final Starting Fixed Loads [Fx,Fy,M]=[[6.8644, 0.700055, -282.558]]"
// "NODES: X MAX=45.677, X MIN=0", "NODES: Y MAX=87.0003, Y MIN=0"

module SINE_BOW_PAPER_AIRPLANE_LAUNCHER() {
    intersection() { // make sure print fits on a 180 x 180 printer bed
        
        rotate([0,0,45]) SHOOTER_SUB2();  // rotate 45!
            
        translate([0,0,-Z_BEAM]) 
            cube([180,180,2*Z_LAUNCH]); // 180 X 180 Bed Size
    };
}

SINE_BOW_PAPER_AIRPLANE_LAUNCHER();

rotate([0,0,45]) translate([L_FLEX-3.5,0,0]) // NOT FOR PRINT, TRANSFORMATIONS FOR ASSY
  TRIGGER(Z_TRIG=30,Z_LAUNCH=Z_BEAM,W_TRIG=W_TRIG); 

*rotate([90,0,0]) TRIGGER(Z_TRIG=30,Z_LAUNCH=Z_BEAM,W_TRIG=W_TRIG); // FOR PRINT

module BEAM_FILLETS(BEAM_T,BEAM_W,BEAM_ANG,R) {
    Y_FILR = R + BEAM_T/2;
    Y_ANG = R*sin(BEAM_ANG); 
    X_FILR = R;
    TRAPIZOID = [[X_FILR,Y_FILR+Y_ANG] , [-X_FILR/3,Y_FILR-Y_ANG] , [-X_FILR/3,-Y_FILR-Y_ANG] , [X_FILR,-Y_FILR+Y_ANG]];
    
    translate([0,0,-BEAM_W/2]) difference() {
        linear_extrude(BEAM_W,convexity=10)
            polygon(TRAPIZOID);
        translate([X_FILR,Y_FILR+Y_ANG,BEAM_W/2]) cylinder(h=2*BEAM_W,r=R,center=true,$fn=48);
        translate([X_FILR,-Y_FILR+Y_ANG,BEAM_W/2]) cylinder(h=2*BEAM_W,r=R,center=true,$fn=48);
    }
}
    
module SHOOTER_SUB1() {
    BEAM1 = OneFlexBeam();
        
    endPoint = [L_FLEX,0,0];
    FLEX_BEAM_FILLETED(BEAM1,BEAM_T=T_MIN,BEAM_W=Z_BEAM,R=Rfillet, END=endPoint);

    translate([0,-BEAM_SPACE,0]) rotate([180,0,0]) 
        FLEX_BEAM_FILLETED(BEAM1,BEAM_T=T_MIN,BEAM_W=Z_BEAM,R=Rfillet, END=endPoint);
    
    translate([-END_T/2,-BEAM_SPACE/2,0]) cube([END_T,BEAM_SPACE*2,Z_BEAM],center=true);
    translate([L_FLEX+END_T/2,-BEAM_SPACE/2,0]) cube([END_T,BEAM_SPACE*2,Z_BEAM],center=true);
}
*SHOOTER_SUB1();

module FLEX_BEAM_FILLETED(BEAM,ORG,BEAM_T,BEAM_W,R,END=[10,0,0]) {
    NB = len(BEAM)-2;  // number of beams
    
    MAKE_BEAM_UNDEFORMED(BEAM,Z_BEAM);
    
    BEAM_FILLETS(BEAM_T=BEAM_T,BEAM_W=BEAM_W,BEAM_ANG=1.5,R=R); // Fillet at start
    
    // Fillet at end
    translate(END) 
        rotate([0,0,180]) BEAM_FILLETS(BEAM_T=BEAM_T,BEAM_W=BEAM_W,BEAM_ANG=-1.5,R=R);
}

module SHOOTER_SUB2() {
    MJX = 3.5;  // offset in z direction for holes
    difference() {
        union() {
            
            translate([END_T,BEAM_SPACE/2,0]) 
                SHOOTER_SUB1();
            
            translate([V_LEN,0,-Z_BEAM/2]) 
                rotate([0,0,180]) 
                    LAUNCHER(CAPZ=Z_LAUNCH,CAPLEN=V_LEN,W=V_W);
        };
        // remove hole ON SLIDING END for tube
        rotate([0,90,0]) translate([Z_BEAM/MJX,0,0]) {
            BIG_D = 1.14*D_TUBE;  // want loose hole for sliding end
            TOP_D = BIG_D*0.5;
            cylinder(h=3*V_LEN,d=BIG_D,center=true,$fn=100);
            
            // ADD HAT ON SLIDING CYLINDER, TO MINIMIZE OVERHANG WHILE PRINTING
            translate([-Z_BEAM/MJX+BIG_D/1.6,0,0]) 
                rotate([0,0,45]) 
                    cube([TOP_D,TOP_D,3*V_LEN],center=true);
        }
        
        // remove hole on FIXED END
        // DON'T CARE ABOUT SOME OVERHANGE HERE, AS WE WANT A TIGHT FIT
        rotate([0,90,0]) translate([Z_BEAM/MJX,0,L_FLEX]) 
            cylinder(h=L_FLEX,d=D_TUBE,center=true,$fn=100);
        
        // remove cone to help with tube insertion
        translate([L_FLEX+END_T-2,0,-Z_BEAM/MJX]) rotate([0,90,0]) 
            cone(d=D_TUBE*2,h=D_TUBE*1.1);
        
        // remove the V slot in the launcher
        Z_TRANS = Z_LAUNCH-Z_VEE;
        translate([V_LEN-2,0,Z_TRANS]) rotate([0,-88,0]) 
            VEE_SLOT(X=Z_VEE,Y=V_W-1,LEN=V_LEN);
        
        // Two screw holes, don't protrude through the top to prevent missassembly
        translate([L_FLEX+22,0,-10]) SCREW_HOLES(DIA=2.5);

    }

}
*SHOOTER_SUB2();

module LAUNCHER(CAPZ=10,CAPLEN=4,W=0.5) { 
    difference() {
        union() {
        
        translate([0,-W/2,0])
            cube([CAPLEN,W,CAPZ],center=false); // cube for airplane
        
        translate([0,-W_SQR/2,0])
            cube([CAPLEN,W_SQR,W_SQR],center=false); // cube for tube
        
        SPT_X = 1.5;  // additional thickness multiplier for supports
        translate([0,-(W*SPT_X)/2,0])
            cube([W*SPT_X,W*SPT_X,CAPZ],center=false); // cube for support
 
        translate([CAPLEN-W*SPT_X-2,-(W*SPT_X)/2,0])
            cube([W*SPT_X+2,W*SPT_X,CAPZ],center=false); // cube for support
        
        // LATCH addition
        translate([W*0.5,-0.9*W_SQR,0]) 
            cube([W,1.8*W_SQR,4],center=false);
        }
        
        text_block(); // remove text on bottom
        
        // remove chamfer on exit end
        translate([CAPLEN,0,CAPZ])
            rotate([0,45,0])
                cube(W*2,center=true);
    }
}
*LAUNCHER(CAPZ=Z_LAUNCH,CAPLEN=V_LEN,W=V_W); 

module VEE_SLOT(X=1,Y=1,LEN=10) {
    // x is vee depth, y is vee width
    X_TIP = .5;  // was 0.7
    translate([0,-Y/2,0])
    difference() {
        linear_extrude(LEN,convexity=10) {
            polygon([[0,Y/2-X_TIP],[X,0],[X,Y],[0,Y/2+X_TIP]]);
        }
        // Slant the pushing end to help keep the wings level during launch
        rotate([0,10,0]) cube([2*X,X,12],center=true);
    }
};
*VEE_SLOT(X=Z_VEE,Y=V_W-1,LEN=V_LEN);

W_TRIG = 22;

function TriggerFlexBeam() =
    let (nb=11)
    let (pts=[for (i=[0:nb]) [20*(i/nb),0] ])
    let (BEAM = BEAM_FROM_NODES(nodes=pts,TBEAMS=2.0,TENDS=5.4,w=W_TRIG,THICKEN_ENDS=true,T_MID=false,TUP=1.05,S=4))
    BEAM;
*echo(TriggerFlexBeam());
*rotate([90,0,0]) MAKE_BEAM_UNDEFORMED(BEAM=TriggerFlexBeam(),THK=W_TRIG);

module TRIGGER(Z_TRIG=10,Z_LAUNCH=5,W_TRIG=20) {
    FLEX_Z = 2;
    T_W = 4; // mm
    color("blue") {
        difference() {
            union() {
                translate([0,0,-Z_TRIG/2-4]) 
                    cube([T_W,W_TRIG,Z_TRIG],center=true); // trigger
                
                translate([T_W/2,0,-Z_LAUNCH/2-FLEX_Z]) 
                    rotate([90,0,0]) 
                    MAKE_BEAM_UNDEFORMED(BEAM=TriggerFlexBeam(),THK=W_TRIG);

                
                translate([22,-W_TRIG/2,-Z_LAUNCH/2-FLEX_Z-2]) 
                    cube([10,W_TRIG,FLEX_Z*2]); // flex beam add at holes
                
                translate([30,-W_TRIG/2,-40-Z_LAUNCH/2]) 
                    cube([10,W_TRIG,40]); // palm upright

            }
            // remove to add trigger chamfer
            translate([-5,0,0]) 
                rotate([0,-35,0]) 
                    cube([10,W_TRIG*2,Z_LAUNCH],center=true); 
            
            // remove trigger notch
            cube([10,W_SQR*1.15,Z_LAUNCH],center=true); 
            
            // remove chamfer on +z side for printing
            rotate([40,0,0]) cube([10,6,Z_LAUNCH*1.05],center=true); 

           
            translate([25,0,0]) SCREW_HOLES(DIA=3.3);  // remove screw holes
            
            translate([40,-W_TRIG/2,-30]) rotate([0,0,45])
                    cube([4,4,50],center=true); // remove palm upright chamfer
            translate([40,W_TRIG/2,-30]) rotate([0,0,45])
                    cube([4,4,50],center=true); // remove palm upright chamfer

        }        
        translate([27.5,-W_TRIG/2,-14]) //-9.5]) 
            rotate([0,45,0]) 
                cube([5,W_TRIG,2]); // add chamfer on flex beam, palm side
    }
}
*TRIGGER(Z_TRIG=30,Z_LAUNCH=Z_BEAM,W_TRIG=W_TRIG); // FOR PRINT

module SCREW_HOLES(DIA=10) {
    translate([0,5,0]) cylinder(h=30,d=DIA,center=true,$fn=50);
    translate([0,-5,0]) cylinder(h=30,d=DIA,center=true,$fn=50);
}

// Text block for Sine-bow Paper Airplane Launcher
module text_block() {
    
    SZ = 5;  // Text height
    TD = 0.5; // Text depth (determined for printabilit) 

    translate([93,0,-TD]) 
    mirror([1,0,0])  // needs to be inverted
    linear_extrude(2*TD) {
        translate([10,-SZ/2,0]) 
            text(str(TITLE),size=SZ,font="Liberation Sans");
    }
}
module test_text() {
    color("yellow") 
    difference() {
        cube([80,10,3]);
        text_block();
        }
}
*test_text();

module cone(d=10,h=5) {
    rotate_extrude(convexity=10,$fn=100) 
        polygon([[d/2,0],[0,h],[0,0]]);
}