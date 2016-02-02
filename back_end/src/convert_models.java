import com.structed.data.entities.Vector;
import com.structed.models.StructEDModel;
import com.structed.models.algorithms.PassiveAggressive;

import java.io.IOException;
import java.text.ParseException;
import java.util.ArrayList;

/**
 * Created by yossiadi on 01/12/2015.
 *
 */
public class convert_models {
    public static void main(String[] args) throws ParseException, IOException, ClassNotFoundException {

        int readerType = 2;
        ArrayList<String> pathes = new ArrayList<String>(){{
//            add("models/jordana_classifier_dl_5_epochs_fold_01.weights");
//            add("models/jordana_classifier_dl_5_epochs_fold_02.weights");
//            add("models/jordana_classifier_dl_5_epochs_fold_03.weights");
//            add("models/jordana_classifier_dl_5_epochs_fold_04.weights");
//            add("models/jordana_classifier_dl_5_epochs_fold_05.weights");
//            add("models/jordana_classifier_dl_5_epochs_fold_06.weights");
//            add("models/jordana_classifier_dl_5_epochs_fold_07.weights");
//            add("models/jordana_classifier_dl_5_epochs_fold_08.weights");
//            add("models/jordana_classifier_dl_5_epochs_fold_09.weights");
//            add("models/jordana_classifier_dl_5_epochs_fold_10.weights");
            add("models/jordana_no_classifier_dl_5_epochs_fold_01.weights");
            add("models/jordana_no_classifier_dl_5_epochs_fold_02.weights");
            add("models/jordana_no_classifier_dl_5_epochs_fold_03.weights");
            add("models/jordana_no_classifier_dl_5_epochs_fold_04.weights");
            add("models/jordana_no_classifier_dl_5_epochs_fold_05.weights");
            add("models/jordana_no_classifier_dl_5_epochs_fold_06.weights");
            add("models/jordana_no_classifier_dl_5_epochs_fold_07.weights");
            add("models/jordana_no_classifier_dl_5_epochs_fold_08.weights");
            add("models/jordana_no_classifier_dl_5_epochs_fold_09.weights");
            add("models/jordana_no_classifier_dl_5_epochs_fold_10.weights");
        }};
        Vector W = new Vector();
        ArrayList<Double> arguments = new ArrayList<Double>() {{
            add(0.5);}}; // model parameters for PA: only C

        for(String path : pathes) {
            StructEDModel tmp_model = new StructEDModel(W, new PassiveAggressive(), new TaskLossVowelDuration(),
                    new InferenceVowelDuration(), null, new FeatureFunctionsVD(), arguments); // create
            tmp_model.loadModel(path);
            for(Integer idx: tmp_model.getWeights().keySet()){
                if(W.containsKey(idx))
                    W.put(idx, W.get(idx)+tmp_model.getWeights().get(idx));
                else
                    W.put(idx, tmp_model.getWeights().get(idx));
            }
        }
        for(Integer idx: W.keySet())
            W.put(idx, W.get(idx)/pathes.size());

        StructEDModel vowel_model = new StructEDModel(W, new PassiveAggressive(), new TaskLossVowelDuration(),
                new InferenceVowelDuration(), null, new FeatureFunctionsVD(), arguments); // create the model
        vowel_model.saveModel("models/jordana_no_classifier_dl_5_epochs_avg.weights");
    }
}
