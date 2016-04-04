from lib.textgrid import TextGrid, IntervalTier, Interval
import os


def read_lengths(path, fave=0):
    data = dict()
    if not fave:
        for f in os.listdir(path):
            if f.endswith('.TextGrid'):
                abs_path = os.path.abspath(path+f)
                t = TextGrid()
                t.read(abs_path)
                onset = t._TextGrid__tiers[0]._IntervalTier__intervals[1]._Interval__xmin
                offset = t._TextGrid__tiers[0]._IntervalTier__intervals[1]._Interval__xmax
                data[f.lower()] = [f, onset, offset]
    else:
        for f in os.listdir(path):
            text_grid_penn = TextGrid()
            text_grid_penn.read(path + f)
            flag = 0
            for interval in text_grid_penn._TextGrid__tiers[0]._IntervalTier__intervals:
                if interval._Interval__mark.lower() == "sp":
                    flag = 1
                    continue
                if flag == 1:
                    flag = 2
                    continue
                if flag == 2:
                    onset = interval._Interval__xmin
                    offset = interval._Interval__xmax
                    break
            data[f.lower()] = [f, onset, offset]
    return data

# ====================== CHANGE THIS PATHS TO THE TEXT-GRID PATH IN YOUR COMPUTER ====================== #
dcm_path = '/Users/yossiadi/Projects/vowel_duration/docs/VD_Final_results/Jordana_predictions/DL_5_epochs/' \
           'structed_predict_classifier_DL/'
dcm_nc_path = '/Users/yossiadi/Projects/vowel_duration/docs/VD_Final_results/Jordana_predictions/DL_5_epochs/' \
              'structed_predict_no_classifier_DL/'
fave_path = '/Users/yossiadi/Projects/vowel_duration/docs/VD_Final_results/Jordana_predictions/Penn/fave/'

manual_path = '/Users/yossiadi/Projects/vowel_duration/db/stereo_16k_audio_files_short/'
manual_path_orig = '/Users/yossiadi/Projects/vowel_duration/db/first_labels/tbtw-textgrids/'


dcm_annotations = read_lengths(dcm_path)
dcm_nc_annotations = read_lengths(dcm_nc_path)
fave_annotations = read_lengths(fave_path, 1)
manual_annotations = read_lengths(manual_path)
orig_manual_annotations = read_lengths(manual_path_orig)

# validation, print mismatch files
for i in manual_annotations:
    if i not in orig_manual_annotations:
        print(i)
for i in orig_manual_annotations:
    if i not in manual_annotations:
        print(i)

output_dir = 'merge_textgrids/'
if not os.path.exists(output_dir):
    os.mkdir(output_dir)

# merge text grids and save them
for i in manual_annotations:
    if (i in dcm_annotations) and (i in dcm_nc_annotations) and (i in fave_annotations):
        t = TextGrid()
        t.read(manual_path_orig+orig_manual_annotations[i][0])
        start = t._TextGrid__xmin
        end = t._TextGrid__xmax
        length = end - start

        # ========= merge and save ========= #
        text_grid = TextGrid()

        # == DCM == #
        onset = orig_manual_annotations[i][1] - (manual_annotations[i][1] - dcm_annotations[i][1])
        offset = orig_manual_annotations[i][2] - (manual_annotations[i][2] - dcm_annotations[i][2]) - 0.01
        dcm_tier = IntervalTier(name='DCM', xmin=0.0, xmax=float(length))
        dcm_tier.append(Interval(0, float(onset), ""))
        dcm_tier.append(Interval(float(onset), float(offset), "vowel"))
        dcm_tier.append(Interval(float(offset), float(length), ""))
        text_grid.append(dcm_tier)

        # == DCM NC == #
        onset = orig_manual_annotations[i][1] - (manual_annotations[i][1] - dcm_nc_annotations[i][1])
        offset = orig_manual_annotations[i][2] - (manual_annotations[i][2] - dcm_nc_annotations[i][2]) - 0.01
        dcm_nc_tier = IntervalTier(name='DCM-NC', xmin=0.0, xmax=float(length))
        dcm_nc_tier.append(Interval(0, float(onset), ""))
        dcm_nc_tier.append(Interval(float(onset), float(offset), "vowel"))
        dcm_nc_tier.append(Interval(float(offset), float(length), ""))
        text_grid.append(dcm_nc_tier)

        # == FAVE == #
        onset = orig_manual_annotations[i][1] - (manual_annotations[i][1] - fave_annotations[i][1])
        offset = orig_manual_annotations[i][2] - (manual_annotations[i][2] - fave_annotations[i][2]) - 0.01
        fave_tier = IntervalTier(name='FAVE', xmin=0.0, xmax=float(length))
        fave_tier.append(Interval(0, float(onset), ""))
        fave_tier.append(Interval(float(onset), float(offset), "vowel"))
        fave_tier.append(Interval(float(offset), float(length), ""))
        text_grid.append(fave_tier)

        text_grid.write(output_dir+orig_manual_annotations[i][0])
