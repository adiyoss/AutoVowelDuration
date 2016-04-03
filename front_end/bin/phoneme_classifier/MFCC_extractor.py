import argparse
import tempfile
import os
from subprocess import call
import wave


def easy_call(command):
    try:
        print command
        call(command, shell=True)
    except Exception as exception:
        print "Error: could not execute the following"
        print ">>", command
        print type(exception)     # the exception instance
        print exception.args      # arguments stored in .args
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
            (phoneme_classifier_C, phoneme_classifier_B, phoneme_classifier_SIGMA, phoneme_classifier_pad, phoneme_classifier_epochs)

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
    
    # extract the mfcc feature mappings from the file
    mfcc_feature_map_command = mfcc_extractor+" "+str(mfc_filename)+" "+mfcc_stats_file+" "+mfcc_tmp_file
    easy_call(mfcc_feature_map_command)

    file_data = open(mfcc_tmp_file, 'r')    
    data_lines = file_data.readlines()    
    textFile = open(args.textgrid_filename, 'w')
    flag = True
    for line in data_lines:
        if flag == False:
            for i in range(2):
                textFile.write(line)
        else:
            textFile.write(line)
            flag = False

    textFile.close()        
    file_data.close()

    # remove all temporery files
    os.remove(mfcc_tmp_file)
    os.remove(mfc_filename)
    os.remove(mfcc_filelist)
    os.remove(scores_filelist)

