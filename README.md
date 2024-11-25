# ich_drain_position
Intracerebral hemorrhage volumetry, quantification classification of drain position.

Follow up CT after minimally invasive surgery for acute intracerebral hemorrhage (ICH) is a common indication for CT-scans. Aim of the examination is to assess volume of ICH and to characterize the position of the drain tip as "correct" or "incorrect.

Manual volumetry is a time consuming task. ABC/2 method is prone to inaccuracies.

We developed a CNN-based model for segmentation of ICH and the drain. A MATLAB (MATLAB R2021a, The MathWorks) script quantified the coverage profile of the ICB and drain segmentations. MAchine learning algorithm classifies the position of the tip, using the coverage profile as correct or incorrect.

## Description of scripts
### segment.py:
1. expects a non-contrast CT in NIfTI format.
2. produces prediction.nii.gz. A 4D NIfTI object with two 3D 1-mm isotropic NIfTI volumes, indicating the probability of each voxel belonging to ICH/drain or the background.
### quantify_drain.m
1. expects the non-contrast CT in NIfTI format and the prediction.nii.gz
2. produces output_xx.json and output_xx.jpg. JSON file with proprotional coverage between the drain and the icb allong 1-mm steps of the drain for the first 60 mm from the drain tip. As well as a a plot of these values in jpg format. xx are numeric counters in cases of multiple drains in the same scan.
### predict.R
1. expects output_xx.json
2. produces: binary classifcation of the tip as "correct" or "incorrect"
 
## Recreating Environment
```
conda env create -f full_env.yml
conda activate segment_ich
python segment.py
matlab -nodisplay -nosplash -r "quantify_drain.m('path/to/input/file.nii', 'path/to/output/newfile.nii'); exit;"
Rscript predict.R
```

Licence




1. using old repo, produce predictions
2. run matlab script, saves outputs to same folder as predictions, using naming comvention
matlab -nodisplay -nosplash -nodesktop -r "input1='path/to/prediction.nii'; input2='path/to/non_contrast_ct.nii'; matlabscript; exit;"


assuming input1='path/to/prediction.nii' outputs are:
1. predicted volume of ICB: 'path/to/prediction_icb_volume.json'
2. Island properties of both true and false detected drains: 'path/to/prediction_properties.json' columns are: island number, followed by 3 dimensions of the objects in mm, followed by volume in cubic mm.
3. Coverage profile for true detected drains: 'path/to/prediction_profile_counter.json'. Counter is incremental numeric.
4. Plot of the coverage profile: 'path/to/prediction_plot_counter.jpeg'. Counter is incremental numeric.


R script expects a folder path, loads all 'profile_counter.json' files, and classifies as correct or not correct.
Output is a csv called 'results.csv', contianing file path of the json and the prediction. 
