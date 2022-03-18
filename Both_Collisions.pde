/**
 **********************************************************************************************************************
 * @file       Elastic.pde
 * @author     Kevin Gilmore
 * @version    V1.0.0
 * @date       03-Feburary-2022
 * @brief      First iteration demonstrating elastic collisions, 1 ball in box with haptic impulse feedback on contact
 **********************************************************************************************************************

 **********************************************************************************************************************
 */



/* library imports *****************************************************************************************************/ 
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
import controlP5.*;
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

/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                 = new PVector(0, 0); 

/* World boundaries */
FWorld            world;
float             worldWidth                          = 30.0;  
float             worldHeight                         = 20.0; 

float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;

float             gravityAcceleration                 = 0; //cm/s2
/* Initialization of virtual tool */
HVirtualCoupling  s;

FCircle           bouncey_ball_1;
int               flag = 0;
float             Vx = 0;
float             Vy = 0;
float             Vx1 = 0;
float             Vy1 = 0;
float             m;
float             Ke_x;
float             Ke_y;
float             px;
float             py;



/* text font */
PFont             f;

/* end elements definition *********************************************************************************************/  



/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  
  /* screen size definition */
  size(1200, 800);
  
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
  
  // elastic ball definition
  bouncey_ball_1        = new FCircle (0.75);
  bouncey_ball_1.setFill(0);
  bouncey_ball_1.setPosition(10,10);
  bouncey_ball_1.setSensor(false);
  bouncey_ball_1.setVelocity(-40, 20);
  bouncey_ball_1.setDamping(0);
  bouncey_ball_1.setDensity(10);
  bouncey_ball_1.setGrabbable(true);
  world.add(bouncey_ball_1);
  
  
 
  
  
  /* Setup the Virtual Coupling Contact Rendering Technique */
  s                   = new HVirtualCoupling((1)); 
  s.h_avatar.setDensity(4); 
  s.h_avatar.setFill(255,0,0); 
  s.h_avatar.setSensor(true);

  s.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2); 
  
  /* World conditions setup */
  world.setGravity((0.0), gravityAcceleration); //1000 cm/(s^2)
  world.setEdges((edgeTopLeftX), (edgeTopLeftY), (edgeBottomRightX), (edgeBottomRightY)); 
  world.setEdgesRestitution(.4);
  world.setEdgesFriction(0);

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

    if (flag==0){
      fill(0, 0, 0);
      textAlign(CENTER);
      text("Elastic", width/2, 60);
    }
    
    else if(flag==1){
      textAlign(CENTER);
      text("Inelastic", width/2, 60);
    }
    
    else if (flag ==2){
      textAlign(CENTER);
      text("Interaction with Haply Effector (Ball will now interact with red avatar)", width/2, 60);
    }
  
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
    }
    
    s.setToolPosition(edgeTopLeftX+worldWidth/2-(posEE).x, edgeTopLeftY+(posEE).y-7); 
    s.updateCouplingForce();
    
    fEE.set(-s.getVirtualCouplingForceX(), s.getVirtualCouplingForceY());
    fEE.div(100000); //dynes to newtons
    
    Ke_x = 0.5*m*Vx*Vx;
    Ke_y = 0.5*m*Vx*Vx;
    px = 0.5*m*Vx;
    py = 0.5*m*Vy;
   
 
    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();
  
   Vx1 = bouncey_ball_1.getVelocityX();
   Vy1 = bouncey_ball_1.getVelocityY();
  
    world.step(1.0f/1000.0f);
  
    renderingForce = false;
  }
}
/* end simulation section **********************************************************************************************/



/* helper functions section, place helper functions here ***************************************************************/

void contactStarted(FContact c){
 
    m = bouncey_ball_1.getMass();
    Vx = bouncey_ball_1.getVelocityX();
    Vy = bouncey_ball_1.getVelocityY();
    
    
    if (c.contains(bouncey_ball_1) && (c.contains(world.right) || c.contains(world.left) || c.contains(world.top) || c.contains(world.bottom))){
      
      if (c.contains(world.right) || c.contains(world.left)){
        Vx = -Vx;
        Vy = Vy;
        if (flag!=2){
          fEE.set(-Ke_x, 0);
        }
      }
      
      if (c.contains(world.top) || c.contains(world.bottom)){
        Vx = Vx;
        Vy = -Vy;
        if (flag!=2){
          
          
          fEE.set(0, -Ke_y);
        }
      }
   }
   
   else if (c.contains(bouncey_ball_1) && c.contains(s.h_avatar) && flag ==2){
    
     fEE.set(100*c.getNormalX(), 100*c.getNormalY());
     s.h_avatar.addForce(-Ke_x*c.getNormalX(), -Ke_y*c.getNormalY());
     
   }
   
   
   torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();
    
    if (flag == 1 || flag == 2){
      Vx = ((random(8,9))/10)*Vx;    
      Vy = ((random(8,9))/10)*Vy; 
    }
    
    bouncey_ball_1.setVelocity(Vx,Vy);
    
    delay(3);

}

void keyPressed() {
  if (key != '1'){
    if (flag == 0){
      flag = 1;
      s.h_avatar.setSensor(true);
    }
    
    else if (flag == 1){
      flag = 2;
      s.h_avatar.setSensor(false);
    }
    
    else if(flag == 2){
      flag = 0;
      s.h_avatar.setSensor(true);
    }
  }
}

//float static_and_moving(FBody static_b, FBody moving_b, float vx, float vy){
 
  
  
//}

/* end helper functions section ****************************************************************************************/
