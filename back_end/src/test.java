import com.structed.constants.Consts;
import com.structed.dal.Reader;
import com.structed.dal.Writer;
import com.structed.data.InstancesContainer;
import com.structed.data.Logger;
import com.structed.data.entities.PredictedLabels;
import com.structed.data.entities.Vector;
import com.structed.models.StructEDModel;
import com.structed.models.algorithms.PassiveAggressive;

import java.util.ArrayList;

import static com.structed.data.Factory.getReader;
import static com.structed.data.Factory.getWriter;

/**
 * Created by yossiadi on 01/12/2015.
 *
 */
public class test {
    public static void main(String[] args) {
        try{
            // ============================ VOWEL DURATION DATA ============================ //
            Logger.info("Loading vowel duration data.");
            String testPath = "data/tutorial/test.txt";
            String model_path = "models/pa.tutorial.vowel.model";

            int readerType = 2;
            int numExamples2Display = 1;
            Reader reader = getReader(readerType);

            // load the data
            InstancesContainer vowelTestInstances = reader.readData(testPath, Consts.SPACE, Consts.COLON_SPLITTER);
            if (vowelTestInstances.getSize() == 0) return;

            ArrayList<Double> arguments;
            StructEDModel vowel_model;
            Vector W;
            ArrayList<Double> task_loss_params = new ArrayList<Double>(){{add(0.0);add(0.0);}}; // task loss parameters

            Logger.info("");
            Logger.info("===================================================");
            Logger.info("============= PASSIVE AGGRESSIVE ============");
            Logger.info("");
            W = new Vector() {{put(0, 0.0);}}; // init the first weight vector
            arguments = new ArrayList<Double>() {{add(0.5);}}; // model parameters for PA: eta and lambda
            vowel_model = new StructEDModel(W, new PassiveAggressive(), new TaskLossVowelDuration(),
                    new InferenceVowelDuration(), null, new FeatureFunctionsVD(), arguments); // create the model
            vowel_model.loadModel(model_path);
            ArrayList<PredictedLabels> labels = vowel_model.predict(vowelTestInstances, task_loss_params, numExamples2Display, true); // predict

            String outputFile = "res/res.txt";
            Writer writer = getWriter(0);
            for (int i=0 ; i<labels.size() ; i++){
                String path = vowelTestInstances.getInstance(i).path;
                writer.writeScoresFile(path, outputFile, labels.get(i), 1);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}