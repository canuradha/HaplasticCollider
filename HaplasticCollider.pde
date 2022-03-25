// import controlP5.*;
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
import java.lang.Math;

private GUI ui;

private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);

float pixelsPerMeter = 10.0;



// Haply Initializatons
Board haplyBoard;
Device widgetOne;
Mechanisms pantograph;

PVector angles = new PVector(0,0);
PVector torques = new PVector(0,0);

PVector posEE = new PVector(0,0);
PVector fEE = new PVector(0,0);

// Virtual tool initializtation
HVirtualCoupling sensor;

// World variable declarations
FWorld world;
float WORLD_WIDTH = 80.0;
float WORLD_HEIGHT = 70.0;
float BOUNDARY_SIZE = 1;

Knob plateVelocity, ballVelocity, plateM, ballM;    // to remove

// World Object declarations
FBox basePlate;
FCircle ball;

// Object parameter variables
float platePositionX = BOUNDARY_SIZE * 5;
float platePositionY =  WORLD_HEIGHT/2;
float plateVelocityX = 0;
float plateVelocityY = 0;
float pVelocityDecay = 0.5;
float plateMass = 200;
float plateMassFactor = 1;
boolean isPlateVelocityChanged = false;

float ballVelocityX = 0;
float ballVelocityY = 0;
float ballRadius = 1;
float ballMass = 250;
float ballMassFactor = 1;
boolean isBallVelocityChanged = false;


// other variables
boolean renderingForce = false;
long baseFrameRate = 120;
byte widgetOneID = 5;
int CW = 0;
int CCW = 1;

float dampingForce = 0;
float virtualCouplingX = 0;
float virtualCouplingY = 0;
float dampingScale = 10000;

void initHaply(){
  // println(Serial.list()[0]);
  haplyBoard = new Board(this, Serial.list()[0], 0);
  widgetOne = new Device(widgetOneID, haplyBoard);
  pantograph = new Pantograph();
  
  widgetOne.set_mechanism(pantograph);
  widgetOne.add_actuator(1, CCW, 2);
  widgetOne.add_actuator(2, CW, 1); 
  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  widgetOne.add_encoder(2, CW, -61, 10752, 1);   
  widgetOne.device_set_parameters();
}

void addSensor(){
   /* Setup the Virtual Coupling Contact Rendering Technique */
  sensor = new HVirtualCoupling((3)); 
  sensor.h_avatar.setDensity(50); 
  sensor.h_avatar.setFill(255,0,0); 
  sensor.h_avatar.setSensor(true);

  if(ui != null)
    ui.setSensor(sensor);

  sensor.init(world, WORLD_WIDTH/2, BOUNDARY_SIZE + 5);
}

void removeSensor(){
  sensor = null;
}

FCircle initBall(float radius, float x, float y, float ballFriction, boolean isHaptic){
  FCircle tempBall = new FCircle(2 * ballRadius);
  tempBall.setPosition( WORLD_WIDTH/4, WORLD_HEIGHT/2);
  tempBall.setFill(0, 0, 150);
  tempBall.setHaptic(isHaptic);
  tempBall.setRestitution(1);
  tempBall.setFriction(ballFriction);
  tempBall.setDensity((float) ((ballMass * ballMassFactor)/ Math.PI * Math.pow(ballRadius , 2)));
  tempBall.setDamping(0);
  return tempBall;
}

FBox initBox(float width, float length, float x, float y, boolean isHaptic){
  FBox temp = new FBox(width , length);
  temp.setPosition(x, y);
  temp.setFill(100);
  temp.setNoStroke();
  temp.setRotatable(false);
  temp.setHaptic(isHaptic);
  temp.setDensity((plateMass * plateMassFactor) / temp.getWidth() * temp.getHeight());
  temp.setDamping(20); 
  return temp;
}

void setup() {
  /* put setup code here, run once: */

  /* screen size definition */
  size(1200, 700);
  
  /* GUI setup */
  hAPI_Fisica.init(this); 
  hAPI_Fisica.setScale(pixelsPerMeter); 

  smooth();
  ui = new GUI(this);
  ui.init(WORLD_WIDTH, WORLD_HEIGHT, BOUNDARY_SIZE);
  world = ui.getWorld();  
  
  ball = initBall(2* ballRadius, WORLD_WIDTH/4, WORLD_HEIGHT/2, 0.0f, false);
  basePlate = initBox(BOUNDARY_SIZE, BOUNDARY_SIZE * 5, platePositionX, platePositionY, false);


  /* Haply Board Setup */
  initHaply();  
  
  
  world.draw();

  frameRate(baseFrameRate);

  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}

void draw(){

  if(ui.getIsStart() && ui.getCurrentLevel() == 1){
    println("This level");
    world = ui.getWorld();
    ui.initCollisions();

    world.add(ball);
    world.add(basePlate);

    // addSensor();
  }else if(renderingForce == false){
    background(255);
    
    world.draw();
  }
}

class SimulationThread implements Runnable{
  public void run(){
    renderingForce = true;
    
    if(haplyBoard.data_available() && sensor != null){
     /* GET END-EFFECTOR STATE (TASK SPACE) */
        

      if(ui.getIsReset()){
        posEE.set(0,0);
        ui.setIsReset(false);
      }else{
        widgetOne.device_read_data();
    
        angles.set(widgetOne.get_device_angles()); 
        posEE.set(widgetOne.get_device_position(angles.array()));
        posEE.set(posEE.copy().mult(200));
      }
    
      sensor.setToolPosition(WORLD_WIDTH/2 - (2.5*posEE.x), (BOUNDARY_SIZE) + (2*posEE.y) - 6); 
      sensor.updateCouplingForce();
    }
    
    if(ui.getCurrentLevel() == 1){
      elasticCollisions();
    }

    //Adjust the UI controls
    ui.setPlateVelocity((float) Math.sqrt(Math.pow(plateVelocityX, 2) + Math.pow(plateVelocityY, 2)));
    ui.setBallVelocity((float) Math.sqrt(Math.pow(ballVelocityX, 2) + Math.pow(ballVelocityY, 2)));
    
    if(sensor != null){
      sensor.h_avatar.setDamping(dampingForce);

      // if(ui.getIsHapticsOn()){
      //   fEE.set(sensor.getVirtualCouplingForceX(), sensor.getVirtualCouplingForceY());        
      // }else{
      //   fEE.set(0,0);
      // }
      // torques.set(widgetOne.set_device_torques(fEE.array()));
      //   widgetOne.device_write_torques();
      
    }
    
    

    world.step();

    renderingForce = false;
  }
}

void elasticCollisions(){
  if(basePlate.isTouchingBody(ball)){

      if(ballVelocityX == 0 && ballVelocityY == 0 ){
        ballVelocityX = 10;
        ballVelocityY = -10;
      }else{
          ballVelocityX = (plateMass* plateVelocityX + ballMass * ballVelocityX - plateMass * (plateVelocityX * pVelocityDecay))/ ballMass;
          ballVelocityY = (plateMass * plateVelocityY + ballMass * ballVelocityY - plateMass * (plateVelocityY + pVelocityDecay))/ ballMass;
      }

      
      plateVelocityX *= pVelocityDecay;
      plateVelocityY *= pVelocityDecay;
      // ball.addImpulse(basePlate.getForceX(), basePlate.getForceY() -1);
      // basePlate.resetForces();
      ball.setVelocity(ballVelocityX, ballVelocityY);
    }
    basePlate.setVelocity(plateVelocityX, plateVelocityY);
}

void keyPressed(){
  if(key == CODED){
    if(keyCode == UP){
      plateVelocityY -= 50;
    }else if(keyCode == DOWN){
      plateVelocityY += 50;
    }else if(keyCode == LEFT){
      plateVelocityX -= 50;
    }else if(keyCode == RIGHT){
      plateVelocityX += 50;
    }
  }else{
    switch (key) {
      case 'q':
         ui.setPlateVelocity( ui.getPlateVelocity() - 10);
        if( ui.getPlateVelocity() == 0){
          basePlate.setVelocity(0,0);
        }else{
          plateVelocityX = Math.signum(plateVelocityX) * (Math.abs(plateVelocityX) - 10);
          plateVelocityY = Math.signum(plateVelocityY) * (Math.abs(plateVelocityY) - 10);
        }
        isPlateVelocityChanged = true;
        break;
      case 'w':
         ui.setPlateVelocity( ui.getPlateVelocity() + 10);
        if( ui.getPlateVelocity() < 500){
          plateVelocityX = Math.signum(plateVelocityX) * (Math.abs(plateVelocityX) + 10);
          plateVelocityY = Math.signum(plateVelocityY) * (Math.abs(plateVelocityY) + 10);
        }
        isPlateVelocityChanged = true;
        break;
      case 'e':
        ui.setPlateMass(ui.getPlateMass()- 1);
        if(plateMassFactor > 1){
          basePlate.setWidth(basePlate.getWidth() - (plateMassFactor/10));
          basePlate.setHeight(basePlate.getHeight() - (plateMassFactor/10));
          plateMassFactor--;
        }       
        break;
      case 'r':
        ui.setPlateMass(ui.getPlateMass() + 1);
        if(plateMassFactor < 10){
          plateMassFactor++;
          basePlate.setWidth(basePlate.getWidth() + (plateMassFactor/10));
          basePlate.setHeight(basePlate.getHeight() + (plateMassFactor/10));
        }         
        break;
      case 'u':
        ui.setBallVelocity(ui.getBallVelocity() - 10);
        if(ui.getBallVelocity() == 0){
          ball.setVelocity(0,0);
        }else{
          ballVelocityX = Math.signum(ballVelocityX) * (Math.abs(ballVelocityX) - 10);
          ballVelocityY = Math.signum(ballVelocityY) * (Math.abs(ballVelocityY) - 10);
        }
        isBallVelocityChanged = true;
        break;
      case 'i':
        ui.setBallVelocity(ui.getBallVelocity() + 10);
        if(ui.getBallVelocity() < 500){
          ballVelocityX = Math.signum(ballVelocityX) * (Math.abs(ballVelocityX) + 10);
          ballVelocityY = Math.signum(ballVelocityY) * (Math.abs(ballVelocityY) + 10);
        }
        isBallVelocityChanged = true;
        break;
      case 'o':
        ui.setBallMass(ui.getBallMass() - 1);
        if(ballMassFactor > 1){
          ball.setSize(ball.getSize() - (ballMassFactor/10));
          ballMassFactor--;
        }       
        break;
      case 'p':
        ui.setBallMass(ui.getBallMass() + 1);
        if(ballMassFactor < 10){
          ballMassFactor++;
          ball.setSize(ball.getSize() + (ballMassFactor/10));
        }  
        break;
    }
    if(isPlateVelocityChanged){
      basePlate.setDensity((plateMass * plateMassFactor) / basePlate.getWidth() * basePlate.getHeight());
      isPlateVelocityChanged = false;
    }
      
    if(isBallVelocityChanged){
      ball.setDensity((float) ((ballMass * ballMassFactor)/ Math.PI * Math.pow(ballRadius , 2)));
      isBallVelocityChanged = false;
    }
  }
  
}

