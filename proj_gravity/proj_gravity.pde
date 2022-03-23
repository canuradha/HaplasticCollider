/**
 **********************************************************************************************************************
 * @file       Maze.pde
 * @author     Elie Hymowitz, Steve Ding, Colin Gallacher
 * @version    V4.0.0
 * @date       08-January-2021
 * @brief      Maze game example using 2-D physics engine
 **********************************************************************************************************************
 * @attention
 *
 *
 **********************************************************************************************************************
 */



/* library imports *****************************************************************************************************/ 
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
/* end library imports *************************************************************************************************/  



/* scheduler definition ************************************************************************************************/ 
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/ 



/* device block definitions ********************************************************************************************/
Board             haplyBoard;
Device            widgetOne;
Mechanisms        pantograph;

byte              widgetOneID                         = 5;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           renderingForce                     = false;
/* end device block definition *****************************************************************************************/



/* framerate definition ************************************************************************************************/
long              baseFrameRate                       = 120;
/* end framerate definition ********************************************************************************************/ 



/* elements definition *************************************************************************************************/

/* Screen and world setup parameters */
float             pixelsPerCentimeter                 = 40.0;
float             pixelsPerMeter                      = 4000.0;

/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                 = new PVector(0, 0); 


/* World boundaries */
FWorld            world;
float             worldWidth                          = 25.0;  
float             worldHeight                         = 10.0; 

float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;

float             gravityAcceleration                 = 980; //cm/

float xE = 0;
float yE = 0;
/* Initialization of virtual tool */
HVirtualCoupling  s;

FCircle well1; 
FCircle well2;
FCircle well3;
FCircle well1_1;
FCircle well2_2; 
FCircle well3_3;

/* text font */
PFont             f;

/* Gravitational force equation */
float             grav_const                         = 6.7;
float             hap_mass                           = 8;
float             mass1                              = 12;
float             mass2                              = 20;
float             mass3                              = 2;
float             gravforce_x                        = 0;
float             gravforce_y                        = 0;
float             gravforce                          = 0;

float             rEE                                = 0.006;
float             distance                           = 0;
float             direction_x                        = 0;
float             direction_y                        = 0;
float             angle                              = 0;

float[]           gravforce_arr1;
float             gravforce_x1                       = 0;
float             gravforce_y1                       = 0;

float[]           gravforce_arr2;
float             gravforce_x2                       = 0;
float             gravforce_y2                       = 0;

float[]           gravforce_arr3;
float             gravforce_x3                       = 0;
float             gravforce_y3                       = 0;

float             gravforce_totx                     = 0;
float             gravforce_toty                     = 0;

/* end elements definition *********************************************************************************************/  



/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  
  /* screen size definition */
  size(1000, 400);
  
  /* set font type and size */
  f                   = createFont("Arial", 16, true);

  
  /* device setup */
  
  /**  
   * The board declaration needs to be changed depending on which USB serial port the Haply board is connected.
   * In the base example, a connection is setup to the first detected serial device, this parameter can be changed
   * to explicitly state the serial port will look like the following for different OS:
   *
   *      windows:      haplyBoard = new Board(this, "COM10", 0);
   *      linux:        haplyBoard = new Board(this, "/dev/ttyUSB0", 0);
   *      mac:          haplyBoard = new Board(this, "/dev/cu.usbmodem1411", 0);
   */
  haplyBoard          = new Board(this, Serial.list()[0], 0);
  widgetOne           = new Device(widgetOneID, haplyBoard);
  pantograph          = new Pantograph();
  
  widgetOne.set_mechanism(pantograph);

  widgetOne.add_actuator(1, CCW, 2);
  widgetOne.add_actuator(2, CW, 1);
 
  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  widgetOne.add_encoder(2, CW, -61, 10752, 1);
  
  
  widgetOne.device_set_parameters();
  
  
  /* 2D physics scaling and world creation */
  hAPI_Fisica.init(this); 
  hAPI_Fisica.setScale(pixelsPerCentimeter); 
  world               = new FWorld();
  
  well1 = new FCircle(2.0);
  well1.setPosition(edgeTopLeftX+worldWidth/2.0, edgeTopLeftY+worldHeight/2.0+0.5);
  well1.setStaticBody(true);
  well1.setSensor(true);
  well1.setFill(0);
  world.add(well1);
  
  well1_1 = new FCircle(3.0);
  well1_1.setPosition(edgeTopLeftX+worldWidth/2.0, edgeTopLeftY+worldHeight/2.0+0.5);
  well1_1.setStaticBody(true);
  well1_1.setSensor(true);
  well1_1.setFill(0,200,0);
  world.add(well1_1);
  
  well2 = new FCircle(3.0);
  well2.setPosition(edgeTopLeftX+worldWidth/4.0, edgeTopLeftY+worldHeight/3.0-1);
  well2.setStaticBody(true);
  well2.setSensor(true);
  well2.setFill(0);
  world.add(well2);
  
  well2_2 = new FCircle(4.0);
  well2_2.setPosition(edgeTopLeftX+worldWidth/4.0, edgeTopLeftY+worldHeight/3.0-1);
  well2_2.setStaticBody(true);
  well2_2.setSensor(true);
  well2_2.setFill(0);
  world.add(well2_2);
  
  well3 = new FCircle(1.0);
  well3.setPosition(edgeTopLeftX+worldWidth/4.0*3, edgeTopLeftY+worldHeight/3.0*2+1);
  well3.setStaticBody(true);
  well3.setSensor(true);
  well3.setFill(0);
  world.add(well3);
  
  well3_3 = new FCircle(2.0);
  well3_3.setPosition(edgeTopLeftX+worldWidth/4.0*3, edgeTopLeftY+worldHeight/3.0*2+1);
  well3_3.setStaticBody(true);
  well3_3.setSensor(true);
  well3_3.setFill(0);
  world.add(well3_3);
  
  //createWell(well1, well1_1, 2, edgeTopLeftX+worldWidth/2.0, edgeTopLeftY+worldHeight/2.0+1);
  //createWell(well2, well2_2, 3, edgeTopLeftX+worldWidth/4.0, edgeTopLeftY+worldHeight/3.0-1);
  //createWell(well3, well3_3, 1, edgeTopLeftX+worldWidth/4.0*3, edgeTopLeftY+worldHeight/3.0*2+1);
  
  /* Setup the Virtual Coupling Contact Rendering Technique */
  s                   = new HVirtualCoupling((0.75)); 
  s.h_avatar.setDensity(4); 
  s.h_avatar.setFill(255,0,0); 
  s.h_avatar.setSensor(false);

  s.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2); 
  
  /* World conditions setup */
  world.setGravity((0.0), gravityAcceleration); //1000 cm/(s^2)
  world.setEdges((edgeTopLeftX), (edgeTopLeftY), (edgeBottomRightX), (edgeBottomRightY)); 
  world.setEdgesRestitution(.4);
  world.setEdgesFriction(0.5);
  
  world.draw();
  
  
  /* setup framerate speed */
  frameRate(baseFrameRate);
  
  
  /* setup simulation thread to run at 1kHz */
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}
/* end setup section ***************************************************************************************************/



/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if(renderingForce == false){
    background(255);
    textFont(f, 22);
    
    //float xE = pixelsPerMeter*posEE.x;
    //float yE = pixelsPerMeter*posEE.y;
    
    //translate(xE, yE);

    arrow(xE, yE-worldHeight, fEE.x, fEE.y);

    world.draw();
  }
}
/* end draw section ****************************************************************************************************/



/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable{
  
  public void run(){
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
    
    renderingForce = true;
    
    if(haplyBoard.data_available()){
      /* GET END-EFFECTOR STATE (TASK SPACE) */
      widgetOne.device_read_data();
    
      angles.set(widgetOne.get_device_angles()); 
      posEE.set(widgetOne.get_device_position(angles.array()));
      posEE.set(posEE.copy().mult(200));  
      
      xE = pixelsPerCentimeter * posEE.x;
      yE = pixelsPerCentimeter * posEE.y;
    }
    
    s.setToolPosition(edgeTopLeftX+worldWidth/2-(posEE).x, edgeTopLeftY+(posEE).y-7); 
    s.updateCouplingForce();
 
 
    fEE.set(-s.getVirtualCouplingForceX(), s.getVirtualCouplingForceY());
    fEE.div(100000); //dynes to newtons
    
    //Moving well1 from side to side in a cycle
  /*  if(well1.getX() < 20 && direction == false){
      well1.setPosition(well1.getX()+0.002, well1.getY());
    } else if(well1.getX()<20 && direction == true){
      well1.setPosition(well1.getX()-0.002, well1.getY());
    } 
    if(well1.getX() < 5){
      well1.setPosition(well1.getX()+0.002, well1.getY());
      direction = false;
    }
    if(well1.getX() > 20){
      well1.setPosition(well1.getX()-0.002, well1.getY());
      direction = true;
    } */
      
     //if(s.h_avatar.isTouchingBody(well1_1)){
     //  fEE.set(0,0);
     //} else {
       gravforce_arr1 = calcGravForces(well1, mass1);       
       gravforce_arr2 = calcGravForces(well2, mass2); 
       gravforce_arr3 = calcGravForces(well3, mass3);
       
       gravforce_totx = gravforce_arr1[0]+gravforce_arr2[0]+gravforce_arr3[0];
       gravforce_toty = gravforce_arr1[1]+gravforce_arr2[1]+gravforce_arr3[1];
       
       //gravforce_totx = constrain(gravforce_totx, -5, 5);    //limit the min and max of force to prevent the haply from getting out of control
       //gravforce_toty = constrain(gravforce_toty, -5, 5);
                 
       fEE.set(gravforce_totx, gravforce_toty);  //apply the gravitational force to the end effector
     //}
     
    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();
   
  
    world.step(1.0f/1000.0f);
  
    renderingForce = false;
  }
}
/* end simulation section **********************************************************************************************/



/* helper functions section, place helper functions here ***************************************************************/
public float[] calcGravForces(FBody well, float mass){
    distance = (float)Math.sqrt(Math.pow(s.getToolPositionX()-well.getX(), 2)+Math.pow(s.getToolPositionY()-well.getY(),2));  //calculate distance between the two bodies
    gravforce = ((grav_const)*hap_mass*mass)/((float)Math.pow(distance,2));   //calculate gravitational force according to the universal gravitation equation                                                                                
    angle = (float)Math.acos(abs(s.getToolPositionX()-well.getX())/distance);  //use inverse cos to find the angle 
    
    direction_x = Math.signum(s.getToolPositionX()-well.getX());  //get the direction that the x-force should be applied
    direction_y = Math.signum(well.getY()-s.getToolPositionY());  //get the direction that the y-force should be applied
    
    gravforce_x = direction_x*gravforce*(float)Math.cos(angle);  //use the angle to get the x-comp of gravitational force
    gravforce_y = direction_y*gravforce*(float)Math.sin(angle);  //use the angle to get the y-comp of gravitational force
     
    float[] gravforce_arr = new float[]{gravforce_x, gravforce_y};
    
    return gravforce_arr; 
    //gravforce_x = constrain(gravforce_x, -5, 5);    //limit the min and max of force to prevent the haply from getting out of control
    //gravforce_y = constrain(gravforce_y, -5, 5);
                 
    //fEE.set(gravforce_x, gravforce_y);  //apply the gravitational force to the end effector
}

void createWell(FCircle inner_well, FCircle outer_well, float size, float pos_x, float pos_y){
  inner_well = new FCircle(size);
  inner_well.setPosition(pos_x, pos_y); 
  inner_well.setStaticBody(true);
  inner_well.setSensor(false); 
  //inner_well.setFill(0); 
  world.add(inner_well);
  
  //outer_well = new FCircle(size+1.5);
  //outer_well.setPosition(pos_x, pos_y);
  //outer_well.setStaticBody(true);
  //outer_well.setSensor(false);
  ////outer_well.setFill(0);
  //world.add(outer_well);
}

void arrow(float x1, float y1, float x2, float y2){
  x2=x2*0.5;
  y2=y2*0.5;
  //x1=-x1+(12.5*40);
  x1 = -x1+(worldWidth/2*pixelsPerCentimeter);
  //y1=y1-(5*40)-60;
  y1=y1-(worldHeight/2*pixelsPerCentimeter)-(pixelsPerCentimeter*1.5);
  y2=y2+y1;
  x2=-x2+x1;

  line(x1, y1, x2, y2);
  pushMatrix();
  translate(x2, y2);
  float a = atan2(x1-x2, y2-y1);
  rotate(a);
  line(0, 0, -10, -10);
  line(0, 0, 10, -10);
  popMatrix();
}
/* end helper functions section ****************************************************************************************/
