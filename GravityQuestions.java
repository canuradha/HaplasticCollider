import java.util.ArrayList;

public class GravityQuestions{
    private ArrayList<String[]> Questions = new ArrayList();
    // private ArrayList<Integer> Answers = new ArrayList();
    private int [] Answers;

    public GravityQuestions(){
        Questions.add(new String[]{
            "GQ_1", 
            "If the distance between Earth and the moon is doubled, with no change in mass, the gravitational force of attraction is:", 
            "Decreased to 0.5x initial value. ", 
            "Increased to 2x initial value. ",
            "Decreased to 1/4 its initial value. ",
            "Remains unchanged."
        });
        Questions.add(new String[]{
            "GQ_2",
            "If the mass of Earth is decreased to half its original mass, with no change in radius or distance, your force of gravity acting on you is:", 
            "Decreased to 0.5x initial value.", 
            "Increased to 2x initial value.",
            "Increased to 4x its initial value.",
            "Will remain unchanged."
        });
        Questions.add(new String[]{
            "GQ_3", 
            "The gravitational force between a small planet and an asteroid in space is 200N. Overtime, the mass of the asteroid is eroded to half its original size and the distance between the asteroid and the planet is also decreased by half. What is the gravitational force between the planet and asteroid after accounting for erosion and movement?", 
            "100N", 
            "200N", 
            "400N", 
            "1600N"
        });
        Questions.add(new String[]{
            "GQ_4", 
            "Mass A is of significantly larger mass than Mass B as they move towards each other due to the mutual force of gravitation. Which force, if either, is greater?", 
            "Force on Mass A", 
            "Force on Mass B", 
            "Both Forces on A and B are equal",
            "Force on Mass A until \ndistance 'd' then Force on B"
        });

        // Answers.add(4);
        // Answers.add(2);
        // Answers.add(4);
        // Answers.add(1);
        Answers = new int[] {3, 1, 3, 3};
        // Answers = new int[] {3, 1, 3};

    }

    public ArrayList<String[]> getQuestions(){
        return Questions;
    }

    public int[] getAnswers(){
        return Answers;
    }
    
}