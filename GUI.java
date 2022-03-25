import controlP5.*;
import co.haply.hphysics.*;
import processing.core.*;
import java.util.List;
import java.util.Arrays;

public class GUI{

    private PApplet currentApp;
    private ControlP5 ui;
    private Knob plateVelocity, ballVelocity, plateM, ballM;
    private Button startButton, toggleHaptics, resetSensor;
    private PFont titleFont, contentFont, LevelTitleFont, questionsFont;

    private FWorld world;
    private HVirtualCoupling hapticSensor;
    private FBox topBoundary, bottomBoundary, leftBoundary, rightBoundary, controlBackground, controlTop;
    private FBox menuRight, menuBottom;

    private float WORLD_WIDTH, WORLD_HEIGHT, BOUNDARY_SIZE;
    int currentLevel = 0;
    boolean isStart, isReset, isHapticsOn;


    Q1 questions = new Q1();


    public GUI(final processing.core.PApplet applet){
        currentApp = applet;
        ui = new ControlP5(applet);
    }

    public void init(float w_width, float w_height, float b_size){
        WORLD_WIDTH = w_width;
        WORLD_HEIGHT = w_height;
        BOUNDARY_SIZE = b_size;
        
        initWorldBoundary();
        // initBackground(w_width, w_height, b_size);
        initControls();
        welcome();
        // allCollissions();
        // initCollisions();
    }

    public void initControls(){
        titleFont = currentApp.createFont("Arial Bold",50f);
        contentFont = currentApp.createFont("Arial", 20f);
        LevelTitleFont = currentApp.createFont("Arial Bold", 30f);
        questionsFont = currentApp.createFont("Arial", 15f);

        plateVelocity = ui.addKnob("Plate Speed")
                            .setRange(0,500)
                            .setValue(0)
                            .setPosition(100, 570)
                            .setRadius(50)
                            .setDragDirection(Knob.VERTICAL)
                            .hide();
  
        plateM =  ui.addKnob("Plate Mass")
                            .setRange(1,10)
                            .setValue(0)
                            .setPosition(260, 570)
                            .setRadius(50)
                            .setDragDirection(Knob.VERTICAL)
                            .hide();

        ballVelocity =  ui.addKnob("ball Speed")
                            .setRange(0,500)
                            .setValue(0)
                            .setPosition(420, 570)
                            .setRadius(50)
                            .setDragDirection(Knob.VERTICAL)
                            .hide();
        
        ballM =  ui.addKnob("Ball Mass")
                            .setRange(1,10)
                            .setValue(0)
                            .setPosition(580, 570)
                            .setRadius(50)
                            .setDragDirection(Knob.VERTICAL)
                            .hide();   

        startButton = ui.addButton("Start")
                            .setValue(0)
                            .setPosition( 1030, 600)
                            .setSize(100,50)
                            .onRelease(nextCallback);

        toggleHaptics = ui.addButton("tHaply")
                            .setPosition( 1030, 530)
                            .setSize(100,50)
                            .setSwitch(true)
                            .setLabel("Haply OFF")
                            .onRelease(toggleHapticsCallback)
                            .hide();

        resetSensor = ui.addButton("rSensor")
                            .setPosition( 870, 530)
                            .setSize(100,50)
                            .setLabel("Reset Sensor")
                            .onRelease(resetCallback)
                            .hide();                         

        ui.addListener(radioListener);

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

        controlTop = new FBox(WORLD_WIDTH,BOUNDARY_SIZE);
        controlTop.setPosition(WORLD_WIDTH/2, WORLD_HEIGHT - (BOUNDARY_SIZE/2 + 15));
        controlTop.setFill(10);
        controlTop.setStaticBody(true);

        world.add(topBoundary);
        world.add(bottomBoundary);        
        world.add(leftBoundary);
        world.add(rightBoundary);

        world.setGravity(0,0);
        world.setGrabbable(false);
        // world.setEdgesRestitution(.4f);
    }

    public void welcome(){
     
        ui.addTextlabel("Wel")
            .setText("WELCOME")
            .setPosition(450, 100)
            .setSize(200, 100)
            .setFont(titleFont)
            .setColorValue(0x00000000);
        
        ui.addTextlabel("welcomeContent")
            .setMultiline(true)
            .setText("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Eu volutpat odio facilisis mauris sit amet. Ut sem nulla pharetra diam sit amet. Et leo duis ut diam quam nulla porttitor massa id. Pretium lectus quam id leo in vitae turpis massa. Senectus et netus et malesuada fames ac turpis egestas integer. A arcu cursus vitae congue mauris. Quis blandit turpis cursus in hac. Nunc scelerisque viverra mauris in aliquam sem. Mi proin sed libero enim sed faucibus turpis in eu. Erat nam at lectus urna duis. Imperdiet proin fermentum leo vel orci porta non. Integer enim neque volutpat ac tincidunt vitae semper quis lectus. Vel elit scelerisque mauris pellentesque pulvinar pellentesque habitant morbi tristique. Rhoncus aenean vel elit scelerisque. Tristique sollicitudin nibh sit amet commodo nulla. Nunc sed velit dignissim sodales ut eu sem integer vitae. Nunc sed augue lacus viverra vitae congue. Lacus suspendisse faucibus interdum posuere lorem ipsum dolor sit.")
            .setSize(800, 500)
            .setPosition(200, 200)
            .setFont(contentFont)
            .setColorValue(0x00000050);

        startButton.show();

    }

    public void initBackground(){

        world.add(menuRight);
        world.add(controlTop);
        world.add(controlBackground);

        isStart = false;
    }

    // add the methods for other levels here
    public void initCollisions(){
        initBackground();
        plateVelocity.show();
        ballVelocity.show();
        plateM.show();
        ballM.show();

        toggleHaptics.show();
        resetSensor.show();
    }

    public void allCollissions(){
        initBackground();
        ui.addButton("Next")
            .setValue(0)
            .setPosition( 1050, 600)
            .setSize(100,50)
            .onRelease(nextCallback)
            .setLock(true);

        ui.addTextlabel("LevelTitle")
            .setText("Elastic and Inelastic \nCollisions")
            .setSize(300, 50)
            .setPosition(850, 20)
            .setFont(LevelTitleFont)
            .setColorValue(0x00000000);

            
            int posX = 850;
            int posY = 100;   


            for(int i = 0; i < questions.getQuestions().size() ; i++){
                addQuestion(
                    questions.getQuestions().get(i)[0], 
                    questions.getQuestions().get(i)[1], 
                    posX, 
                    posY + i*50,
                    Arrays.copyOfRange(questions.getQuestions().get(i), 2, questions.getQuestions().get(i).length) 
                );
            }         
            

    }

    // Button Listeners
    private CallbackListener nextCallback = new CallbackListener(){
        public void controlEvent(CallbackEvent event) {
            if(currentLevel == 0){
                event.getController().setLabel("Next");
            }
            for(ControllerInterface<?>  t: ui.getAll()){
                if(!t.getName().equals("Start")){
                    t.hide();
                }
            }
            clearWorld();
            currentLevel++;
            isStart = true;
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
                // switch(event.getName())
                System.out.println(event.group().getName());
            }
        }
    };


    // questions
    private void addQuestion(String label, String qText, int posX, int posY, String [] answers){
        ui.addTextlabel(label)
            .setMultiline(true)
            .setText(qText)
            .setSize(350, 20)
            .setPosition(posX, posY)
            .setFont(questionsFont)
            .setColorValue(0x00000060);

        RadioButton temp  = ui.addRadioButton(label+"Ans")
            .setItemsPerRow(answers.length)
            .setSpacingColumn(300/answers.length)
            .setPosition(posX, posY + 30);
        
        for(int i=0; i< answers.length; i++){
            temp.addItem(answers[i], i+1);
        }
        temp.setColorLabels(100);
        
    }


    // Setters
    public void setPlateVelocity(float value){
        plateVelocity.setValue(value);
    }

    public void setBallVelocity(float value){
        ballVelocity.setValue(value);
    }

    public void setPlateMass(float value){
        plateM.setValue(value);
    }

    public void setBallMass(float value){
        ballM.setValue(value);
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
    public float getPlateVelocity(){
        return plateVelocity.getValue();
    }

    public float getBallVelocity(){
        return ballVelocity.getValue();
    }

    public float getPlateMass(){
        return plateM.getValue();
    }

    public float getBallMass(){
        return ballM.getValue();
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
    
}