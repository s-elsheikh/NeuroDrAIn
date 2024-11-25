# NeuroDrAin
This is an end-to-end AI based pipeline for evaluation of CT examinations following minimally invasive surgery for acute intracerebral hemorrhage (ICH). The pipeline carries out automated ICH volumetry, quantification classification of drain position.

Follow up CT after minimally invasive surgery for acute intracerebral hemorrhage (ICH) is a common indication for CT-scans. Aim of the examination is to assess volume of ICH and to characterize the position of the drain tip as "correct" or "incorrect.
Manual volumetry is a time consuming task. ABC/2 method is prone to inaccuracies.

We developed a CNN-based model for segmentation of ICH and the drain ([segment_ich](https://github.com/s-elsheikh/segment_ich/)). A MATLAB (MATLAB R2021a, The MathWorks) script quantified the coverage profile of the ICB and drain segmentations. Machine learning algorithm classifies the position of the tip, using the coverage profile as correct or incorrect.

This repository includes all necessary files from another repository [segment_ich](https://github.com/s-elsheikh/segment_ich/) to run the complete pipeline.


## Recreating Environment

The pipeline requires python, MATLAB and R programming languages. Creating the environment using the supplied environment file installs all necessary dependancies, except for MATLAB, which requires a separate licence. 

```
conda env create -f environment.yml
conda activate NeuroDrAIn
```
## Description of scripts
### segment.py:
1. expects a non-contrast CT in NIfTI format, located in 'data/' folder. 
2. produces 'data/pred_drain_icb.nii.gz'. A 4D NIfTI object with two 3D 1-mm isotropic NIfTI volumes, indicating the probability of each voxel belonging to ICH/drain or the background.
3. The file names are hardcoded in the script. applying on multiple files/folders and renaming outputs were not implemented.
```
python_segment.py
```
### quantify_drain.m
1. expects the non-contrast CT in NIfTI format and the prediction file.
2. produces output_xx.json and output_xx.jpg. JSON file with proprotional coverage between the drain and the icb allong 1-mm steps of the drain for the first 60 mm from the drain tip. As well as a a plot of these values in jpg format. xx are numeric counters in cases of multiple drains in the same scan.
3. File names are supplied as command line arguments to the matlab script
```
matlab -nodisplay -nosplash -nodesktop -r "input1='/data/pred_drain_icb.nii.gz'; input2='/data/s_002.nii'; quantify_drain.m; exit;"
```
#### Outputs
Assuming input1='/data/pred_drain_icb.nii.gz' outputs are:
1. predicted volume of ICB: '/data/pred_drain_icb_volume_icb.json'
2. Island properties of both true and false detected drains: '/data/pred_drain_icb_properties.json' columns are: island number, followed by the 3 dimensions of the objects in mm, followed by volume in cubic mm.
3. Coverage profile for true detected drains: '/data/pred_drain_icb_profile_counter.json'. Counter is incremental numeric.
4. Plot of the coverage profile: '/data/pred_drain_icb_plot_counter.jpeg'. Counter is incremental numeric.


### predict_position.R

R script expects a folder path, loads all 'profile_counter.json' files, and classifies as correct or not correct.
Output is a csv called 'results.csv', contianing file path of the json and the prediction. 

```
Rscript --vanilla predict_position.R ./data
```
