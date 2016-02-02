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
import com.structed.data.CacheVowelData;
import com.structed.data.Factory;
import com.structed.data.Logger;
import com.structed.data.entities.Example;
import com.structed.data.entities.Vector;
import com.structed.data.featurefunctions.IFeatureFunctions;
import com.structed.models.kernels.IKernel;
import com.structed.utils.ConverterHelplers;
import com.structed.utils.MathHelpers;
import jsc.distributions.Gamma;

/**
 * Created by yossiadi on 03/11/2015.
 *
 */
public class FeatureFunctionsVD implements IFeatureFunctions {

    int sizeOfVector = 103;
    final int offset_10 = 2;
    final int offset_20 = 4;

    final int win_size_5 = 1;
    final int win_size_10 = 2;
    final int win_size_15 = 3;
    final int win_size_20 = 4;
    final int win_size_25 = 5;
    final int win_size_30 = 6;
    final int win_size_40 = 8;
    final int win_size_50 = 10;
    final double NORMALIZE = 0.05;

    final int SHORT_TERM_ENERGY = 0;
    final int TOTAL_ENERGY = 1;
    final int LOW_ENERGY = 2;
    final int HIGH_ENERGY = 3;
    final int WIENER_ENTROPY = 4;
    final int AUTO_CORRELATION = 5;
    final int PITCH = 6;
    final int VOICING = 7;
    final int ZERO_CROSSING = 8;
    final int IS_VOWEL = 9;
    final int IS_NAZAL = 10;
    final int SUM_VOWELS = 13;
    final int MFCC_1 = 16;
    final int MFCC_2 = 17;
    final int MFCC_3 = 18;
    final int MFCC_4 = 19;

    @Override
    //return null on error
    public Example convert(Example example, String label, IKernel kernel) {

        try{
            Example newExample = Factory.getExample(0);

            String labelValues[] = label.split(Consts.CLASSIFICATION_SPLITTER);
            Vector phiFeatures = new Vector();

            //convert full vector
            if(ConverterHelplers.tryParseInt(labelValues[0])) {

                int start = Integer.parseInt(labelValues[0]);
                int end = Integer.parseInt(labelValues[1]);

                //=================calculate the features=================//
                //=========Difference 5 and 10 frames from location=======//
                int loc=0;

                //====Short Term Energy====//
                phiFeatures.put(loc, calculateDiff(example, win_size_15, start, SHORT_TERM_ENERGY));//short term energy, start location - 20 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_20, start, SHORT_TERM_ENERGY));//short term energy, start location - 30 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_25, start, SHORT_TERM_ENERGY));//short term energy, start location - 30 window
                loc++;

                phiFeatures.put(loc, calculateDiff(example, win_size_15, end, SHORT_TERM_ENERGY));//short term energy, end location - 30 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_20, end, SHORT_TERM_ENERGY));//short term energy, end location - 30 window
                loc++;

                //====Total Energy====//
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_40, start, TOTAL_ENERGY)));//total energy, start location - 20 window
                loc++;
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_50, start, TOTAL_ENERGY)));//total energy, start location - 30 window
                loc++;
                // offsets
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_40, start - offset_10, TOTAL_ENERGY)));//total energy, start location - 20 window
                loc++;
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_50, start - offset_20, TOTAL_ENERGY)));//total energy, start location - 30 window
                loc++;

                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_40, end, TOTAL_ENERGY)));//total energy, start location - 30 window
                loc++;
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_50, end, TOTAL_ENERGY)));//total energy, start location - 30 window
                loc++;


                //====Low Energy====//
                phiFeatures.put(loc, calculateDiff(example, win_size_30, start, LOW_ENERGY));//low energy, start location - 30 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_40, start, LOW_ENERGY));//low energy, start location - 30 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, start, LOW_ENERGY));//low energy, start location - 40 window
                loc++;
                // offsets
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_40, start - offset_10, LOW_ENERGY)));//total energy, start location - 20 window
                loc++;
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_50, start - offset_20, LOW_ENERGY)));//total energy, start location - 30 window
                loc++;

                phiFeatures.put(loc, calculateDiff(example, win_size_40, end, LOW_ENERGY));//low energy, end location - 20 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, end, LOW_ENERGY));//low energy, end location - 30 window
                loc++;

                //====High Energy====//
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_40, start, HIGH_ENERGY)));//high energy, end location - 30 window
                loc++;
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_50, start, HIGH_ENERGY)));//high energy, end location - 30 window
                loc++;
                // offsets
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_40, start - offset_10, HIGH_ENERGY)));//total energy, start location - 20 window
                loc++;
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_50, start - offset_20, HIGH_ENERGY)));//total energy, start location - 30 window
                loc++;

                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_40, end, HIGH_ENERGY)));//high energy, end location - 30 window
                loc++;
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_50, end, HIGH_ENERGY)));//high energy, end location - 30 window
                loc++;

                //====Wiener Entropy====//
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_40, start, WIENER_ENTROPY)));//wiener entropy, start location - 30 window
                loc++;
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_50, start, WIENER_ENTROPY)));//wiener entropy, start location - 30 window
                loc++;

                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_40, end, WIENER_ENTROPY)));//wiener entropy, start location - 30 window
                loc++;
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_50, end, WIENER_ENTROPY)));//wiener entropy, start location - 30 window
                loc++;

                //===========Auto Correlation==========//
                phiFeatures.put(loc, calculateDiff(example, win_size_5, start, AUTO_CORRELATION));//auto correlation, start location - 5 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_10, start, AUTO_CORRELATION));//auto correlation, start location - 10 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_15, start, AUTO_CORRELATION));//auto correlation, start location - 15 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_20, start, AUTO_CORRELATION));//auto correlation, start location - 15 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_25, start, AUTO_CORRELATION));//auto correlation, start location - 15 window
                loc++;

                //==========Difference 5 and 15 frames from start=========//
                //====Pitch====//
                phiFeatures.put(loc, calculateDiff(example, win_size_40, start, PITCH));//pitch, start location - 20 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, start, PITCH));//pitch, start location - 30 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_40, end, PITCH));//pitch, start location - 20 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, end, PITCH));//pitch, start location - 30 window
                loc++;

                //====Voicing====//
                phiFeatures.put(loc, calculateDiff(example, win_size_40, start, VOICING));//voicing, start location - 15 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, start, VOICING));//voicing, start location - 20 window
                loc++;

                phiFeatures.put(loc, calculateDiff(example, win_size_40, end, VOICING));//voicing, end location - 30 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, end, VOICING));//voicing, end location - 30 window
                loc++;

                //====Zero-Crossing====//
                phiFeatures.put(loc, calculateDiff(example, win_size_40, start, ZERO_CROSSING));//zero-crossing, start location - 20 window
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, start, ZERO_CROSSING));//zero-crossing, start location - 30 window
                loc++;
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_40, end, ZERO_CROSSING)));//zero-crossing, end location - 20 window
                loc++;
                phiFeatures.put(loc, Math.abs(calculateDiff(example, win_size_50, end, ZERO_CROSSING)));//zero-crossing, end location - 30 window
                loc++;

                //=================Phoneme-Classifier==================//
                //====VOWELS - INDICATOR====//
                phiFeatures.put(loc, calculateDiff(example, win_size_30, start, IS_VOWEL));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_40, start, IS_VOWEL));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, start, IS_VOWEL));
                loc++;


                phiFeatures.put(loc, calculateDiff(example, win_size_30, end, IS_VOWEL));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_40, end, IS_VOWEL));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, end, IS_VOWEL));
                loc++;

                //====NASAL - INDICATOR====//
                phiFeatures.put(loc, calculateDiff(example, win_size_40, end, IS_NAZAL));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, end, IS_NAZAL));
                loc++;

                //====VOWELS - SUM DIVIDE BY SUM ALL====//
                phiFeatures.put(loc, calculateDiff(example, win_size_30, start, SUM_VOWELS));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_40, start, SUM_VOWELS));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, start, SUM_VOWELS));
                loc++;

                phiFeatures.put(loc, calculateDiff(example, win_size_30, end, SUM_VOWELS));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_40, end, SUM_VOWELS));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, end, SUM_VOWELS));
                loc++;

                //==== DELTA ====//
                // MFCC_1
                phiFeatures.put(loc, calculateDiff(example, win_size_15, start, MFCC_1));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, start, MFCC_1));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_15, end, MFCC_1));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, end, MFCC_1));
                loc++;

                // MFCC_2
                phiFeatures.put(loc, calculateDiff(example, win_size_15, start, MFCC_2));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, start, MFCC_2));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_15, end, MFCC_2));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, end, MFCC_2));
                loc++;

                // MFCC_3
                phiFeatures.put(loc, calculateDiff(example, win_size_15, start, MFCC_3));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, start, MFCC_3));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_15, end, MFCC_3));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, end, MFCC_3));
                loc++;

                // MFCC_4
                phiFeatures.put(loc, calculateDiff(example, win_size_15, start, MFCC_4));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, start, MFCC_4));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_15, end, MFCC_4));
                loc++;
                phiFeatures.put(loc, calculateDiff(example, win_size_50, end, MFCC_4));
                loc++;

                //==============Mean value from start to end==============//
                //true means prev the start point, false means after the end point
                phiFeatures.put(loc, calculateMean(example, start, end, SHORT_TERM_ENERGY, win_size_50, true));//Mean of short-term energy
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, SHORT_TERM_ENERGY, win_size_50, false));//Mean of short-term energy
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, TOTAL_ENERGY, win_size_50, true));//Mean of low energy
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, TOTAL_ENERGY, win_size_50, false));//Mean of low energy
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, HIGH_ENERGY, win_size_50, true));//Mean of low energy
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, HIGH_ENERGY, win_size_50, false));//Mean of low energy
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, LOW_ENERGY, win_size_50, true));//Mean of low energy
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, LOW_ENERGY, win_size_50, false));//Mean of low energy
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, VOICING, win_size_50, true));//Mean of voicing
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, VOICING, win_size_50, false));//Mean of voicing
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, ZERO_CROSSING, win_size_50, true));//Mean of zero-crossing
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, ZERO_CROSSING, win_size_50, false));//Mean of zero-crossing
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, SUM_VOWELS, win_size_50, true));
                loc++;
                phiFeatures.put(loc, calculateMean(example, start, end, SUM_VOWELS, win_size_50, false));
                loc++;

                // ==== MAX FUNCTION ==== //
                phiFeatures.put(loc, example.getFeatures2D().get(start).get(TOTAL_ENERGY));
                loc++;
                phiFeatures.put(loc, example.getFeatures2D().get(start).get(LOW_ENERGY));
                loc++;
                phiFeatures.put(loc, example.getFeatures2D().get(start).get(HIGH_ENERGY));
                loc++;
                phiFeatures.put(loc, example.getFeatures2D().get(start).get(AUTO_CORRELATION));
                loc++;

                //============== Delta MFCC Feature Function==============//
                //======================= START ==========================//
                phiFeatures.put(loc, NORMALIZE *example.getFeatures2D().get(start).get(MFCC_1));
                loc++;
                phiFeatures.put(loc, NORMALIZE *example.getFeatures2D().get(start).get(MFCC_2));
                loc++;
                phiFeatures.put(loc, NORMALIZE *example.getFeatures2D().get(start).get(MFCC_3));
                loc++;
                phiFeatures.put(loc, NORMALIZE *example.getFeatures2D().get(start).get(MFCC_4));
                loc++;

                //=======================END=======================//
                phiFeatures.put(loc, NORMALIZE *example.getFeatures2D().get(end).get(MFCC_1));
                loc++;
                phiFeatures.put(loc, NORMALIZE *example.getFeatures2D().get(end).get(MFCC_2));
                loc++;
                phiFeatures.put(loc, NORMALIZE *example.getFeatures2D().get(end).get(MFCC_3));
                loc++;
                phiFeatures.put(loc, NORMALIZE *example.getFeatures2D().get(end).get(MFCC_4));
                loc++;

                //===============Gamma Distribution Over The Vowel Length==============//
                //shape = mean^2/var
                //scale = var/mean
                double variance = Math.pow(Consts.STD_VOWEL_LENGTH,2);
                double shape = Math.pow(Consts.MEAN_VOWEL_LENGTH,2)/variance;
                double scale = variance/Consts.MEAN_VOWEL_LENGTH;
                Gamma gamma = new Gamma(shape, scale);
                double vowelLength = end - start;
                phiFeatures.put(loc,gamma.pdf(vowelLength)/gamma.pdf(Consts.MAX_VOWEL_LENGTH));
                loc++;

                //===============Gaussian Distribution Over The Vowel Length==============//
                double numerator = -Math.pow((vowelLength - Consts.MEAN_VOWEL_LENGTH),2);
                double denominator = 2*Math.pow(Consts.STD_VOWEL_LENGTH,2);
                phiFeatures.put(loc,Math.exp(numerator/denominator));

                newExample.setFeatures(phiFeatures);
                return newExample;
            }
            return null;

        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    //**********************************FEATURE FUNCTIONS***************************************//
    //******************************************************************************************//
    //calculate the average difference of featureNumber win_size before and after location
    private double calculateDiff(Example example, int win_size, int location, int featureNumber)
    {
        try {
            double preVal;
            //get the cumulative values of featureNumber
            double startVal = CacheVowelData.getCumulativeValue(example, location - win_size, featureNumber);
            double endVal = CacheVowelData.getCumulativeValue(example, location, featureNumber);

            preVal = endVal - startVal;
            preVal /= win_size;


            double afterVal;
            //get the cumulative values of featureNumber
            startVal = endVal;
            endVal = CacheVowelData.getCumulativeValue(example, location + win_size, featureNumber);

            afterVal = endVal - startVal;
            afterVal /= win_size;

            Double value = afterVal - preVal;
            if(value.isNaN())
                value = 0.0;

            //return the diff
            return value;

        } catch (Exception e){
            Logger.error("Error in function: calculateDiff, feature number: " + featureNumber + ", example: " + example.path);
            return 0;
        }
    }

    //calculate the avg value from start till end of featureNumber
    //if isPrev equals true then create mean difference from start
    //else create mean difference from end
    private double calculateMean(Example example, int start, int end, int featureNumber, int win_size, boolean isPrev)
    {
        try {
            double avg;
            int counter = end - start;

            //get the cumulative values of featureNumber
            double startVal = CacheVowelData.getCumulativeValue(example,start,featureNumber);
            double endVal = CacheVowelData.getCumulativeValue(example,end,featureNumber);

            //computer the mean
            avg = endVal-startVal;

            avg /= counter;

            double val;
            if(isPrev) {
                //get the cumulative values of featureNumber
                startVal = CacheVowelData.getCumulativeValue(example, start - win_size, featureNumber);
                endVal = CacheVowelData.getCumulativeValue(example, start, featureNumber);

                val = endVal - startVal;
                val /= win_size;
            } else {
                //get the cumulative values of featureNumber
                startVal = CacheVowelData.getCumulativeValue(example, end, featureNumber);
                endVal = CacheVowelData.getCumulativeValue(example, end + win_size, featureNumber);

                val = startVal - endVal;
                val /= win_size;
            }

            Double value = MathHelpers.sigmoid(avg - val);
            if(value.isNaN())
                value = 0.0;

            return value;

        } catch (Exception e){
            Logger.error("Error in function: calculateMean, feature number: "+featureNumber+", example: "+example.path);
            return 0;
        }
    }


    @Override
    public int getSizeOfVector() {
        return sizeOfVector;
    }
    //******************************************************************************************//
}
