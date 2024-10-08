// Large Displacement Beam, Modules and Functions
include <LDB_Indexes.scad>
//use <ME_lib.scad>
use <../MAKE3-Arm/openSCAD-code/ME_lib.scad>

// Display intermediate load steps?
Display_steps = false;
// Scale of Force & Moment Display
force_scale = 0.3; // [0.001:.025:10.0]
// MATERIAL PROPERTIES. 
// Modulus of Elasticity (PSI)
//E_PLA_PSI = 320000;  // USED IN MANY FUNCTIONS AND MODULES
//E_PLA_NSMM = 2344;  // Modulus of Elasticity (NEWTONS PER mm^2), PLA
E_PETG_NSMM = 2068;  // Modulus of Elasticity (NEWTONS PER mm^2), PETG

// ~Stress level at which the material will fail
//FAILURE_STRESS = 6600;  // PLA, IN PSI
//FAILURE_STRESS_PLA_METRIC = 45;  // ~Stress level at which PLA will fail (NEWTONS per mm^2)
FAILURE_STRESS_PETG_METRIC = 60;  // ~Stress level at which PETG will fail (NEWTONS per mm^2)
// This could be tensile failure, compression failure, bending, etc.

//DENSITY_PLA_IMPERIAL = 0.045;  // material density (lb per inch^3)
//DENSITY_PLA_METRIC = 0.0012318;  // material density (gram per mm^3)
DENSITY_PETG_METRIC = 0.0012733;  // material density (gram per mm^3)

Load_Steps = 6;  // THE NUMBER OF STEPS IS DEPENDENT ON THE PROBLEM

//    // beam from points
    t=1.5;  // mm, individual beam thickness, minimum
    w=15.0;  // mm, width of beam (3d printing z-direction)
    L=150;  // mm, total length of beams
    ORIGIN = [0,0,0];  // NOTE, origin is applied seperatly from shape

    START_ANG=0;
    pts=[[0,0],[L*cos(START_ANG),L*sin(START_ANG)]];  // shape
    new_pts = addPoints(pts,5.0);  // breaks points into sub lines
    //echo(new_pts=new_pts);
    //color("blue") draw_points(new_pts,dia=0.03);
   
    BEAM1 = beamFromNodes(new_pts,t,w,true,true);
    NumberBeams = len(BEAM1);
    
    Fy = 2.25;
    Mz = -Fy*L*.95/2;
    LOADS1 = concat([for (i=[1:NumberBeams]) [0,0,0]],[[0,Fy,Mz]]);
    echo(LOADS1=LOADS1," n=", len(LOADS1));

    //translate(ORIGIN) draw_beam_undeformed(BEAM1);  // OLD MODULE
    translate(ORIGIN) MAKE_BEAM_UNDEFORMED(BEAM1,w);

    // Set the beam thickness to be a Minimum MS of 2
    MSFLOOR = 1.5;
    //BEAM1 = SetBeamMinMS(BEAM0 ,LOADS1 , MSFLOOR, FAILURE_STRESS_PETG_METRIC , E_PETG_NSMM ,DENSITY_PETG_METRIC , ORIGIN, STEPS=Load_Steps);
    
    //echo(BEAM0=BEAM0);
    echo(BEAM1=BEAM1," n=", len(BEAM1));
    
    StartingNodes = getNodesFromBeams(BEAM1,ORIGIN[0],ORIGIN[1]);  // DOES NOT MATCH NEW POINTS
    //color("red") draw_points(StartingNodes,dia=0.03);

/*    
    Do_Analysis(BEAM1,LOADS1,force_scale,Display_steps,FAILURE_STRESS_PETG_METRIC,E_PETG_NSMM,DENSITY_PETG_METRIC,ORIGIN,steps=Load_Steps);
    
    //StartingNodes = getNodesFromBeams(BEAM1,ORIGIN[0],ORIGIN[1]);
    echo(StartingNodes=StartingNodes);

    FinalNodes = GetFinalNodes(BEAM1,FAILURE_STRESS_PETG_METRIC,E_PETG_NSMM,DENSITY_PETG_METRIC,LOADS1, ORIGIN, STEPS=Load_Steps);
    
    NODE_NUM = NumberBeams-0;
    THING(StartingNodes,NODE_NUM);
    TranslateChildren(StartingNodes,FinalNodes,NODE_NUM) THING(StartingNodes,NODE_NUM);
*/


/*    // SINGLE BEAM ANALYSIS, TO CHECK THE FUNCTIONS
    LEN = 3;
    t=0.1;  
    w=0.5;

    // loads on the END are given
    FX2 = 0;
    FY2 = -2.5;  // 2
    M2 = 6;  // 4  , -7

    // loads on the START are solved
    FX1 = -FX2;
    FY1 = -FY2;
    M1 = FY2*LEN+M2;

    I=((w*t*t*t)/12);
    //echo(I=I);

    NP=4;
    RoarkPts = [for (i=[1:NP+2]) 
        let (x = ((i-1)/NP)*LEN)
        [x,Y_MidRoark(FY2,M2,LEN,E_PLA_PSI,I,x)]]; 

    color("red") draw_points(RoarkPts,dia=0.03);   
    RoarkAngles = getAnglesFromNodes(RoarkPts,0,0);

    function NL_Beam(NSeg, Len, Fy,M,E,I,x_start=0,y_start=0,i=1) = 
        i <= NSeg ? 
        let(x= (i/NSeg)*Len)
        let(y=Y_MidRoark(Fy,M,Len,E,I,x))
        let(ang=asin((y-y_start)/(Len/NSeg)))
        let(x_end = Len/NSeg*cos(ang) + x_start)
        let(y_end = Len/NSeg*sin(ang) + y_start)
        //echo(i=i,x=x,y=y,ang=ang,x_end=x_end,y_end=y_end)
        concat( [[x_end,y_end]],
            NL_Beam(NSeg,Len,Fy,M,E,I,x_start=x_end,y_start=y_end,i=i+1))
        : [] ;
        
    NL_Beam_Pts = NL_Beam(NP, LEN, FY2,M2,E_PLA_PSI,I);
    color("blue") draw_points(NL_Beam_Pts,dia=0.035);
    echo(NL_Beam_Pts=NL_Beam_Pts);
        
    pts=[[0,0],[LEN,0]];  // shape
    BEAM1 = beamFromNodes(pts,t,w,false);

    // compute weight
    Weight = computeWeight(BEAM1,DENSITY_PLA_IMPERIAL,START=0,END=len(BEAM1));
    echo(Weight=Weight);

    draw_beam_undeformed(BEAM1); 

    LOADS1 = [[FX1,FY1,M1],[FX2,FY2,M2]];
    echo(LOADS1=LOADS1);

    RESULTS = computeBeamChain(BEAM1,LOADS1,FAILURE_STRESS,E_PLA_PSI);
    echo("[theta,theta_end,a,b,cr,ms,stressmin,stressmax,energy,weight,newTHK,-Fx,-Fy,-m_total]");
    echo(RESULTS=RESULTS);
    NODES = concat([[0,0,0]],getNodeFromResults(RESULTS,[0]));
    echo(NODES=NODES);
    draw_beam_deformed(BEAM1,RESULTS,displayHinge=true);      
    draw_loads(nodes=NODES, loads=LOADS1, torques=LOADS1,scale=force_scale);

    // Draw tangent line at the end point
    translate([RESULTS[0][Za],RESULTS[0][Zb],0]) 
        rotate([0,0,RESULTS[0][Zthetaend]]) 
            translate([LEN/4,0,0]) cube([LEN/2,t/2,w*1.2],center=true);

    echo("Theta End Roark=",ThetaEndRoark(FY2,M2,LEN,E_PLA_PSI,I)," EndLDB = ",RESULTS[0][Zthetaend]);
    echo(RoarkAngles=RoarkAngles);
    echo("Y End Roark=",Y_EndRoark(FY2,M2,LEN,E_PLA_PSI,I)," Y LDB = ",RESULTS[0][Zb]);
*/


// ROARK 6TH EDITION BEAM FORMULA SOLUTIONS (TRANSVERSE SHEAR AND MOMENT AT FREE END)

function ThetaEndRoark(FY=1,M=0,LEN=1,E=1000,I=0.1) = 
// Superposition of two Roark Beam formulas for end angle
// Table 3, p100, case 1a and 3a
    (180/PI)*((FY*LEN^2)/(2*E*I)) + (180/PI)*(M*LEN/(E*I));
    
function Y_EndRoark(FY=1,M=0,LEN=1,E=1000,I=0.1) = 
// Superposition of two Roark Beam formulas for end displacement
// Table 3, p100, case 1a and 3a
    (FY*LEN^3)/(3*E*I) + M*LEN^2/(2*E*I);

function Y_MidRoark(FY=1,M=0,LEN=1,E=1000,I=0.1,X=0.5) = 
// Superposition of two Roark Beam formulas for any mid displacement
// Table 3, p100, case 1a and 3a
    let (a = LEN-X)
    let (y_FY = (FY/(6*E*I)*(2*LEN^3 - 3*LEN^2*a + a^3))) // case 1a
    let (y_M = M*X^2/(2*E*I))  // case 3a
    (y_FY + y_M); // return the sum
    
module Do_Analysis(LDB_DEF,NODE_LOADS,fscale,Display_steps,Failure_Stress,E,density,Origin=[0,0,0],steps) {
    echo("******* LARGE DISPLACEMENT 2D BEAM ANALYSIS *******");
    echo(E=E,Failure_Stress=Failure_Stress,density=density,fscale=fscale);
    echo(LDB_DEF=LDB_DEF);
    echo(NODE_LOADS=NODE_LOADS);
    // perform data checks
    num_beams = count_beams(LDB_DEF);
    echo(str("NUMBER OF BEAMS =",num_beams,", NUMBER OF NODES =",len(NODE_LOADS)));
    ttl_load = sum_loads(NODE_LOADS);
    echo(str("TOTAL APPLIED LOADS AND MOMENTS =",ttl_load));
    if (num_beams > 0 && num_beams == len(NODE_LOADS)-1 && abs(ttl_load) > 0) {

        // compute weight
        Weight = computeWeight(LDB_DEF,density,START=0,END=len(LDB_DEF));
        echo(Weight=Weight);
    
        // Spread Loads. Moments don't include force-moments at this time
        initial_loads = spread_ext_loads(NODE_LOADS);
        //echo(initial_loads=initial_loads);

        // Generate GLOBAL Beam ANGLES, undeformed
        beam_angles = global_angles(LDB_DEF);
        //echo("INITIAL ",beam_angles=beam_angles);

        // MAIN ANALYSIS (MODULE)
        computeStepsModule(f_scale=fscale,LDB_DEF=LDB_DEF,Failure_Stress=Failure_Stress,E=E,density=density,loads=initial_loads, beam_angles=beam_angles,original_angles=beam_angles,Origin=Origin,STEPS=steps,index=steps,displaySteps=Display_steps); 
                
    } else echo("**NUMBER OF BEAMS OR LOADS IS ZERO, TERMINATING**"); 
}

module output_STRESS_MS_Energy(n,loadScale,Results) { 
    echo(str("STEP=",n,",load scale=",loadScale,
    ",σ MAX=",max_tree(Results,Zstressmax),
             ",σ MIN=",min_tree(Results,Zstressmin),
             ",MIN MS=",min_tree(Results,Zms),
             ",MAX MS=",max_tree(Results,Zms),
             ",ENERGY=",sum_fwd(Results,0,Zenergy)));
}

// Recursive Module to perform analysis in (STEPS) steps 
module computeStepsModule(f_scale=1,LDB_DEF,Failure_Stress,E,density,loads,beam_angles,original_angles, Origin, STEPS=1,index=99,displaySteps=true) {
    
    loadScale = (((STEPS)-index)/STEPS);
    
    loads_scaled = scale_int_loads(loads,loadScale); // scale internal loads
    loads_local = rotate_int_loads(loads_scaled,beam_angles); // Convert internal global forces to beam-local forces 
    force_mom_temp = momentsDueToForce(loads_local, LDB_DEF, beam_angles); // Calculate moments due to forces
    beam_moments = sum_moments(force_mom_temp); // Sum moments due to forces
    NEW_loads_local = add_moments_to_loads(loads_local,beam_moments);  // Add moments due-to-forces
    newResults = computeBeamChain(LDB_DEF,NEW_loads_local,Failure_Stress,E);
    Nodes = concat([Origin],getNodeFromResults(newResults,original_angles, x_start=Origin[0], y_start=Origin[1]));
    newAngleVec = getAnglesFromNodes(Nodes,Origin[0],Origin[1]); // update the beam_angles array
       
    output_STRESS_MS_Energy(index,loadScale,newResults);
    MIN_MS = min_tree(newResults,Zms);
    
    // Determine Node Display Diameter from the overall model node size
    NODE_DISPLAY_DIA = max(abs(max_tree(Nodes,Nx)),abs(max_tree(Nodes,Ny))) * 0.005;

    if ( index>0 ) { // recursion.  Counts down.

        computeStepsModule(f_scale,LDB_DEF,Failure_Stress,E,density,loads,newAngleVec,original_angles, Origin, STEPS, index-1 , displaySteps);
        
        if (displaySteps) { 
            color("red",loadScale+.1) 
                draw_points(Nodes,dia=NODE_DISPLAY_DIA); 
            } 
    } if (index==0) {  // last iteration
        
        if (displaySteps) { 
            color("red",loadScale) draw_points(Nodes,dia=NODE_DISPLAY_DIA); 
            //echo("FINAL_NODES,",Nodes);
            
            draw_loads(nodes=Nodes, loads=loads_scaled, torques=NEW_loads_local,scale=f_scale);
        }
        translate(Origin) union () 
            draw_beam_deformed(LDB_DEF,newResults,displayHinge=true,SUBMS=MIN_MS);

        echo(str("NODES: X MAX=",max_tree(Nodes,Nx),", X MIN=",min_tree(Nodes,Nx)));
        echo(str("NODES: Y MAX=",max_tree(Nodes,Ny),", Y MIN=",min_tree(Nodes,Ny)));
    }
}


// Function to Set Beam Minimum Thickness for a Beam Chain and set of Loads
//  Given a Floor Margin of Safety, all Beams with MS below this
//  will have THK set = THK * ( MS_FLOOR / MS )
// This is the Step 1 Funcion, that is not recursive, and calls Step 2
function SetBeamMinMS(BEAM_CHAIN,loads, MS_FLOOR=1, Failure_Stress,E,density, Origin, STEPS=1) =
    let (initial_loads = spread_ext_loads(loads)) // Spread Loads
    let (beam_angles = global_angles(BEAM_CHAIN)) // Generate GLOBAL Beam ANGLES, undeformed
    GetBeamMinMS_Step2(BEAM_CHAIN,initial_loads,MS_FLOOR,Failure_Stress,E,density,beam_angles,beam_angles, Origin, STEPS=STEPS,index=STEPS);

// Step 2 Recursive function to perform analysis return Beam Chain
//  with updated thicknesses
function GetBeamMinMS_Step2(BEAM_CHAIN ,loads, MS_FLOOR, Failure_Stress,E,density,beam_angles,original_angles, Origin, STEPS=1,index=99) =
    let (loadScale = (((STEPS)-index)/STEPS))
    let (loads_scaled = scale_int_loads(loads,loadScale))
    let (loads_local = rotate_int_loads(loads_scaled,beam_angles))
    let (force_mom_temp = momentsDueToForce(loads_local, BEAM_CHAIN, beam_angles))
    let (beam_moments = sum_moments(force_mom_temp))
    let (NEW_loads_local = add_moments_to_loads(loads_local,beam_moments))
    let (newResults = computeBeamChain(BEAM_CHAIN,NEW_loads_local,Failure_Stress,E))
    
    let (n = len(BEAM_CHAIN))

    let (NEW_BEAMS = [ for (i=[0:1:n-1]) [Qbeam , BEAM_CHAIN[i][Zlen] , NewThk(BEAM_CHAIN[i][Zthk],newResults[i][Zms],MS_FLOOR), BEAM_CHAIN[i][Zw], BEAM_CHAIN[i][Zang] ] ] )
        
//echo(str("NewThk()=",NewThk(BEAM_CHAIN[0][Zthk],newResults[0][Zms],MS_FLOOR),",",BEAM_CHAIN[0][Zthk],",",newResults[0][Zms],",",MS_FLOOR))
    
    let (Nodes = concat([[Origin[0],Origin[1],atan2(newResults[0][Zb],newResults[0][Za])]],getNodeFromResults(newResults,original_angles, x_start=Origin[0], y_start=Origin[1])))

    let (newAngleVec = getAnglesFromNodes(Nodes,Origin[0],Origin[1]))

    index == 0 ? // last step, return Beam Chain
        NEW_BEAMS
    : // else, reduce index and do recursion
        GetBeamMinMS_Step2(BEAM_CHAIN,loads,MS_FLOOR,Failure_Stress,E,density,newAngleVec,original_angles, Origin, STEPS, index-1)
    ;

function NewThk(ORIG_THK,MS,MS_FLOOR) = 
    (MS >= MS_FLOOR ? ORIG_THK : ORIG_THK*(MS_FLOOR/MS));

//echo(str("NewThk(0.1,0.5,2.0)=",NewThk(0.1,0.5,2.0)));

// Function to Get Nodes from a Beam and set of Loads
// This is the Step 1 Funcion, that is not recursive, and calls Step 2
function GetFinalNodes(LDB_DEF,Failure_Stress,E,density,loads, Origin, STEPS=1) =
    let (initial_loads = spread_ext_loads(loads)) // Spread Loads
    let (beam_angles = global_angles(LDB_DEF)) // Generate GLOBAL Beam ANGLES, undeformed
    GetFinalNodesStep2(LDB_DEF,Failure_Stress,E,density,initial_loads,beam_angles,beam_angles, Origin, STEPS=STEPS,index=STEPS);

// Step 2 Recursive function to perform analysis return the node locations
function GetFinalNodesStep2(LDB_DEF,Failure_Stress,E,density,loads,beam_angles,original_angles, Origin, STEPS=1,index=99) =
    let (loadScale = (((STEPS)-index)/STEPS))
    let (loads_scaled = scale_int_loads(loads,loadScale))
    let (loads_local = rotate_int_loads(loads_scaled,beam_angles))
    let (force_mom_temp = momentsDueToForce(loads_local, LDB_DEF, beam_angles))
    let (beam_moments = sum_moments(force_mom_temp))
    let (NEW_loads_local = add_moments_to_loads(loads_local,beam_moments))
    let (newResults = computeBeamChain(LDB_DEF,NEW_loads_local,Failure_Stress,E))
    let (Nodes = concat([[Origin[0],Origin[1],atan2(newResults[0][Zb],newResults[0][Za])]],getNodeFromResults(newResults,original_angles, x_start=Origin[0], y_start=Origin[1])))
    let (newAngleVec = getAnglesFromNodes(Nodes,Origin[0],Origin[1]))

    index == 0 ? // last step, return nodes
        Nodes
    : // else, reduce index and do recursion
        GetFinalNodesStep2(LDB_DEF,Failure_Stress,E,density,loads,newAngleVec,original_angles, Origin, STEPS, index-1)
    ;

module TranslateChildren(StartNodes,FinalNodes,N) {
    T_X = FinalNodes[N][Nx] - StartNodes[N][Nx];
    T_Y = FinalNodes[N][Ny] - StartNodes[N][Ny];
    R_Z = FinalNodes[N-1][Nang] - StartNodes[N-1][Nang];
    echo(str("TRANSLATIONS X=",T_X,", Y=",T_Y,", ROTATION=",R_Z));
    translate([T_X,T_Y,0]) 
        translate([StartNodes[N][Nx],StartNodes[N][Ny],0])
        rotate([0,0,R_Z]) 
            translate([-StartNodes[N][Nx],-StartNodes[N][Ny],0])
                children();
}

function computeWeight(LDB_DEF,density,START=0,END=1) = 
    // Loop thru all beam elements and sum weight off each beam
    let (LEN = LDB_DEF[START][Zlen])
    let (THK=LDB_DEF[START][Zthk])
    let (W=LDB_DEF[START][Zw])
    let (AREA = THK*W)
    let (WEIGHT = AREA*LEN*density)
//echo("BEAM",START=START,density=density,LEN=LEN,AREA=AREA,WEIGHT=WEIGHT)
    (START>=END-1 ? WEIGHT : WEIGHT + computeWeight(LDB_DEF,density,START+1,END));
    
function computeBeamChain(LDB_DEF,Internal_Loads,Failure_Stress,E) =    
    // NEW METHOD
    // Loop thru all beam elements and compute beam type, then angular deflections
    // NOTE: length of loads = length of LDB + 1
    let (n = len(LDB_DEF))
    [ for (i=[0:1:n-1]) 
        let (m2 = Internal_Loads[i+1][Zm])
        let (Fx = Internal_Loads[i+1][Zfx])
        let (Fy = Internal_Loads[i+1][Zfy])
        let (LEN = LDB_DEF[i][Zlen])
//echo("BEAM",i=i,Fx=Fx,Fy=Fy,m2=m2)
    NewBeamAngleFromLoads(LEN=LEN ,THK=LDB_DEF[i][Zthk] ,W=LDB_DEF[i][Zw], Fx=Fx, Fy=Fy, M=m2,Failure_Stress=Failure_Stress, E=E,BEAM_NO = i) ];

// Given a Beam Element and Loads, Calculate the deflection
function NewBeamAngleFromLoads(LEN,THK,W,Fx,Fy,M,Failure_Stress,E, BEAM_NO) = 
    let (Iz = ((W*THK^3)/12))
    let (AREA = THK*W)
    let (cr = 0.7)  // constant characteristic radius, for now
    let (Kaxial = E*AREA/LEN)   // Axial spring rate
    let (NEW_LEN = (Fx / Kaxial) + LEN)  // Axial displacement
    let (y_end = Y_EndRoark(Fy,M,NEW_LEN,E,Iz))  // new method
    let (theta = (abs(y_end) < cr*NEW_LEN*0.9) ? asin(y_end/(cr*LEN)) : 0 ) // degrees 
    let (theta_end = ThetaEndRoark(Fy,M,NEW_LEN,E,Iz)) // new method
    let (a = a_position(NEW_LEN,cr,theta))  // non linear displacement
    let (b = b_position(NEW_LEN,cr,theta))  // non linear displacement
    let (c = THK / 2)              // half thickness
    let (m_total = M - Fx * b + Fy * a)
    let (stressmax = m_total*c/Iz + Fx/a)
    let (stressmin = -m_total*c/Iz + Fx/a)
    let (ms = getSafetyMargin(stressmax,stressmin,Failure_Stress))
    let (newTHK = checkMS(ms,THK,BEAM_NO))  // GIVES MESSAGE TO GAUGE UP
    let (t_rad = theta * PI / 180)      // radians
    let (Krotate = E*Iz/LEN) //force per radian, Only used for energy calc
    let (EnergyRotate = 0.5* Krotate * (t_rad*t_rad))  // PE = 1/2 * K * x ^2
    let (EnergyAxial = 0.5 * Kaxial * (Fx / Kaxial)*(Fx / Kaxial))
    let (energy = EnergyRotate + EnergyAxial)
//echo(BEAM_NO=BEAM_NO,cr=cr,y_end=y_end,theta=theta,theta_end=theta_end,a=a,b=b,ms=ms)
    // QUALITY CHECKING HERE:
    ((abs(y_end) > cr*LEN*0.9) ? 
        echo("***** IMPOSSIBLE BEAM SOLUTION *****",BEAM_NO=BEAM_NO) 
    [theta,theta_end,a,b,cr,ms,stressmin,stressmax,energy,newTHK,-Fx,-Fy,-m_total] 
       : // no quality problems
    [theta,theta_end,a,b,cr,ms,stressmin,stressmax,energy,newTHK,-Fx,-Fy,-m_total]);


function getSafetyMargin(stressMax,stressMin,FailureStress) = 
    (abs(stressMax) > abs(stressMin)) ? 
        FailureStress/abs(stressMax)-1 
        : FailureStress/abs(stressMin)-1 ;

function checkMS(ms,thk,BEAMNO) = 
    ms < 0.0 ?
    let (newTHK = thk*(1-ms))
    echo(BEAMNO=BEAMNO,"##### NEGATIVE MARGIN OF SAFETY, GAUGE UP!! ###### NEW THK=",newTHK) newTHK 
    : thk ;  // return current thickness is MS is positive
    
function a_position(L,cr,theta) = L*(1-cr*(1-cos(theta)));
function b_position(L,cr,theta) = cr*L*sin(theta);

/* Models the undeformed beam, using cylinders at ends of each beam, and hull()
module draw_beam_undeformed(LDBdef,idx = 0) {
    // Parameter idx is hidden for module
    elem_type = LDBdef[idx][Ztype];
    if (elem_type == Qbeam) {  // Note: undefined causes the recursion to stop
        L = LDBdef[idx][Zlen];
        t = LDBdef[idx][Zthk];
        w = LDBdef[idx][Zw];
        LDBdef_ang = LDBdef[idx][Zang];  // Z rotation of beam
//echo("UNDEFORMED BEAM",idx=idx,LDBdef_ang=LDBdef_ang);
        // draw the beam segment
        linear_extrude(height=w,center=true) 
            hull() { 
                circle(d=t,$fn=16);  // START
                rotate([0,0,LDBdef_ang]) translate([L,0,0]) circle(d=t,$fn=16); // END
        }
        // Recursive call generating the next beam
        rotate([0,0,LDBdef_ang]) translate([L,0,0]) draw_beam_undeformed(LDBdef,idx + 1); 
    } 
} */

// NEW BEAM MODELER
module MAKE_BEAM_UNDEFORMED(BEAM,THK,idx=0) {
    
    OUTLINE_U = outline_beam_undeformed(BEAM,UP=true);
    OUTLINE_D = outline_beam_undeformed(BEAM,UP=false);
    
    OUTLINE = concat(OUTLINE_U,reverse_array(OUTLINE_D));
    
    linear_extrude(THK,convexity=10,center=true) 
        polygon(OUTLINE);
}

// Create an array of points that outline the beam
// This is called twice, for each side of the beam (UP boolean)
// Assumes the first node is at [x_start,y_start]  of beam angle ang_start
function outline_beam_undeformed(BEAM,UP=true,x_start=0,y_start=0,ang_start=0,index=0) =  
    let (ROT = (UP) ? 90 : -90) // rotation from the beam vector direction
    index < len(BEAM)-1 ? // -1 FOR NEW METHOD ONLY
        index == 0 ? //  first point, first beam
           let (T = BEAM[index][Zthk]/2)
           concat([ [x_start + T*cos(ang_start+ROT),y_start+ T*sin(ang_start+ROT) ] ],
            outline_beam_undeformed(BEAM,UP,x_start,y_start, BEAM[index][Zang],index+1) )
        :  // middle beams
            let (T = (BEAM[index][Zthk] + BEAM[index+1][Zthk])/4)
            let (LEN = BEAM[index][Zlen])
            let (END_ANG = BEAM[index][Zang])
            let (ANG = ang_start)
            let (x_end = x_start + LEN*cos(ANG)) 
            let (y_end = y_start + LEN*sin(ANG))
            concat([ [ x_end + T*cos(ANG+ROT) , y_end + T*sin(ANG+ROT)] ] ,
            outline_beam_undeformed(BEAM,UP,x_end,y_end,END_ANG + ANG,index+1) )
      : [] ; /*  // last point, use prior beam  NOT USED NEW METHOD
            let (T =       BEAM[index-1][Zthk]/2 )
            let (LEN =     BEAM[index-1][Zlen])
            let (END_ANG = BEAM[index-1][Zang])
            let (ANG = ang_start)
            let (x_end = x_start + LEN*cos(ANG)) 
            let (y_end = y_start + LEN*sin(ANG))
        [ [x_end + T*cos(ANG+ROT), y_end  + T*sin(ANG+ROT)] ]  ; */

// recursive module that draws the deformed beam.
module draw_beam_deformed(LDBdef,results,displayHinge=false,SUBMS=0.0,idx = 0,prior_ang=0) {
    elem_type = LDBdef[idx][Ztype];
    if (elem_type == Qbeam) {  // Note: undefined causes the recursion to stop
        L = LDBdef[idx][Zlen];
        t = LDBdef[idx][Zthk];
        w = LDBdef[idx][Zw];
        LDBdef_ang = LDBdef[idx][Zang];  // Unloaded Z rotation of beam relative to prior beam
        cr = results[idx][Zrad];
        babyL = L*(1-cr);
        end_ang = results[idx][Zthetaend];
        a = results[idx][Za];
        b = results[idx][Zb];
        ms = results[idx][Zms] - SUBMS; 
//echo(idx=idx,elem_type=elem_type,LDBdef_ang=LDBdef_ang,end_ang=end_ang,cr=cr,a=a,b=b);
        // draw the two beam segments 
        color ([val_red(ms),val_green(ms),0.2]) linear_extrude(height=w,center=true) 
            hull() { 
                rotate([0,0,LDBdef_ang]) translate([babyL,0,0]) circle(d=t,$fn=16);
                circle(d=t,$fn=16);  // ZERO,ZERO
        }
        color ([val_red(ms),val_green(ms),0]) linear_extrude(height=w,center=true) 
            hull() { 
                rotate([0,0,LDBdef_ang]) translate([babyL,0,0]) circle(d=t,$fn=16);
                rotate([0,0,LDBdef_ang]) translate([a,b,0]) circle(d=t,$fn=16);
        }
        
        if(displayHinge) color("black") rotate([0,0,LDBdef_ang]) translate([babyL,0,0]) cylinder(h=w*1.2,d=t/2,$fn=16);
            
        // Recursive call generating the next beam
        rotate([0,0,LDBdef_ang]) translate([a,b,0]) rotate([0,0,end_ang]) 
                draw_beam_deformed(LDBdef,results,displayHinge,SUBMS,idx + 1,LDBdef_ang+prior_ang);
    } 
}

// module that draws the loads 
module draw_loads(nodes,loads,torques,scale=1,z_offset=20) {
    //  z_offset is used to move the force/moment objects above the beam for vis
    N=len(loads)-1;
    for (i=[0:N]) {
        fx = loads[i][Zfx];
        fy = loads[i][Zfy];
        moment = torques[i][Zm];
        fmag = sqrt(fx*fx + fy*fy);
//echo("DRAW_LOADS,",i=i,fx=fx,fy=fy,moment=moment);
        // draw forces and torques
        if (abs(fmag)>0.1) color ("red") 
            translate([nodes[i][0],nodes[i][1],z_offset]) 
                force_arrow([0,0,0],[fx,fy,0],mag=fmag*scale);
        if (abs(moment)>0.1) color ("blue")
            translate([nodes[i][0],nodes[i][1],z_offset]) 
                torque_arrow([0,0,0],mag=moment*scale);
    }
}

// sum angles along segments to get global angles.
function global_angles(LDBdef,prior_ang=0) =
    let (n = len(LDBdef))
    [ for (i=[0:1:n-1]) LDBdef[i][Zang] ] ;
//    let (new_sum = sum_fwd(LDBdef,i,Zang)) 
//echo("ANGLES",i=i,prior_ang=prior_ang, new_sum=new_sum)
//    new_sum+prior_ang ] ;

function sum_range(ARRAY,start=0,end=1) = 
    let (val = ARRAY[start])
    (start>=end ? val : val + sum_range(ARRAY,start+1,end));
    
//AA = [0,1,2,3,4,5];
//BB = sum_range(AA,0,1);
//echo(BB=BB);

// recursive forward summation function to sum "thing"
// from the start (or start element) to the i'th element 
function sum_fwd(ARRAY,i,thing,start=0) = 
    let (val = ARRAY[i][thing])
    (i==start ? val : val + sum_fwd(ARRAY,i-1,thing,start));

//TEST = [[0,0,0],[0,0,0],[0,1,0],[0,55,0]];
//SUM = sum_fwd(TEST,len(TEST)-1,1);
//echo("FWD",SUM=SUM);

// recursive function to find maximum "thing"  (NOTE: i parameters is hidden-don't supply)
function max_tree(array,thing,i=0) = 
    let (val = array[i][thing])
    (val==undef ? -99999999 : max(val,max_tree(array,thing,i+1)) );

// recursive function to find minimum "thing"  (NOTE: i parameters is hidden-don't supply)
function min_tree(array,thing,i=0) = 
    let (val = array[i][thing])
    (val==undef ? 99999999 : min(val,min_tree(array,thing,i+1)) );

// recursive function to spread the external forces and moments from tail of tree to root
function spread_ext_loads(ext_loads) =
    let (n = len(ext_loads))
    //echo("SPREAD EXT LOADS",n=n)
    [ for (i=[0:1:n-1]) 
    [sum_fwd(ext_loads,n-1,Zfx,i), sum_fwd(ext_loads,n-1,Zfy,i), sum_fwd(ext_loads,n-1,Zm,i)]];

// recursive function to rotate the internal forces from a global system to a beam-local system.  Moments are copied
function rotate_int_loads(int_loads,beam_angles) = 
    let (n = len(int_loads))
    [ for (i=[0:1:n-1]) (
        let (fx = int_loads[i][Zfx])
        let (fy = int_loads[i][Zfy])
        let (ang = (i==0? beam_angles[i] :-beam_angles[i-1])) // special Ground case
//echo(i=i,fx=fx,f=fy,ang=ang)
        [rot_x(fx,fy,ang) , rot_y(fx,fy,ang) ,int_loads[i][Zm] ])];

// recursive function to scale the internal forces and moments
function scale_int_loads(int_loads,scale=1) = 
    let (n = len(int_loads))
    [ for (i=[0:1:n-1]) 
        let (fx = int_loads[i][Zfx] * scale)
        let (fy = int_loads[i][Zfy] * scale)
        let (moment = int_loads[i][Zm] * scale)
        [fx,fy,moment ]  ];

// calculate moment due to force on current beam 
function momentsDueToForce(loads, LDBdef, angles) = 
    let (n = len(LDBdef))
    [ for (i=[1:1:n-2]) (  // OLD METHOD WAS 0:1:n-1
                let (L = LDBdef[i][Zlen])
                let (fy = loads[i][Zfy])  // OLD METHOD WAS loads[i+1]
//echo("MO DUE TO FORCE",i,L=L,fy=fy)
                let (m = (fy*L == undef ? 0 : fy*L))
                m 
            )  ];

// recursive function to sum moments from tail of tree to root
function sum_moments(moments) =
    let (n = len(moments))
    [ for (i=[0:1:n-1]) (sum_range(moments,i,n-1)) ];
    
// recursive function to add beam_moments to node_loads
function add_moments_to_loads(node_loads,beam_moments) =
    let (n = len(node_loads))
    [ for (i=[0:1:n-1]) 
        let (moment = node_loads[i][Zm])
        let (moment2 = (i==n-1? 0 : beam_moments[i]))
        [node_loads[i][Zfx],node_loads[i][Zfy],moment+moment2] ];
    
function rot_x (x,y,a) = x*cos(a)-y*sin(a);

function rot_y (x,y,a) = x*sin(a)+y*cos(a);
    
// convert the margin of safety into a red to green value
function val_red(i) = i < .5 ? 1 : i > 1 ? 0 : 2-i*2 ;

function val_green(i) = i < 0 ? 0 : i > .5 ? 1 : i*2 ;

    
// recursive function to count the number of beams and check data
function count_beams(LDBdef,i=0,count=0) =
    (i < len(LDBdef) ? 
    let (length=(LDBdef[i][Zlen] == 0 ? echo("** FOUND ZERO LENGTH BEAM **",i=i) : 0))
    let (thick=(LDBdef[i][Zthk] == 0 ? echo("** FOUND ZERO THICKNESS BEAM **",i=i):0))
    let (width=(LDBdef[i][Zw] == 0 ? echo("** FOUND ZERO WIDTH BEAM **",i=i):0))
    //echo("BEAM",i=i,count=count)
        count_beams(LDBdef,i+1,count+1) 
    : count );

// recursive function to sum the loads, for check data
function sum_loads(LOADS,i=0,running_sum=0) =
    (i < len(LOADS) ?
    let (Fx=LOADS[i][Zfx])
    let (Fy=LOADS[i][Zfy])
    let (m=LOADS[i][Zm])
    let (sum=(Fx+Fy+m)+running_sum)
    sum_loads(LOADS,i+1,sum)
    : running_sum ); 
    
module draw_points(pts,dia=0.1) {
    numPts = len(pts);
    for (i=[0:numPts-1]) translate([pts[i][0],pts[i][1],1]) color("black") circle(dia,$fn=8);
}
// Function to get Nodes from Results recursively (NOTE: last 4 parameters are hidden-don't supply)
// NEED TO APPEND INITIAL ANGLES
function getNodeFromResults(resultsArray,initAngles,x_start=0,y_start=0,ang_start=0, index=0) = 
    index < len(resultsArray) ?
        let (x = resultsArray[index][Za])
        let (y = resultsArray[index][Zb])
        let (ang = (index==0 ? 0 : resultsArray[index-1][Zthetaend]))
        let (initAng = initAngles[index])
        let (sum_ang = initAng + ang + ang_start) // add up to get new angle
        let (x_end = rot_x(x,y,sum_ang) + x_start) // add up to get new x
        let (y_end = rot_y(x,y,sum_ang) + y_start) // add up to get new y 
//echo(index=index,x=x,y=y,y_start=y_start,initAng=initAng,sum_ang=sum_ang)
        concat([ [x_end , y_end ,resultsArray[index][Zthetaend]] ],
        // Recursive call to process the next point
        getNodeFromResults(resultsArray, initAngles, x_end , y_end , sum_ang, index + 1) ) 
    :  [] ;  // Return nothing when all points are processed

// GENERATE NODES FROM A BEAM DEFINITION  ***********************
function getNodesFromBeams(BEAMS,x_start=0,y_start=0,ang_start=0,index=0) =
    index < len(BEAMS) ? 
        index == 0 ? // first node
            concat([ [x_start,y_start,BEAMS[index][Zang] ] ],
            getNodesFromBeams(BEAMS,x_start,y_start, BEAMS[index][Zang],index+1) )
        :  // middle nodes
            let (LEN = BEAMS[index][Zlen])
            let (END_ANG = BEAMS[index][Zang])
            let (ANG = ang_start)
            let (x_end = x_start + LEN*cos(ANG)) 
            let (y_end = y_start + LEN*sin(ANG))
            concat([ [ x_end, y_end, ANG] ] ,
            getNodesFromBeams(BEAMS,x_end,y_end,END_ANG + ANG,index+1) )
        :  // last node
            let (LEN = BEAMS[index-1][Zlen])
            let (END_ANG = BEAMS[index-1][Zang])
            let (ANG = ang_start)
            let (x_end = x_start + LEN*cos(ANG)) 
            let (y_end = y_start + LEN*sin(ANG))
        [ [x_end, y_end, ANG] ]  ; 

function getAnglesFromNodes(NodesArray,x_start=0,y_start=0, index=1) = 
    index < len(NodesArray) ?
        let (x = NodesArray[index][Nx])
        let (y = NodesArray[index][Ny])
        let (beamAng = atan2(y-y_start,x-x_start))
 //echo(index=index,x=x,x_start=x_start,y=y,y_start=y_start,beamAng=beamAng)
        concat([ beamAng ],
           getAnglesFromNodes(NodesArray, x , y , index + 1) ) 
    :  [] ;  // Return nothing when all points are processed

function beamFromNodes(nodes,t,w,THICKEN_ENDS=false,T_MID=false,TUP = 1.03,S=9,index=0,prior_ang=0) =
    // beam stresses at the fix endS can be larger than reported, due to stress concentrations
    // THICKEN_ENDS option will gradually increase thickenss of the ends
    // TUP is scaler for thickening up the ends
    // S is the number of nodes from each end to thicken
    // More nodes, increase S, decrease TUP
    let (n = len(nodes)-1)
    index < n ? 
    let (T_NEW_1 = index < S ? t*TUP^(S-index) : t) // Thicken Start End
    let (T_NEW_2 = index > n-S ? t*TUP^(index-(n-S)) : T_NEW_1) // Thicken End End
    let (MID_N = floor(n/2))
    let (T_NEW_3 = (index == MID_N && T_MID) ? t*1.4 : T_NEW_2) // Thicken up the middle
    let (T_NEW_4 = (index == (MID_N-1) && T_MID) ? t*1.2 : T_NEW_3) // Thicken up the middle
    let (T_NEW_5 = (index == (MID_N+1) && T_MID) ? t*1.2 : T_NEW_4) // Thicken up the middle
    let (T_NEW = THICKEN_ENDS ? T_NEW_5 : t)
    let (length = sqrt((nodes[index][0]-nodes[index+1][0])^2 + (nodes[index][1]-nodes[index+1][1])^2))
    let (dx=nodes[index+1][0]-nodes[index][0])
    let (dy=nodes[index+1][1]-nodes[index][1])
    let (ang = atan2((nodes[index+1][1]-nodes[index][1]),(nodes[index+1][0]-nodes[index][0])))
//echo(index=index,n=n,T_NEW) //ang=ang,prior_ang=prior_ang,dx=dx,dy=dy)
    concat([[Qbeam,length,T_NEW,w,ang-prior_ang]],beamFromNodes(nodes,t,w,THICKEN_ENDS,T_MID,TUP,S,index+1,ang))  : [] ;

function addPoints(points, minDistance) = flatten([
    [points[0]], // copy initial point
    for (i = [1:len(points)-1]) concat(
        recursivelyAddPoints(points[i-1], points[i], minDistance),
        [points[i]]
    )  ]  );

function flatten(l) = [ for (a = l) for (b = a) b ] ;  // need to use with addPoints 

function recursivelyAddPoints(pointA, pointB, minDistance) = 
    let(
        distance = norm(pointB - pointA),
        numPoints = ceil(distance / minDistance),
        step = 1 / numPoints
    ) [
        for (i = [1:numPoints-1])
            pointA + (pointB - pointA) * i * step
    ];

/* Example usage
points = [
    [0, 0, 0],
    [0, 10, 0],
    [5, 10, 0]
];

minDistance = 2;
result = addPoints(points, minDistance);
//result = flatten(addPoints(points, minDistance));
draw_points(result,dia=0.3);
echo(points=points," n=",len(points));
echo(result=result," n=",len(result));
        */

// Function to reverse an array of points
function reverse_array(arr) =
    let(len_arr = len(arr)) 
        [for (i = [0 : len_arr - 1]) arr[len_arr - i - 1]] ;

module THING(StartingNodes,NODE,LEN=10) {
    translate([StartingNodes[NODE][Nx],StartingNodes[NODE][Ny],0]) 
        cube([LEN,LEN*0.1,LEN*0.1],center=false);
}