import controlP5.*;
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
import java.lang.Math;


private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);

ControlP5 cp5;

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
FBox topBoundary, bottomBoundary, leftBoundary, rightBoundary, varBack;
float worldWidth = 100.0;
float worldHeight = 70.0;
float boundarySize = 2;

Knob plateVelocity, ballVelocity, plateM, ballM;

// World Object declarations
FBox basePlate;
FCircle ball;

// Object parameter variables
float platePositionX = boundarySize  * 5;
float platePositionY =  worldHeight/2;
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


void setup() {
  /* put setup code here, run once: */

  /* screen size definition */
  size(1000, 700);

  /* Haply Board Setup */
  haplyBoard = new Board(this, Serial.list()[0], 0);
  pantograph = new Pantograph();

  widgetOne = new Device(widgetOneID, haplyBoard);
  widgetOne.set_mechanism(pantograph);
  widgetOne.add_actuator(1, CCW, 2);
  widgetOne.add_actuator(2, CW, 1); 
  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  widgetOne.add_encoder(2, CW, -61, 10752, 1); 
  
  widgetOne.device_set_parameters();

  /* Physics and world object creation */
  hAPI_Fisica.init(this); 
  hAPI_Fisica.setScale(pixelsPerMeter); 
  world = new FWorld();
  // world.setEdges();

  /* GUI setup */
  smooth();
  cp5 = new ControlP5(this);

  plateVelocity =  cp5.addKnob("Plate Speed")
                      .setRange(0,500)
                      .setValue(0)
                      .setPosition(210, 570)
                      .setRadius(50)
                      .setDragDirection(Knob.VERTICAL);
  
  plateM =  cp5.addKnob("Plate Mass")
                      .setRange(1,10)
                      .setValue(0)
                      .setPosition(370, 570)
                      .setRadius(50)
                      .setDragDirection(Knob.VERTICAL);

  ballVelocity =  cp5.addKnob("ball Speed")
                      .setRange(0,500)
                      .setValue(0)
                      .setPosition(530, 570)
                      .setRadius(50)
                      .setDragDirection(Knob.VERTICAL);
  
  ballM =  cp5.addKnob("Ball Mass")
                      .setRange(1,10)
                      .setValue(0)
                      .setPosition(690, 570)
                      .setRadius(50)
                      .setDragDirection(Knob.VERTICAL);   

  varBack = new FBox(worldWidth, 15);
  varBack.setPosition(worldWidth/2, worldHeight - 7.5);
  varBack.setStaticBody(true);
  varBack.setFill(100);                   
  
  topBoundary = new FBox(worldWidth, boundarySize);
  topBoundary.setPosition(worldWidth/2, boundarySize/2);
  topBoundary.setFill(10);
  topBoundary.setStaticBody(true);
  
  bottomBoundary = new FBox(worldWidth,boundarySize);
  bottomBoundary.setPosition(worldWidth/2, worldHeight- (boundarySize/2 + 15));
  bottomBoundary.setFill(10);
  bottomBoundary.setStaticBody(true);

  leftBoundary = new FBox(boundarySize, worldHeight - 15);
  leftBoundary.setPosition(boundarySize/2, worldHeight/2 - 7.5);
  leftBoundary.setFill(10);
  leftBoundary.setStaticBody(true);

  rightBoundary = new FBox(boundarySize, worldHeight - 15);
  rightBoundary.setPosition(worldWidth - boundarySize/2, worldHeight/2 - 7.5);
  rightBoundary.setFill(10);
  rightBoundary.setStaticBody(true);

  basePlate = new FBox(boundarySize , boundarySize * 5 );
  basePlate.setPosition(platePositionX, platePositionY);
  basePlate.setFill(100);
  basePlate.setNoStroke();
  basePlate.setRotatable(false);
  basePlate.setHaptic(true);
  basePlate.setDensity((plateMass * plateMassFactor) / basePlate.getWidth() * basePlate.getHeight());
  basePlate.setDamping(20);

  ball = new FCircle(2 * ballRadius);
  ball.setPosition( worldWidth/4, worldHeight/2);
  ball.setFill(0, 0, 150);
  // ball.setHaptic(true);
  ball.setRestitution(1);
  // ball.setFriction(0);
  ball.setDensity((float) ((ballMass * ballMassFactor)/ Math.PI * Math.pow(ballRadius , 2)));
  ball.setDamping(0);
  
  world.add(topBoundary);
  world.add(bottomBoundary);
  world.add(leftBoundary);
  world.add(rightBoundary);
  world.add(varBack);
  world.add(ball);
  world.add(basePlate);

  /* Setup the Virtual Coupling Contact Rendering Technique */
  //sensor = new HVirtualCoupling((0.5)); 
  //sensor.h_avatar.setDensity(50); 
  //sensor.h_avatar.setFill(255,0,0); 
  //sensor.h_avatar.setSensor(true);

  
  world.setGravity(0,0);
  world.setGrabbable(false);
  //sensor.init(world, worldWidth/2, boundarySize + 5);
  
  world.draw();

  frameRate(baseFrameRate);

  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}

void draw(){
  if(renderingForce == false){
    background(200);
    world.draw();
  }
}

class SimulationThread implements Runnable{
  public void run(){
    renderingForce = true;

    //if(haplyBoard.data_available()){
    //  /* GET END-EFFECTOR STATE (TASK SPACE) */
    //  widgetOne.device_read_data();
    
    //  angles.set(widgetOne.get_device_angles()); 
    //  posEE.set(widgetOne.get_device_position(angles.array()));
    //  posEE.set(posEE.copy().mult(200));  
    //}

    //sensor.setToolPosition(worldWidth/4 - (2.5*(posEE).x), (boundarySize) + (2*(posEE).y) - 6); 
    //sensor.updateCouplingForce();

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
    plateVelocity.setValue((float) Math.sqrt(Math.pow(plateVelocityX, 2) + Math.pow(plateVelocityY, 2)));
    ballVelocity.setValue((float) Math.sqrt(Math.pow(ballVelocityX, 2) + Math.pow(ballVelocityY, 2)));
    
    //sensor.h_avatar.setDamping(dampingForce);
    // fEE.set(sensor.getVirtualCouplingForceX(), sensor.getVirtualCouplingForceY());
    
    //torques.set(widgetOne.set_device_torques(fEE.array()));
    //widgetOne.device_write_torques();

    world.step();

    renderingForce = false;
  }
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
        plateVelocity.setValue(plateVelocity.getValue() - 10);
        if(plateVelocity.getValue() == 0){
          basePlate.setVelocity(0,0);
        }else{
          plateVelocityX = Math.signum(plateVelocityX) * (Math.abs(plateVelocityX) - 10);
          plateVelocityY = Math.signum(plateVelocityY) * (Math.abs(plateVelocityY) - 10);
        }
        isPlateVelocityChanged = true;
        break;
      case 'w':
        plateVelocity.setValue(plateVelocity.getValue() + 10);
        if(plateVelocity.getValue() < 500){
          plateVelocityX = Math.signum(plateVelocityX) * (Math.abs(plateVelocityX) + 10);
          plateVelocityY = Math.signum(plateVelocityY) * (Math.abs(plateVelocityY) + 10);
        }
        isPlateVelocityChanged = true;
        break;
      case 'e':
        plateM.setValue(plateM.getValue()- 1);
        if(plateMassFactor > 1){
          basePlate.setWidth(basePlate.getWidth() - (plateMassFactor/10));
          basePlate.setHeight(basePlate.getHeight() - (plateMassFactor/10));
          plateMassFactor--;
        }       
        break;
      case 'r':
        plateM.setValue(plateM.getValue() + 1);
        if(plateMassFactor < 10){
          plateMassFactor++;
          basePlate.setWidth(basePlate.getWidth() + (plateMassFactor/10));
          basePlate.setHeight(basePlate.getHeight() + (plateMassFactor/10));
        }         
        break;
      case 'u':
        ballVelocity.setValue(ballVelocity.getValue() - 10);
        if(ballVelocity.getValue() == 0){
          ball.setVelocity(0,0);
        }else{
          ballVelocityX = Math.signum(ballVelocityX) * (Math.abs(ballVelocityX) - 10);
          ballVelocityY = Math.signum(ballVelocityY) * (Math.abs(ballVelocityY) - 10);
        }
        isBallVelocityChanged = true;
        break;
      case 'i':
        ballVelocity.setValue(ballVelocity.getValue() + 10);
        if(ballVelocity.getValue() < 500){
          ballVelocityX = Math.signum(ballVelocityX) * (Math.abs(ballVelocityX) + 10);
          ballVelocityY = Math.signum(ballVelocityY) * (Math.abs(ballVelocityY) + 10);
        }
        isBallVelocityChanged = true;
        break;
      case 'o':
        ballM.setValue(ballM.getValue() - 1);
        if(ballMassFactor > 1){
          ball.setSize(ball.getSize() - (ballMassFactor/10));
          ballMassFactor--;
        }       
        break;
      case 'p':
        ballM.setValue(ballM.getValue() + 1);
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