// Robot Arm Simulation tool
//  SACC = Servo Arm with Compliant Claw
//  Started on 3/24/2020 by SrAmo
//  last modified July 18 2021 by SrAmo
/*  >>>>> Introduction <<<<<

    The purpose of this tool is to:
    1) Parametrically draw a Robot Arm. This is from the assembly.scad files
    2) Draw the forces and torques on the arm (at a position)
    3) Draw the reach path for the arm (using List Comprehension)
    4) Animate the arm through the reach path (using Animate)
    5) Provide design guidance on setting spring rates to minimize the torques on the motors
       The minimum motor margin of safety through the reach path is
       displayed using ECHO. 
    
### Robot Arm Nomenclature  ###
    
    Arm logical diagram (links connected by joints):
    Base -A- AB_arm -B- BC_arm -C- End -D- Claw
    
     DEFINITION OF ARM ANGLES
     When looking at the arm in the XY view (Top), Pos X to the right
     When the AB arm is horizontal pointing right from A, is 0 deg (pos CCW)
     When the BC arm is horizontal pointing right from A, is 0 deg (pos CCW)
     angle limits at the B joint. Angle is 0 when BC in line with AB
     ANGLE ranges are defined in the configuration file.
    
### Global Parameters are in the Configuration include file  ###

    Animation: use View/Animate.
    The OpenSCAD variable $t = time and ranges from 0 to .9999
    When animating the code is recompiled for each step.
    
    Parameters can be modified during animation!
    
### Engineering Margin of Safety for motors (servos):
     MS = (Max-Motor-Torque/Max-calculated-Torque) - 1
     Max-calculated-Torque is that found throughout the reach path
*/
//###### USE ONE CONFIGURATION FILE AT A TIME #######//
include <SACC-26-Configuration.scad>
//include <InputArm-Configuration.scad>

//###### USE ONE ASSEMBLY FILE AT A TIME #######//
use <SACC_Assembly.scad>
//use <InputArm_Assembly.scad>

use <force_lib.scad>
use <Robot_Arm_Parts_lib.scad>

// Check to calculate forces
calc_forces = true;
// Check to display assembly
display_assembly = true;
// Check to display reach path 
display_reach = true; 
// Check to display a throwing path 
display_throw = false; 
// Number of position step in internal calculation
steps = 40;
// Angle of End Effector
C_angle = 0;   
// Maximum Motor Torque (gram-mm) 
Motor_Max_Torque = 200000; 

// DEFINITION OF WEIGHTS
// Maximum payload weight (thing being lifted) (g)
payload=300;  // 680 g (try to maximize)
// weight of end effector with no payload (g)
end_weight=250;  // 250 g (measure)
// End effector offsets from C to grip/load point. Moment arm.
LengthEnd=[125,0,0.0];   // mm (measure)

combined_weight = payload+end_weight;

// This should be a function of C_ANGLE, but isn't presently
C_moment = combined_weight*LengthEnd[0]; 
C_MS = (Motor_Max_Torque/abs(C_moment))-1;
echo (end_weight=end_weight,payload=payload,combined_weight=combined_weight,C_moment=C_moment,C_MS=C_MS);

// DEFINITION OF SPRINGS are in the configuration file
// SPRINGS TO HELP JOINT A AND B ARE OPTIONAL

echo (lenAB=lenAB,lenBC=lenBC); // echo main link lengths

// values used in the reach path calculations
min_A=A_rigging-(A_range/2);
max_A=A_rigging+(A_range/2);
min_B=B_rigging-(B_range/2);
max_B=B_rigging+(B_range/2);
//echo (min_A=min_A,max_A=max_A,A_range=(max_A-min_A));
//echo (min_B=min_B,max_B=max_B,B_range=(max_B-min_B));

/* servo control values for the limit points
    lim1x = ((max_B-max_B_to_A)-min_A)/A_range;
    lim1y = ((min_A+max_B_to_A)-min_B)/B_range;
    lim2x = ((min_B-min_B_to_A)-min_A)/A_range;
    lim2y = ((max_A+min_B_to_A)-min_B)/B_range;
    // slope M and y Intercept B for limits for servo control
    lim1_M = (1-lim1x)/lim1y;
    lim2_M = lim2y/(1-lim2x);
    lim1_B = lim1y;
    lim2_B = -lim2_M*lim2x;
    echo(lim1x=lim1x,lim1y=lim1y,lim2x=lim2x,lim2y=lim2y);
    echo(lim1_M=lim1_M,lim2_M=lim2_M,lim1_B=lim1_B,lim2_B=lim2_B);
*/

// recursive module that draws a 3D point list
module draw_3d_list(the3dlist=[],size=10,dot_color="blue",idx=0) {
    point=the3dlist[idx];
    //echo(point=point);
    if (point != undef) { // not undefined means there is a point
       color(dot_color) translate(point) circle(size);   
       idx=idx+1;
       draw_3d_list(the3dlist,size,dot_color,idx);
    }  
    // Note: that an undefined causes the recursion to stop
}

// USE LIST COMPREHENSIONS TO FILL ARRAYS
angles = [ for (a = [0 : steps-1]) get_angles_from_t(a/steps,min_A,max_A,min_B,max_B)];
// angle[0] = A, angle[1] = B
//echo(angles=angles);

b = [ for (a = [0 : steps-1]) [lenAB*cos(angles[a][0]),lenAB*sin(angles[a][0]),0] ];

c = [ for (a = [0 : steps-1]) [get_CX(angles[a]),get_CY(angles[a]),0]];
draw_3d_list(c,10,"green");

cx = [ for (a = [0 : steps-1]) get_CX(angles[a])];
cx_min=min(cx);
cx_max=max(cx);
x_range = cx_max-cx_min;
//echo ("RANGE of C Joint ",cx_min=cx_min,cx_max=cx_max,x_range=x_range);
cy = [ for (a = [0 : steps-1]) get_CY(angles[a])];
cy_min=min(cy);
cy_max=max(cy);
y_range = cy_max-cy_min;
//echo (cy_min=cy_min,cy_max=cy_max,y_range=y_range);
max_range = (x_range > y_range) ? x_range : y_range;

// Scale of Force & Moment Display
force_scale = max_range/(10*combined_weight); // arbitrary formula, but works

module Margin_Safety(min,max,name="THING NAME") {
    // calculate Engineering Margin of Safety for "thing"
    MAX = max(abs(max),abs(min));
    MS = (Motor_Max_Torque/MAX)-1;
    echo(name," MARGIN OF SAFETY ",MS=MS,MAX=MAX);
}


if (calc_forces) {
    // USE LIST COMPREHENSIONS TO FILL ARRAYS
    //
    // FIRST CALCULATE MS WITH LOAD AND NO SPRINGS
    B_trq_load_nospr = [ for (a = [0 : steps-1]) combined_weight*lenBC*cos(angles[a][1])+C_moment ];
    B_trq_load_nospr_min=min(B_trq_load_nospr);
    B_trq_load_nospr_max=max(B_trq_load_nospr);
    Margin_Safety(B_trq_load_nospr_min,B_trq_load_nospr_max,"B SERVO NO SPRING");

    B_trq_noload_nospr = [ for (a = [0 : steps-1]) end_weight*lenBC*cos(angles[a][1]) ];
    B_trq_noload_nospr_min=min(B_trq_noload_nospr);
    B_trq_noload_nospr_max=max(B_trq_noload_nospr);
    Margin_Safety(B_trq_noload_nospr_min,B_trq_noload_nospr_max,"B SERVO NO SPRING NO PAYLOAD ");

    A_trq_load_nospr = [ for (a = [0 : steps-1]) combined_weight*lenAB*cos(angles[a][0])+ B_trq_load_nospr[a] ]; 
    A_trq_load_nospr_min=min(A_trq_load_nospr);
    A_trq_load_nospr_max=max(A_trq_load_nospr);
    Margin_Safety(A_trq_load_nospr_min,A_trq_load_nospr_max,"A SERVO NO SPRING");

    // The A spring helps the Joint A MOTOR
    A_spr_pt_AB = [ for (a = [0 : steps-1]) [spr_dist_AB*cos(angles[a][0]),spr_dist_AB*sin(angles[a][0]),0] ];
    A_spr_length = [ for (a = [0 : steps-1]) norm(vector_subtract(A_spr_pt_AB[a],A_spr_pt_gnd)) ];
    //A_spr_len_min=min(A_spr_length);
    //A_spr_len_max=max(A_spr_length);
    A_spr_force = [ for (a = [0 : steps-1]) A_spr_k*(A_spr_length[a]-A_spr_free_len) ];
    A_spr_torque = [ for (a = [0 : steps-1]) A_spr_force[a]*dist_line_origin(A_spr_pt_gnd,A_spr_pt_AB[a]) ];  
    A_spr_torque_min=min(A_spr_torque);
    A_spr_torque_max=max(A_spr_torque);
    echo (A_spr_torque_min=A_spr_torque_min,A_spr_torque_max=A_spr_torque_max);
    //echo(A_spr_torque=A_spr_torque);
    
    A_trq_load_spr = [ for (a = [0 : steps-1]) combined_weight*lenAB*cos(angles[a][0])+ B_trq_load_nospr[a] - A_spr_torque[a] ]; 
    A_trq_load_spr_min=min(A_trq_load_spr);
    A_trq_load_spr_max=max(A_trq_load_spr);
    Margin_Safety(A_trq_load_spr_min,A_trq_load_spr_max,"A SERVO WITH SPRING");
    
    A_trq_noload_spr = [ for (a = [0 : steps-1]) end_weight*lenAB*cos(angles[a][0])+ B_trq_noload_nospr[a] - A_spr_torque[a] ]; 
    A_trq_noload_spr_min=min(A_trq_noload_spr);
    A_trq_noload_spr_max=max(A_trq_noload_spr);
    Margin_Safety(A_trq_noload_spr_min,A_trq_noload_spr_max,"A SERVO WITH SPRING NO PAYLOAD ");

    /*
    // USE LIST COMPREHENSIONS TO FILL ARRAYS
    //
    // optimized spring rate... explain or do iteratively
    optimum_A_spr_k=1*(combined_weight*lenAB/2)/((sqrt(0.751*lenAB*lenAB)-lenAB/2)*(lenAB/4));  
    echo(A_spr_k=A_spr_k,optimum_A_spr_k=optimum_A_spr_k,A_spr_free_len=A_spr_free_len,A_spr_len_min=A_spr_len_min,A_spr_len_max=A_spr_len_max);
    echo (A_spr_torque_min=A_spr_torque_min,A_spr_torque_max=A_spr_torque_max);

    // B SPRING, HELPS THE B MOTOR
    B_spr_pt = [ for (a = [0 : steps-1]) [B_spr_r*cos(angles[a][1]),B_spr_r*sin(angles[a][1]),0] ];
    B_spr_length = [ for (a = [0 : steps-1]) norm(vector_subtract(B_spr_pt[a],B_spr_pt_gnd)) ];
    B_spr_len_min=min(B_spr_length);
    B_spr_len_max=max(B_spr_length);
    B_spr_force = [ for (a = [0 : steps-1]) B_spr_k*(B_spr_length[a]-B_spr_free_len) ];
    
    B_spr_torque = [ for (a = [0 : steps-1]) B_spr_force[a]*dist_line_origin(A_spr_pt_gnd,B_spr_pt[a]) ];  
    B_spr_torque_min=min(B_spr_torque);
    B_spr_torque_max=max(B_spr_torque);
    //echo (B_spr_torque=B_spr_torque);
   
    A_payload_torque = [ for (a = [0 : steps-1])combined_weight*lenAB*cos(angles[a][0]) ]; 
    
    A_noload_torque = [ for (a = [0 : steps-1]) end_weight*lenAB*cos(angles[a][0]) ]; 
       
    a_torq_payload = [ for (a = [0 : steps-1]) A_spr_torque[a]-A_payload_torque[a] ];
    A_torq_payload_min=min(a_torq_payload);
    A_torq_payload_max=max(a_torq_payload);
    echo (A_torq_payload_min=A_torq_payload_min,A_torq_payload_max=A_torq_payload_max);

    a_torq_noload = [ for (a = [0 : steps-1]) A_spr_torque[a]-A_noload_torque[a] ];
    A_torq_noload_min=min(a_torq_noload);
    A_torq_noload_max=max(a_torq_noload);
    echo (A_torq_noload_min=A_torq_noload_min,A_torq_noload_max=A_torq_noload_max);

    echo(B_spr_k=B_spr_k,B_spr_free_len=B_spr_free_len,B_spr_len_min=B_spr_len_min,B_spr_len_max=B_spr_len_max);
    echo (B_spr_torque_min=B_spr_torque_min,B_spr_torque_max=B_spr_torque_max);
    
    B_torq_payload = [ for (a = [0 : steps-1]) -combined_weight*lenBC*cos(angles[a][1])+B_spr_torque[a]+C_moment ];
    B_torq_payload_min=min(B_torq_payload);
    B_torq_payload_max=max(B_torq_payload);
    echo (B_torq_payload_min=B_torq_payload_min,B_torq_payload_max=B_torq_payload_max);
    //echo(B_torq_payload=B_torq_payload);

    B_torq_noload = [ for (a = [0 : steps-1]) -end_weight*lenBC*cos(angles[a][1])+B_spr_torque[a] ];
    B_torq_noload_min=min(B_torq_noload);
    B_torq_noload_max=max(B_torq_noload);
    echo (B_torq_noload_min=B_torq_noload_min,B_torq_noload_max=B_torq_noload_max);
    
    // calculate motor margins
    A_MS = (Motor_Max_Torque/max(abs(A_torq_payload_max),abs(A_torq_payload_min)))-1;
    B_MS = (Motor_Max_Torque/max(abs(B_torq_payload_max),abs(B_torq_payload_min)))-1;
    echo("MOTOR MARGIN OF SAFETY ",Motor_Max_Torque=Motor_Max_Torque,A_MS=A_MS,B_MS=B_MS,C_MS=C_MS);
    */
}

// #### pt used with animation ####

//pt = [3,3,0];  // LengthEnd point, No animation. change to position arm

alphas=get_angles_from_t($t,min_A,max_A,min_B,max_B);
//alphas=throw_from_t($t,min_A,max_A,min_B,max_B);
new_end = rotZ_pt(C_angle,LengthEnd);
pt = vector_add(get_pt_from_angles(alphas),new_end);
A_angle = alphas[0];
B_angle = alphas[1];

if (display_assembly) {
    //difference () {
        draw_assy (A_angle,B_angle,C_angle); 
        // x = 0 cut 
        //translate ([-20,-10,-10])
        //cube (20,center=false);
        // z = 0 cut 
        //translate ([-12,-20,.1])
        //cube (40,center=false);
    //}
}

if (calc_forces) internal_loads (A_angle,B_angle,C_angle);
    
if (display_reach) plot_limits (steps); // turn off for 3d rendering
    
if (display_throw) {
    // not being used
    throw_min_A = max_A - 100; // min A for throw
    plot_throw (steps); // turn off for 3d rendering
}

//$vpr = [0, $t * 360,0];   // view point rotation

//$vpt = [c[0],c[1],c[2]];   // view point translation

//**************** END OF MAIN ******************

function get_CX (a) = (cos(a[0])*lenAB+cos(a[1])*lenBC);
function get_CY (a) = (sin(a[0])*lenAB+sin(a[1])*lenBC);

module internal_loads (A_angle=0,B_angle=0,C_angle=0) {
    r_pulley = AB_pulley_d/2;  // CHECK
    
    // Calculate and Draw the forces and torques 
    b=[lenAB*cos(A_angle),lenAB*sin(A_angle),0];  
    c=[(cos(A_angle)*lenAB+cos(B_angle)*lenBC),(sin(A_angle)*lenAB+sin(B_angle)*lenBC),0];
    
    // upper arm vector
    vecBC=[(c[0]-b[0])/lenBC,(c[1]-b[1])/lenBC,(c[2]-b[2])/lenBC];
    angle_BC = atan2(vecBC[1],vecBC[0]);  // angle for upper arm motor
    // lower arm vector
    vecAB=[b[0]/lenAB,b[1]/lenAB,b[2]/lenAB];
    // tangent points of belt to pulley
    LengthEnd_t=[c[0]-r_pulley*vecBC[1],c[1]+r_pulley*vecBC[0],c[2]];
    pulley_t1=[b[0]-r_pulley*vecBC[1],b[1]+r_pulley*vecBC[0],-0.2];
    pulley_t2=[b[0]-r_pulley*vecAB[1],b[1]+r_pulley*vecAB[0],-0.2];
    ground_t=[-r_pulley*vecAB[1],r_pulley*vecAB[0],0];
    A_spr_pt_AB = spr_dist_AB*vecAB;    
    
    // payload force on LengthEnd
    force_arrow(pt,[0,-1,0],combined_weight*force_scale);
    
    // Torque at C
    color("green",1) torque_arrow(c,C_moment*(force_scale/100));
    // Torque at B
    b_moment = C_moment+ combined_weight*(c[0]-b[0]);
    color("Blue",1) torque_arrow(b,b_moment*(force_scale/100));
    //echo(b_moment=b_moment,C_moment=C_moment);
    // Sum moments about C to determine belt force on LengthEnd
    // NO LONGER USING A BELT FOR C
    
    belt_force=combined_weight*(LengthEnd[0]/r_pulley); // ratio of distances
    force_arrow(LengthEnd_t,-vecBC,belt_force*force_scale); 
    
    // Sum forces to determine force on joint C using a force polygon
    c_vec=vector_subtract(combined_weight*[0,-1,0],belt_force*vecBC);
    c_to=vector_add(c,c_vec);  
    c_force=norm(c_vec);
    force_arrow(c,c_vec,c_force*force_scale);
    force_arrow(b,-c_vec,c_force*force_scale); // equal & opp on b
    
    // Determine torque on joint B.  Link BC is a cantilever beam.
    // The upper arm motor holds joint B in (fixed) rotation.
    // The torque is the joint c force x the distance to joint b.
    //
    // translate the c vectors to the origin for distance calc.
    c1=vector_subtract(c,b);
    c2=vector_subtract(c_to,b);
    cforce_to_b_arm=dist_line_origin([c1[0],c1[1]],[c2[0],c2[1]]);
    torque_at_B=cforce_to_b_arm*c_force;
    
    
    // torque of upper arm motor at A
    color("Blue",1) torque_arrow([0,0,0],B_mtr_trq*(force_scale/50));
    
    // calculate and draw B joint pulley (belt) forces
    // there are two belt forces on the B joint pulley (_t1 and _t2)
    //force_arrow(pulley_t1,vecBC,-belt_force*force_scale); 
    //force_arrow(pulley_t2,-vecAB,belt_force*force_scale); 
    // Do vector polygon to sum forces on pulley at B
    p_vec=vector_subtract(-belt_force*vecBC,belt_force*-vecAB);
    p_force=norm(p_vec);
    //force_arrow(b,p_vec,p_force*force_scale); 
    
    // Determine torque on joint A.  
    // Link AB is like a cantilever beam with multiple forces on it (1,2,3)
    // 1) calculate and draw torque due to pulley force at B
    p_end = vector_add(b,p_vec);
    pforce_to_A_arm=dist_line_origin([b[0],b[1]],[p_end[0],p_end[1]]);
    p_torque_at_A=(abs(p_force) > 0.01) ? -p_force*pforce_to_A_arm : 0 ;
    
    // 2) calculate and draw torque due to upper arm force (uaf) at B
    uaf_end = vector_add(b,-c_vec);
    uaf_to_A_arm=dist_line_origin([b[0],b[1]],[uaf_end[0],uaf_end[1]]);
    uaf_torque_at_A=-c_force*uaf_to_A_arm;
     
    // 3) Spring to assist the lower arm motor
    // To minimize the torque on the lower arm we add a spring
    //   between ground and the AB arm.
    //   The spring has the least force when AB arm is vertical
    A_spr_len = norm(A_spr_pt_AB-A_spr_pt_gnd); 
    A_spr_force = A_spr_k*(A_spr_len-A_spr_free_len);
    force_arrow(A_spr_pt_AB,A_spr_pt_gnd-A_spr_pt_AB,A_spr_force*force_scale);
    A_spr_to_origin=dist_line_origin(A_spr_pt_gnd,A_spr_pt_AB);
    A_spr_torque = A_spr_force*A_spr_to_origin;
    
    B_spr_pt = [B_spr_r*cos(B_angle),B_spr_r*sin(B_angle),0];
    B_spr_len = norm(B_spr_pt-B_spr_pt_gnd);
    B_spr_force = B_spr_k*(B_spr_len-B_spr_free_len);
    force_arrow(B_spr_pt,B_spr_pt_gnd-B_spr_pt,B_spr_force*force_scale);
    B_spr_torque = B_spr_force*dist_line_origin(B_spr_pt_gnd,B_spr_pt);
    
    B_mtr_trq = torque_at_B+B_spr_torque;
    
    // draw basic shapes to represent the arm, includes springs
    //draw_basic();
    
    // Total Lower Arm Torque
    A_mtr_trq=p_torque_at_A+uaf_torque_at_A+A_spr_torque;
    color("Plum",1) torque_arrow([0,0,0],A_mtr_trq*(force_scale/50));
    
    // Output to console.  Used to get data into spreadsheet
    //echo ($t=$t,c=c,A_angle=A_angle,B_angle=B_angle,    B_spr_torque=B_spr_torque,B_mtr_trq=B_mtr_trq,    p_torque_at_A=p_torque_at_A,uaf_torque_at_A=uaf_torque_at_A,    A_spr_force=A_spr_force,A_spr_to_origin=A_spr_to_origin,    A_spr_torque=A_spr_torque,A_mtr_trq=A_mtr_trq); 
    
    module draw_basic () {
        // AB link
        color("Plum",.5)  pt_pt_cylinder(from=origin, to=b, d=0.2);
        // BC link
        color("Blue",.5)  pt_pt_cylinder(from=b, to=c, d=0.2);
        // CD end effector
        color("Green",.5)  pt_pt_cylinder(from=c, to=c+LengthEnd, d=0.2);
        // AB link sping
        color("Plum",.7)  pt_pt_cylinder(from=A_spr_pt_AB,to=A_spr_pt_gnd,d=0.2);
        // BC link sping
        color("Blue",.7)  pt_pt_cylinder(from=B_spr_pt,to=A_spr_pt_gnd,d=0.2);
    }
}


function get_pt_from_angles (A)= ([C_x_ang(A[0],A[1]),C_y_ang(A[0],A[1]),0]); 

function get_angles_from_t 
(t=0.5,min_A=-10,max_A=150,min_B=-50,max_B=90)= 
(t<0.15) ? ([min_A,interp(min_B,min_A+max_B_to_A,t,0,0.15),0]) : 
 (t<0.38) ? ([interp(0,100,t,0.15,0.38),interp(0,100,t,0.15,0.38),0]): 
 (t<0.5) ? ([interp(max_B-max_B_to_A,max_A,t,0.38,0.5),max_B,0]): 
(t<0.63) ? ([max_A,interp(max_B,max_A+min_B_to_A,t,0.5,0.63),0]): 
(t<0.75) ?([interp(max_A,min_B-min_B_to_A,t,0.63,0.75),interp(max_A+min_B_to_A,min_B,t,0.63,0.75),0]) :
([interp(min_B-min_B_to_A,min_A,t,0.75,1),min_B,0]); 
/*  old version of get_angles_from_t
 (t<0.38) ? ([interp(min_A,max_B-max_B_to_A,t,0.15,0.38),interp(min_A+max_B_to_A,max_B,t,0.15,0.38),0]): 
function get_angles_from_t 
(t=0.5,min_A=-10,max_A=150,min_B=-50,max_B=90)= 
(t<0.25) ? ([interp(min_A,90,t,0,0.25),interp(min_A,90,t,0,0.25),0]) : 
 (t<0.38) ? ([interp(90,max_A,t,0.25,0.38),interp(90,max_B,t,0.25,0.38),0]): 
 (t<0.5) ? ([max_A,interp(max_B,max_A+min_B_to_A,t,0.38,0.5),0]): 
(t<0.63) ? ([interp(max_A,70,t,0.5,0.63),interp(max_A+min_B_to_A,70+min_B_to_A,t,0.5,0.63),0]): 
(t<0.75) ?([interp(70,min_A,t,0.63,0.75),interp(70+min_B_to_A,min_B,t,0.63,0.75),0]) :
([min_A,interp(min_B,min_A,t,0.75,1),0]); 
*/
function throw_from_t 
(t=0.5,min_A=-10,max_A=150,min_B=-50,max_B=90)= 
(t<0.25) ? ([interp(0,max_A,t,0,0.25),interp(0,max_B,t,0,0.25),0]) : 
 (t<0.9) ? ([interp(max_A,throw_min_A,t,0.25,0.9),interp(max_B,min_B+50,t,0.25,0.9),0]): 
([interp(throw_min_A,0,t,0.9,1),interp(min_B+50,0,t,0.9,1),0]); 

function C_x_ang (A,B) = (cos(A)*lenAB+cos(B)*lenBC);

function C_y_ang (A,B) = (sin(A)*lenAB+sin(B)*lenBC);

function interp (A,B,t,t_l,t_h) = (A+((t-t_l)/(t_h-t_l))*(B-A));

module inverse (c=[10,10,0]) {
    // calculate the angles from pt ***Inverse Kinematics***

    vt = norm(c);  // vector length from A to C

    sub_angle1 = atan2(c[1],c[0]);  // atan2 (Y,X)!
    sub_angle2 = acos((vt*vt+lenAB*lenAB-(lenBC*lenBC))/(2*vt*lenAB));
    //echo(vt=vt,sub_angle1=sub_angle1,sub_angle2=sub_angle2);
    A_angle = sub_angle1 + sub_angle2;
    B_angle = acos((lenBC*lenBC+lenAB*lenAB-vt*vt)/(2*lenBC*lenAB));
} 
module plot_limits(n=20){
    // plot the expected limits of range of motion
    $fs=max_range/200;
    points = [ for (t = [0 : 1/n : 1]) get_pt_from_angles(get_angles_from_t(t,min_A,max_A,min_B,max_B)) ];
    draw_3d_list(points,max_range/120,"salmon");
    /*
    for (i=[0:1/n:1]){
        color("salmon") 
        translate(get_pt_from_angles(get_angles_from_t(i,min_A,max_A,min_B,max_B))) 
        circle(r);
    }
    */
}
module plot_throw(n=20){
    // plot the expected limits of range of motion
    $fn=8;
    r=max_range/120;
    
    for (i=[0:1/n:1]){
        color("blue") 
        translate(get_pt_from_angles(throw_from_t(i,min_A,max_A,min_B,max_B))) 
        circle(r);
    }
}

