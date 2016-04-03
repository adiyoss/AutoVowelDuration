# coding=utf-8
# !/usr/bin/env python

import sys
import os
import shutil
import argparse
from subprocess import call
import numpy as np

__author__ = 'yossiadi'


# run system commands
def easy_call(command):
    try:
        call(command, shell=True)
    except Exception as exception:
        print "Error: could not execute the following"
        print ">>", command
        print type(exception)  # the exception instance
        print exception.args  # arguments stored in .args
        exit(-1)


def extract_acoustic_features(input_file, feature_file, label_file):
    if os.path.exists(input_file) and os.path.exists(feature_file) and os.path.exists(label_file):
        command = "./bin/VowelDurationFrontEnd %s %s %s" % (input_file, feature_file, label_file)
        easy_call(command)

        # remove leftovers
        os.remove(input_file)
        os.remove(feature_file)
        os.remove(label_file)


# get the length of the wav file
def get_wav_file_length(wav_file):
    import wave
    import contextlib
    with contextlib.closing(wave.open(wav_file, 'r')) as f:
        frames = f.getnframes()
        rate = f.getframerate()
        duration = frames / float(rate)
        return duration


def copy_arrays(arr1, arr2):
    """
    :rtype :
    """
    if len(arr1) == len(arr2):
        return arr2

    if len(arr1) >= len(arr2):
        for i in range(0, len(arr2)):
            arr1[i] = arr2[i]
        return arr1

    if len(arr1) <= len(arr2):
        for i in range(0, len(arr1)):
            arr1[i] = arr2[i]
        return arr1


# input: phoneme_classifier_path  - classifier path
#        wav_file                 - wave files path
#        features_file            - features path

# output: the new data with the phoneme classifier feature will
# be at the data_features_path inside dir called plus_phonemes
def add_phomene_classifier(phoneme_classifier_path, wav_file, features_file):
    # consts
    tmp_file_name = "phonemes/phones.txt"
    phone_dir = "phonemes/"
    plus_phone_dir = "plus_phonemes/"

    # validation
    if not os.path.exists(wav_file):
        print >> sys.stderr, "wav file does not exits"
        return
    if not os.path.exists(phone_dir):
        os.makedirs(phone_dir)
    current_dir = os.getcwd()

    command = 'python ' + current_dir + "/" + phoneme_classifier_path + " " + wav_file + " " + tmp_file_name
    easy_call(command)

    if not os.path.exists(plus_phone_dir):
        os.makedirs(plus_phone_dir)

    data_file = open(features_file)
    file_name = features_file.split('/')

    phoneme_file = open(tmp_file_name)
    out_file = open(plus_phone_dir + file_name[len(file_name) - 1], 'wb')

    data_file = data_file.readlines()
    phoneme_file_lines = phoneme_file.readlines()
    is_first = True

    for index in range(0, min(len(data_file), len(phoneme_file_lines))):
        # writes the first line as is
        if is_first:
            out_file.write(data_file[0])
            is_first = False
            continue

        values = data_file[index].split('\n')
        new_line = values[0].rsplit(' ', 1)[0]
        new_line = new_line + ' ' + phoneme_file_lines[index]
        out_file.write(new_line)

    # data_file.close()
    phoneme_file.close()
    out_file.close()
    shutil.rmtree(phone_dir)


# smooth and normalize the voicing, pitch, vowels, nasals and glides
def smooth_features(data_file):
    pitch = 6
    voicing = 7
    vowel = 9
    nasal = 10
    glide = 11
    sil = 12

    # smoothing all the relevant features
    data = np.loadtxt(data_file, skiprows=1)
    window_size = 60
    mask = np.hamming(window_size)
    smooth_pitch = np.convolve(data[:, pitch], mask, 'same')
    smooth_voicing = np.convolve(data[:, voicing], mask, 'same')

    smooth_vowels = np.convolve(data[:, vowel], mask, 'same')
    smooth_nasal = np.convolve(data[:, nasal], mask, 'same')
    smooth_glide = np.convolve(data[:, glide], mask, 'same')
    smooth_sil = np.convolve(data[:, sil], mask, 'same')

    high = 1.0
    low = 0.0

    min_val = np.min(smooth_pitch)
    max_val = np.max(smooth_pitch)
    rng = max_val - min_val
    scaled_points = high - (((high - low) * (max_val - smooth_pitch)) / rng)
    data[:, pitch] = copy_arrays(data[:, pitch], scaled_points)

    min_val = np.min(smooth_voicing)
    max_val = np.max(smooth_voicing)
    rng = max_val - min_val
    scaled_points = high - (((high - low) * (max_val - smooth_voicing)) / rng)
    data[:, voicing] = copy_arrays(data[:, voicing], scaled_points)

    # vowels
    min_val = np.min(smooth_vowels)
    max_val = np.max(smooth_vowels)
    rng = max_val - min_val
    scaled_points = high - (((high - low) * (max_val - smooth_vowels)) / rng)
    data[:, vowel] = copy_arrays(data[:, vowel], scaled_points)

    # nasals
    min_val = np.min(smooth_nasal)
    max_val = np.max(smooth_nasal)
    rng = max_val - min_val
    scaled_points = high - (((high - low) * (max_val - smooth_nasal)) / rng)
    data[:, nasal] = copy_arrays(data[:, nasal], scaled_points)

    # glides
    min_val = np.min(smooth_glide)
    max_val = np.max(smooth_glide)
    rng = max_val - min_val
    scaled_points = high - (((high - low) * (max_val - smooth_glide)) / rng)
    data[:, glide] = copy_arrays(data[:, glide], scaled_points)

    # sil
    min_val = np.min(smooth_sil)
    max_val = np.max(smooth_sil)
    rng = max_val - min_val
    scaled_points = high - (((high - low) * (max_val - smooth_sil)) / rng)
    data[:, sil] = copy_arrays(data[:, sil], scaled_points)

    # remove the old file and write the new one
    os.remove(data_file)
    np.savetxt(data_file, data)


def add_formants(data_path, wav_path, praat_command):
    # consts
    tmp_dir = "tmp/"
    if not os.path.exists(tmp_dir):
        os.makedirs(tmp_dir)

    file_name = wav_path.split('/')
    csv_file_name = file_name[len(file_name) - 1].replace('.wav', '.csv')
    abs_path_dir = os.path.abspath(tmp_dir)
    shutil.copy(wav_path, abs_path_dir)

    command = praat_command + ' bin/Extract_F1_F2.praat ' + abs_path_dir + " " + abs_path_dir + " .wav"
    os.system(command)

    ifile = open(tmp_dir + csv_file_name)
    filename = csv_file_name.split(".")
    ofile = open(tmp_dir + filename[0] + ".txt", "w")
    data = ifile.readlines()
    for line in data:
        line = line.replace("?", "0")
        ofile.write(line)
    ofile.close()
    ifile.close()
    os.remove(tmp_dir + csv_file_name)

    # Normalize the formants first
    for _file in os.listdir(tmp_dir):
        if _file.endswith(".txt"):
            data = np.loadtxt(tmp_dir + _file, skiprows=1)

            # normalizing the features and save them
            high = 1.0
            low = 0.0
            # F1
            min_val = np.min(data[:, 0])
            max_val = np.max(data[:, 0])
            rng = max_val - min_val
            scaled_points = high - (((high - low) * (max_val - data[:, 0])) / rng)
            data[:, 0] = scaled_points
            # F2
            min_val = np.min(data[:, 1])
            max_val = np.max(data[:, 1])
            rng = max_val - min_val
            scaled_points = high - (((high - low) * (max_val - data[:, 1])) / rng)
            data[:, 1] = scaled_points

            np.savetxt(tmp_dir + _file, data)

    data_fid = open(data_path)
    file_name = wav_path.split('.')

    formants_file = file_name[0].split('/')
    formants_fid = open(tmp_dir + formants_file[len(formants_file) - 1] + '.txt')
    features_filename = data_fid.name.split('/')
    out_file = open(tmp_dir + features_filename[len(features_filename) - 1], 'wb')

    data_file = data_fid.readlines()
    formants_file_lines = formants_fid.readlines()
    counter_data = 0
    counter_formants = -1
    general_count = 0

    for data_line in data_file[0:]:
        values = data_line.split('\n')
        newLine = values[0].rsplit(' ', 0)[0]

        # here we decide how many times to multiple the features
        if general_count % 2 == 0:
            counter_formants += 1

        # validation
        if counter_data >= len(formants_file_lines):
            break

        filtered_formants_line = formants_file_lines[counter_formants].replace("\t", " ")
        newLine = newLine + ' ' + filtered_formants_line
        counter_data += 1
        general_count += 1
        out_file.write(newLine)

    data_fid.close()
    formants_fid.close()
    out_file.close()

    # remove leftovers and update the features file
    shutil.copy(tmp_dir + features_filename[len(features_filename) - 1], data_fid.name)
    shutil.rmtree(tmp_dir)


def main(wav_file, output_data):
    # defines
    tmp_dir = "tmp/"
    tmp_input = "tmp.input"
    tmp_label = "tmp.labels"
    tmp_features = "tmp.features"
    tmp_file = "tmp.wav"
    zero = 0.01

    praat_app = "/Applications/Praat.app/Contents/MacOS/Praat"
    output_data = os.path.abspath(output_data)

    # validation
    if not os.path.exists(wav_file):
        print >> sys.stderr, "wav file does not exits"
        return
    if not os.path.exists(tmp_dir):
        os.mkdir(tmp_dir)

    cmd = "sbin/sox %s -r 16000 -b 16 %s" % (wav_file, tmp_file)
    easy_call(cmd)

    # =================== ACOUSTIC FEATURES =================== #
    # creating the files
    input_file = open(tmp_dir + tmp_features, 'wb')  # open the input file for the feature extraction
    features_file = open(tmp_dir + tmp_input, 'wb')  # open file for the feature list path
    labels_file = open(tmp_dir + tmp_label, 'wb')  # open file for the labels
    length = get_wav_file_length(tmp_file)

    # write the data
    input_file.write(
        '"' + tmp_file + '" ' + str('%.8f' % 0) + ' ' + str(float(length) - zero) + ' ' + str('%.8f' % 0) + ' ' + str(
            '%.8f' % 0))
    features_file.write(output_data)

    input_file.close()
    features_file.close()
    labels_file.close()

    # extract the first nine acoustic features
    extract_acoustic_features(input_file.name, features_file.name, labels_file.name)
    # ========================================================= #

    # ================== PHONEME CLASSIFIER =================== #
    # extract the phonemes and merge the files
    abs_path = os.path.abspath(tmp_file)
    os.chdir("bin/phoneme_classifier")
    add_phomene_classifier('phoneme_classifier.py', abs_path, output_data)
    os.chdir("../..")

    # remove leftovers
    os.remove(output_data)
    file_name = output_data.split('/')
    shutil.copy("bin/phoneme_classifier/plus_phonemes/" + file_name[len(file_name) - 1], output_data)
    shutil.rmtree("bin/phoneme_classifier/plus_phonemes/")
    # ======================================================== #

    # =================== SMOOTH FEATURES ==================== #
    smooth_features(output_data)
    # ======================================================== #

    # # =================== FORMANT F1 & F2 ==================== #
    # add_formants(output_data, wav_file, praat_app)
    # # ======================================================== #

    # remove left overs
    shutil.rmtree(tmp_dir)
    if os.path.exists(tmp_file):
        os.remove(tmp_file)


if __name__ == "__main__":
    # the first argument is the wav file
    # the second argument is output .data features
    # -------------MENU-------------- #
    # command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("wav_filename", help="The wav file")
    parser.add_argument("output_data", help="The output data file(features)")
    args = parser.parse_args()

    # main function
    main(args.wav_filename, args.output_data)
