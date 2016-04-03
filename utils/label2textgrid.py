import os
import sys
import argparse
from lib.textgrid import *
from subprocess import call

__author__ = 'yossiadi'


# run system commands
def easy_call(command):
    try:
        call(command, shell=True)
    except Exception as exception:
        print "Error: could not execute the following"
        print ">>", command
        print type(exception)     # the exception instance
        print exception.args      # arguments stored in .args
        exit(-1)


def get_wav_file_length(wav_file):
    import wave
    import contextlib
    with contextlib.closing(wave.open(wav_file, 'r')) as f:
        frames = f.getnframes()
        rate = f.getframerate()
        duration = frames / float(rate)
    return duration


def main(label_path, wav_file, output_text_grid):
    # defines
    num_of_frames = 5
    msc_2_sec = 0.001

    # validation
    if not os.path.exists(label_path):
        print >>sys.stderr, "label file does not exits"
        return
    if not os.path.exists(wav_file):
        print >>sys.stderr, "wav file does not exits"
        return

    # read the label file and parse it
    fid = open(label_path)
    lines = fid.readlines()
    values = lines[0].split()[1].split('-')
    fid.close()

    # extract length
    length = get_wav_file_length(wav_file)

    # create the TextGrid file and save it
    onset = values[0]
    offset = values[1].split(':')[0]
    text_grid = TextGrid()

    vowels_tier = IntervalTier(name='VOWEL', xmin=0.0, xmax=float(length))
    vowels_tier.append(Interval(0, float(onset)*num_of_frames*msc_2_sec, ""))
    vowels_tier.append(Interval(float(onset)*num_of_frames*msc_2_sec, float(offset)*num_of_frames*msc_2_sec, "Vowel"))
    vowels_tier.append(Interval(float(offset)*num_of_frames*msc_2_sec, float(length), ""))

    text_grid.append(vowels_tier)
    text_grid.write(output_text_grid)


if __name__ == "__main__":
    # the first argument is the label file path
    # the second argument is the wav file path
    # the third argument is the output path
    # -------------MENU-------------- #
    # command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("label_filename", help="The label file")
    parser.add_argument("wav_filename", help="The wav file")
    parser.add_argument("output_text_grid", help="The output TextGrid file")
    args = parser.parse_args()

    # main function
    main(args.label_filename, args.wav_filename, args.output_text_grid)
