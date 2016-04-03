# Automatic Measurement of Vowel Duration via Structured Prediction.
A key barrier to making phonetic studies scalable and replicable is the need to rely on subjective, manual annotation. To help meet this challenge, a machine learning algorithm is developed for automatic measurement of a widely used phonetic measure: vowel duration. Manually-annotated data is used to train a model that takes as input an arbitrary length segment of the acoustic signal containing a single vowel that is preceded and followed by consonants and outputs the duration of the vowel. The model is based on the structured prediction framework. The input signal and a hypothesized set of a vowel’s onset and offset are mapped to an abstract vector space by a set of acoustic feature functions. The learning algorithm is trained in this space to minimize the difference in expectations between predicted and manually-measured vowel durations. The trained model can then automatically estimate vowel durations without phonetic or orthographic transcription. Results comparing the model to three sets of manually annotated data suggest it out-performs the current gold standard for duration measurement, an HMM-based forced aligner (which requires phonetic transcription as an input).

## Content
The repository contains code for vowel duration measurement, feature extraction, visualization tools and results analysis
 - back_end folder: contains the training algorithms, it can be used for training the model on new datasets or using different features.
 - front_end folder: contains the features extraction algorithm, it can be used for configuring different parameters for the feature extraction or just for visualization.
 - analysis folder: contains the R scripts that were used to evaluate the results in [Automatic Measurement of Vowel Duration via Structured Prediction](https://todo).
 - visualization folder: contains features and features functions visualization tools.

## Installation
Currently the code runs on MacOSX and Linux only.
The code uses the following dependencies:
 - Java
 - Python (2.7) + Numpy
 - For the visualization tools: Matplotlib
 
## Usage
For measurement just type python predict.py <input_wav_file> <output_text_grid_file>

