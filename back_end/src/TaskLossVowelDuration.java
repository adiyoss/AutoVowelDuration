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
import com.structed.models.loss.ITaskLoss;

import java.util.List;

/**
 * Created by yossiadi on 03/11/2015.
 *
 */
public class TaskLossVowelDuration implements ITaskLoss {
    @Override
    //max{0, |ys - ys'| - epsilon} + max{0, |ye - ye'| - epsilon}
    public double computeTaskLoss(String predictClass, String actualClass, List<Double> params) {
        try {
            Double epsilon_onset = params.get(0);
            Double epsilon_offset = params.get(1);

            String predictValues[] = predictClass.split(Consts.CLASSIFICATION_SPLITTER);
            String actualClassValues[] = actualClass.split(Consts.CLASSIFICATION_SPLITTER);

            double predictResStart = Double.parseDouble(predictValues[0]);
            double actualResStart = Double.parseDouble(actualClassValues[0]);

            double predictResEnd = Double.parseDouble(predictValues[1]);
            double actualResEnd = Double.parseDouble(actualClassValues[1]);

            double diffStart = Math.abs(predictResStart - actualResStart);
            double diffEnd = Math.abs(predictResEnd - actualResEnd);

            //subtract the epsilon
            double absRes = 0;
            if(diffStart >=  epsilon_onset)
                absRes += diffStart;
            if(diffEnd >= epsilon_offset)
                absRes += diffEnd;

            //get the max from the absolute result minus epsilon and 0
            return absRes;

        } catch (Exception e){
            e.printStackTrace();
            return 0;
        }
    }
}
