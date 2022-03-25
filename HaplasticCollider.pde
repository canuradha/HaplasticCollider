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
FCircle ball, bouncey_ball_1, bouncey_ball_2, well_large, well_medium, well_small;

FLine line_;

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

//Gravity well variable declarations
float xE, yE = 0; 
float grav_const = 6.7;

float hap_mass = 8;
float mass_large = 20;
float mass_medium = 12; 
float mass_small = 2; 

float gravforce_x = 0; 
float gravforce_y = 0; 
float gravforce = 0; 

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

  sensor.init(world, WORLD_WIDTH/2, BOUNDARY_SIZE + 5);
}

void removeSensor(){
  sensor = null;
}

FCircle initBall(float radius, float x, float y, float ballFriction, boolean isHaptic){
  FCircle tempBall = new FCircle(radius);
  tempBall.setPosition( WORLD_WIDTH/4, WORLD_HEIGHT/2); //Should this be X and Y
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

FCircle initWell(float radius, float pos_x, float pos_y){
  FCircle tempWell = new FCircle(radius);
  tempWell.setPosition(pos_x, pos_y);
  tempWell.setStaticBody(true);
  tempWell.setSensor(true);
  tempWell.setFill(0);
  return tempWell;
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
  
  well_large = initWell(15, WORLD_WIDTH/2, WORLD_HEIGHT/2.3);
  //well_large = initWell(15, WORLD_WIDTH/4, WORLD_HEIGHT/3.5);
  //well_medium = initWell(10, WORLD_WIDTH/1.8, WORLD_HEIGHT/1.8);
  //well_small = initWell(5, WORLD_WIDTH/1.2, WORLD_HEIGHT/3);
  
  ball = initBall(2* ballRadius, WORLD_WIDTH/4, WORLD_HEIGHT/2, 0.0f, false);
  basePlate = initBox(BOUNDARY_SIZE, BOUNDARY_SIZE * 5, platePositionX, platePositionY, false);
  bouncey_ball_1 = initBall(2* ballRadius, WORLD_WIDTH/2, WORLD_HEIGHT/2, 0.0f, false);
  bouncey_ball_1.setVelocity(-20,15);
  
  bouncey_ball_2 = initBall(20* ballRadius, WORLD_WIDTH/2, WORLD_HEIGHT/2, 0.0f, false);
  bouncey_ball_2.setVelocity(-20,15);
  


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
  }
  else if(ui.getIsStart() && ui.getCurrentLevel() == 2){
    println("This level");
    world = ui.getWorld();
    ui.initElasticCollisions();
    world.add(bouncey_ball_1);
    addSensor();
    println("Second level");
    

 }else if(ui.getIsStart() && ui.getCurrentLevel() == 3){
    println("This level");
    world = ui.getWorld();
    ui.initInelasticCollisions();
    world.add(bouncey_ball_2);
    addSensor();
    println("Third level");
 }
 
 else if(ui.getIsStart() && ui.getCurrentLevel()==4){
    world = ui.getWorld();
    
    ui.initGravity();    
    world.add(well_large);
    //world.add(well_medium);
    //world.add(well_small);
    addSensor();
    //arrow(xE, yE, fEE.x, fEE.y);
    //line(200, 100, 600, 400);

 }
    
 else if(renderingForce == false){
    background(255);
    //arrow(xE, yE, fEE.x, fEE.y);
    world.draw();
  }
}

class SimulationThread implements Runnable{
  public void run(){
    renderingForce = true;

     if(haplyBoard.data_available()){
      /* GET END-EFFECTOR STATE (TASK SPACE) */
       widgetOne.device_read_data();
    
       angles.set(widgetOne.get_device_angles()); 
       posEE.set(widgetOne.get_device_position(angles.array()));
       posEE.set(posEE.copy().mult(200));  
       
       xE = pixelsPerMeter*posEE.x;
       yE = pixelsPerMeter*posEE.y;
     }

    if(sensor != null){
       sensor.setToolPosition(WORLD_WIDTH/2 - (2.5*(posEE).x), (BOUNDARY_SIZE) + (2*(posEE).y) - 6); 
       sensor.updateCouplingForce();
     }
    
    if(sensor != null){
      fEE.set(-sensor.getVirtualCouplingForceX(), sensor.getVirtualCouplingForceY());
      fEE.div(100000); //dynes to newtons
    }
 
    if(ui.getCurrentLevel() == 1){
      elasticCollisions();
    }
    
    if (ui.getCurrentLevel() == 4){
      gravforce_arr1 = calcGravForces(well_large, mass_large);      
      //gravforce_arr2 = calcGravForces(well_medium, mass_medium); 
      //gravforce_arr3 = calcGravForces(well_small, mass_small);
           
      //gravforce_totx = gravforce_arr1[0]+gravforce_arr2[0]+gravforce_arr3[0];
      //gravforce_toty = gravforce_arr1[1]+gravforce_arr2[1]+gravforce_arr3[1];
      
      gravforce_totx = gravforce_arr1[0];
      gravforce_toty = gravforce_arr1[1];
         
      fEE.set(gravforce_totx, gravforce_toty);
      
    }
        

    //Adjust the UI controls
    ui.setPlateVelocity((float) Math.sqrt(Math.pow(plateVelocityX, 2) + Math.pow(plateVelocityY, 2)));
    ui.setBallVelocity((float) Math.sqrt(Math.pow(ballVelocityX, 2) + Math.pow(ballVelocityY, 2)));
       
     torques.set(widgetOne.set_device_torques(fEE.array()));
     widgetOne.device_write_torques();

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

void contactStarted(FContact c){
  if (ui.getCurrentLevel() == 2){

    FBody body1 = c.getBody1();
    FBody body2 = c.getBody2();
  
    if (body1.isSensor() == true || body2.isSensor() == true){
      return;
    }
  
      commit_elastic_results(c, body1, body2);
    }
    
  if (ui.getCurrentLevel() == 3){
    FBody body1 = c.getBody1();
    FBody body2 = c.getBody2();
  
    if (body1.isSensor() == true || body2.isSensor() == true){
      return;
    }
  
      commit_inelastic_results(c, body1, body2, 0.5);
    }
    
    print("looped \n");
}

void commit_elastic_results (FContact c, FBody body1, FBody body2){
  
 float Vx1_i = body1.getVelocityX();
 float Vy1_i = body1.getVelocityY();
 float Vx2_i = body2.getVelocityX();
 float Vy2_i = body2.getVelocityY();
 
  float m1 = body1.getMass();
  float m2 = body2.getMass();
 
  float v1x_f =  (m1-m2)*Vx1_i/(m1+m2) + 2*m2*Vx2_i/(m1+m2);
  float v1y_f =  (m1-m2)*Vy1_i/(m1+m2) + 2*m2*Vy2_i/(m1+m2);
  float v2x_f =  (m2-m1)*Vx2_i/(m1+m2) + 2*m1*Vx1_i/(m1+m2);
  float v2y_f =  (m2-m1)*Vy2_i/(m1+m2) + 2*m1*Vy1_i/(m1+m2);
  
  float KExf_total = 0.5*m1*v1x_f*v1x_f + 0.5*m2*v2x_f*v2x_f;
  float KEyf_total = 0.5*m1*v1y_f*v1y_f + 0.5*m2*v2y_f*v2y_f;
  
  double V1_rat = Math.sqrt(v1x_f*v1x_f + v1y_f*v1y_f)/Math.sqrt(Vx1_i*Vx1_i + Vy1_i*Vy1_i);
  double V2_rat = Math.sqrt(v2x_f*v2x_f + v2y_f*v2y_f)/Math.sqrt(Vx2_i*Vx2_i + Vy2_i*Vy2_i);
  
  if (V1_rat >100000){
    V1_rat = 0;
  }
   if (V2_rat >100000){
    V2_rat = 0;
  }
  
  body1.setRestitution(abs((float)V1_rat));
  body2.setRestitution(abs((float)V2_rat));
  

    fEE.set(c.getNormalX()*KExf_total, c.getNormalY()*KEyf_total);

  
  
  torques.set(widgetOne.set_device_torques(fEE.array()));
  widgetOne.device_write_torques();
  delay(3);
  print("delayed \n");
  
}

void commit_inelastic_results (FContact c, FBody body1, FBody body2, float KE_loss_fract){
  
  float Vx1_i = body1.getVelocityX();
  float Vy1_i = body1.getVelocityY();
  float Vx2_i = body2.getVelocityX();
  float Vy2_i = body2.getVelocityY();
 
  float m1 = body1.getMass();
  float m2 = body2.getMass();
  
  float pxi_total = m1*Vx1_i + m2*Vx2_i;
  float pyi_total = m1*Vy1_i + m2*Vy2_i;
  
  float KExi_total = 0.5*m1*Vx1_i*Vx1_i + 0.5*m2*Vx2_i*Vx2_i;
  float KEyi_total = 0.5*m1*Vy1_i*Vy1_i + 0.5*m2*Vy2_i*Vy2_i;
  float KEx_loss =  KE_loss_fract*KExi_total;
  float KEy_loss =  KE_loss_fract*KEyi_total;
  float KExf_total = KExi_total - KEx_loss;
  float KEyf_total = KEyi_total - KEy_loss;
 
  float v1x_f =  (m1-m2)*Vx1_i/(m1+m2) + 2*m2*Vx2_i/(m1+m2);
  float v1y_f =  (m1-m2)*Vy1_i/(m1+m2) + 2*m2*Vy2_i/(m1+m2);
  float v2x_f =  (m2-m1)*Vx2_i/(m1+m2) + 2*m1*Vx1_i/(m1+m2);
  float v2y_f =  (m2-m1)*Vy2_i/(m1+m2) + 2*m1*Vy1_i/(m1+m2);
  
  double V1_rat = Math.sqrt(v1x_f*v1x_f + v1y_f*v1y_f)/Math.sqrt(Vx1_i*Vx1_i + Vy1_i*Vy1_i);
  double V2_rat = Math.sqrt(v2x_f*v2x_f + v2y_f*v2y_f)/Math.sqrt(Vx2_i*Vx2_i + Vy2_i*Vy2_i);
  
  if (V1_rat >100000){
    V1_rat = 0;
  }
   if (V2_rat >100000){
    V2_rat = 0;
  }
  
  body1.setRestitution(KE_loss_fract*abs((float)V1_rat));
  body2.setRestitution(KE_loss_fract*abs((float)V2_rat));
  
  fEE.set(c.getNormalX()*KExf_total, c.getNormalY()*KEyf_total);
  torques.set(widgetOne.set_device_torques(fEE.array()));
  widgetOne.device_write_torques();
  
  delay(3);
  bouncey_ball_2.setSize(bouncey_ball_2.getSize()*0.9);
  
}


public float[] calcGravForces(FBody well, float mass){
    distance = (float)Math.sqrt(Math.pow(sensor.getToolPositionX()-well.getX(), 2)+Math.pow(sensor.getAvatarPositionY()-well.getY(),2));  //calculate distance between the two bodies
    gravforce = ((grav_const)*hap_mass*mass)/((float)Math.pow(distance,2));   //calculate gravitational force according to the universal gravitation equation        
    
    angle = (float)Math.acos(abs(sensor.getToolPositionX()-well.getX())/distance);  //use inverse cos to find the angle 
    
    direction_x = Math.signum(sensor.getToolPositionX()-well.getX());  //get the direction that the x-force should be applied
    direction_y = Math.signum(well.getY()-sensor.getToolPositionY());  //get the direction that the y-force should be applied
    
    gravforce_x = direction_x*gravforce*(float)Math.cos(angle);  //use the angle to get the x-comp of gravitational force
    gravforce_y = direction_y*gravforce*(float)Math.sin(angle);  //use the angle to get the y-comp of gravitational force
     
    float[] gravforce_arr = new float[]{gravforce_x, gravforce_y};
    print("Yesssssss \n");
    //line(200, 100, 600, 400);
    return gravforce_arr; 
}

void arrow(float x1, float y1, float x2, float y2){
  x2=x2*0.5;
  y2=y2*0.5;
  //WORLD_WIDTH = 80; WORLD_HEIGHT = 70;
  x1 = -x1+(WORLD_WIDTH/2*pixelsPerMeter);
  y1=y1-(WORLD_HEIGHT/2*pixelsPerMeter)-1000;
  y1=500;
  //700 AND 30
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
