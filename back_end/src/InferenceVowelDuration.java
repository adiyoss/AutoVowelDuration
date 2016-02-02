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
import com.structed.constants.ErrorConstants;
import com.structed.data.Logger;
import com.structed.data.entities.Example;
import com.structed.data.entities.PredictedLabels;
import com.structed.data.entities.Vector;
import com.structed.models.ClassifierData;
import com.structed.models.inference.IInference;
import com.structed.utils.MathHelpers;

/**
 * Created by yossiadi on 03/11/2015.
 *
 */
public class InferenceVowelDuration implements IInference {
    //predict function
    //argmax(yS,yE) (W*Phi(Xi,yS,yE)) + Task Loss
    //this function assumes that the argument vector has already been converted to phi vector
    //return null on error
    public PredictedLabels predictForTrain(Example vector, Vector W, String realClass, ClassifierData classifierData, double epsilonArgMax)
    {
        try{
            double maxVal = 0;
            String maxLabel = "";
            boolean isFirst = true;

            //validation
            if(vector.sizeOfVector<=0)
            {
                Logger.error(ErrorConstants.PHI_VECTOR_DATA);
                return null;
            }

            //loop over all the classifications of this specific example
            for(int i=Consts.MIN_GAP_START ; i<vector.sizeOfVector-(Consts.MIN_GAP_END) ; i++)
            {
                for(int j=i+Consts.MIN_VOWEL ; j<i+Consts.MAX_VOWEL ; j++)
                {
                    if(j>vector.sizeOfVector-(Consts.MIN_GAP_END))
                        break;

                    Example phiData = classifierData.phi.convert(vector,(i+1)+Consts.CLASSIFICATION_SPLITTER+(j+1),classifierData.kernel);
                    //multiple the vectors
                    double tmp = MathHelpers.multipleVectors(W, phiData.getFeatures());

                    if(epsilonArgMax != 0){
                        //add the task loss
                        tmp += epsilonArgMax*classifierData.taskLoss.computeTaskLoss((i+1)+Consts.CLASSIFICATION_SPLITTER+(j+1), realClass, classifierData.arguments);
                    }

                    if(isFirst) {
                        maxLabel = (i + 1) + Consts.CLASSIFICATION_SPLITTER + (j + 1);
                        maxVal = tmp;
                        isFirst = false;
                    }
                    else if(tmp > maxVal) {
                        maxLabel = (i + 1) + Consts.CLASSIFICATION_SPLITTER + (j + 1);
                        maxVal = tmp;
                    }
                }
            }

            PredictedLabels result = new PredictedLabels();
            result.put(maxLabel, maxVal);

            return result;

        } catch (Exception e){
            e.printStackTrace();
            return null;
        }
    }

    public PredictedLabels predictForTest(Example vector, Vector W, String realClass, ClassifierData classifierData, int returnAll)
    {
        return predictForTrain(vector, W, realClass, classifierData ,0);
    }
}
