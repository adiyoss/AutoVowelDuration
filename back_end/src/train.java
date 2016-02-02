/*
 * Vowel Duration Measurement Package - Automatic vowel duration measurement using structured prediction algorithms
 * Copyright (C) 2015 Yossi Adi, E-Mail: yossiadidrum@gmail.com
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
            String trainPath = "data/db/files/cynthias_data/train.txt";
            String testPath = "data/db/files/cynthias_data/test.txt";

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
            vowel_model.saveModel("models/pa.vowel.model");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
