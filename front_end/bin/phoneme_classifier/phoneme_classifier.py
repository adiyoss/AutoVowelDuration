#######################PHONEME_CODE########################
# -------------------------VOWELS--------------------------#
# 0  - ae - VOWEL                                         #                                                                                                       
# 1  - ah - VOWEL                                         #
# 2  - ao - VOWEL                                         #
# 3  - aw - VOWEL                                         #
# 4  - ay - VOWEL                                         #
# 10 - eh - VOWEL                                         #
# 13 - er - VOWEL                                         #
# 14 - ey - VOWEL                                         #
# 18 - ih - VOWEL                                         #
# 19 - iy - VOWEL                                         #
# 24 - ow - VOWEL                                         #
# 25 - oy - VOWEL                                         #
# 33 - uh - VOWEL                                         #
# 34 - uw - VOWEL                                         #
# -------------------------GLISED--------------------------#
# 11 - el - GLIDE                                         #
# 17 - hh - GLIDE                                         #
# 27 - r - GLIDE                                          #
# 36 - w - GLIDE                                          #
# 37 - y - GLIDE                                          #
# -------------------------NASALES-------------------------#
# 12 - en - NASAL                                         #
# 22 - m - NASAL                                          #
# 23 - ng - NASAL                                         #
# --------------------------STOPS--------------------------#
# 5  - b - STOP                                           #
# 7  - d - STOP                                           #
# 9  - dx - STOP                                          #
# 16 - g - STOP                                           #
# 21 - k - STOP                                           #
# 26 - p - STOP                                           #
# 31 - t - STOP                                           #
# -------------------------AFFRICATES----------------------#
# 6  - ch - AFFRICATE                                     #
# 20 - jh - AFFRICATE                                     #
# -------------------------FRICATIVES----------------------#
# 8  - dh - FRICATIVE                                     #
# 15 - f - FRICATIVE                                      # 
# 28 - s - FRICATIVE                                      #
# 29 - sh - FRICATIVE                                     #
# 32 - th - FRICATIVE                                     #
# 35 - v - FRICATIVE                                      #
# 38 - z - FRICATIVE                                      #
# ---------------------------OTHER-------------------------#
# 30 - sil - OTHER                                        #
###########################################################
# =========================================================
# ==================NASAL/GLIDE VERSION====================
# =========================================================
import argparse
import tempfile
import os
from subprocess import call
import wave
import math


def easy_call(command):
    try:
        print command
        call(command, shell=True)
    except Exception as exception:
        print "Error: could not execute the following"
        print ">>", command
        print type(exception)  # the exception instance
        print exception.args  # arguments stored in .args
        exit(-1)


if __name__ == "__main__":

    # command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("wav_filename", help="input WAV file name")
    parser.add_argument("textgrid_filename", help="output TextGrid file name")
    parser.add_argument("--scores_filename", default="", help="output scores matrix")
    args = parser.parse_args()

    # binaries
    sox_bin = "sbin/sox"
    hcopy_bin = "sbin/Hcopy"
    phoneme_classifier_bin = "bin/PhonemeFrameBasedDecode"
    htk_config = "config/htk.config"
    mfcc_stats_file = "config/mfcc.stats"
    phoneme_list_filename = "config/phonemes_39"
    mfcc_tmp_file = "config/tmp.mfcc"
    mfcc_extractor = "config/htk_ceps_dist"

    # frame-base phoneme classifier parameters
    phoneme_classifier_pad = "5"
    phoneme_classifier_SIGMA = "4.3589"
    phoneme_classifier_C = "1"
    phoneme_classifier_B = "0.8"
    phoneme_classifier_epochs = "1"
    phoneme_classifier_model = "models/pa_phoeneme_frame_based.C_%s.B_%s.sigma_%s.pad_%s.epochs_%s.model" % \
                               (phoneme_classifier_C, phoneme_classifier_B, phoneme_classifier_SIGMA,
                                phoneme_classifier_pad, phoneme_classifier_epochs)

    # generate intermediate files from a temp filename
    (tmp_fd, tmp_filename) = tempfile.mkstemp()
    wav_filename = tmp_filename + ".16kHz.wav"
    mfc_filename = tmp_filename + ".mfc"

    # read Wav file parameters
    wave_file = wave.Wave_read(args.wav_filename)
    wave_sampling_rate = wave_file.getframerate()
    wave_file.close()

    # converts WAV to 16kHz
    if wave_sampling_rate != 16000:
        cmd = "%s %s -r 16k %s remix 1" % (sox_bin, args.wav_filename, wav_filename)
        easy_call(cmd)
        rm_wav_file = True
    else:
        wav_filename = args.wav_filename
        rm_wav_file = False

    # extract MFCC features using HCopy utility
    cmd_params = "%s -C %s %s %s" % (hcopy_bin, htk_config, wav_filename, mfc_filename)
    easy_call(cmd_params)

    # predict phonemes from MFCCs
    if args.scores_filename != "":
        scores_filename = args.scores_filename
    else:
        scores_filename = tmp_filename + ".scores"
    mfcc_filelist = tmp_filename + ".mfc_list"
    fid = open(mfcc_filelist, 'w')
    fid.write(mfc_filename)
    fid.close()
    scores_filelist = tmp_filename + ".scores_list"
    fid = open(scores_filelist, 'w')
    fid.write(scores_filename)
    fid.close()
    cmd_params = "%s -n %s -kernel_expansion rbf3 -sigma %s -mfcc_stats %s -averaging -scores %s %s " \
                 "null %s %s" % (phoneme_classifier_bin, phoneme_classifier_pad, phoneme_classifier_SIGMA,
                                 mfcc_stats_file, scores_filelist, mfcc_filelist, phoneme_list_filename,
                                 phoneme_classifier_model)
    easy_call(cmd_params)

    # read phoneme list
    phoneme_list_file = open(phoneme_list_filename)
    phoneme_map = [line.rstrip() for line in phoneme_list_file]
    phoneme_list_file.close()

    # load matrix of scores and build phoneme with start and end times
    scores_file = open(scores_filename)
    header_read = False
    prev_max_phoneme = ''
    prev_max_score = 0
    prev_start_frame = 0
    current_frame = 0
    phonemes = list()
    vowels = {0, 1, 2, 3, 4, 10, 13, 14, 18, 19, 24, 25, 33, 34}
    nasals = {12, 22, 23}
    glides = {11, 17, 27, 36, 37}
    sil = 30

    for line in scores_file:
        line.rstrip()
        # skip the first line
        if not header_read:
            header_read = True
        else:
            vector_row = list()
            scores = map(float, line.split())

            # zero-one function for the vowels
            scores_arg_max = max(enumerate(scores), key=lambda x: x[1])[0]

            isVowel = 0
            isNasal = 0
            isGlide = 0
            isSil = 0

            # find out if the phoneme with the highest score is vowel
            if scores_arg_max in vowels:
                isVowel = 1
            # find out if the phoneme with the highest score is nasals
            if scores_arg_max in nasals:
                isNasal = 1

            # find out if the phoneme with the highest score is glides
            if scores_arg_max == glides:
                isGlide = 1

            # find out if the phoneme with the highest score is sil
            if scores_arg_max == sil:
                isSil = 1

            vector_row.append(isVowel)
            vector_row.append(isNasal)
            vector_row.append(isGlide)
            vector_row.append(isSil)

            # exp sum over vowels/nasals/glides
            sum_vowels = 0
            sum_nasals = 0
            sum_glides = 0

            # exp sum over glides
            sum_total = 0

            for phoneme in range(0, len(scores)):
                # add the vowel value
                if phoneme in vowels:
                    sum_vowels += math.exp(scores[phoneme])
                # add the nasal value
                if phoneme in nasals:
                    sum_nasals += math.exp(scores[phoneme])
                # add the glide value
                if phoneme in glides:
                    sum_glides += math.exp(scores[phoneme])
                sum_total += math.exp(scores[phoneme])

            vector_row.append(sum_vowels / sum_total)
            vector_row.append(sum_nasals / sum_total)
            vector_row.append(sum_glides / sum_total)
            phonemes.append(vector_row)

    # extract the mfcc feature mappings from the file
    mfcc_feature_map_command = mfcc_extractor + " " + str(mfc_filename) + " " + mfcc_stats_file + " " + mfcc_tmp_file
    easy_call(mfcc_feature_map_command)

    # append the mfcc data to the phonemes data and write the output file
    file_data = open(mfcc_tmp_file, 'r')
    data_lines = file_data.readlines()
    textFile = open(args.textgrid_filename, 'w')
    count = 1
    for item in phonemes:
        for i in range(2):
            for value in item:
                textFile.write(str(value) + ' ')
            textFile.write(data_lines[count])
        count += 1

    textFile.close()
    file_data.close()

    # remove all temporary files
    os.remove(mfcc_tmp_file)
    os.remove(mfc_filename)
    if args.scores_filename == "":
        os.remove(scores_filename)
    os.remove(mfcc_filelist)
    os.remove(scores_filelist)
