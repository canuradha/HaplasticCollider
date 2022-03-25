import controlP5.*;
import co.haply.hphysics.*;
import processing.core.*;
import java.util.ArrayList;
import java.util.List;

public class GUI{

    private PApplet currentApp;
    private ControlP5 ui;
    private Knob plateVelocity, ballVelocity, plateM, ballM;
    private PFont titleFont, contentFont;

    private FWorld world;
    private FBox topBoundary, bottomBoundary, leftBoundary, rightBoundary, controlBackground, controlTop;
    private FBox menuRight, menuBottom;

    private float WORLD_WIDTH, WORLD_HEIGHT, BOUNDARY_SIZE;
    int currentLevel = 0;
    boolean isStart;

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
    }

    public void initControls(){
        titleFont = currentApp.createFont("Arial Bold",50f);
        contentFont = currentApp.createFont("Arial", 20f);

        plateVelocity =  ui.addKnob("Plate Speed")
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
    }

    public void welcome(){
        // for(String font: PFont.list()){
        //     System.out.println(font);
        // }

        ui.addButton("Start")
            .setValue(0)
            .setPosition( 1050, 600)
            .setSize(100,50)
            .onRelease(nextCallback);

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
    }
    
    public void initGravity(){
      initBackground();
      
    }



    
    // Button Listeners
    private CallbackListener nextCallback = new CallbackListener(){
        public void controlEvent(CallbackEvent event) {
            if(currentLevel == 0){
                event.getController().setLabel("Next");
                for(ControllerInterface<?>  t: ui.getAll()){
                    if(!t.getName().equals("Start")){
                        t.hide();
                    }
                }
            } 
            clearWorld();
            currentLevel++;
            isStart = true;
        }
    };


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
    
}
