import java.util.ArrayList;

public class Q1{
    private ArrayList<String[]> Questions = new ArrayList();
    // private ArrayList<Integer> Answers = new ArrayList();
    private int [] Answers;

    public Q1(){
        Questions.add(new String[]{
            "Q1_1", 
            "Given an inelastic collision where object 1 has a pre-impact kinetic energy of 10J and object 2 has a pre-impact kinetic energy of 20J, what is the total kinetic energy of the system after collision?", 
            "30 J", 
            "25 J",
            "> 30 J",
            "< 30 J"
        });
        Questions.add(new String[]{
            "Q1_2",
            "An object with a mass of 10 Kg and a velocity of 10m/s has a momentum of 100 Kg*m/s and a kinetic energy of 500J. If the velocity were to decrease to 5m/s, what would the resulting momentum and kinetic energy be?", 
            "50 Kg*m/s and 250 J", 
            "50 Kg*m/s and 125 J", 
            "25 Kg*m/s and 250 J", 
            "25 Kg*m/s and 125 J"
        });
        Questions.add(new String[]{
            "Q1_3", 
            "In a perfectly elastic collision between object 1, mass: 2Kg, velocity: 5m/s in the +X direction, and a static, infinitely massive wall, what will be the resulting velocity of object 1 after collision?", 
            "4m/s in the +X direction", 
            "5 m/s in the +X direction", 
            "2.5 m/s in the +X direction", 
            "5m/s in the -X direction"
        });
        Questions.add(new String[]{
            "Q1_4", 
            "Imagine a pool ball traveling with a certain velocity 'V' collides with an identical, stationary pool ball (mass and size are identical). Assuming the collision is perfectly elastic in nature, what will happen to the second, initially stationary ball?", 
            "Begin moving with with Velocity 'V'", 
            "Remain stationary", 
            "Move with 1/2 'V'", 
            "None of the above"
        });

        // Answers.add(4);
        // Answers.add(2);
        // Answers.add(4);
        // Answers.add(1);
        Answers = new int[] {4, 2, 4, 1};

    }

    public ArrayList<String[]> getQuestions(){
        return Questions;
    }

    public int[] getAnswers(){
        return Answers;
    }
    
}
