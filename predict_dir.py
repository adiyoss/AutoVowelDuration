import argparse
import os

from predict import main


def run_dir(in_path, out_path):
    f = open('error.txt', 'w')
    cwd = os.getcwd()
    for item in os.listdir(in_path):
        os.chdir(cwd)
        e = True
        if item.endswith('.wav'):
            out_file_path = out_path + item.replace('.wav', '.TextGrid')
            if not os.path.exists(out_file_path):
                e = main(in_path + item, out_file_path)
        if not e:
            f.write(item+'\n')
            print('ERROR with file: ' + item)
    f.close()

if __name__ == "__main__":
    # the first argument is the wav file path
    # the second argument is the TextGrid path
    # -------------MENU-------------- #
    # command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("in_dir", help="The input directory")
    parser.add_argument("out_dir", help="The output directory")
    args = parser.parse_args()

    # main function
    run_dir(args.in_dir, args.out_dir)
