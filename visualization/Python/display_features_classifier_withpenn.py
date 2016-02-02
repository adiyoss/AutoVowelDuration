__author__ = 'adiyoss'

import os
import sys
from optparse import OptionParser
import numpy as np
import matplotlib.pyplot as plt

NUM_OF_FEATURES = 22
graphIndex = 0
predict_line = 1
penn_line = 1
label_line = 1


def on_type(event):
    global graphIndex
    global predict_line
    global label_line
    global penn_line

    if event.key == 'q':
        sys.exit(0)
    elif event.key == 'right':
        graphIndex -= 1
    elif event.key == 'left':
        graphIndex += 1
    elif event.key == 'r':
        predict_line = 0 if predict_line == 1 else 1
    elif event.key == 'l':
        label_line = 0 if label_line == 1 else 1
    elif event.key == 'p':
        penn_line = 0 if penn_line == 1 else 1
    else:
        return
    plt.close()


def display_features(filename, frame_begin_and_end_real, frame_begin_and_end_struct, frame_begin_and_end_penn):
    global labels_plot, predict_plot, penn_plot
    if not os.path.isfile(filename):
        sys.stderr.write("WARNING: file not found, " + str(filename))

    labels = frame_begin_and_end_real.split('-')
    struct = frame_begin_and_end_struct.split('-')
    penn = frame_begin_and_end_penn.split('-')
    m = np.loadtxt(filename)
    feature_names = ['Short Term Energy', 'Total Energy', 'Low Energy', 'High Energy', 'Wiener Entropy',
                     'Auto Correlation', 'Pitch', 'Voicing', 'Zero Crossing', 'Vowel', 'Nasal', 'Glide', 'Sil',
                     'Sum Vowels', 'Sum Nasals', 'Sum Glides', 'MFCC_1', 'MFCC_2', 'MFCC_3', 'MFCC_4', 'F1', 'F2']
    while True:
        index = graphIndex % len(feature_names)
        fig = plt.figure(1, figsize=(20, 10))
        fig.canvas.mpl_connect('key_press_event', on_type)
        fig.suptitle(feature_names[index], fontsize='x-large', style='italic', fontweight='bold')
        max_m = np.max(m[:, index])
        min_m = np.min(m[:, index])
        width = float(0.6)
        plt.plot((m[:, index]), linestyle='-', linewidth=width, color='#006699')
        if label_line == 1:
            labels_plot, = plt.plot([labels[0], labels[0]], [min_m, max_m], linestyle=':', color="#B80000", lw=2)
            plt.plot([labels[1], labels[1]], [min_m, max_m], linestyle=':', color="#B80000", lw=2)
        if predict_line == 1:
            predict_plot, = plt.plot([struct[0], struct[0]], [min_m, max_m], linestyle=':', color='#298A4A', lw=2)
            plt.plot([struct[1], struct[1]], [min_m, max_m], linestyle=':', color='#298A4A', lw=2)
        if penn_line == 1:
            penn_plot, = plt.plot([penn[0], penn[0]], [min_m, max_m], linestyle=':', color='#0033CC', lw=2)
            plt.plot([penn[1], penn[1]], [min_m, max_m], linestyle=':', color='#0033CC', lw=2)
        plt.xlim(xmin=0, xmax=len(m))

        # plot the legend
        plt.figtext(0.13, 0.05, 'Q: quit', style='italic')
        plt.figtext(0.2, 0.05, "R: Enable/disable StructED marks", style='italic')
        plt.figtext(0.38, 0.05, 'P: Enable/disable Penn marks', style='italic')
        plt.figtext(0.55, 0.05, 'L: Enable/disable target label marks', style='italic')
        plt.figtext(0.13, 0.02, 'Left arrow: Next figure', style='italic')
        plt.figtext(0.38, 0.02, 'Right arrow: Previous figure', style='italic')
        l2 = plt.legend([labels_plot, predict_plot, penn_plot], ["Target Label", "StructED Label", "Penn Label"])
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
parser.add_option("-s", "--struct", dest="struct", help="The predicted onset and offset by structED", metavar="FILE")
parser.add_option("-p", "--penn", dest="penn", help="The predicted onset and offset by Penn", metavar="FILE")
(options, args) = parser.parse_args()

# validation
if options.file is None or options.label is None or options.struct is None or options.penn is None:
    sys.stderr.write("Invalid number of arguments.")
else:
    #run the script
    display_features(options.file, options.label, options.struct, options.penn)

