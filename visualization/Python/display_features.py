__author__ = 'adiyoss'

import os
import sys
from optparse import OptionParser
import numpy as np
import matplotlib.pyplot as plt

NUM_OF_PHONEMES = 39
NUM_OF_ACUSTIC_FEATURES = 9
graphIndex = 0
graphTitle = 0
predict_line = 1
label_line = 1

def ontype(event):
    global graphIndex
    global graphTitle
    global predict_line
    global label_line

    if event.key == 'q':
        sys.exit(0)

    elif event.key == 'right':
        graphIndex = graphIndex-1
        graphTitle = graphTitle-1

    elif event.key == 'left':
        graphIndex = graphIndex+1
        graphTitle = graphTitle+1
    elif event.key == 'p':
        if predict_line == 1:
            predict_line = 0
        else:
            predict_line = 1

    elif event.key == 'l':
        if label_line == 1:
            label_line = 0            
        else:
            label_line = 1
    else:
        return

    plt.close()


def display_features(filename,frame_begin_and_end_real, frame_begin_and_end_predict):
    global graphIndex

    if os.path.isfile(filename) == False:
        sys.stderr.write("WARNING: file not found, "+str(filename))

    labels = frame_begin_and_end_real.split('-')
    predict = frame_begin_and_end_predict.split('-')
    m = np.loadtxt(filename)
    feature_names = ['Short Term Energy','Total Energy','Low Energy','High Energy','Wiener Entropy','Auto Correlation','Pitch','Voicing','Zero Crossing','MFCC_1','MFCC_2','MFCC_3','MFCC_4','F1','F2']
    while True:        
        index = graphIndex%len(m[0])
        if index == NUM_OF_ACUSTIC_FEATURES + NUM_OF_PHONEMES - 1:
            graphIndex -= NUM_OF_PHONEMES
            index -= NUM_OF_PHONEMES
        if index == NUM_OF_ACUSTIC_FEATURES:
            graphIndex += NUM_OF_PHONEMES            
            index += NUM_OF_PHONEMES

        print index
        title_index = graphTitle%len(feature_names)

        fig = plt.figure(1, figsize=(20, 10))
        fig.canvas.mpl_connect('key_press_event', ontype)
        fig.suptitle(feature_names[title_index], fontsize='x-large', style='italic', fontweight='bold')
        max_m = np.max(m[:,index])
        min_m = np.min(m[:,index])
        width = float(0.6)
        plt.plot((m[:,index]), linestyle='-', linewidth=width, color = '#006699')
        if label_line == 1:
            labels_plot, = plt.plot([labels[0], labels[0]], [min_m, max_m], linestyle='-.', color="#730A0A", lw=2)
            plt.plot([labels[1], labels[1]], [min_m, max_m], linestyle='-.', color="#730A0A", lw=2)
        if predict_line == 1:
            predict_plot, = plt.plot([predict[0], predict[0]], [min_m, max_m], linestyle='-.', color = '#335C09', lw=2)
            plt.plot([predict[1], predict[1]], [min_m, max_m], linestyle='-.', color = '#335C09', lw=2)
        plt.xlim(xmin=0, xmax=len(m))
        
        # plot the summary
        onset_diff = (float(labels[0]) - float(predict[0]))*5
        offset_diff = (float(labels[1]) - float(predict[1]))*5
        total_diff = onset_diff+offset_diff
        plt.figtext(0.01, 0.885, 'Summary:', style='italic', fontweight='bold', size='large')
        plt.figtext(0.01, 0.85, 'Vowel onset: '+str(float(labels[0])*5), style='italic')
        plt.figtext(0.01, 0.83, 'Vowel offset: '+str(float(labels[1])*5), style='italic')
        plt.figtext(0.01, 0.81, 'Predicted onset: '+str(float(predict[0])*5), style='italic')
        plt.figtext(0.01, 0.79, 'Predicted offset: '+str(float(predict[1])*5), style='italic')
        plt.figtext(0.01, 0.72, 'Onset difference:', style='italic',fontweight='bold',size='large')
        plt.figtext(0.01, 0.7, str(onset_diff)+' milli seconds', style='italic')
        plt.figtext(0.01, 0.65, 'Offset difference:', style='italic',fontweight='bold',size='large')
        plt.figtext(0.01, 0.63, str(offset_diff)+' milli seconds', style='italic')
        plt.figtext(0.01, 0.58, 'Total difference:', style='italic',fontweight='bold',size='large')
        plt.figtext(0.01, 0.56, str(total_diff)+' milli seconds', style='italic')

        # plot the legend
        plt.figtext(0.13, 0.05, 'Q: quit', style='italic')
        plt.figtext(0.2, 0.05, 'P: Enable/disable prediction marks', style='italic')
        plt.figtext(0.38, 0.05, 'L: Enable/disable real label marks', style='italic')
        plt.figtext(0.13, 0.02, 'Left arrow: Next figure', style='italic')
        plt.figtext(0.38, 0.02, 'Right arrow: Previous figure', style='italic')
        l2 = plt.legend([labels_plot, predict_plot], ["Real Label", "Predict Label"])        
        plt.gca().add_artist(l2) # add l1 as a separate artist to the axes        
        plt.show()

# parse the parameters
# the first argument should be the labels file from the intellij
# the second argument should be the path to the directory in which the textGrid files are located
# #-------------MENU--------------#
parser = OptionParser()
parser.add_option("-f", "--file", dest="file", help="The name of the data file", metavar="FILE")
parser.add_option("-l", "--label", dest="label", help="The onset and offset of the vowel, Example: 100-138", metavar="FILE")
parser.add_option("-p", "--predict", dest="predict", help="The predicted onset and offset of the vowel, same as before", metavar="FILE")
(options, args) = parser.parse_args()

#validation
if options.file == None or options.label == None or options.predict == None:
    sys.stderr.write("Invalid number of arguments.")
else:
    #run the script
    display_features(options.file, options.label, options.predict)