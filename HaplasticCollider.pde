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

float dampingForce = 50;
float virtualCouplingX = 0;
float virtualCouplingY = 0;
float dampingScale = 100000;

//Gravity well variable declarations
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

//Collison variable initiliizations 
 float Vx1_i;
 float Vy1_i;
 float Vx2_i;
 float Vy2_i;
 
  float m1;
  float m2;
 
  float v1x_f;
  float v1y_f;
  float v2x_f;
  float v2y_f;
  
  
  float KExf_total;
  float KEyf_total;
  
  double V1_rat;
  double V2_rat;
  
  float KExi_total;
  float KEyi_total;
  float KEx_loss;
  float KEy_loss;
  
  double Perc;

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
  sensor.h_avatar.setDensity(400); 
  sensor.h_avatar.setFill(255,0,0); 
  // sensor.h_avatar.setSensor(true);

  if(ui != null)
    ui.setSensor(sensor);

  sensor.init(world, WORLD_WIDTH/2, BOUNDARY_SIZE + 5);
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
  
  // ball = initBall(2* ballRadius, WORLD_WIDTH/4, WORLD_HEIGHT/2, 0.0f, false);
  // basePlate = initBox(BOUNDARY_SIZE, BOUNDARY_SIZE * 5, platePositionX, platePositionY, false);
 
  //Initialization of balls for Modules 1 and 2
  bouncey_ball_1 = initBall(4* ballRadius, WORLD_WIDTH/2, WORLD_HEIGHT/2, 0.0f, false);
  bouncey_ball_1.setVelocity(25,25);
  
  bouncey_ball_2 = initBall(10* ballRadius, WORLD_WIDTH/2, WORLD_HEIGHT/2, 0.0f, false);
  bouncey_ball_2.setVelocity(50,50);
 
 //Initialization of Grav wells for module 3
  
  well_large = initWell(15, WORLD_WIDTH/4, WORLD_HEIGHT/3.5);
  well_medium = initWell(10, WORLD_WIDTH/1.8, WORLD_HEIGHT/1.8);
  well_small = initWell(5, WORLD_WIDTH/1.2, WORLD_HEIGHT/3);


  /* Haply Board Setup */
  initHaply();  
  
  
  world.draw();

  frameRate(baseFrameRate);

  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}

void draw(){

  //if(ui.getIsStart() && ui.getCurrentLevel() == 1){
  //  println("This level");
  //  world = ui.getWorld();
  //  ui.initCollisions();

  //  world.add(ball);
  //  world.add(basePlate);

    // addSensor();
  //}
  if(ui.getIsStart()){
    world =ui.getWorld();

    switch(ui.getCurrentLevel()){
      case 1:
        ui.initElasticCollisions();
        world.add(bouncey_ball_1);
        addSensor();
        println("Second level");
        break;

      case 2:
        ui.initInelasticCollisions();
        world.add(bouncey_ball_2);
        addSensor();
        println("Third level");
        break;
      
      case 3:
        ui.initGravity();   
        addSensor();
        world.add(well_large);
        world.add(well_medium);
        world.add(well_small);
        break;

      case 4:
        ui.initAllCollisions();
        world.add(bouncey_ball_1);
        world.add(bouncey_ball_2);
        addSensor();
        break;

    }
  } else if(renderingForce == false){
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
        widgetOne.device_set_parameters();
        ui.setIsReset(false);
      }else{
        widgetOne.device_read_data();
    
        angles.set(widgetOne.get_device_angles()); 
        posEE.set(widgetOne.get_device_position(angles.array()));
      }

      posEE.set(posEE.copy().mult(200));
    
      sensor.setToolPosition(WORLD_WIDTH/2 - (2.5*posEE.x), (BOUNDARY_SIZE) + (2*posEE.y) - 7); 
      sensor.updateCouplingForce();
    }

    
  
    

    //Adjust the UI controls
    ui.setPlateVelocity((float) Math.sqrt(Math.pow(plateVelocityX, 2) + Math.pow(plateVelocityY, 2)));
    ui.setBallVelocity((float) Math.sqrt(Math.pow(ballVelocityX, 2) + Math.pow(ballVelocityY, 2)));
    
    if(sensor != null){
      sensor.h_avatar.setDamping(dampingForce);

      if(ui.getIsHapticsOn()){
        fEE.set(-sensor.getVirtualCouplingForceX(), sensor.getVirtualCouplingForceY());        
      }else{
        fEE.set(0,0);
      }
      fEE.div(dampingScale);
      torques.set(widgetOne.set_device_torques(fEE.array()));
      widgetOne.device_write_torques();
      
    }
    
    world.step();

    renderingForce = false;
  }
}

//void elasticCollisions(){
//  if(basePlate.isTouchingBody(ball)){

//      if(ballVelocityX == 0 && ballVelocityY == 0 ){
//        ballVelocityX = 10;
//        ballVelocityY = -10;
//      }else{
//          ballVelocityX = (plateMass* plateVelocityX + ballMass * ballVelocityX - plateMass * (plateVelocityX * pVelocityDecay))/ ballMass;
//          ballVelocityY = (plateMass * plateVelocityY + ballMass * ballVelocityY - plateMass * (plateVelocityY + pVelocityDecay))/ ballMass;
//      }

      
//      plateVelocityX *= pVelocityDecay;
//      plateVelocityY *= pVelocityDecay;
//      // ball.addImpulse(basePlate.getForceX(), basePlate.getForceY() -1);
//      // basePlate.resetForces();
//      ball.setVelocity(ballVelocityX, ballVelocityY);
//    }
//    basePlate.setVelocity(plateVelocityX, plateVelocityY);
  
  
//}


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

void contactStarted(FContact c){ //Called on contact between any 2 objects

  FBody body1 = c.getBody1(); //Read bodies involved
  FBody body2 = c.getBody2();


  if (body1.isSensor() == true || body2.isSensor() == true ){ //Exit function if one of the objects is a sensor (non-solid)
  
  // add if haptics due to boundary contacts needs to be skipped -> || body1.getName().contains("Boundary") || body2.getName().contains("Boundary")
    return;
  }
  if(ui.getIsHapticsOn()){
    if (ui.getCurrentLevel() == 1){ //Check for first level
  
      commit_elastic_results(c, body1, body2); //Elastic collision function

    }else if (ui.getCurrentLevel() == 2){ //Check for second level
      
      commit_inelastic_results(c, body1, body2, 0.5); //Inelastic Collision function
      
    }else if (ui.getCurrentLevel() == 3){

      gravforce_arr1 = calcGravForces(well_large, mass_large);      
      gravforce_arr2 = calcGravForces(well_medium, mass_medium); 
      gravforce_arr3 = calcGravForces(well_small, mass_small);
      
      gravforce_totx = gravforce_arr1[0]+gravforce_arr2[0]+gravforce_arr3[0];
      gravforce_toty = gravforce_arr1[1]+gravforce_arr2[1]+gravforce_arr3[1];
      
      fEE.set(gravforce_totx, gravforce_toty);
      
    }
  }
  

  fEE.div(dampingScale);
  torques.set(widgetOne.set_device_torques(fEE.array()));
  widgetOne.device_write_torques();
    
}

void commit_elastic_results (FContact c, FBody body1, FBody body2){ //Elastic collision function, determines resulting speeds after collision
  
  Vx1_i = body1.getVelocityX(); //read velocities just before impact
  Vy1_i = body1.getVelocityY();
  Vx2_i = body2.getVelocityX();
  Vy2_i = body2.getVelocityY();
 
  m1 = body1.getMass(); //Read masses of objects involved
  m2 = body2.getMass();
 
  v1x_f =  (m1-m2)*Vx1_i/(m1+m2) + 2*m2*Vx2_i/(m1+m2); //Determine velocities after impact
  v1y_f =  (m1-m2)*Vy1_i/(m1+m2) + 2*m2*Vy2_i/(m1+m2);
  v2x_f =  (m2-m1)*Vx2_i/(m1+m2) + 2*m1*Vx1_i/(m1+m2);
  v2y_f =  (m2-m1)*Vy2_i/(m1+m2) + 2*m1*Vy1_i/(m1+m2);
    
  KExf_total = 0.5*m1*v1x_f*v1x_f + 0.5*m2*v2x_f*v2x_f; //Determine final kinetic energies
  KEyf_total = 0.5*m1*v1y_f*v1y_f + 0.5*m2*v2y_f*v2y_f;
  
  V1_rat = Math.sqrt(v1x_f*v1x_f + v1y_f*v1y_f)/Math.sqrt(Vx1_i*Vx1_i + Vy1_i*Vy1_i); //determine ratio of final to intitial speeds
  V2_rat = Math.sqrt(v2x_f*v2x_f + v2y_f*v2y_f)/Math.sqrt(Vx2_i*Vx2_i + Vy2_i*Vy2_i);
  
  if (V1_rat >100000){ //Conditional to prevent massless objects being an issue with infinite ratios
    V1_rat = 0;
  }
   if (V2_rat >100000){
    V2_rat = 0;
  }
  
  body1.setRestitution(abs((float)V1_rat)); //use speed ratios to set restitution (amount of velocity change on impacts)
  body2.setRestitution(abs((float)V2_rat));
  

  fEE.set(150*c.getNormalX()*KExf_total, 150*c.getNormalY()*KEyf_total);  
 
  //Determine change in slider based on percent of max speed (set as 50 in X, 50 in Y)
  if (body1 == bouncey_ball_1){
    Perc =  Math.sqrt(v1x_f*v1x_f + v1y_f*v1y_f)/Math.sqrt(50*50 + 50*50);
  }
  
   else if (body2 == bouncey_ball_1){
    Perc =  Math.sqrt(v2x_f*v2x_f + v2y_f*v2y_f)/Math.sqrt(50*50 + 50*50);
  }
  
  ui.Impact_Slider.setValue((float) Perc*100); //update slider
  double D = 20* (float) Perc;
  delay((int) D);
  
 
  
}

void commit_inelastic_results (FContact c, FBody body1, FBody body2, float KE_loss_fract){
  
  Vx1_i = body1.getVelocityX();
  Vy1_i = body1.getVelocityY();
  Vx2_i = body2.getVelocityX();
  Vy2_i = body2.getVelocityY();
 
  m1 = body1.getMass();
  m2 = body2.getMass();
  
  KExi_total = 0.5*m1*Vx1_i*Vx1_i + 0.5*m2*Vx2_i*Vx2_i;
  KEyi_total = 0.5*m1*Vy1_i*Vy1_i + 0.5*m2*Vy2_i*Vy2_i;
  KEx_loss =  KE_loss_fract*KExi_total;
  KEy_loss =  KE_loss_fract*KEyi_total;
  KExf_total = KExi_total - KEx_loss;
  KEyf_total = KEyi_total - KEy_loss;
 
  v1x_f =  (m1-m2)*Vx1_i/(m1+m2) + 2*m2*Vx2_i/(m1+m2);
  v1y_f =  (m1-m2)*Vy1_i/(m1+m2) + 2*m2*Vy2_i/(m1+m2);
  v2x_f =  (m2-m1)*Vx2_i/(m1+m2) + 2*m1*Vx1_i/(m1+m2);
  v2y_f =  (m2-m1)*Vy2_i/(m1+m2) + 2*m1*Vy1_i/(m1+m2);
  
  V1_rat = Math.sqrt(v1x_f*v1x_f + v1y_f*v1y_f)/Math.sqrt(Vx1_i*Vx1_i + Vy1_i*Vy1_i);
  V2_rat = Math.sqrt(v2x_f*v2x_f + v2y_f*v2y_f)/Math.sqrt(Vx2_i*Vx2_i + Vy2_i*Vy2_i);
  
  if (V1_rat >100000){
    V1_rat = 0;
  }
   if (V2_rat >100000){
    V2_rat = 0;
  }
  
  body1.setRestitution(KE_loss_fract*abs((float)V1_rat)); //set restitution incorporating energy loss due to inelastic collision.
  body2.setRestitution(KE_loss_fract*abs((float)V2_rat));
  
  fEE.set(150*c.getNormalX()*KExf_total, 150*c.getNormalY()*KEyf_total);
  
  
  if (body1 == bouncey_ball_2){
    Perc =  Math.sqrt(v1x_f*v1x_f + v1y_f*v1y_f)/Math.sqrt(50*50 + 50*50);
  }
  
   else if (body2 == bouncey_ball_2){
    Perc =  Math.sqrt(v2x_f*v2x_f + v2y_f*v2y_f)/Math.sqrt(50*50 + 50*50);
  }
  
  
  ui.Impact_Slider.setValue((float) Perc*100);
   double D = 20* (float) Perc;
  delay((int) D);
  
  bouncey_ball_2.setSize(bouncey_ball_2.getSize()*0.975);
  
}


public float[] calcGravForces(FBody well, float mass){
    distance = (float)Math.sqrt(Math.pow(sensor.getToolPositionX()-well.getX(), 2)+Math.pow(sensor.getToolPositionY()-well.getY(),2));  //calculate distance between the two bodies
    gravforce = ((grav_const)*hap_mass*mass)/((float)Math.pow(distance,2));   //calculate gravitational force according to the universal gravitation equation        
    print("Test \n");
    angle = (float)Math.acos(abs(sensor.getToolPositionX()-well.getX())/distance);  //use inverse cos to find the angle 
    
    direction_x = Math.signum(sensor.getToolPositionX()-well.getX());  //get the direction that the x-force should be applied
    direction_y = Math.signum(well.getY()-sensor.getToolPositionY());  //get the direction that the y-force should be applied
    
    gravforce_x = direction_x*gravforce*(float)Math.cos(angle);  //use the angle to get the x-comp of gravitational force
    gravforce_y = direction_y*gravforce*(float)Math.sin(angle);  //use the angle to get the y-comp of gravitational force
     
    float[] gravforce_arr = new float[]{gravforce_x, gravforce_y};
  
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
