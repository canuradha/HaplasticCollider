import java.util.ArrayList;

public class Q1{
    private ArrayList<String[]> Questions = new ArrayList();
    private ArrayList<String> Answers = new ArrayList();

    public Q1(){
        Questions.add(new String[]{"Q1_1", "Sample Question 1", "Ans 1", "Ans 2", "Ans 3", "Ans 4", "Ans 5"});
        Questions.add(new String[]{"Q1_2", "Sample Question 2", "Ans_1", "Ans_2", "Ans_3", "Ans_4", "Ans_5"});
        Questions.add(new String[]{"Q1_3", "Sample Question 3", "Ans 1 ", "Ans 2 ", "Ans 3 ", "Ans 4 ", "Ans 5 "});

        Answers.add("1");
        Answers.add("1,4");
        Answers.add("3");

    }

    public ArrayList<String[]> getQuestions(){
        return Questions;
    }

    public ArrayList<String> getAnsweres(){
        return Answers;
    }
    
}
