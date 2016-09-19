import argparse
import os
import numpy as np
from textgrid import TextGrid


def main(text_grid_filename, output_label):
    if os.path.exists(text_grid_filename):
        t = TextGrid()
        t.read(text_grid_filename)
        onset = t._TextGrid__tiers[0]._IntervalTier__intervals[1]._Interval__xmin
        offset = t._TextGrid__tiers[0]._IntervalTier__intervals[1]._Interval__xmax
        f = open(output_label, 'w')
        onset_i = np.ceil(onset * 100 * 2)  # extract every 5 ms
        offset_i = np.floor(offset * 100 * 2)  # extract every 5 ms
        f.write('1 2\n')
        f.write(str(onset_i) + ' ' + str(offset_i) + '\n')


if __name__ == "__main__":
    # the first argument is the wav file
    # the second argument is output .data features
    # -------------MENU-------------- #
    # command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("text_grid_filename", help="The TextGrid file")
    parser.add_argument("output_label", help="The output label file")
    args = parser.parse_args()

    # main function
    main(args.text_grid_filename, args.output_label)
