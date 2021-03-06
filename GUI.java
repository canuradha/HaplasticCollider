import controlP5.*;
import co.haply.hphysics.*;
import processing.core.*;
import processing.core.PGraphics;
import java.util.ArrayList;
import java.util.Arrays;

public class GUI{

    float pixelsPerMeter = 10.0f;
    private PApplet currentApp;
    private ControlP5 ui;
    private Knob knob_1, knob_2, knob_3, knob_4;
    private Button startButton, toggleHaptics, resetSensor, backButton;
    private PFont titleFont, contentFont, LevelTitleFont, questionsFont;
    private Slider Impact_Slider;
    private Textlabel SliderLabel, menuTitle, menuDesc, welcomeTitle, welcomeText;

    private FWorld world;
    private HVirtualCoupling hapticSensor;
    private FBox topBoundary, bottomBoundary, leftBoundary, rightBoundary, controlBackground, controlTop;
    FBox worldBackground;
    private FBox menuRight, menuBottom;
    PImage backgroundpic;
    

    private ArrayList<Knob> knobList;
    private float WORLD_WIDTH, WORLD_HEIGHT, BOUNDARY_SIZE;
    int currentLevel = 0;
    private boolean isStart, isReset, isHapticsOn, isActive;
    
    CollisionQuestions questions = new CollisionQuestions();
    GravityQuestions gravQue = new GravityQuestions();
    
    private int[] Answers;


    public GUI(final processing.core.PApplet applet){
        currentApp = applet;
        ui = new ControlP5(applet);
    }

    public void init(float w_width, float w_height, float b_size){
        WORLD_WIDTH = w_width;
        WORLD_HEIGHT = w_height;
        BOUNDARY_SIZE = b_size;
        
        initWorldBoundary();
        initControls();
    }

    public void initControls(){
        titleFont = currentApp.createFont("Arial Bold",50f);
        contentFont = currentApp.createFont("Arial", 20f);
        LevelTitleFont = currentApp.createFont("Arial Bold", 30f);
        questionsFont = currentApp.createFont("Arial", 12f);

        knob_1 = ui.addKnob("Ball 1 Speed")
                            .setRange(0,10)
                            .setValue(0)
                            .setPosition(100, 570)
                            .setRadius(50)
                            .setDragDirection(Knob.VERTICAL)
                            .hide();
  
        knob_2 =  ui.addKnob("Ball 1 Mass")
                            .setRange(1,10)
                            .setValue(0)
                            .setPosition(260, 570)
                            .setRadius(50)
                            .setDragDirection(Knob.VERTICAL)
                            .hide();

        knob_3 =  ui.addKnob("Ball 2 Speed")
                            .setRange(1,10)
                            .setValue(0)
                            .setPosition(420, 570)
                            .setRadius(50)
                            .setDragDirection(Knob.VERTICAL)
                            .hide();
        
        knob_4 =  ui.addKnob("Ball 2 Mass")
                            .setRange(1,10)
                            .setValue(0)
                            .setPosition(580, 570)
                            .setRadius(50)
                            .setDragDirection(Knob.VERTICAL)
                            .hide();   

        knobList = new ArrayList();
        knobList.add(knob_1);
        knobList.add(knob_2);
        knobList.add(knob_3);
        knobList.add(knob_4);
                            
        Impact_Slider = ui.addSlider("Impact Force Slider")
                            .setLabelVisible(false)
                            .setPosition(630,580)
                            .setSize(150,30)
                            .setRange(0,100)
                            .setValue(0)
                            .setColorValue(0x000000ff)
                            .hide(); 
                             
        SliderLabel = ui.addTextlabel("Impact Force (%)")
                            .setText("Impact Force (%)")
                            .setPosition(635,630)
                            .setFont(questionsFont)
                            .setColorValue(0x000000ff)
                            .hide();  

        startButton = ui.addButton("Start")
                            .setValue(0)
                            .setPosition( 1030, 610)
                            .setSize(100,50)
                            .onRelease(nextCallback);
                            
        backButton = ui.addButton("Back")
                            .setValue(0)
                            .setPosition( 870, 610)
                            .setSize(100,50)
                            .onRelease(previousCallback)
                            .hide();

        toggleHaptics = ui.addButton("tHaply")
                            .setPosition( 1030, 540)
                            .setSize(100,50)
                            .setSwitch(true)
                            .setLabel("Haply OFF")
                            .onRelease(toggleHapticsCallback)
                            .hide();

        resetSensor = ui.addButton("rSensor")
                            .setPosition( 870, 540)
                            .setSize(100,50)
                            .setLabel("Reset Sensor")
                            .onRelease(resetCallback)
                            .hide();                         

        menuTitle =  ui.addTextlabel("LevelTitle")
                        .setText("")
                        .setSize(300, 50)
                        .setPosition(850, 20)
                        .setFont(LevelTitleFont)
                        .setColorValue(0x00000000)
                        .hide();

        menuDesc =  ui.addTextlabel("LevelDesc")
                        .setMultiline(true)
                        .setText("")
                        .setSize(320, 400)
                        .setPosition(850, 90)
                        .setFont(questionsFont)
                        .setColorValue(0x00000060)
                        .hide();

        welcomeTitle = ui.addTextlabel("Wel")
                        .setText("WELCOME")
                        .setPosition(450, 100)
                        .setSize(200, 100)
                        .setFont(titleFont)
                        .setColorValue(0x00000000)
                        .hide();
        
        welcomeText = ui.addTextlabel("welcomeContent")
            .setMultiline(true)
            .setText("Hello and welcome to Haplastic Collider! The following modules aim to act as an immersive educational tool for teaching the users about fundamentals of two essential physics concepts in an engaging way! This includes collisions and gravitational forces that are experianced in everyday life, whether its watching an apple fall from a tree like Isaac Newton or playing a game of pool or croquet. \n\nThe following modules use a haptics interface \"Haply\" to allow you to feel the forces that would result from either a collision (impact) or gravity. This is done to allow you to feel the difference of certain factors like mass and velocity make in the magnitude of these forces. To ensure the best experience, we highly recommend you to play with the changeable variables, hold on to the Haply and have fun!")
            .setSize(800, 500)
            .setPosition(200, 200)
            .setFont(contentFont)
            .setColorValue(0x00000050)
            .hide();
                        
       

    }

    public void initWorldBoundary(){
        world = new FWorld();

        topBoundary = new FBox(WORLD_WIDTH + 80, BOUNDARY_SIZE);
        topBoundary.setPosition(WORLD_WIDTH/2, BOUNDARY_SIZE/2);
        topBoundary.setFill(10);
        topBoundary.setStaticBody(true);
        topBoundary.setName("Boundary Top");
        
        rightBoundary = new FBox(BOUNDARY_SIZE, WORLD_HEIGHT);
        rightBoundary.setPosition((WORLD_WIDTH + 160 - BOUNDARY_SIZE)/ 2, WORLD_HEIGHT/2);
        rightBoundary.setFill(10);
        rightBoundary.setStaticBody(true);

        leftBoundary = new FBox(BOUNDARY_SIZE, WORLD_HEIGHT);
        leftBoundary.setPosition(BOUNDARY_SIZE/2, WORLD_HEIGHT/2);
        leftBoundary.setFill(10);
        leftBoundary.setStaticBody(true);
        leftBoundary.setName("Boundary Left");

        bottomBoundary = new FBox(WORLD_WIDTH + 80, BOUNDARY_SIZE);
        bottomBoundary.setPosition(WORLD_WIDTH/2, WORLD_HEIGHT - BOUNDARY_SIZE/2);
        bottomBoundary.setFill(10);
        bottomBoundary.setStaticBody(true);

        controlBackground = new FBox(WORLD_WIDTH, 15);
        controlBackground.setPosition(WORLD_WIDTH/2, WORLD_HEIGHT - 7.5f);
        controlBackground.setStaticBody(true);
        controlBackground.setFill(100);    

        menuRight = new FBox(BOUNDARY_SIZE, WORLD_HEIGHT);
        menuRight.setPosition(WORLD_WIDTH + BOUNDARY_SIZE/2, WORLD_HEIGHT/2);
        menuRight.setFill(10);
        menuRight.setStaticBody(true);
        menuRight.setName("Boundary Right");

        controlTop = new FBox(WORLD_WIDTH,BOUNDARY_SIZE);
        controlTop.setPosition(WORLD_WIDTH/2, WORLD_HEIGHT - (BOUNDARY_SIZE/2 + 15));
        controlTop.setFill(10);
        controlTop.setStaticBody(true);
        controlTop.setName("Boundary Bottom");
        
        worldBackground = new FBox (WORLD_WIDTH, WORLD_HEIGHT/2 + 18f);
        worldBackground.setPosition(WORLD_WIDTH/2, WORLD_HEIGHT - 42.5f);
        worldBackground.setStaticBody(true);
        worldBackground.setFill(1);
        worldBackground.setSensor(true);
        

        world.add(topBoundary);
        world.add(bottomBoundary);        
        world.add(leftBoundary);
        world.add(rightBoundary);

        world.setGravity(0,0);
        world.setGrabbable(false);
    }

    public void welcome(){
     
        welcomeTitle.show();
        welcomeText.show();
        startButton.show();

    }

   

    public void initBackground(){

        world.add(menuRight);
        world.add(controlTop);
        world.add(controlBackground);
        world.add(worldBackground);

        isStart = false;
    }

    // add the methods for other levels here
    public void initCollisions(){
        initBackground();
        knob_2.show();
        knob_1.show();
        knob_4.show();
        knob_3.show();

        toggleHaptics.show();
        resetSensor.show();
    }
    
     public void initElasticCollisions(){
        initBackground();
        showKnobs(3, true, "Mass of Effector", "Mass of Ball", "Velocity of Ball");
        Impact_Slider.show();
        SliderLabel.show();
        menuTitle.setText("Elastic Collisions").show();
        menuDesc.setText("Elastic collisions have no loss of kinetic energy; in other words, both momentum and kinetic energy are the same before and after the collision. In the real world, examples of elastic collisions include scattering of light, atomic or subatomic particles.  \n\n Kinetic energy is defined mathematically as: \n\n Ke = 0.5*m*v^2 (1a), where m = mass, v = velocity \n\n Momentum is defined mathematically by the formula: \n\n p = mv (1b), where m = mass, v = velocity \n\nThis means that while momemtum scales linearly with mass and velocity, kinetic energy scales linearly with mass but exponenetially with velocity. The higher the mass and konetic energy of the objects involved in the collision, the larger the impact force created on collision \n\n\n controls: \n\t Q, A - Increase/ Decrease Mass of the effector\n\n\t W, S - Increase/ Decrease Mass of the Ball\n\n\t E, D - Increase/ Decrease Velocity of the Ball").show();
        
    }
    
     public void initInelasticCollisions(){
        initBackground();
        showKnobs(3, true, "Mass of Effector", "Mass of Ball",  "Velocity of Ball");
        backButton.show();
        Impact_Slider.show();
        SliderLabel.show();
        menuTitle.setText("Inelastic Collisions").show();
        menuDesc.setText("In inelastic collisions, some of the kinetic energy of the objects is lost to the surroundings or changed into another form of energy such as sound or heat. Because of this loss, kinetic energy is no longer conserved in the objects involved through the collision, although momentum is. Therefore: \n\n KEi ??? Kef,\n\n where KEi is Kinetic energy before collision and KEf is after.  \n\nInelastic collisions are more common in our daily lives, including things like car crashes, the game of pool, or the classic Newton???s cradle. \n\nA major difference between elastic and inelastic collisions is this loss in energy. Due to the loss of kinetic energy in inelastic collisions, two collsions, one elastic and one inelastic, with the exact same intitial parameters (object masses and velocities), will have different outcomes.\n\n\n controls: \n\t Q, A - Increase/ Decrease Mass of the effector\n\n\t W, S - Increase/ Decrease Mass of the Ball\n\n\t E, D - Increase/ Decrease Velocity of the Ball").show();

    }
    
     public void initGravity_single(){
        initBackground();
        showKnobs(2, false, "Mass of Effector", "Mass of Well");
        menuTitle.setText("Gravitational Forces").show();
        menuDesc.setText("Gravity is the universal force that "+
        "causes bodies to be drawn towards each other. It is what keeps you on the ground and causes objects to fall. "+
        "All objects are attracted to each other by the force of gravity defined by the universal gravitation equation below: \n\n"+
        "Gravitational Force = G * m1 * m2 / d??, \nWhere G is the universal gravitation constant (G = 6.67 * 10-11 Nm??/kg??), "+
        "m1 is the mass of body 1, m2 is the mass of body 2, and d is the distance between the centre of the two bodies. \n\n"+
        "Based on this equation, the force of gravity is directly proportional to the mass of the bodies and inversely proportional"+
        " to the square of the distance between them. \n\nBlack holes are a place in "+
        "space where the pull of gravitational force is so strong that even light cannot escape. Move the end effector around the screen "+
        "and observe how the force feels as you move closer to the black hole. \n\n\n controls: \n\t Q, A - Increase/ Decrease Mass of the effector\n\n\t W, S - Increase/ Decrease Mass of the Gravity Well").show();
    }
    
    public void initGravity_triple(){
        initBackground();
        showKnobs(4, false, "Mass of Effector", "Mass of Well", "Mass of Well 2", "Mass of Well 3");
        menuTitle.setText("Gravitational Forces").show();
        menuDesc.setText("When there are multiple bodies in a system, the gravitational force between the bodies interacts "+
        "in a manner that is dependent on their mass and distance. Move the end effector around the screen and fell how the "+
        "direction of force changes based on your proximity to the different bodies. When you are ready, answer the questions "+
        "below to test your understanding. ").setSize(330, 150).setPosition(850, 60).show();

        int posX = 850;
        int posY = 150;   
        toggleActive(false);

        for(int i = 0; i < gravQue.getQuestions().size() ; i++){
            addQuestion(
                gravQue.getQuestions().get(i)[0], 
                gravQue.getQuestions().get(i)[1], 
                posX, 
                posY + i*100,
                Arrays.copyOfRange(gravQue.getQuestions().get(i), 2, gravQue.getQuestions().get(i).length) 
            );
        }  
        Answers = new int[gravQue.getAnswers().length];  
    }

    public void initAllCollisions(){
        initBackground();
        showKnobs(3, false, "Mass of Effector", "Mass of Ball 1", "Mass of Ball 2");
        toggleActive(false);
        menuTitle.setText("Elastic and Inelastic").show();

            
        int posX = 850;
        int posY = 90;   


        for(int i = 0; i < questions.getQuestions().size() ; i++){
            addQuestion(
                questions.getQuestions().get(i)[0], 
                questions.getQuestions().get(i)[1], 
                posX, 
                posY + i*105,
                Arrays.copyOfRange(questions.getQuestions().get(i), 2, questions.getQuestions().get(i).length) 
            );
        }  
        Answers = new int[questions.getAnswers().length];  
        ui.addListener(radioListener);
     }
    
    public void initSandbox(){
        initBackground();
        menuDesc.setText("This is the final level, good work so far! For this level, you must bring the effector (rocket) to the target area, earth. While travelling, you will find wild planets, asteroids and blackholes blocking your path. Do your best to figure out how to get back home!").show();
        menuTitle.setText("Sandbox").show() ;
        
        ui.addTextlabel("hint")
            .setText("HINT: Inelastic collisions may result in a loss of mass...")
            .setPosition(80, 625)
            .setSize(100, 100)
            .setFont(contentFont)
            .setColorValue(0x00000000);
        
        toggleActive(false);
    }

    public void initEnd(){
        for(ControllerInterface<?>  t: ui.getAll()){
            t.hide();
        }
        switchHaptics(true);
        welcomeTitle.setPosition(430, 100).setText("!! Congradulations !!").show();
        welcomeText.setText("Thanks For Participating...!!! \n\nHope you now have a better understanding about collision mechanics and gravitational forces").show();
        clearWorld();
        isStart = false;
    }

    // Button Listeners
    private CallbackListener nextCallback = new CallbackListener(){
        public void controlEvent(CallbackEvent event) {
            if(currentLevel < 6){
                for(ControllerInterface<?>  t: ui.getAll()){
                    if(!t.getName().equals("Start")){
                        t.hide();
                    }
                    if(t.getName().equals("Back") && currentLevel > 1){
                        System.out.println(currentLevel);
                        t.show();
                    }
                }
                if(currentLevel == 0){
                    event.getController().setLabel("Next");
                }
                
                switchHaptics(true);
                toggleHaptics.show();
                resetSensor.show();
                clearWorld();
                currentLevel++;
                isStart = true;
            }
        }
    };

    private CallbackListener previousCallback = new CallbackListener(){
        public void controlEvent(CallbackEvent event) {
            if(currentLevel > 1){
                for(ControllerInterface<?>  t: ui.getAll()){
                    if(!t.getName().equals("Back") || currentLevel == 2){
                        t.hide();
                    }
                    if(t.getName().equals("Start")){
                        t.show();
                    }
                }
               
                switchHaptics(true);                
                currentLevel--;
                toggleHaptics.show();
                resetSensor.show();
                isStart = true;
                clearWorld();
            }
        }
    };

    private CallbackListener toggleHapticsCallback = new CallbackListener(){
        public void controlEvent(CallbackEvent event) {
            switchHaptics(isHapticsOn);          
        }
    };

    private CallbackListener resetCallback = new CallbackListener(){
        public void controlEvent(CallbackEvent event) {
            isReset = true; 
            switchHaptics(true); 
        }
    };


    // radiobutton Listeners
    private ControlListener radioListener = new ControlListener(){
        public void controlEvent(ControlEvent event){
            if(event.isGroup()){
                Answers[Integer.parseInt(event.getGroup().getName().split("_")[1]) - 1] = (int) event.getGroup().getValue();
                if(currentLevel == 3 && Arrays.equals(Answers, questions.getAnswers())){
                    toggleActive(true);
                }else if(currentLevel == 5 && Arrays.equals(Answers, gravQue.getAnswers())){
                    toggleActive(true);
                }else {
                    toggleActive(false);
                }
            }
        }
    };


    // questions
    private void addQuestion(String label, String qText, int posX, int posY, String [] answers){
        int ansLineSpace = qText.length() > 205 ? 65 : 55;
        ui.addTextlabel(label)
            .setMultiline(true)
            .setValue(qText)
            .setSize(320, ansLineSpace)
            .setPosition(posX, posY)
            .setFont(questionsFont)
            .setColorValue(0x00000060);

        RadioButton temp  = ui.addRadioButton(label+"_Ans")
            .setItemsPerRow(2)
            .setSpacingColumn(320/2 + 10)
            .setSpacingRow(5)
            .setPosition(posX + 10, posY + ansLineSpace);
        
        for(int i=0; i< answers.length; i++){
            temp.addItem(answers[i], i+1);
        }
        temp.setColorLabels(100);
        
    }


    // Setters
    public void setKnob_1(float value){
        knob_1.setValue(value);
    }
    public void setKnob_2(float value){
        knob_2.setValue(value);
    }    
    public void setKnob_3(float value){
        knob_3.setValue(value);
    }
    public void setKnob_4(float value){
        knob_4.setValue(value);
    }
    public void setImpactSlider(float value){
        Impact_Slider.setValue(value);
    }
    
    public void setIsReset(boolean rValue){
        isReset = rValue;
    }

    public void setIsHapticsOn(boolean hValue){
        isHapticsOn = hValue;
    }

    public void setSensor(HVirtualCoupling s){
        hapticSensor = s;
    }


    //Getters
    public float getKnob_1(){
        return knob_1.getValue();
    }
    public float getKnob_2(){
        return knob_2.getValue();
    }   
    public float getKnob_3(){
        return knob_3.getValue();
    }
    public float getKnob_4(){
        return knob_4.getValue();
    }
    public float getImpactSlider(){
        return Impact_Slider.getValue();
    }

    
    public FWorld getWorld(){
        return world;
    }

    public int getCurrentLevel(){
        return currentLevel;
    }

    public boolean getIsStart(){
        return isStart;
    }
    
    public boolean getIsReset(){
        return isReset;
    }

    public boolean getIsHapticsOn(){
        return isHapticsOn;
    }

    //world methods
    public void clearWorld(){
        world.clear();

        world = new FWorld();
        world.setGravity(0,0);
        world.setGrabbable(false);
        world.add(topBoundary);
        world.add(bottomBoundary);        
        world.add(leftBoundary);
        world.add(rightBoundary);

    }

    public void endSim(){
        currentLevel = 7;
        isStart = true;
    }

    private void switchHaptics(boolean isOn){
         if(isOn){ // turn off
            toggleHaptics.setOff();
            toggleHaptics.setLabel("Haply OFF");
            isHapticsOn = false;
            if(hapticSensor != null)
                hapticSensor.h_avatar.setSensor(true);
        }else{
            toggleHaptics.setOn();
            toggleHaptics.setLabel("Happly ON");
            isHapticsOn = true;
            if(hapticSensor != null)
                hapticSensor.h_avatar.setSensor(false);
        }   
    }

    private void showKnobs(float number, boolean isSliderPresent, String ...knobNames){
        float initX = 100, spacing = 150;
        if(isSliderPresent){
            initX = 50;
        }
        for(int i=0; i< number; i++){
            knobList.get(i).setPosition(initX + (i*spacing), 570).setLabel(knobNames[i]).show();
        }
        if(currentLevel <= 2){
            knob_3.setRange(1,50);
        }else{ 
            knob_3.setRange(1,10);
        }
    }

    private void toggleActive(boolean isActive){
        if(isActive){
            this.startButton.show();
        }else{
            this.startButton.hide();
        }
    }
    
}
