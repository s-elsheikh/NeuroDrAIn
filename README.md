# NeuroDrAin
NeuroDrAin is an end-to-end AI-based pipeline for evaluating CT scans following minimally invasive surgery for acute intracerebral hemorrhage (ICH). The pipeline automates ICH volumetry, quantifies drainage coverage by the ICH, and classifies the drain tip position as 'correct' or 'not correct'.

Follow-up CT scans after minimally invasive surgery for ICH are commonly used to assess the volume of ICH and evaluate the drain tip position, classifying it as either "correct" or "incorrect." Manual volumetry is time-consuming, and the ABC/2 method is prone to inaccuracies.

We previously developed a CNN-based model for segmenting ICH and drain structures [Accuracy of automated segmentation and volumetry of acute intracerebral hemorrhage following minimally invasive surgery using a patch‑based convolutional neural network in a small dataset](https://rdcu.be/dyUGM) ([segment_ich](https://github.com/s-elsheikh/segment_ich/)). 

We describe a MATLAB script, that quantifies the coverage profile of ICH and drain segmentations. As well as a machine learning algorithm then uses this coverage profile to classify the tip position as "correct" or "incorrect." (under review). 

This repository includes all necessary files from the [segment_ich](https://github.com/s-elsheikh/segment_ich/) repository to run the complete pipeline.


## Environment Setup

The pipeline requires Python, MATLAB, and R programming languages. The python environment can be setup using: 

```
conda env create -f environment.yml
conda activate NeuroDrAIn
```

This will install [Patchwork CNN Toolbox](https://bitbucket.org/reisert/patchwork/src/master/) including necessary dependancies. 

A MATLAB installation including [Tools for NIfTI and ANALYZE image](https://de.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image) is required. 

An R session including [caret](https://CRAN.R-project.org/package=caret), [jsonlite](https://CRAN.R-project.org/package=jsonlite) and [stepPlr](https://CRAN.R-project.org/package=stepPlr) are required. Please refer to [Session Info](session_info.txt). 


## Description of scripts
### segment.py:
1. Expects a non-contrast CT scan in NIfTI format, located in the `data/` folder. 
2. Produces `data/pred_drain_icb.nii.gz`, a 4D NIfTI object containing two 3D isotropic NIfTI volumes (1-mm resolution) indicating the probability of each voxel belonging to ICH/drain or background.
3. File names are hardcoded in the script. Batch processing of multiple files or renaming outputs has not been implemented.

#### Usage

```
python3 python_segment.py
```
------------------------------------------------------------------------------------------------------------

### quantify_drain.m
1. expects the non-contrast CT in NIfTI format and the prediction file.
2. File names are supplied as command-line arguments to the MATLAB script.

#### Plot of sample data

![Sample data resulting from  `quantify_drain.m`, showing an example of a correct and of a not correct position](images/coverage_profile.png)




#### Usage

**Not tested**

```
matlab -nodisplay -nosplash -nodesktop -r "input1='/data/pred_drain_icb.nii.gz'; input2='/data/s_002.nii'; quantify_drain.m; exit;"
```
#### Outputs
Assuming input1='/data/pred_drain_icb.nii.gz' outputs are:
1. **Predicted ICH volume:**
'/data/pred_drain_icb_volume_icb.json'
3. **Drain Properties:**
'/data/pred_drain_icb_properties.json' 
  * Contains properties of detected drains (true and false positives), including the island number, dimensions (in mm), and volume (in cubic mm).
5. **Coverage profile:**
'/data/pred_drain_icb_profile_counter.json' (incremental numeric counters).
6. **Coverage Profile Plot:**
'/data/pred_drain_icb_plot_counter.jpeg' (incremental numeric counters).

------------------------------------------------------------------------------------------------------------

### predict_position.R

The R script expects a folder path containing all `profile_counter.json` files. It classifies each drain tip as "correct" or "incorrect" and outputs the results in a CSV file.

#### Usage

```
Rscript --vanilla predict_position.R data
```
--------------------------------------------------------------------------------------------------------------

This project is licensed under the [MIT License](LICENSE).

