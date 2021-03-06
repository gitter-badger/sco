SHELL := /bin/bash

# for full stimuli, use the following:
STIMULI_IDX := $(shell seq 69 224)

# for testing:
# STIMULI_IDX := $(shell seq 69 73)

VOXEL_IDX = $(shell seq 0 2)

# KNK_PATH=/home/billbrod/Documents/Kendrick-socmodel/code/
KNK_PATH=/Users/winawerlab/matlab/git/knkutils/
SUBJ=test-sub
SUBJ_DIR=/Volumes/server/Freesurfer_subjects
# SUBJ_DIR=/home/billbrod/Documents/SCO-test-data/Freesurfer_subjects

# make sure matlab is in your path, which it may not be by default if you're on Mac.

# for our stimuli, we use the pictures from Kay2013, which Kendrick
# provides on his website.
stimuli.mat : 
	wget -q http://kendrickkay.net/socmodel/stimuli.mat
        # we need to do this to get the stimuli.mat into the format we want
	matlab -nodesktop -nodisplay -r "load('$@','images'); save('$@','images'); quit"

soc_model_params.csv : stimuli.mat
	python2.7 model_comparison_script.py $< $(SUBJ) $@ $(STIMULI_IDX) -v $(VOXEL_IDX) -s $(SUBJ_DIR)

voxel_idx.txt :
	#  we don't need to increment these voxel indices because this
	#  refers to actual values in the dataframe / table
	echo $(VOXEL_IDX) > $@

stim_idx.txt :
	echo $(STIMULI_IDX) > $@
	# for stimuli indices, we need to increment them by one to
	# turn them from python into matlab indices.
	python2.7 sco/model_comparison/py_to_matlab.py -p2m $@

MATLAB_soc_model_params.csv : soc_model_params.csv voxel_idx.txt stim_idx.txt
	matlab -nodesktop -nodisplay -r "cd $(shell pwd)/sco/model_comparison; compareWithKay2013('$(KNK_PATH)', '$(shell pwd)/stimuli.mat', '$(shell pwd)/stim_idx.txt', '$(shell pwd)/voxel_idx.txt', '$(shell pwd)/$<', '$(shell pwd)/soc_model_params_image_names.mat', '$(shell pwd)/$@'); quit;"

.PHONY : images
# this will create several images, with names based on the default options in sco/model_comparison/core.py
images : MATLAB_soc_model_params.csv stimuli.mat soc_model_params.csv
	python2.7 sco/model_comparison/core.py $< soc_model_params_image_names.mat sco/model_comparison/stimuliNames.mat stimuli.mat $(STIMULI_IDX)

.PHONY : cleantmps
cleantmps :
	-rm voxel_idx.txt
	-rm stim_idx.txt

.PHONY : fullclean
fullclean : cleantmps
	-rm soc_model_params.csv
	-rm soc_model_params_image_names.mat
	-rm MATLAB_soc_model_params.csv
