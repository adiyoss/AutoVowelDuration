# Automatic Measurement of Vowel Duration via Structured Prediction.
A key barrier to making phonetic studies scalable and replicable is the need to rely on subjective, manual annotation. To help meet this challenge, a machine learning algorithm is developed for automatic measurement of a widely used phonetic measure: vowel duration. Manually-annotated data is used to train a model that takes as input an arbitrary length segment of the acoustic signal containing a single vowel that is preceded and followed by consonants and outputs the duration of the vowel. The model is based on the structured prediction framework. The input signal and a hypothesized set of a vowel’s onset and offset are mapped to an abstract vector space by a set of acoustic feature functions. The learning algorithm is trained in this space to minimize the difference in expectations between predicted and manually-measured vowel durations. The trained model can then automatically estimate vowel durations without phonetic or orthographic transcription. Results comparing the model to three sets of manually annotated data suggest it out-performs the current gold standard for duration measurement, an HMM-based forced aligner (which requires phonetic transcription as an input) [[paper].](http://asa.scitation.org/doi/abs/10.1121/1.4972527)

## Content
The repository contains code for vowel duration measurement, feature extraction, visualization tools and results analysis
 - `back_end folder`: contains the training algorithms, it can be used for training the model on new datasets or using different features.
 - `front_end folder`: contains the features extraction algorithm, it can be used for configuring different parameters for the feature extraction or just for visualization.
 - `analysis folder`: contains the R scripts that were used to evaluate the results in [Automatic Measurement of Vowel Duration via Structured Prediction](https://arxiv.org/pdf/1610.08166v1.pdf).
 - `data folder`: contains two folders, the first one called wav (contains a wav file and its manual annotation), and the second is pred_text_grid (contains the predicted TextGrid file). This example can be used to test our tool.
 - `visualization folder`: contains features and features functions visualization tools.

## Installation
Currently the code runs on MacOSX only.
The code uses the following dependencies:
 - [Java] (https://java.com/en/download/)
 - [Python (2.7) + Numpy] (https://penandpants.com/2012/02/24/install-python/)
 - For the visualization tools: [Matplotlib] (https://penandpants.com/2012/02/24/install-python/)
 
## Usage
For measurement just type: 
```bash
python predict.py "input wav file" "output text grid file"
```

## Example
You can try our tool using the example file in the data folder and compare it to the manual annotation.
From the repository directory type: 
```bash
python predict.py data/wav/ex.wav data/pred_text_grid/ex.TextGrid
```

## Tutorial - How to train your own model
### Step 1: Feature Extraction
The first step in training your own model is extracting the features from the raw data. In order to do so, we provide two python scripts to extract the features and the labels.
The two scripts are placed under `front_end` folder:
 - The first script is called `extract_features.py`. This script gets as input a .wav file and a target output file and extract the features for the given file. You can run the script using an example file we provided: 

 ```bash
	python extract_features.py data/orig/ex.wav data/features/ex.data
```

 - The second script is called `extract_labels.py`. This script gets as input a .TextGrid file and a target output file and generates the labels for the given file. You can run the script using an example file we provided:

```bash
	python extract_labels.py data/orig/ex.TextGrid data/features/ex.labels
```

You can visualize the features using the `display_features_and_phi.py` script. 
In order to do so:
 - cd into the `visualization/Python/`
 - type 

 ```bash
	python display_features_and_phi.py -f ../../front_end/data/features/ex.data -l 90-150 -p 0-0
 ```

This script will display visually the features we just extracted. The numbers 90-150 indicates the vowel boundaries we just extracted using the `extract_labels.py` script. These numbers can be found inside data/features/ex.labels.

### Step 2: Train the model
We also provide the ability to train new model using your own data. After extracting the features and labels, we need to summarized all the file paths in a single file.
You can do it using your own script or the one we provided. The script can be found under utils folder and is called `sum_files.py`. 

Usage example (this example was run from the utils folder), this script will generate a training file from all the data in those folders: 

 ```bash
	python sum_files.py ../back_end/data/tutorial/feat/ ../back_end/data/tutorial/lab/ all.txt
 ```


In the `back_end/data/tutorial/` you can find more training and test example as well as the files with the paths. The features are under `fea` folder and the labels under `lab` folder. Train.txt and test.txt are the files which contains the paths to the train and test examples.

In order to train a model using these features we need to run a small Java code similar to this (The train and test code can be found under: `back_end/src/`):
 - Define the train and test path files:
```java
    Logger.info("Loading vowel duration data.");
    String trainPath = "data/tutorial/train.txt";
    String testPath = "data/tutorial/test.txt";
```
 -  Define model parameters and read the data:
```java
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
```
 -  Train and save the model
```java
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

    // save the model
    vowel_model.saveModel("models/pa.tutorial.vowel.model");
```
Testing can be done using the same code but, with the difference of first load the saved model and remove the instruction of train the model.

```java
vowel_model.loadModel("models/pa.tutorial.vowel.model");
```

After training the model on the few training examples we provided (20 examples) for one epoch, the error rate should be 9.0 or 9.2 when both task loss values set to zero.

For any questions regarding using the package please contact: yossiadidrum@gmail.com.

