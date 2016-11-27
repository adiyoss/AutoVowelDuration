import os
import sys
import shutil
import argparse
from subprocess import call
import front_end.extract_features as fe
import utils.run_back_end as model
import utils.label2textgrid as l2t

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


def main(wav_file_name, output_text_grid_file):
    try:
        # convert the wav file to 16khz sample rate
        print "Converting the wav file to 16khz sample rate"
        new_file_wav_file = wav_file_name.replace(".wav", "_16.wav")
        cmd = "utils/sbin/sox %s -r 16000 %s" % (wav_file_name, new_file_wav_file)
        easy_call(cmd)
        back_up = wav_file_name
        wav_file_name = new_file_wav_file

        # consts
        tmp_dir = "tmp_data/"
        tmp_data_file = "tmp.data"
        tmp_labels_file = "tmp.labels"

        # clean temporary files
        if os.path.exists(tmp_dir):
            shutil.rmtree(tmp_dir)

        # validation
        if not os.path.exists(wav_file_name):
            print >>sys.stderr, "wav file does not exits"
            return
        if not os.path.exists(tmp_dir):
            os.mkdir(tmp_dir)

        data_filename = os.path.abspath(tmp_dir+tmp_data_file)
        labels_filename = os.path.abspath(tmp_dir+tmp_labels_file)
        abs_wav_filename = os.path.abspath(wav_file_name)
        abs_text_grid_path = os.path.abspath(output_text_grid_file)

        # extract the features - the front end part
        os.chdir("front_end/")
        fe.main(abs_wav_filename, data_filename)
        os.chdir("../")

        os.chdir("utils/")
        # predict the vowel onset and offset
        model.main(data_filename, labels_filename)
        # convert the predictions into text grid file
        l2t.main(labels_filename, abs_wav_filename, abs_text_grid_path)
        os.chdir("../")
        
    except Exception as e:
        print(e.message)
        # remove leftovers
        if os.path.exists(tmp_dir):
            shutil.rmtree(tmp_dir)
        if os.path.exists(wav_file_name):
            os.remove(wav_file_name)
        return False
    finally:
        # remove leftovers
        if os.path.exists(tmp_dir):
            shutil.rmtree(tmp_dir)
        if os.path.exists(wav_file_name):
            os.remove(wav_file_name)
    return True

if __name__ == "__main__":
    # the first argument is the wav file path
    # the second argument is the TextGrid path
    # -------------MENU-------------- #
    # command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("wav_file_name", help="The wav file")
    parser.add_argument("output_text_grid_file", help="The output text grid file")
    args = parser.parse_args()

    # main function
    main(args.wav_file_name, args.output_text_grid_file)
