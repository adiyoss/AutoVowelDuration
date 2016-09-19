import argparse
import os


def main(data_files, label_files, output_file):
    abs_data = os.path.abspath(data_files)
    abs_label = os.path.abspath(label_files)
    abs_output = os.path.abspath(output_file)
    names = list()
    suffix_x = '.data'
    suffix_y = '.labels'
    for item in os.listdir(abs_data):
        if item.endswith(suffix_x) and os.path.exists(abs_label+'/'+item.replace(suffix_x, suffix_y)):
            row_str = str(abs_data+'/'+item) + ' ' + str(abs_label+'/'+item.replace(suffix_x, suffix_y)) + '\n'
            names.append(row_str)

    with open(abs_output, 'w') as f:
        for r in names:
            f.write(r)

if __name__ == "__main__":
    # -------------MENU-------------- #
    # command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("data_files", help="The path the dir with the features")
    parser.add_argument("label_files", help="The path the dir with the labels")
    parser.add_argument("output_file", help="The output file")
    args = parser.parse_args()

    # main function
    main(args.data_files, args.label_files, args.output_file)