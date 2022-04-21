// import controlP5.*;
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
import java.lang.Math;

private GUI ui;

private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);

float pixelsPerMeter = 10.0;


//Graphics
PImage asteroid;
PImage planet;
PImage gravWellImg;
PImage backgroundpic;
PImage rocket;


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

// Knob plateVelocity, ballVelocity, plateM, ballM;    // to remove

// World Object declarations
FBox basePlate;
FCircle ball, bouncey_ball_1, bouncey_ball_2, well_single, well_large, well_medium, well_small;
FLine arrow_line; 

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


float MIN_BALL_SIZE = ballRadius;
float MAX_BALL_SIZE = 10*ballRadius;
float MAX_WELL_SIZE = 15 * ballRadius;
float MAX_VELOCITY = 150.0;


// other variables
boolean renderingForce = false;
long baseFrameRate = 120;
byte widgetOneID = 5;
int CW = 0;
int CCW = 1;

float dampingForce = 50;
float virtualCouplingX = 0;
float virtualCouplingY = 0;
//float dampingScale = 100000;
float dampingScale = 2;

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

float distance = 0;
float direction_x, direction_y, angle = 0;

float[] gravforce_arr0;
float gravforce_x0, gravforce_y0 = 0;

float[] gravforce_arr1;
float gravforce_x1, gravforce_y1 = 0;

float[] gravforce_arr2;
float gravforce_x2, gravforce_y2 = 0;

float[] gravforce_arr3;
float gravforce_x3, gravforce_y3 = 0;

float gravforce_totx, gravforce_toty = 0;

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
  
  double perc;

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
  sensor = new HVirtualCoupling((4)); 
  sensor.h_avatar.setDensity(400); 
  sensor.h_avatar.setFill(255,0,0); 
  // sensor.h_avatar.setSensor(true);
  sensor.h_avatar.attachImage(resizeImage(rocket, (int) (pixelsPerMeter*sensor.h_avatar.getSize()), (int) (pixelsPerMeter*sensor.h_avatar.getSize())));

  if(ui != null)
    ui.setSensor(sensor);

  sensor.init(world, WORLD_WIDTH/2, BOUNDARY_SIZE + 5);
}


FCircle initBall(float radius, float x, float y, float ballFriction, boolean isHaptic, PImage img, float initVelocity){
  FCircle tempBall = new FCircle(radius);
  tempBall.setPosition(x, y); //Should this be X and Y
  tempBall.setFill(0, 0, 150);
  tempBall.setHaptic(isHaptic);
  tempBall.setRestitution(1);
  tempBall.setFriction(ballFriction);
  tempBall.setDensity((float) ((ballMass * ballMassFactor)/ Math.PI * Math.pow(ballRadius , 2)));
  tempBall.setDamping(0);
  tempBall.attachImage(resizeImage(img, (int) (pixelsPerMeter*tempBall.getSize()), (int) (pixelsPerMeter*tempBall.getSize())));
  tempBall.setVelocity(initVelocity, initVelocity);
  return tempBall;
}

// FBox initBox(float width, float length, float x, float y, boolean isHaptic){
//   FBox temp = new FBox(width , length);
//   temp.setPosition(x, y);
//   temp.setFill(100);
//   temp.setNoStroke();
//   temp.setRotatable(false);
//   temp.setHaptic(isHaptic);
//   temp.setDensity((plateMass * plateMassFactor) / temp.getWidth() * temp.getHeight());
//   temp.setDamping(20); 
//   return temp;
// }

FCircle initWell(float radius, float pos_x, float pos_y, PImage img){
  FCircle tempWell = new FCircle(radius);
  tempWell.setPosition(pos_x, pos_y);
  tempWell.setStaticBody(true);
  tempWell.setSensor(true);
  tempWell.setFill(0);
  tempWell.attachImage(resizeImage(img, (int) (pixelsPerMeter*tempWell.getSize()), (int) (pixelsPerMeter*tempWell.getSize())));
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
 
  asteroid = loadImage("Images/asteroid.png");
  planet = loadImage("Images/planet.png");
  gravWellImg = loadImage("Images/GravWell.png");
  backgroundpic = loadImage("Images/backgroundpic.png");
  rocket = loadImage("Images/rocket.png");
        
 
  //Initialization of balls for Modules 1 and 2
  bouncey_ball_1 = initBall(4* ballRadius, WORLD_WIDTH/2, WORLD_HEIGHT/2, 0.0f, false, planet, 25);
  
  bouncey_ball_2 = initBall(10* ballRadius, WORLD_WIDTH/2, WORLD_HEIGHT/2, 0.0f, false, planet, -50);
 
 //Initialization of Grav wells for module 3
 well_single = initWell(15, WORLD_WIDTH/2, WORLD_HEIGHT/2.3, gravWellImg);
 well_large = initWell(15,WORLD_WIDTH/4, WORLD_HEIGHT/3.5, gravWellImg); 
 well_medium = initWell(10, WORLD_WIDTH/1.8, WORLD_HEIGHT/1.8, gravWellImg);
 well_small = initWell(5, WORLD_WIDTH/1.2, WORLD_HEIGHT/3, gravWellImg);
  
 arrow_line = new FLine(WORLD_WIDTH/2 - (2.5*posEE.x), (BOUNDARY_SIZE) + (2*posEE.y) - 7, 10, 10); 
 

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
    backgroundpic.resize((int) (pixelsPerMeter*ui.worldBackground.getWidth()), (int) (pixelsPerMeter*ui.worldBackground.getHeight()));
    ui.worldBackground.attachImage(backgroundpic);
    resetObjects();

    switch(ui.getCurrentLevel()){
      case 1:
        ui.initElasticCollisions();
        dampingScale = 75000;
        world.add(bouncey_ball_1);
        ui.setKnob_2(bouncey_ball_1.getSize());
        ui.setKnob_3(reScale((float)Math.sqrt(Math.pow(bouncey_ball_1.getVelocityX(),2)+ Math.pow(bouncey_ball_1.getVelocityY(), 2)), MAX_VELOCITY, 0, 10));
        addSensor();
        if(sensor != null){
          ui.setKnob_1(sensor.h_avatar.getSize());
        }
        println("Second level");
        break;

      case 2:
        ui.initInelasticCollisions();
        dampingScale = 75000;
        world.add(bouncey_ball_2);
        ui.setKnob_2(bouncey_ball_2.getSize());
        addSensor();
        if(sensor != null){
          ui.setKnob_1(sensor.h_avatar.getSize());
        }
        println("Third level");
        break;
        
      case 3:
        ui.initAllCollisions();
        dampingScale = 75000;
        world.add(bouncey_ball_1);
        world.add(bouncey_ball_2);
        ui.setKnob_2(bouncey_ball_1.getSize());
        ui.setKnob_3(bouncey_ball_2.getSize());
        addSensor();
        if(sensor != null){
          ui.setKnob_1(sensor.h_avatar.getSize());
        }
        break;
      
      case 4:
        ui.initGravity_single(); 
        dampingScale = 2;  
        addSensor();
        if(sensor != null){
          ui.setKnob_1(sensor.h_avatar.getSize());
        }
        world.add(well_single);
        ui.setKnob_2(reScale(well_single.getSize(), 15, 0, 10));
        //world.add(arrow_line);
        // world.add(well_medium);
        // world.add(well_small);
        //arrow(xE, yE, fEE.x, fEE.y);
        //line(posEE.x, posEE.y, posEE.x+10, posEE.y+10);
        break;
     
     case 5:
        ui.initGravity_triple(); 
        dampingScale = 2;  
        addSensor();
        if(sensor != null){
          ui.setKnob_1(sensor.h_avatar.getSize());
        }
        world.add(well_large);
        world.add(well_medium);
        world.add(well_small);
        ui.setKnob_2(reScale(well_large.getSize(), 15, 0, 10));
        ui.setKnob_3(reScale(well_medium.getSize(), 15, 0, 10));
        ui.setKnob_4(reScale(well_small.getSize(), 15, 0, 10));
        //arrow(xE, yE, fEE.x, fEE.y);
        //line(200, 100, 600, 400);
        break;
        
      case 6:
        ui.initSandbox();   
        dampingScale = 100;
        addSensor();
        if(sensor != null){
          ui.setKnob_1(sensor.h_avatar.getSize());
        }

        well_medium.setPosition(well_medium.getX() + 5, well_medium.getY()-15);
        well_large.setPosition(well_large.getX(), well_large.getY()+10);
        world.add(well_medium);
        world.add(well_small);
        world.add(well_large);       
        
        world.add(bouncey_ball_1);
        world.add(bouncey_ball_2);
        //arrow(xE, yE, fEE.x, fEE.y);
        //line(200, 100, 600, 400);
        break;
    }
  } else if(renderingForce == false){
    background(255);
    
    if(ui.getCurrentLevel() == 4){
      //line(posEE.x, posEE.y, 100, 100);
      arrow(xE, yE, fEE.x, fEE.y);
    } else if(ui.getCurrentLevel() == 5){
      arrow(xE, yE, fEE.x, fEE.y);
    }
    
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
        
        //xE = pixelsPerMeter*posEE.x;
        //yE = pixelsPerMeter*posEE.y;
      }

      posEE.set(posEE.copy().mult(200));
    
      sensor.setToolPosition(WORLD_WIDTH/2 - (2.5*posEE.x), (BOUNDARY_SIZE) + (2*posEE.y) - 7); 
      sensor.updateCouplingForce();
      
    }
    
    if(sensor != null){
      sensor.h_avatar.setDamping(dampingForce);

      if(ui.getIsHapticsOn()){
        fEE.set(-sensor.getVirtualCouplingForceX(), sensor.getVirtualCouplingForceY());  
        if (ui.getCurrentLevel() == 4){
          xE = pixelsPerMeter*posEE.x;
          yE = pixelsPerMeter*posEE.y;
          gravforce_arr0 = calcGravForces(well_single, mass_large);      
          
          fEE.set(gravforce_arr0[0], gravforce_arr0[1]);
          
          //arrow_line.setStart(-xE+(WORLD_WIDTH/2*pixelsPerMeter), yE);
          //arrow_line.setEnd(-xE+(WORLD_WIDTH/2*pixelsPerMeter)+10, yE+10);
          //line(200, 100, 600, 400);  
          //line(posEE.x, posEE.y, posEE.x+10, posEE.y+10);
          
        }else if (ui.getCurrentLevel() == 5){
          xE = pixelsPerMeter*posEE.x;
          yE = pixelsPerMeter*posEE.y;
          
          gravforce_arr1 = calcGravForces(well_large, mass_large);      
          gravforce_arr2 = calcGravForces(well_medium, mass_medium); 
          gravforce_arr3 = calcGravForces(well_small, mass_small);
          
          gravforce_totx = gravforce_arr1[0]+gravforce_arr2[0]+gravforce_arr3[0];
          gravforce_toty = gravforce_arr1[1]+gravforce_arr2[1]+gravforce_arr3[1];
          
          fEE.set(gravforce_totx, gravforce_toty);
        
        }
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

void keyPressed(){
  int currentLevel = ui.getCurrentLevel();
  switch (key){
    // mass of the effector change
    case 'q':
      if(sensor != null && sensor.h_avatar.getSize() < MAX_BALL_SIZE){
        sensor.h_avatar.setSize(sensor.h_avatar.getSize() + 0.5);
        sensor.h_avatar.attachImage(resizeImage(rocket, (int) (pixelsPerMeter*sensor.h_avatar.getSize()), (int) (pixelsPerMeter*sensor.h_avatar.getSize())));
        ui.setKnob_1(sensor.h_avatar.getSize());
      }
      break;
    case 'a':
      if(sensor != null && sensor.h_avatar.getSize() > MIN_BALL_SIZE){
        sensor.h_avatar.setSize(sensor.h_avatar.getSize() - 0.5);
        sensor.h_avatar.attachImage(resizeImage(rocket, (int) (pixelsPerMeter*sensor.h_avatar.getSize()), (int) (pixelsPerMeter*sensor.h_avatar.getSize())));
        ui.setKnob_1(sensor.h_avatar.getSize());;
      }        
      break;
    // other changes
    case 'w':
      if((currentLevel == 1 || currentLevel == 3) && bouncey_ball_1.getSize() < MAX_BALL_SIZE){
        bouncey_ball_1.setSize(bouncey_ball_1.getSize() + 0.5);
        bouncey_ball_1.attachImage(resizeImage(planet, (int) (pixelsPerMeter*bouncey_ball_1.getSize()), (int) (pixelsPerMeter*bouncey_ball_1.getSize())));
        ui.setKnob_2(bouncey_ball_1.getSize());
      }else if (currentLevel == 2 && bouncey_ball_2.getSize() < MAX_BALL_SIZE){
        bouncey_ball_2.setSize(bouncey_ball_2.getSize() + 0.5);
        ui.setKnob_2(constrain(bouncey_ball_2.getSize(), 0, 10));
        bouncey_ball_2.attachImage(resizeImage(asteroid, (int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize())));
      }else if(currentLevel == 4 && well_single.getSize() < MAX_WELL_SIZE){
        well_single.setSize(well_single.getSize() + 0.5);
        ui.setKnob_2(reScale(well_single.getSize(), 15, 0, 10));
        well_single.attachImage(resizeImage(gravWellImg, (int) (pixelsPerMeter*well_single.getSize()), (int) (pixelsPerMeter*well_single.getSize())));
      }else if (currentLevel == 5 && well_large.getSize() < MAX_WELL_SIZE){
        well_large.setSize(well_large.getSize() + 0.5);
        ui.setKnob_2(reScale(well_large.getSize(), 15, 0, 10));
        well_large.attachImage(resizeImage(gravWellImg, (int) (pixelsPerMeter*well_large.getSize()), (int) (pixelsPerMeter*well_large.getSize())));
      }
      break;
    case 's':
      if((currentLevel == 1 || currentLevel == 3) && bouncey_ball_1.getSize() > MIN_BALL_SIZE){
        bouncey_ball_1.setSize(bouncey_ball_1.getSize() - 0.5);
        bouncey_ball_1.attachImage(resizeImage(planet, (int) (pixelsPerMeter*bouncey_ball_1.getSize()), (int) (pixelsPerMeter*bouncey_ball_1.getSize())));
        ui.setKnob_2(constrain(bouncey_ball_1.getSize(), 0, 10));
      }else if (currentLevel == 2 && bouncey_ball_2.getSize() > MIN_BALL_SIZE){
        bouncey_ball_2.setSize(bouncey_ball_2.getSize() - 0.5);
        ui.setKnob_2(constrain(bouncey_ball_2.getSize(), 0, 10));
        bouncey_ball_2.attachImage(resizeImage( asteroid, (int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize())));
      }else if(currentLevel == 4 && well_single.getSize() > MIN_BALL_SIZE){
        well_single.setSize(well_single.getSize() - 0.5);
        ui.setKnob_2(reScale(well_single.getSize(), 15, 0, 10));
        well_single.attachImage(resizeImage( gravWellImg, (int) (pixelsPerMeter*well_single.getSize()), (int) (pixelsPerMeter*well_single.getSize())));
      }else if (currentLevel == 5 && well_large.getSize() > MIN_BALL_SIZE){
        well_large.setSize(well_large.getSize() - 0.5);
        ui.setKnob_2(reScale(well_large.getSize(), 15, 0, 10));
        well_large.attachImage(resizeImage( gravWellImg, (int) (pixelsPerMeter*well_large.getSize()), (int) (pixelsPerMeter*well_large.getSize())));
      }
      break;
    case 'e':
      if(currentLevel == 1){
        // 10% increase
        bouncey_ball_1.setVelocity(bouncey_ball_1.getVelocityX() * 1.1, bouncey_ball_1.getVelocityY() * 1.1);
        ui.setKnob_3(reScale((float)Math.sqrt(Math.pow(bouncey_ball_1.getVelocityX(),2)+ Math.pow(bouncey_ball_1.getVelocityY(), 2)), 150, 0, 10));
      }else if(currentLevel == 2){
        bouncey_ball_2.setVelocity(bouncey_ball_2.getVelocityX() * 1.1, bouncey_ball_2.getVelocityY() * 1.1);
        ui.setKnob_3(reScale((float)Math.sqrt(Math.pow(bouncey_ball_2.getVelocityX(),2)+ Math.pow(bouncey_ball_2.getVelocityY(), 2)), 150, 0, 10));
      }else if (currentLevel == 3 && bouncey_ball_1.getSize() < MAX_WELL_SIZE){
        bouncey_ball_2.setSize(bouncey_ball_2.getSize() + 0.5);
        ui.setKnob_3(constrain(bouncey_ball_2.getSize(), 0, 10));
        bouncey_ball_2.attachImage(resizeImage(asteroid, (int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize())));
      }else if (currentLevel == 5 && well_medium.getSize() < MAX_WELL_SIZE){
        well_medium.setSize(well_medium.getSize() + 0.5);
        ui.setKnob_3(reScale(well_medium.getSize(), 15, 0, 10));
        well_medium.attachImage(resizeImage(gravWellImg, (int) (pixelsPerMeter*well_medium.getSize()), (int) (pixelsPerMeter*well_medium.getSize())));
      }
      break;
    case 'd':
      if(currentLevel == 1){
        // 10% decrease
        bouncey_ball_1.setVelocity(bouncey_ball_1.getVelocityX() * 0.9, bouncey_ball_1.getVelocityY() * 0.9);
        ui.setKnob_3(reScale((float)Math.sqrt(Math.pow(bouncey_ball_1.getVelocityX(),2)+ Math.pow(bouncey_ball_1.getVelocityY(), 2)), 150, 0, 10));
      }else if(currentLevel == 2){
        bouncey_ball_2.setVelocity(bouncey_ball_2.getVelocityX() * 0.9, bouncey_ball_2.getVelocityY() * 0.9);
        ui.setKnob_3(reScale((float)Math.sqrt(Math.pow(bouncey_ball_2.getVelocityX(),2)+ Math.pow(bouncey_ball_2.getVelocityY(), 2)), 150, 0, 10));
      }else if (currentLevel == 3 && bouncey_ball_1.getSize() > MIN_BALL_SIZE){
        bouncey_ball_2.setSize(bouncey_ball_2.getSize() - 0.5);
        ui.setKnob_3(constrain(bouncey_ball_2.getSize(), 0, 10));
        bouncey_ball_2.attachImage(resizeImage(asteroid,(int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize())));
      }else if (currentLevel == 5 && well_medium.getSize() > MIN_BALL_SIZE){
        well_medium.setSize(well_medium.getSize() - 0.5);
        ui.setKnob_3(reScale(well_medium.getSize(), 15, 0, 10));
        well_medium.attachImage(resizeImage(gravWellImg, (int) (pixelsPerMeter*well_medium.getSize()), (int) (pixelsPerMeter*well_medium.getSize())));
      }
    break;
    case 'r':
      if(currentLevel == 5 && well_small.getSize() < MAX_WELL_SIZE){
        well_small.setSize(well_small.getSize() + 0.5);
        ui.setKnob_4(reScale(well_small.getSize(), 15, 0, 10));
        well_small.attachImage(resizeImage(gravWellImg, (int) (pixelsPerMeter*well_small.getSize()), (int) (pixelsPerMeter*well_small.getSize())));
      }
    break;
     case 'f':
      if(currentLevel == 5 && well_small.getSize() > MIN_BALL_SIZE){
        well_small.setSize(well_small.getSize() - 0.5);
        ui.setKnob_4(reScale(well_small.getSize(), 15, 0, 10));
        well_small.attachImage(resizeImage(gravWellImg, (int) (pixelsPerMeter*well_small.getSize()), (int) (pixelsPerMeter*well_small.getSize())));
      }
    break;
  }
  // if(key == CODED){
  //   if(keyCode == UP){
  //     plateVelocityY -= 50;
  //   }else if(keyCode == DOWN){
  //     plateVelocityY += 50;
  //   }else if(keyCode == LEFT){
  //     plateVelocityX -= 50;
  //   }else if(keyCode == RIGHT){
  //     plateVelocityX += 50;
  //   }
  // }
 
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
      if(body1 == bouncey_ball_1 || body2 == bouncey_ball_1){
        commit_elastic_results(c, body1, body2);
      }else if(body1 == bouncey_ball_2 && body2 == sensor.h_avatar || body1 == sensor.h_avatar && body2 == bouncey_ball_2){
        commit_inelastic_results(c, body1, body2, 0.5);
      }
    }
    
  }
  
  // println(body1.getVelocityX() + " , " + body2.getVelocityX() );
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
    perc =  Math.sqrt(v1x_f*v1x_f + v1y_f*v1y_f)/Math.sqrt(50*50 + 50*50);
  }else if (body2 == bouncey_ball_1){
    perc =  Math.sqrt(v2x_f*v2x_f + v2y_f*v2y_f)/Math.sqrt(50*50 + 50*50);
  }
  ui.setKnob_3(reScale((float) perc, 100,0,10));
  perc = constrain((float) perc,0,1);
  ui.setImpactSlider((float) perc*100); //update slider
  double D = 20* (float) perc;
  if (D>15){
    D = 15;
  }
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
    perc =  Math.sqrt(v1x_f*v1x_f + v1y_f*v1y_f)/Math.sqrt(50*50 + 50*50);
  }else if (body2 == bouncey_ball_2){
    perc =  Math.sqrt(v2x_f*v2x_f + v2y_f*v2y_f)/Math.sqrt(50*50 + 50*50);
  }
  
   //changed
  ui.setImpactSlider((float) perc*100);
  double D = 20* (float) perc;
  delay((int) D);
  
  bouncey_ball_2.setSize(bouncey_ball_2.getSize()*0.95);
  bouncey_ball_2.attachImage(resizeImage(asteroid, (int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize())));
  // ui.setKnob_2.

  if(ui.getCurrentLevel() == 2){
    ui.setKnob_3((float)Math.sqrt(bouncey_ball_2.getVelocityX()*bouncey_ball_2.getVelocityX() + bouncey_ball_2.getVelocityY()*bouncey_ball_2.getVelocityY()));
    ui.setKnob_2(bouncey_ball_2.getSize());
  }else if(ui.getCurrentLevel() == 3){
    ui.setKnob_3(bouncey_ball_2.getSize());
  }else if(ui.getCurrentLevel()==6 & (body1 == sensor.h_avatar || body2 == sensor.h_avatar)){
    
    if (bouncey_ball_2.getSize() < 14){
      bouncey_ball_2.setSize(bouncey_ball_2.getSize()*1.05);
      bouncey_ball_2.attachImage(resizeImage(asteroid, (int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize())));
    }
    
    // if (sensor.h_avatar.getSize() >1){
    //   sensor.h_avatar.setSize(sensor.h_avatar.getSize()*(0.95));
    // }
  }
  

  if(sensor != null && sensor.h_avatar.getSize() >1){
    sensor.h_avatar.setSize(sensor.h_avatar.getSize() * 0.95);
    sensor.h_avatar.attachImage(resizeImage(rocket, (int) (pixelsPerMeter*sensor.h_avatar.getSize()), (int) (pixelsPerMeter*sensor.h_avatar.getSize())));
  }
  
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
  x2=x2*10;
  y2=y2*10;
  //WORLD_WIDTH = 80; WORLD_HEIGHT = 70; pixelsPerMeter = 10; 

  //x1 = -x1*2.5+400;
  //y1 = y1*2-55;
  x1 = -x1 * (pixelsPerMeter/4) + (WORLD_WIDTH*5);
  y1 = y1 * (pixelsPerMeter/5) - (WORLD_HEIGHT/2) - 20;
  

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

float reScale(float value, float maxValue, int minScale, int maxScale){
  return (value/maxValue) * (maxScale - minScale);
}

PImage resizeImage(PImage src, int width, int height){
  PImage temp = src.copy();
  temp.resize(width, height);
  return temp;
}

void resetObjects(){
  bouncey_ball_1.setSize(4* ballRadius);
  bouncey_ball_1.setPosition(WORLD_WIDTH/3, WORLD_HEIGHT/2);
  bouncey_ball_1.setVelocity(25, 25);
  bouncey_ball_1.attachImage(resizeImage(planet, (int) (pixelsPerMeter*bouncey_ball_1.getSize()), (int) (pixelsPerMeter*bouncey_ball_1.getSize())));
  
  bouncey_ball_2.setSize(10* ballRadius);
  bouncey_ball_2.setPosition(2*WORLD_WIDTH/3, WORLD_HEIGHT/2);
  bouncey_ball_2.setVelocity(-50, -50);
  bouncey_ball_2.attachImage(resizeImage(asteroid, (int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize())));

  well_single.setSize(15);
  well_single.setPosition(WORLD_WIDTH/2, WORLD_HEIGHT/2.3);
  well_single.attachImage(resizeImage(gravWellImg, (int)(1.25*pixelsPerMeter*well_single.getSize()), (int)(1.25*pixelsPerMeter*well_single.getSize())));

  well_large.setSize(15);
  well_large.setPosition(WORLD_WIDTH/4, WORLD_HEIGHT/3.5);
  well_large.attachImage(resizeImage(gravWellImg, (int)(1.25*pixelsPerMeter*well_large.getSize()), (int)(1.25*pixelsPerMeter*well_large.getSize())));

  well_medium.setSize(10);
  well_medium.setPosition(WORLD_WIDTH/1.8, WORLD_HEIGHT/1.8);
  well_medium.attachImage(resizeImage(gravWellImg, (int) (1.25*pixelsPerMeter*well_medium.getSize()), (int) (1.25*pixelsPerMeter*well_medium.getSize())));

  well_small.setSize(5);
  well_small.setPosition(WORLD_WIDTH/1.2, WORLD_HEIGHT/3);
  well_small.attachImage(resizeImage(gravWellImg, (int) (1.25*pixelsPerMeter*well_small.getSize()), (int) (1.25*pixelsPerMeter*well_small.getSize())));
}








// // import controlP5.*;
// import processing.serial.*;
// import static java.util.concurrent.TimeUnit.*;
// import java.util.concurrent.*;
// import java.lang.Math;

// private GUI ui;

// private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);

// float pixelsPerMeter = 10.0;


// //Graphics
// PImage asteroid;
// PImage planet;
// PImage gravwell_s;
// PImage gravwell_m;
// PImage gravwell_l;
// PImage gravwell_single;
// PImage backgroundpic, rocket;


// // Haply Initializatons
// Board haplyBoard;
// Device widgetOne;
// Mechanisms pantograph;

// PVector angles = new PVector(0,0);
// PVector torques = new PVector(0,0);

// PVector posEE = new PVector(0,0);
// PVector fEE = new PVector(0,0);

// // Virtual tool initializtation
// HVirtualCoupling sensor;

// // World variable declarations
// FWorld world;
// float WORLD_WIDTH = 80.0;
// float WORLD_HEIGHT = 70.0;
// float BOUNDARY_SIZE = 1;

// Knob plateVelocity, ballVelocity, plateM, ballM;    // to remove

// // World Object declarations
// FBox basePlate;
// FCircle ball, bouncey_ball_1, bouncey_ball_2, well_single, well_large, well_medium, well_small;
// FLine arrow_line; 

// // Object parameter variables
// float platePositionX = BOUNDARY_SIZE * 5;
// float platePositionY =  WORLD_HEIGHT/2;
// float plateVelocityX = 0;
// float plateVelocityY = 0;
// float pVelocityDecay = 0.5;
// float plateMass = 200;
// float plateMassFactor = 1;
// boolean isPlateVelocityChanged = false;

// float ballVelocityX = 0;
// float ballVelocityY = 0;
// float ballRadius = 1;
// float ballMass = 250;
// float ballMassFactor = 1;
// boolean isBallVelocityChanged = false;


// float MIN_BALL_SIZE = ballRadius;
// float MAX_BALL_SIZE = 10*ballRadius;
// float MAX_WELL_SIZE = 15 * ballRadius;
// float MAX_VELOCITY = 150.0;


// // other variables
// boolean renderingForce = false;
// long baseFrameRate = 120;
// byte widgetOneID = 5;
// int CW = 0;
// int CCW = 1;

// float dampingForce = 50;
// float virtualCouplingX = 0;
// float virtualCouplingY = 0;
// //float dampingScale = 100000;
// float dampingScale = 2;

// //Gravity well variable declarations
// float xE, yE = 0; 
// float grav_const = 6.7;

// float hap_mass = 8;
// float mass_large = 20;
// float mass_medium = 12; 
// float mass_small = 2; 

// float gravforce_x = 0; 
// float gravforce_y = 0; 
// float gravforce = 0; 

// float distance = 0;
// float direction_x, direction_y, angle = 0;

// float[] gravforce_arr0;
// float gravforce_x0, gravforce_y0 = 0;

// float[] gravforce_arr1;
// float gravforce_x1, gravforce_y1 = 0;

// float[] gravforce_arr2;
// float gravforce_x2, gravforce_y2 = 0;

// float[] gravforce_arr3;
// float gravforce_x3, gravforce_y3 = 0;

// float gravforce_totx, gravforce_toty = 0;

// //Collison variable initiliizations 
//  float Vx1_i;
//  float Vy1_i;
//  float Vx2_i;
//  float Vy2_i;
 
//   float m1;
//   float m2;
 
//   float v1x_f;
//   float v1y_f;
//   float v2x_f;
//   float v2y_f;
  
//   float KExf_total;
//   float KEyf_total;
  
//   double V1_rat;
//   double V2_rat;
  
//   float KExi_total;
//   float KEyi_total;
//   float KEx_loss;
//   float KEy_loss;
  
//   double perc;

// void initHaply(){
//   // println(Serial.list()[0]);
//   haplyBoard = new Board(this, Serial.list()[0], 0);
//   widgetOne = new Device(widgetOneID, haplyBoard);
//   pantograph = new Pantograph();
  
//   widgetOne.set_mechanism(pantograph);
//   widgetOne.add_actuator(1, CCW, 2);
//   widgetOne.add_actuator(2, CW, 1); 
//   widgetOne.add_encoder(1, CCW, 241, 10752, 2);
//   widgetOne.add_encoder(2, CW, -61, 10752, 1);   
//   widgetOne.device_set_parameters();
// }

// void addSensor(){
//    /* Setup the Virtual Coupling Contact Rendering Technique */
//   sensor = new HVirtualCoupling((3)); 
//   sensor.h_avatar.setDensity(400); 
//   sensor.h_avatar.setFill(255,0,0); 
//   rocket.resize((int)(1.25*pixelsPerMeter*sensor.h_avatar.getSize()), ((int) (1.25*pixelsPerMeter*sensor.h_avatar.getSize())));
//   sensor.h_avatar.attachImage(rocket);
//   // sensor.h_avatar.setSensor(true);

//   if(ui != null)
//     ui.setSensor(sensor);

//   sensor.init(world, WORLD_WIDTH/2, BOUNDARY_SIZE + 5);
// }


// FCircle initBall(float radius, float x, float y, float ballFriction, boolean isHaptic){
//   FCircle tempBall = new FCircle(radius);
//   tempBall.setPosition(x, y); //Should this be X and Y
//   tempBall.setFill(0, 0, 150);
//   tempBall.setHaptic(isHaptic);
//   tempBall.setRestitution(1);
//   tempBall.setFriction(ballFriction);
//   tempBall.setDensity((float) ((ballMass * ballMassFactor)/ Math.PI * Math.pow(ballRadius , 2)));
//   tempBall.setDamping(0);
//   return tempBall;
// }

// FBox initBox(float width, float length, float x, float y, boolean isHaptic){
//   FBox temp = new FBox(width , length);
//   temp.setPosition(x, y);
//   temp.setFill(100);
//   temp.setNoStroke();
//   temp.setRotatable(false);
//   temp.setHaptic(isHaptic);
//   temp.setDensity((plateMass * plateMassFactor) / temp.getWidth() * temp.getHeight());
//   temp.setDamping(20); 
//   return temp;
// }

// FCircle initWell(float radius, float pos_x, float pos_y){
//   FCircle tempWell = new FCircle(radius);
//   tempWell.setPosition(pos_x, pos_y);
//   tempWell.setStaticBody(true);
//   tempWell.setSensor(true);
//   tempWell.setFill(0);
//   return tempWell;
// }

// void setup() {
//   /* put setup code here, run once: */

//   /* screen size definition */
//   size(1200, 700);
  
//   /* GUI setup */
//   hAPI_Fisica.init(this); 
//   hAPI_Fisica.setScale(pixelsPerMeter); 

//   smooth();
//   ui = new GUI(this);
//   ui.init(WORLD_WIDTH, WORLD_HEIGHT, BOUNDARY_SIZE);
//   world = ui.getWorld();  
  
//   // ball = initBall(2* ballRadius, WORLD_WIDTH/4, WORLD_HEIGHT/2, 0.0f, false);
//   // basePlate = initBox(BOUNDARY_SIZE, BOUNDARY_SIZE * 5, platePositionX, platePositionY, false);
 
//   asteroid = loadImage("asteroid.png");
//   planet = loadImage("planet.png");
//   gravwell_single = loadImage("GravWell.png");
//   gravwell_l = loadImage("GravWell.png");
//   gravwell_m = loadImage("GravWell.png");
//   gravwell_s = loadImage("GravWell.png");
//   backgroundpic = loadImage("backgroundpic.png");
//   rocket = loadImage("rocket.png");
        
 
//   //Initialization of balls for Modules 1 and 2
//   bouncey_ball_1 = initBall(4* ballRadius, WORLD_WIDTH/2, WORLD_HEIGHT/2, 0.0f, false);
//   bouncey_ball_1.setVelocity(25,25);
  
//   bouncey_ball_2 = initBall(10* ballRadius, WORLD_WIDTH/2, WORLD_HEIGHT/2, 0.0f, false);
//   bouncey_ball_2.setVelocity(50,50);
 
//  //Initialization of Grav wells for module 3
  
  
//  well_single = initWell(15, WORLD_WIDTH/2, WORLD_HEIGHT/2.3);
//  gravwell_single.resize((int)(1.25*pixelsPerMeter*well_single.getSize()), (int)(1.25*pixelsPerMeter*well_single.getSize()));
//  well_single.attachImage(gravwell_single);
 
//  well_large = initWell(15,WORLD_WIDTH/4, WORLD_HEIGHT/3.5);
//  gravwell_l.resize((int)(1.25*pixelsPerMeter*well_large.getSize()), (int)(1.25*pixelsPerMeter*well_large.getSize()));
//  well_large.attachImage(gravwell_l);
 
//  well_medium = initWell(10, WORLD_WIDTH/1.8, WORLD_HEIGHT/1.8);
//  gravwell_m.resize((int) (1.25*pixelsPerMeter*well_medium.getSize()), (int) (1.25*pixelsPerMeter*well_medium.getSize()));
//  well_medium.attachImage(gravwell_m);
 
//  well_small = initWell(5, WORLD_WIDTH/1.2, WORLD_HEIGHT/3);
//  gravwell_s.resize((int) (1.25*pixelsPerMeter*well_small.getSize()), (int) (1.25*pixelsPerMeter*well_small.getSize()));
//  well_small.attachImage(gravwell_s);
  
//  arrow_line = new FLine(WORLD_WIDTH/2 - (2.5*posEE.x), (BOUNDARY_SIZE) + (2*posEE.y) - 7, 10, 10); 
 

//   /* Haply Board Setup */
//   initHaply();  
  
 
//   world.draw();

//   frameRate(baseFrameRate);

//   SimulationThread st = new SimulationThread();
//   scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
// }

// void draw(){

//   //if(ui.getIsStart() && ui.getCurrentLevel() == 1){
//   //  println("This level");
//   //  world = ui.getWorld();
//   //  ui.initCollisions();

//   //  world.add(ball);
//   //  world.add(basePlate);

//     // addSensor();
//   //}
//   if(ui.getIsStart()){
//     world =ui.getWorld();
//     backgroundpic.resize((int) (pixelsPerMeter*ui.worldBackground.getWidth()), (int) (pixelsPerMeter*ui.worldBackground.getHeight()));
//     ui.worldBackground.attachImage(backgroundpic);

//     switch(ui.getCurrentLevel()){
//       case 1:
//         ui.initElasticCollisions();
//         world.add(bouncey_ball_1);
//         planet.resize((int) (pixelsPerMeter*bouncey_ball_1.getSize()), (int) (pixelsPerMeter*bouncey_ball_1.getSize()));
//         bouncey_ball_1.attachImage(planet);
//         ui.setKnob_2(bouncey_ball_1.getSize());
//         ui.setKnob_3(reScale((float)Math.sqrt(Math.pow(bouncey_ball_1.getVelocityX(),2)+ Math.pow(bouncey_ball_1.getVelocityY(), 2)), MAX_VELOCITY, 0, 10));
//         addSensor();
//         println("Second level");
//         break;

//       case 2:
//         ui.initInelasticCollisions();
//         asteroid.resize((int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize()));
//         bouncey_ball_2.attachImage(asteroid);
//         world.add(bouncey_ball_2);
//         ui.setKnob_2(bouncey_ball_2.getSize());
//         addSensor();
//         println("Third level");
//         break;
        
//       case 3:
//         ui.initAllCollisions();
//         bouncey_ball_2.setSize(10*ballRadius);
//         asteroid.resize((int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize()));
//         world.add(bouncey_ball_1);
//         world.add(bouncey_ball_2);
//         ui.setKnob_2(bouncey_ball_1.getSize());
//         ui.setKnob_3(bouncey_ball_2.getSize());
//         addSensor();
//         break;
      
//       case 4:
//         ui.initGravity_single();   
//         addSensor();
//         world.add(well_single);
//         ui.setKnob_2(reScale(well_single.getSize(), 15, 0, 10));
//         world.add(arrow_line);
//         // world.add(well_medium);
//         // world.add(well_small);
//         arrow(xE, yE, fEE.x, fEE.y);
//         //line(posEE.x, posEE.y, posEE.x+10, posEE.y+10);
//         break;
     
//      case 5:
//         ui.initGravity_triple();   
//         addSensor();
//         world.add(well_large);
//         world.add(well_medium);
//         world.add(well_small);
//         ui.setKnob_2(reScale(well_large.getSize(), 15, 0, 10));
//         ui.setKnob_3(reScale(well_medium.getSize(), 15, 0, 10));
//         ui.setKnob_4(reScale(well_small.getSize(), 15, 0, 10));
//         //arrow(xE, yE, fEE.x, fEE.y);
//         //line(200, 100, 600, 400);
//         break;
        
//       case 6:
//         ui.initSandbox();   
//         addSensor();
//         well_medium.setSize(well_medium.getSize()*2);
//         well_small.setSize(well_small.getSize()*2);
//         well_large.setSize(well_large.getSize()*2);
        
//         gravwell_s.resize((int)(1.25*pixelsPerMeter*well_small.getSize()), (int)(1.25*pixelsPerMeter*well_small.getSize()));
//         gravwell_m.resize((int)(1.25*pixelsPerMeter*well_medium.getSize()), (int)(1.25*pixelsPerMeter*well_medium.getSize()));
//         gravwell_l.resize((int)(1.25*pixelsPerMeter*well_large.getSize()), (int)(1.25*pixelsPerMeter*well_large.getSize()));
        
//         well_medium.setPosition(well_medium.getX() + 5, well_medium.getY()-15);
//         well_large.setPosition(well_large.getX(), well_large.getY()+10);
        
//         world.add(well_medium);
//         world.add(well_small);
//         world.add(well_large);
        
//         planet.resize((int) (pixelsPerMeter*bouncey_ball_1.getSize()), (int) (pixelsPerMeter*bouncey_ball_1.getSize()));
//         bouncey_ball_1.attachImage(planet);
//         bouncey_ball_2.setSize(10*ballRadius);
//         asteroid.resize((int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize()));
                      
//         world.add(bouncey_ball_1);
//         world.add(bouncey_ball_2);
//         //arrow(xE, yE, fEE.x, fEE.y);
//         //line(200, 100, 600, 400);
//         break;
//     }
//   } else if(renderingForce == false){
//     background(255);
    
//     if(ui.getCurrentLevel() == 4){
//       //line(posEE.x, posEE.y, 100, 100);
//       arrow(xE, yE, fEE.x, fEE.y);
//     } else if(ui.getCurrentLevel() == 5){
//       arrow(xE, yE, fEE.x, fEE.y);
//     }
    
//     world.draw();
//   }
// }

// class SimulationThread implements Runnable{
//   public void run(){
//     renderingForce = true;
    
//     if(haplyBoard.data_available() && sensor != null){
//      /* GET END-EFFECTOR STATE (TASK SPACE) */
        

//       if(ui.getIsReset()){
//         posEE.set(0,0);
//         widgetOne.device_set_parameters();
//         ui.setIsReset(false);
//       }else{
//         widgetOne.device_read_data();
    
//         angles.set(widgetOne.get_device_angles()); 
//         posEE.set(widgetOne.get_device_position(angles.array()));
        
//         //xE = pixelsPerMeter*posEE.x;
//         //yE = pixelsPerMeter*posEE.y;
//       }

//       posEE.set(posEE.copy().mult(200));
    
//       sensor.setToolPosition(WORLD_WIDTH/2 - (2.5*posEE.x), (BOUNDARY_SIZE) + (2*posEE.y) - 7); 
//       sensor.updateCouplingForce();
      
//     }

//     // //Adjust the UI controls
//     // ui.setKnob_1((float) Math.sqrt(Math.pow(plateVelocityX, 2) + Math.pow(plateVelocityY, 2)));
//     // ui.setKnob_2((float) Math.sqrt(Math.pow(ballVelocityX, 2) + Math.pow(ballVelocityY, 2)));
    
//     if(sensor != null){
//       sensor.h_avatar.setDamping(dampingForce);

//       if(ui.getIsHapticsOn()){
//         fEE.set(-sensor.getVirtualCouplingForceX(), sensor.getVirtualCouplingForceY());  
//         if (ui.getCurrentLevel() == 4){
//           xE = pixelsPerMeter*posEE.x;
//           yE = pixelsPerMeter*posEE.y;
//           gravforce_arr0 = calcGravForces(well_single, mass_large);      
          
//           fEE.set(gravforce_arr0[0], gravforce_arr0[1]);
          
//           //arrow_line.setStart(-xE+(WORLD_WIDTH/2*pixelsPerMeter), yE);
//           //arrow_line.setEnd(-xE+(WORLD_WIDTH/2*pixelsPerMeter)+10, yE+10);
//           //line(200, 100, 600, 400);  
//           //line(posEE.x, posEE.y, posEE.x+10, posEE.y+10);
          
//         }else if (ui.getCurrentLevel() == 5){
//           xE = pixelsPerMeter*posEE.x;
//           yE = pixelsPerMeter*posEE.y;
          
//           gravforce_arr1 = calcGravForces(well_large, mass_large);      
//           gravforce_arr2 = calcGravForces(well_medium, mass_medium); 
//           gravforce_arr3 = calcGravForces(well_small, mass_small);
          
//           gravforce_totx = gravforce_arr1[0]+gravforce_arr2[0]+gravforce_arr3[0];
//           gravforce_toty = gravforce_arr1[1]+gravforce_arr2[1]+gravforce_arr3[1];
          
//           fEE.set(gravforce_totx, gravforce_toty);
        
//         }
//       }else{
//         fEE.set(0,0);
//       }
          
//       fEE.div(dampingScale);
//       torques.set(widgetOne.set_device_torques(fEE.array()));
//       widgetOne.device_write_torques();
      
//     }
    
//     world.step();

//     renderingForce = false;
//   }
// }

// //void elasticCollisions(){
// //  if(basePlate.isTouchingBody(ball)){

// //      if(ballVelocityX == 0 && ballVelocityY == 0 ){
// //        ballVelocityX = 10;
// //        ballVelocityY = -10;
// //      }else{
// //          ballVelocityX = (plateMass* plateVelocityX + ballMass * ballVelocityX - plateMass * (plateVelocityX * pVelocityDecay))/ ballMass;
// //          ballVelocityY = (plateMass * plateVelocityY + ballMass * ballVelocityY - plateMass * (plateVelocityY + pVelocityDecay))/ ballMass;
// //      }

      
// //      plateVelocityX *= pVelocityDecay;
// //      plateVelocityY *= pVelocityDecay;
// //      // ball.addImpulse(basePlate.getForceX(), basePlate.getForceY() -1);
// //      // basePlate.resetForces();
// //      ball.setVelocity(ballVelocityX, ballVelocityY);
// //    }
// //    basePlate.setVelocity(plateVelocityX, plateVelocityY);
  
  
// //}


// void keyPressed(){
//   int currentLevel = ui.getCurrentLevel();
//   switch (key){
//     // mass of the effector change
//     case 'q':
//       if(sensor != null && sensor.h_avatar.getSize() < MAX_BALL_SIZE){
//         sensor.h_avatar.setDensity(sensor.h_avatar.getDensity() + 10);
//         ui.setKnob_1(constrain(sensor.h_avatar.getDensity() + 10, 0, 10));
//       }
//       break;
//     case 'a':
//       if(sensor != null && sensor.h_avatar.getSize() > MIN_BALL_SIZE){
//         sensor.h_avatar.setDensity(sensor.h_avatar.getDensity() - 10);
//         ui.setKnob_1(constrain(sensor.h_avatar.getDensity() - 10, 0, 10));
//       }        
//       break;
//     // other changes
//     case 'w':
//       if((currentLevel == 1 || currentLevel == 3 || currentLevel == 6) && bouncey_ball_1.getSize() < MAX_BALL_SIZE){
//         bouncey_ball_1.setSize(bouncey_ball_1.getSize() + 0.5);
//         ui.setKnob_2(bouncey_ball_1.getSize());
//       }else if (currentLevel == 2 && bouncey_ball_2.getSize() < MAX_BALL_SIZE){
//         bouncey_ball_2.setSize(bouncey_ball_2.getSize() + 0.5);
//         ui.setKnob_2(constrain(bouncey_ball_2.getSize(), 0, 10));
//         asteroid.resize((int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize()));
//       }else if(currentLevel == 4 && well_single.getSize() < MAX_WELL_SIZE){
//         well_single.setSize(well_single.getSize() + 0.5);
//         ui.setKnob_2(reScale(well_single.getSize(), 15, 0, 10));
//         gravwell_single.resize((int) (pixelsPerMeter*well_single.getSize()), (int) (pixelsPerMeter*well_single.getSize()));
//       }else if (currentLevel == 5 && well_large.getSize() < MAX_WELL_SIZE){
//         well_large.setSize(well_large.getSize() + 0.5);
//         ui.setKnob_2(reScale(well_large.getSize(), 15, 0, 10));
//         gravwell_l.resize((int) (pixelsPerMeter*well_large.getSize()), (int) (pixelsPerMeter*well_large.getSize()));
//       }
//       break;
//     case 's':
//       if((currentLevel == 1 || currentLevel == 3 || currentLevel == 6) && bouncey_ball_1.getSize() > MIN_BALL_SIZE){
//         bouncey_ball_1.setSize(bouncey_ball_1.getSize() - 0.5);
//         ui.setKnob_2(constrain(bouncey_ball_1.getSize(), 0, 10));
//       }else if (currentLevel == 2 && bouncey_ball_2.getSize() > MIN_BALL_SIZE){
//         bouncey_ball_2.setSize(bouncey_ball_2.getSize() - 0.5);
//         ui.setKnob_2(constrain(bouncey_ball_2.getSize(), 0, 10));
//         asteroid.resize((int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize()));
//       }else if(currentLevel == 4 && well_single.getSize() > MIN_BALL_SIZE){
//         well_single.setSize(well_single.getSize() - 0.5);
//         ui.setKnob_2(reScale(well_single.getSize(), 15, 0, 10));
//         gravwell_single.resize((int) (pixelsPerMeter*well_single.getSize()), (int) (pixelsPerMeter*well_single.getSize()));
//       }else if (currentLevel == 5 && well_large.getSize() > MIN_BALL_SIZE){
//         well_large.setSize(well_large.getSize() - 0.5);
//         ui.setKnob_2(reScale(well_large.getSize(), 15, 0, 10));
//         gravwell_l.resize((int) (pixelsPerMeter*well_large.getSize()), (int) (pixelsPerMeter*well_large.getSize()));
//       }
//       break;
//     case 'e':
//       if(currentLevel == 1){
//         // 10% increase
//         bouncey_ball_1.setVelocity(bouncey_ball_1.getVelocityX() * 1.1, bouncey_ball_1.getVelocityY() * 1.1);
//         ui.setKnob_3(reScale((float)Math.sqrt(Math.pow(bouncey_ball_1.getVelocityX(),2)+ Math.pow(bouncey_ball_1.getVelocityY(), 2)), 150, 0, 10));
//       }else if(currentLevel == 2){
//         bouncey_ball_2.setVelocity(bouncey_ball_2.getVelocityX() * 1.1, bouncey_ball_2.getVelocityY() * 1.1);
//         ui.setKnob_3(reScale((float)Math.sqrt(Math.pow(bouncey_ball_2.getVelocityX(),2)+ Math.pow(bouncey_ball_2.getVelocityY(), 2)), 150, 0, 10));
//       }else if (currentLevel == 3 && bouncey_ball_1.getSize() < MAX_WELL_SIZE){
//         bouncey_ball_2.setSize(bouncey_ball_2.getSize() + 0.5);
//         ui.setKnob_3(constrain(bouncey_ball_2.getSize(), 0, 10));
//         asteroid.resize((int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize()));
//       }else if (currentLevel >= 5 && well_medium.getSize() < MAX_WELL_SIZE){
//         well_medium.setSize(well_medium.getSize() + 0.5);
//         ui.setKnob_3(reScale(well_medium.getSize(), 15, 0, 10));
//         gravwell_m.resize((int) (pixelsPerMeter*well_medium.getSize()), (int) (pixelsPerMeter*well_medium.getSize()));
//       }
//       break;
//     case 'd':
//       if(currentLevel == 1){
//         // 10% decrease
//         bouncey_ball_1.setVelocity(bouncey_ball_1.getVelocityX() * 0.9, bouncey_ball_1.getVelocityY() * 0.9);
//         ui.setKnob_3(reScale((float)Math.sqrt(Math.pow(bouncey_ball_1.getVelocityX(),2)+ Math.pow(bouncey_ball_1.getVelocityY(), 2)), 150, 0, 10));
//       }else if(currentLevel == 2){
//         bouncey_ball_2.setVelocity(bouncey_ball_2.getVelocityX() * 0.9, bouncey_ball_2.getVelocityY() * 0.9);
//         ui.setKnob_3(reScale((float)Math.sqrt(Math.pow(bouncey_ball_2.getVelocityX(),2)+ Math.pow(bouncey_ball_2.getVelocityY(), 2)), 150, 0, 10));
//       }else if (currentLevel == 3 && bouncey_ball_1.getSize() > MIN_BALL_SIZE){
//         bouncey_ball_2.setSize(bouncey_ball_2.getSize() - 0.5);
//         ui.setKnob_3(constrain(bouncey_ball_2.getSize(), 0, 10));
//         asteroid.resize((int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize()));
//       }else if (currentLevel >= 5 && well_medium.getSize() > MIN_BALL_SIZE){
//         well_medium.setSize(well_medium.getSize() - 0.5);
//         ui.setKnob_3(reScale(well_medium.getSize(), 15, 0, 10));
//         gravwell_m.resize((int) (pixelsPerMeter*well_medium.getSize()), (int) (pixelsPerMeter*well_medium.getSize()));
//       }
//     break;
//     case 'r':
//       if(currentLevel >= 5 && well_small.getSize() < MAX_WELL_SIZE){
//         well_small.setSize(well_small.getSize() + 0.5);
//         ui.setKnob_4(reScale(well_small.getSize(), 15, 0, 10));
//         gravwell_s.resize((int) (pixelsPerMeter*well_small.getSize()), (int) (pixelsPerMeter*well_small.getSize()));
//       }
//     break;
//      case 'f':
//       if(currentLevel >= 5 && well_small.getSize() > MIN_BALL_SIZE){
//         well_small.setSize(well_small.getSize() - 0.5);
//         ui.setKnob_4(reScale(well_small.getSize(), 15, 0, 10));
//         gravwell_s.resize((int) (pixelsPerMeter*well_small.getSize()), (int) (pixelsPerMeter*well_small.getSize()));
//       }
//     break;
//   }
//   // if(key == CODED){
//   //   if(keyCode == UP){
//   //     plateVelocityY -= 50;
//   //   }else if(keyCode == DOWN){
//   //     plateVelocityY += 50;
//   //   }else if(keyCode == LEFT){
//   //     plateVelocityX -= 50;
//   //   }else if(keyCode == RIGHT){
//   //     plateVelocityX += 50;
//   //   }
//   // }
 
// }

// void contactStarted(FContact c){ //Called on contact between any 2 objects

//   FBody body1 = c.getBody1(); //Read bodies involved
//   FBody body2 = c.getBody2();


//   if (body1.isSensor() == true || body2.isSensor() == true ){ //Exit function if one of the objects is a sensor (non-solid)
  
//   // add if haptics due to boundary contacts needs to be skipped -> || body1.getName().contains("Boundary") || body2.getName().contains("Boundary")
//     return;
//   }
//   if(ui.getIsHapticsOn()){
//     if ((ui.getCurrentLevel() == 1 || ui.getCurrentLevel() == 3 || ui.getCurrentLevel() == 6) & (body1 == bouncey_ball_1 || body2 == bouncey_ball_1)){ //Check for first level
  
//       commit_elastic_results(c, body1, body2); //Elastic collision function

//     }else if ((ui.getCurrentLevel() == 2 || ui.getCurrentLevel() == 3 || ui.getCurrentLevel() == 6) & (body1 == bouncey_ball_2 || body2 == bouncey_ball_2)){ //Check for second level
      
//       commit_inelastic_results(c, body1, body2, 0.75); //Inelastic Collision function
      
//     }
//   }
  
//   // println(body1.getVelocityX() + " , " + body2.getVelocityX() );
//   fEE.div(dampingScale);
//   torques.set(widgetOne.set_device_torques(fEE.array()));
//   widgetOne.device_write_torques();
    
// }

// void commit_elastic_results (FContact c, FBody body1, FBody body2){ //Elastic collision function, determines resulting speeds after collision
  
//   Vx1_i = body1.getVelocityX(); //read velocities just before impact
//   Vy1_i = body1.getVelocityY();
//   Vx2_i = body2.getVelocityX();
//   Vy2_i = body2.getVelocityY();
 
//   m1 = body1.getMass(); //Read masses of objects involved
//   m2 = body2.getMass();
 
//   v1x_f =  (m1-m2)*Vx1_i/(m1+m2) + 2*m2*Vx2_i/(m1+m2); //Determine velocities after impact
//   v1y_f =  (m1-m2)*Vy1_i/(m1+m2) + 2*m2*Vy2_i/(m1+m2);
//   v2x_f =  (m2-m1)*Vx2_i/(m1+m2) + 2*m1*Vx1_i/(m1+m2);
//   v2y_f =  (m2-m1)*Vy2_i/(m1+m2) + 2*m1*Vy1_i/(m1+m2);
    
//   KExf_total = 0.5*m1*v1x_f*v1x_f + 0.5*m2*v2x_f*v2x_f; //Determine final kinetic energies
//   KEyf_total = 0.5*m1*v1y_f*v1y_f + 0.5*m2*v2y_f*v2y_f;
  
//   V1_rat = Math.sqrt(v1x_f*v1x_f + v1y_f*v1y_f)/Math.sqrt(Vx1_i*Vx1_i + Vy1_i*Vy1_i); //determine ratio of final to intitial speeds
//   V2_rat = Math.sqrt(v2x_f*v2x_f + v2y_f*v2y_f)/Math.sqrt(Vx2_i*Vx2_i + Vy2_i*Vy2_i);
  
//   if (V1_rat >100000){ //Conditional to prevent massless objects being an issue with infinite ratios
//     V1_rat = 0;
//   }
//    if (V2_rat >100000){
//     V2_rat = 0;
//   }
  
//   body1.setRestitution(abs((float)V1_rat)); //use speed ratios to set restitution (amount of velocity change on impacts)
//   body2.setRestitution(abs((float)V2_rat));
  

//   fEE.set(150*c.getNormalX()*KExf_total, 150*c.getNormalY()*KEyf_total);  
 
//   //Determine change in slider based on percent of max speed (set as 50 in X, 50 in Y)
//   if (body1 == bouncey_ball_1){
//     perc =  Math.sqrt(v1x_f*v1x_f + v1y_f*v1y_f)/Math.sqrt(50*50 + 50*50);
//   }else if (body2 == bouncey_ball_1){
//     perc =  Math.sqrt(v2x_f*v2x_f + v2y_f*v2y_f)/Math.sqrt(50*50 + 50*50);
//   }
//   ui.setKnob_3(reScale((float) perc, 100,0,10));
//   perc = constrain((float) perc,0,1);
//   ui.setImpactSlider((float) perc*100); //update slider
//   double D = 15* (float) perc;
//   if (D>15){
//     D = 15;
//   }
//   delay((int) D);

  
// }

// void commit_inelastic_results (FContact c, FBody body1, FBody body2, float KE_loss_fract){
  
//   Vx1_i = body1.getVelocityX();
//   Vy1_i = body1.getVelocityY();
//   Vx2_i = body2.getVelocityX();
//   Vy2_i = body2.getVelocityY();
 
//   m1 = body1.getMass();
//   m2 = body2.getMass();
  
//   KExi_total = 0.5*m1*Vx1_i*Vx1_i + 0.5*m2*Vx2_i*Vx2_i;
//   KEyi_total = 0.5*m1*Vy1_i*Vy1_i + 0.5*m2*Vy2_i*Vy2_i;
//   KEx_loss =  KE_loss_fract*KExi_total;
//   KEy_loss =  KE_loss_fract*KEyi_total;
//   KExf_total = KExi_total - KEx_loss;
//   KEyf_total = KEyi_total - KEy_loss;
 
//   v1x_f =  (m1-m2)*Vx1_i/(m1+m2) + 2*m2*Vx2_i/(m1+m2);
//   v1y_f =  (m1-m2)*Vy1_i/(m1+m2) + 2*m2*Vy2_i/(m1+m2);
//   v2x_f =  (m2-m1)*Vx2_i/(m1+m2) + 2*m1*Vx1_i/(m1+m2);
//   v2y_f =  (m2-m1)*Vy2_i/(m1+m2) + 2*m1*Vy1_i/(m1+m2);
  
//   V1_rat = Math.sqrt(v1x_f*v1x_f + v1y_f*v1y_f)/Math.sqrt(Vx1_i*Vx1_i + Vy1_i*Vy1_i);
//   V2_rat = Math.sqrt(v2x_f*v2x_f + v2y_f*v2y_f)/Math.sqrt(Vx2_i*Vx2_i + Vy2_i*Vy2_i);
  
//   if (V1_rat >100000){
//     V1_rat = 0;
//   }
//    if (V2_rat >100000){
//     V2_rat = 0;
//   }
  
//   body1.setRestitution(KE_loss_fract*abs((float)V1_rat)); //set restitution incorporating energy loss due to inelastic collision.
//   body2.setRestitution(KE_loss_fract*abs((float)V2_rat));
  
//   fEE.set(150*c.getNormalX()*KExf_total, 150*c.getNormalY()*KEyf_total);
  
  
//   if (body1 == bouncey_ball_2){
//     perc =  Math.sqrt(v1x_f*v1x_f + v1y_f*v1y_f)/Math.sqrt(50*50 + 50*50);
//   }else if (body2 == bouncey_ball_2){
//     perc =  Math.sqrt(v2x_f*v2x_f + v2y_f*v2y_f)/Math.sqrt(50*50 + 50*50);
//   }
  
//   ui.setKnob_3((float)Math.sqrt(bouncey_ball_2.getVelocityX()*bouncey_ball_2.getVelocityX() + bouncey_ball_2.getVelocityY()*bouncey_ball_2.getVelocityY())); //changed
//   ui.setImpactSlider((float) perc*100);
//    double D = 15* (float) perc;
//   if (D>15){
//     D = 15;
//   }
//   delay((int) D);
  
//   if(ui.getCurrentLevel() == 2 || ui.getCurrentLevel() == 3){
//     bouncey_ball_2.setSize(bouncey_ball_2.getSize()*0.925);
//     asteroid.resize((int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize()));
//   }
//   else if(ui.getCurrentLevel()==6 & (body1 == sensor.h_avatar || body2 == sensor.h_avatar)){
    
//     if (bouncey_ball_2.getSize() < 14){
//       bouncey_ball_2.setSize(bouncey_ball_2.getSize()*1.05);
//       asteroid.resize((int) (pixelsPerMeter*bouncey_ball_2.getSize()), (int) (pixelsPerMeter*bouncey_ball_2.getSize()));
//     }
    
//     if (sensor.h_avatar.getSize() >1){
//       sensor.h_avatar.setSize(sensor.h_avatar.getSize()*(0.95));
//     }
//   }
// }


// public float[] calcGravForces(FBody well, float mass){
//     distance = (float)Math.sqrt(Math.pow(sensor.getToolPositionX()-well.getX(), 2)+Math.pow(sensor.getAvatarPositionY()-well.getY(),2));  //calculate distance between the two bodies
//     gravforce = ((grav_const)*hap_mass*mass)/((float)Math.pow(distance,2));   //calculate gravitational force according to the universal gravitation equation        
    
//     angle = (float)Math.acos(abs(sensor.getToolPositionX()-well.getX())/distance);  //use inverse cos to find the angle 
    
//     direction_x = Math.signum(sensor.getToolPositionX()-well.getX());  //get the direction that the x-force should be applied
//     direction_y = Math.signum(well.getY()-sensor.getToolPositionY());  //get the direction that the y-force should be applied
    
//     gravforce_x = direction_x*gravforce*(float)Math.cos(angle);  //use the angle to get the x-comp of gravitational force
//     gravforce_y = direction_y*gravforce*(float)Math.sin(angle);  //use the angle to get the y-comp of gravitational force
     
//     float[] gravforce_arr = new float[]{gravforce_x, gravforce_y};
//     print("Yesssssss \n");  
//     //line(200, 100, 600, 400);
//     return gravforce_arr; 
// }

// void arrow(float x1, float y1, float x2, float y2){
//   x2=x2*10;
//   y2=y2*10;
//   //WORLD_WIDTH = 80; WORLD_HEIGHT = 70; pixelsPerMeter = 10; 

//   //x1 = -x1*2.5+400;
//   //y1 = y1*2-55;
//   x1 = -x1 * (pixelsPerMeter/4) + (WORLD_WIDTH*5);
//   y1 = y1 * (pixelsPerMeter/5) - (WORLD_HEIGHT/2) - 20;
  

//   //700 AND 30
//   y2=y2+y1;
//   x2=-x2+x1;
  
//   line(x1, y1, x2, y2);
//   pushMatrix();
//   translate(x2, y2);
//   float a = atan2(x1-x2, y2-y1);
//   rotate(a);
//   line(0, 0, -10, -10);
//   line(0, 0, 10, -10);
//   popMatrix();
// }

// float reScale(float value, float maxValue, int minScale, int maxScale){
//   return (value/maxValue) * (maxScale - minScale);
// }
// >>>>>>> 09aa7807f6dc24568273d461947cddf50bb1f359
