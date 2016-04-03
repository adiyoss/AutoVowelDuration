__author__ = 'yossiadi'

import os
import sys
import shutil
import argparse
from subprocess import call


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


# main function
def main(data_filename, output_labels_file):
    # consts
    file_out = "back_end/res/files.txt"
    back_end_dir = "back_end/"
    runnable_jar = "run_vowel_predict.sh"
    log_file = "back_end/res/res.txt"
    tmp_dir = "tmp/"
    tmp_file = "tmp.txt"

    # validation
    if not os.path.exists(data_filename):
        print >>sys.stderr, "data(features) file does not exits"
        return
    if not os.path.exists(tmp_dir):
        os.mkdir(tmp_dir)

    # create the label file
    labels_path = tmp_dir+tmp_file
    tmp_fid = open(labels_path, 'w')
    tmp_fid.write("1 2\n")
    tmp_fid.write("0 0\n")
    tmp_fid.close()

    # create the data file
    abs_path_data = os.path.abspath(data_filename)
    abs_path_label = os.path.abspath(labels_path)
    fid = open(file_out, 'w')
    fid.write(abs_path_data+" "+abs_path_label)
    fid.close()

    # extract the onset and offset of the vowel
    os.chdir(back_end_dir)
    cmd = "sh %s" % runnable_jar
    easy_call(cmd)
    os.chdir("../")

    # copy the result to the desired place and remove leftovers
    shutil.copy(log_file, output_labels_file)
    os.remove(log_file)
    os.remove(file_out)
    shutil.rmtree(tmp_dir)

if __name__ == "__main__":
    # the first argument is the data file path
    # the second argument is the output path
    # -------------MENU-------------- #
    # command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("data_filename", help="The data(features) file")
    parser.add_argument("output_labels_file", help="The output labels file")
    args = parser.parse_args()

    # main function
    main(args.data_filename, args.output_labels_file)
