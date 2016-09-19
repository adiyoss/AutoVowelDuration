/*
 * Copyright (c) 2016 Yossi Adi
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 * associated documentation files (the "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial
 * portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
 * OR OTHER DEALINGS IN THE SOFTWARE.
 */

import com.structed.constants.Consts;
import com.structed.dal.Reader;
import com.structed.data.InstancesContainer;
import com.structed.data.Logger;
import com.structed.data.entities.Vector;
import com.structed.models.StructEDModel;
import com.structed.models.algorithms.PassiveAggressive;

import java.io.File;
import java.util.ArrayList;

import static com.structed.data.Factory.getReader;

/**
 * Created by yossiadi on 03/11/2015.
 *
 */
public class train {

    public static void main(String[] args) {
        try{
            // ============================ VOWEL DURATION DATA ============================ //
            Logger.info("Loading vowel duration data.");
            String trainPath = "data/tutorial/train.txt";
            String testPath = "data/tutorial/test.txt";

            int epochNum = 1;
            int readerType = 2;
            int isAvg = 1;
            int numExamples2Display = 1;
            Reader reader = getReader(readerType);

            // load the data
            InstancesContainer vowelTrainInstances = reader.readData(trainPath, Consts.SPACE, Consts.COLON_SPLITTER);
            InstancesContainer vowelTestInstances = reader.readData(testPath, Consts.SPACE, Consts.COLON_SPLITTER);
            if (vowelTrainInstances.getSize() == 0) return;

            ArrayList<Double> arguments;
            StructEDModel vowel_model;
            Vector W;
            ArrayList<Double> task_loss_params = new ArrayList<Double>(){{add(1.0);add(2.0);}}; // task loss parameters

            // create models dir if doesn't exists
            File f = new File("models");
            if(!f.exists())
                f.mkdir();

            Logger.info("");
            Logger.info("=============================================");
            Logger.info("============= PASSIVE AGGRESSIVE ============");
            Logger.info("");

            // ======= PA ====== //
            W = new Vector() {{put(0, 0.0);}}; // init the first weight vector
            arguments = new ArrayList<Double>() {{
                add(0.5);}}; // model parameters for PA: only C
            vowel_model = new StructEDModel(W, new PassiveAggressive(), new TaskLossVowelDuration(),
                    new InferenceVowelDuration(), null, new FeatureFunctionsVD(), arguments); // create the model
            vowel_model.train(vowelTrainInstances, task_loss_params, null, epochNum, isAvg, true); // train
            vowel_model.predict(vowelTestInstances, task_loss_params, numExamples2Display, true); // predict

            // save the model
            vowel_model.saveModel("models/pa.tutorial.vowel.model");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
