__author__ = 'adiyoss'

import os
import sys
from optparse import OptionParser
import numpy as np
import matplotlib.pyplot as plt

NUM_OF_FEATURES = 22
graphIndex = 0
predict_line = 1
label_line = 1
phi_indicator = 0


def on_type(event):
    global graphIndex
    global predict_line
    global label_line
    global phi_indicator

    if event.key == 'q':
        sys.exit(0)
    elif event.key == 'right':
        graphIndex -= 1
    elif event.key == 'left':
        graphIndex += 1
    elif event.key == 'p':
        predict_line = 0 if predict_line == 1 else 1
    elif event.key == 'l':
        label_line = 0 if label_line == 1 else 1
    elif event.key == 'r':
        phi_indicator = 0
    elif event.key == 'f':
        phi_indicator = 1
    elif event.key == 'm':
        phi_indicator = 2
    else:
        return
    plt.close()


def display_features(filename, frame_begin_and_end_real, frame_begin_and_end_predict):
    if not os.path.isfile(filename):
        sys.stderr.write("WARNING: file not found, " + str(filename))

    # compute the phi values   
    labels = frame_begin_and_end_real.split('-')
    predict = frame_begin_and_end_predict.split('-')
    m = np.loadtxt(filename)
    phi_m = np.zeros(m.shape, dtype=np.float64)
    phi_mean = np.zeros(m.shape, dtype=np.float64)
    window_size = 10  # 25ms window

    for i in range(window_size, len(m) - window_size):
        pre_values = np.zeros(len(m[0, :]))
        post_values = np.zeros(len(m[0, :]))
        for j in range(window_size):
            pre_values += (m[i - window_size + j, :])
            post_values += (m[i + j, :])
        phi_m[i, :] = (post_values - pre_values) / window_size

    tmp = np.zeros(len(m[0, :]))

    onset = int(labels[0])
    offset = int(labels[1])
    for i in range(0, onset):
        tmp += m[i, :]
    tmp /= onset
    for i in range(0, onset):
        phi_mean[i, :] = tmp

    tmp = np.zeros(len(m[0, :]))
    for i in range(onset, offset):
        tmp += m[i, :]
    tmp /= offset
    for i in range(onset, offset):
        phi_mean[i, :] = tmp

    tmp = np.zeros(len(m[0, :]))
    for i in range(offset, len(m)):
        tmp += m[i, :]
    tmp /= (len(m) - offset)
    for i in range(offset, len(m)):
        phi_mean[i, :] = tmp


    # the feature names for the title
    feature_names = ['Short Term Energy', 'Total Energy', 'Low Energy', 'High Energy', 'Wiener Entropy',
                     'Auto Correlation', 'Pitch',
                     'Voicing', 'Zero Crossing', 'Vowel', 'Nasal', 'Glide', 'Sil', 'Sum Vowels', 'Sum Nasals',
                     'Sum Glides',
                     'MFCC_1', 'MFCC_2', 'MFCC_3', 'MFCC_4', 'F1', 'F2']
    while True:
        index = graphIndex % len(feature_names)
        fig = plt.figure(1, figsize=(20, 10))
        fig.canvas.mpl_connect('key_press_event', on_type)
        fig.suptitle(feature_names[index], fontsize='x-large', style='italic', fontweight='bold')
        max_m = np.max(m[:, index])
        min_m = np.min(m[:, index])
        width = float(0.6)
        if phi_indicator == 0:
            plt.plot((m[:, index]), linestyle='-', linewidth=width, color='#006699')
        elif phi_indicator == 1:
            plt.plot((phi_m[:, index]), linestyle='-', linewidth=width, color='#006699')
        elif phi_indicator == 2:
            plt.plot((phi_mean[:, index]), linestyle='-', linewidth=width, color='#006699')

        if label_line == 1:
            labels_plot, = plt.plot([labels[0], labels[0]], [min_m, max_m], linestyle='-', color="#730A0A", lw=2)
            plt.plot([labels[1], labels[1]], [min_m, max_m], linestyle='-', color="#730A0A", lw=2)
        if predict_line == 1:
            predict_plot, = plt.plot([predict[0], predict[0]], [min_m, max_m], linestyle=':', color='#335C09', lw=2)
            plt.plot([predict[1], predict[1]], [min_m, max_m], linestyle=':', color='#335C09', lw=2)
        plt.xlim(xmin=0, xmax=len(m))

        # plot the legend
        plt.figtext(0.13, 0.05, 'Q: quit', style='italic')
        plt.figtext(0.2, 0.05, 'P: Enable/disable prediction marks', style='italic')
        plt.figtext(0.38, 0.05, 'L: Enable/disable real label marks', style='italic')
        plt.figtext(0.56, 0.05, 'F/R: Show/Hide the feature functions', style='italic')        
        plt.figtext(0.13, 0.02, 'Left arrow: Next figure', style='italic')
        plt.figtext(0.38, 0.02, 'Right arrow: Previous figure', style='italic')
        l2 = plt.legend([labels_plot, predict_plot], ["Real Label", "Predict Label"])
        plt.gca().add_artist(l2)  # add l1 as a separate artist to the axes
        plt.show()

# parse the parameters
# the first argument should be the labels file from the intellij
# the second argument should be the path to the directory in which the textGrid files are located
# #-------------MENU--------------#
parser = OptionParser()
parser.add_option("-f", "--file", dest="file", help="The name of the data file", metavar="FILE")
parser.add_option("-l", "--label", dest="label", help="The onset and offset of the vowel, Example: 100-138",
                  metavar="FILE")
parser.add_option("-p", "--predict", dest="predict", help="The predicted onset and offset of the vowel, same as before",
                  metavar="FILE")
(options, args) = parser.parse_args()

# validation
if options.file is None or options.label is None or options.predict is None:
    sys.stderr.write("Invalid number of arguments.")
else:
    # run the script
    display_features(options.file, options.label, options.predict)