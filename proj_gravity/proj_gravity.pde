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

float             gravityAcceleration                 = 980; //cm/s2
/* Initialization of virtual tool */
HVirtualCoupling  s;

FCircle well1; 
FCircle well2;
FCircle well3;

/* define game start */
boolean           direction                          = false;

/* text font */
PFont             f;

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
  
  well2 = new FCircle(3.0);
  well2.setPosition(edgeTopLeftX+worldWidth/4.0, edgeTopLeftY+worldHeight/3.0-1);
  well2.setStaticBody(true);
  well2.setSensor(true);
  well2.setFill(0);
  world.add(well2);
  
  well3 = new FCircle(1.0);
  well3.setPosition(edgeTopLeftX+worldWidth/4.0*3, edgeTopLeftY+worldHeight/3.0*2+1);
  well3.setStaticBody(true);
  well3.setSensor(true);
  well3.setFill(0);
  world.add(well3);
  
  /* Setup the Virtual Coupling Contact Rendering Technique */
  s                   = new HVirtualCoupling((0.75)); 
  s.h_avatar.setDensity(4); 
  s.h_avatar.setFill(255,0,0); 
  s.h_avatar.setSensor(true);

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
    
    //Moving well1 from side to side in a cycle
    if(well1.getX() < 20 && direction == false){
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
    }
      
    //Generating the gravity well force
     //if(abs(s.getToolPositionX()-well1.getX())< 2 && abs(s.getToolPositionY()-(well1.getY())) < 2){
     //  //fEE.set(-(well1.getX()-s.getToolPositionX())*2, -(s.getToolPositionY()-well1.getY())*2);
     //  fEE.set((s.h_avatar.getX()-well1.getX())*2, (well1.getY()-s.h_avatar.getY())*2);
     //}
     
     //Force for Well 1 (Center well) - Magnitude *2
     if(abs(s.h_avatar.getX()-well1.getX())< 2 && abs(s.h_avatar.getY()-(well1.getY())) < 2){
       if(abs(s.h_avatar.getX()-well1.getX()) > 0.5 && abs(well1.getY()-s.h_avatar.getY()) > 0.5){
         //fEE.set((1/(s.h_avatar.getX()-well1.getX()))*3, (1/(well1.getY()-s.h_avatar.getY()))*3);
         fEE.set(2/((s.h_avatar.getX()-well1.getX())*abs((s.h_avatar.getX()-well1.getX()))), 
                 2/((well1.getY()-s.h_avatar.getY())*abs(well1.getY()-s.h_avatar.getY())));
       } else {
         fEE.set((s.h_avatar.getX()-well1.getX())*2, (well1.getY()-s.h_avatar.getY())*2);
       }
     }
     
     //Force for Well 2 (Top well) - Magnitude *2.5
     if(abs(s.h_avatar.getX()-well2.getX())< 3 && abs(s.h_avatar.getY()-(well2.getY())) < 3){
        if(abs(s.h_avatar.getX()-well2.getX()) > 0.5 && abs(s.h_avatar.getY()-(well2.getY())) > 0.5){
          fEE.set(2.5/((s.h_avatar.getX()-well2.getX())*abs((s.h_avatar.getX()-well2.getX()))), 
                 2.5/((well2.getY()-s.h_avatar.getY())*abs(well2.getY()-s.h_avatar.getY())));
        } else {
          fEE.set((s.h_avatar.getX()-well2.getX())*2.5, (well2.getY()-s.h_avatar.getY())*2.5);
        }
     }  
   
 
     //Force for well 3 (Bottom well) 
    if(abs(s.h_avatar.getX()-well3.getX())< 1 && abs(s.h_avatar.getY()-(well3.getY())) < 1){
       //The if-else statement is to prevent the shaking caused when the distance between the end effector 
       //and the well center is too small, causing it to approach infinity. 
       if(abs(s.h_avatar.getX()-well3.getX()) > 0.5 && abs(s.h_avatar.getY()-(well3.getY())) > 0.5){
          fEE.set(1/((s.h_avatar.getX()-well3.getX())*abs((s.h_avatar.getX()-well3.getX()))), 
                 1/((well3.getY()-s.h_avatar.getY())*abs(well3.getY()-s.h_avatar.getY())));
        } else {
          //When they are too close (within 0.5), this executes instead to prevent shaking. 
          fEE.set((s.h_avatar.getX()-well3.getX())*2, (well3.getY()-s.h_avatar.getY())*2);  
        }
    }
     
    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();
   
  
    world.step(1.0f/1000.0f);
  
    renderingForce = false;
  }
}
/* end simulation section **********************************************************************************************/



/* helper functions section, place helper functions here ***************************************************************/

/*
void contactPersisted(FContact contact){
  float size;
  float b_s;

}
*/
/* end helper functions section ****************************************************************************************/
